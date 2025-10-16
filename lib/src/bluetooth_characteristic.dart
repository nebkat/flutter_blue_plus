// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import 'bluetooth_attribute.dart';
import 'bluetooth_descriptor.dart';
import 'bluetooth_events.dart';
import 'bluetooth_msgs.dart';
import 'bluetooth_service.dart';
import 'flutter_blue_plus.dart';
import 'utils.dart';
import 'uuid.dart';

const Uuid cccdUuid = Uuid.fromBytes([0x29, 0x02]);

class BluetoothCharacteristic extends BluetoothAttribute {
  final BluetoothService service;
  final CharacteristicProperties properties;
  late final List<BluetoothDescriptor> descriptors;

  @internal
  BluetoothCharacteristic.fromProto(BmBluetoothCharacteristic p, BluetoothService service)
      : service = service,
        properties = CharacteristicProperties.fromProto(p.properties),
        super(device: service.device, uuid: p.uuid, index: p.index) {
    descriptors = p.descriptors.map((d) => BluetoothDescriptor.fromProto(d, this)).toList();
  }

  @override
  BluetoothAttribute? get parentAttribute => service;

  late final StreamController<List<int>> _streamController = StreamController<List<int>>.broadcast(
    onListen: () async {
      try {
        await setNotifyValue(true);
      } catch (e, stack) {
        _streamController.addError(e, stack);
      }
    },
    onCancel: () async {
      if (device.isDisconnected) return;
      try {
        await setNotifyValue(false);
      } catch (e, stack) {
        _streamController.addError(e, stack);
      }
    },
  );

  Stream<List<int>> get notifications => _streamController.stream;

  /// convenience accessor
  BluetoothDescriptor? get cccd => descriptors.where((d) => d.uuid == cccdUuid).firstOrNull;

  /// read a characteristic
  Future<List<int>> read({Duration timeout = const Duration(seconds: 15)}) async {
    device.ensureConnected("readCharacteristics");

    // Only allow a single ble operation to be underway at a time
    return Mutex.global.protect(() async {
      var request = BmReadCharacteristicRequest(
        address: device.remoteId,
        identifier: identifierPath,
      );

      // invoke
      final futureResponse = FlutterBluePlus.invokeMethodAndWaitForEvent<OnCharacteristicReceivedEvent>(
        'readCharacteristic',
        request.toMap(),
        (e) => e.characteristic == this,
      );

      // wait for response
      OnCharacteristicReceivedEvent response = await futureResponse
          .fbpEnsureAdapterIsOn("readCharacteristic")
          .fbpEnsureDeviceIsConnected(device, "readCharacteristic")
          .fbpTimeout(timeout, "readCharacteristic");

      // failed?
      response.ensureSuccess('readCharacteristic');

      // set return value
      return response.value;
    });
  }

