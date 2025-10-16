// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'bluetooth_attribute.dart';
import 'bluetooth_characteristic.dart';
import 'bluetooth_events.dart';
import 'bluetooth_msgs.dart';
import 'flutter_blue_plus.dart';
import 'utils.dart';

class BluetoothDescriptor extends BluetoothAttribute {
  final BluetoothCharacteristic characteristic;

  BluetoothDescriptor.fromProto(BmBluetoothDescriptor p, BluetoothCharacteristic characteristic)
      : characteristic = characteristic,
        super(device: characteristic.device, uuid: p.uuid);

  @override
  BluetoothAttribute? get parentAttribute => characteristic;

  /// Retrieves the value of a specified descriptor
  Future<List<int>> read({Duration timeout = const Duration(seconds: 15)}) async {
    device.ensureConnected("readDescriptor");

    // Only allow a single ble operation to be underway at a time
    return Mutex.global.protect(() async {
      var request = BmReadDescriptorRequest(
        address: device.remoteId,
        identifier: identifierPath,
      );

      // Invoke
      final futureResponse = FlutterBluePlus.invokeMethodAndWaitForEvent<OnDescriptorReadEvent>(
        'readDescriptor',
        request.toMap(),
        (e) => e.descriptor == this,
      );

      // wait for response
      OnDescriptorReadEvent response = await futureResponse
          .fbpEnsureAdapterIsOn("readDescriptor")
          .fbpEnsureDeviceIsConnected(device, "readDescriptor")
          .fbpTimeout(timeout, "readDescriptor");

      // failed?
      response.ensureSuccess("readDescriptor");

      return response.value;
    });
  }

  /// Writes the value of a descriptor
  Future<void> write(List<int> value, {Duration timeout = const Duration(seconds: 15)}) async {
    device.ensureConnected("writeDescriptor");

    // Only allow a single ble operation to be underway at a time
    await Mutex.global.protect(() async {
      var request = BmWriteDescriptorRequest(
        address: device.remoteId,
        identifier: identifierPath,
        value: value,
      );

      // invoke
      final futureResponse = FlutterBluePlus.invokeMethodAndWaitForEvent<OnDescriptorWrittenEvent>(
        'writeDescriptor',
        request.toMap(),
        (e) => e.descriptor == this,
      );

      // wait for response
      OnDescriptorWrittenEvent response = await futureResponse
          .fbpEnsureAdapterIsOn("writeDescriptor")
          .fbpEnsureDeviceIsConnected(device, "writeDescriptor")
          .fbpTimeout(timeout, "writeDescriptor");

      // failed?
      response.ensureSuccess("writeDescriptor");
    });
  }

  @override
  String toString() {
    return '${(BluetoothDescriptor)}{'
        'uuid: $uuid'
        '}';
  }
}