  /// Writes a characteristic.
  ///  - [withoutResponse]:
  ///       If `true`, the write is not guaranteed and always returns immediately with success.
  ///       If `false`, the write returns error on failure.
  ///  - [allowLongWrite]: if set, larger writes > MTU are allowed (up to 512 bytes).
  ///       This should be used with caution.
  ///         1. it can only be used *with* response
  ///         2. the peripheral device must support the 'long write' ble protocol.
  ///         3. Interrupted transfers can leave the characteristic in a partially written state
  ///         4. If the mtu is small, it is very very slow.
  Future<void> write(
    List<int> value, {
    bool withoutResponse = false,
    bool allowLongWrite = false,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    //  check args
    if (withoutResponse && allowLongWrite) {
      throw ArgumentError("cannot longWrite withoutResponse, not allowed on iOS or Android");
    }

    device.ensureConnected("writeCharacteristic");

    // Only allow a single ble operation to be underway at a time
    return Mutex.global.protect(() async {
      final writeType = withoutResponse ? BmWriteType.withoutResponse : BmWriteType.withResponse;

      var request = BmWriteCharacteristicRequest(
        address: device.remoteId,
        identifier: identifierPath,
        writeType: writeType,
        allowLongWrite: allowLongWrite,
        value: value,
      );

      // invoke
      final futureResponse = FlutterBluePlus.invokeMethodAndWaitForEvent<OnCharacteristicWrittenEvent>(
        'writeCharacteristic',
        request.toMap(),
        (e) => e.characteristic == this,
      );

      // wait for response so that we can:
      //  1. check for success (writeWithResponse)
      //  2. wait until the packet has been sent, to prevent iOS & Android dropping packets (writeWithoutResponse)
      OnCharacteristicWrittenEvent response = await futureResponse
          .fbpEnsureAdapterIsOn("writeCharacteristic")
          .fbpEnsureDeviceIsConnected(device, "writeCharacteristic")
          .fbpTimeout(timeout, "writeCharacteristic");

      // failed?
      response.ensureSuccess('writeCharacteristic');
    });
  }

  /// Sets notifications or indications for the characteristic.
  ///   - If a characteristic supports both notifications and indications,
  ///     we use notifications. This is a limitation of CoreBluetooth on iOS.
  ///   - [forceIndications] Android Only. force indications to be used instead of notifications.
  Future<bool> setNotifyValue(
    bool notify, {
    Duration timeout = const Duration(seconds: 15),
    bool forceIndications = false,
  }) async {
    device.ensureConnected("setNotifyValue");

    // check
    if (Platform.isMacOS || Platform.isIOS) {
      assert(forceIndications == false, "iOS & macOS do not support forcing indications");
    }

    // Only allow a single ble operation to be underway at a time
    await Mutex.global.protect(() async {
      var request = BmSetNotifyValueRequest(
        address: device.remoteId,
        identifier: identifierPath,
        forceIndications: forceIndications,
        enable: notify,
      );

      // Notifications & Indications are configured by writing to the
      // Client Characteristic Configuration Descriptor (CCCD)
      Stream<OnDescriptorWrittenEvent> responseStream =
          FlutterBluePlus.extractEventStream<OnDescriptorWrittenEvent>((m) => m.descriptor == cccd);

      // Start listening now, before invokeMethod, to ensure we don't miss the response
      Future<OnDescriptorWrittenEvent> futureResponse = responseStream.first;

      // invoke
      bool hasCCCD = await FlutterBluePlus.invokeMethod('setNotifyValue', request.toMap());

      // wait for CCCD descriptor to be written?
      if (hasCCCD) {
        OnDescriptorWrittenEvent response = await futureResponse
            .fbpEnsureAdapterIsOn("setNotifyValue")
            .fbpEnsureDeviceIsConnected(device, "setNotifyValue")
            .fbpTimeout(timeout, "setNotifyValue");

        // failed?
        response.ensureSuccess("setNotifyValue");
      }
    });

    return true;
  }

  @override
  String toString() {
    return '${(BluetoothCharacteristic)}{'
        'uuid: $uuid, '
        'properties: $properties, '
        'descriptors: $descriptors'
        '}';
  }
}

class CharacteristicProperties {
  final bool broadcast;
  final bool read;
  final bool writeWithoutResponse;
  final bool write;
  final bool notify;
  final bool indicate;
  final bool authenticatedSignedWrites;
  final bool extendedProperties;
  final bool notifyEncryptionRequired;
  final bool indicateEncryptionRequired;

  CharacteristicProperties.fromProto(BmCharacteristicProperties p)
      : broadcast = p.broadcast,
        read = p.read,
        writeWithoutResponse = p.writeWithoutResponse,
        write = p.write,
        notify = p.notify,
        indicate = p.indicate,
        authenticatedSignedWrites = p.authenticatedSignedWrites,
        extendedProperties = p.extendedProperties,
        notifyEncryptionRequired = p.notifyEncryptionRequired,
        indicateEncryptionRequired = p.indicateEncryptionRequired;

  @override
  String toString() {
    return "[" +
        [
          if (broadcast) 'broadcast',
          if (read) 'read',
          if (writeWithoutResponse) 'writeWithoutResponse',
          if (write) 'write',
          if (notify) 'notify',
          if (indicate) 'indicate',
          if (authenticatedSignedWrites) 'authenticatedSignedWrites',
          if (extendedProperties) 'extendedProperties',
          if (notifyEncryptionRequired) 'notifyEncryptionRequired',
          if (indicateEncryptionRequired) 'indicateEncryptionRequired'
        ].join(", ") +
        "]";
  }
}
