import 'bluetooth_attribute.dart';
import 'bluetooth_characteristic.dart';
import 'bluetooth_descriptor.dart';
import 'bluetooth_device.dart';
import 'bluetooth_msgs.dart';
import 'bluetooth_utils.dart';
import 'flutter_blue_plus.dart';

class BluetoothEvents {
  Stream<OnConnectionStateChangedEvent> get onConnectionStateChanged =>
      FlutterBluePlus.extractEventStream<OnConnectionStateChangedEvent>();

  Stream<OnMtuChangedEvent> get onMtuChanged => FlutterBluePlus.extractEventStream<OnMtuChangedEvent>();

  Stream<OnReadRssiEvent> get onReadRssi => FlutterBluePlus.extractEventStream<OnReadRssiEvent>();

  Stream<OnServicesResetEvent> get onServicesReset => FlutterBluePlus.extractEventStream<OnServicesResetEvent>();

  Stream<OnDiscoveredServicesEvent> get onDiscoveredServices =>
      FlutterBluePlus.extractEventStream<OnDiscoveredServicesEvent>();

  Stream<OnCharacteristicReceivedEvent> get onCharacteristicReceived =>
      FlutterBluePlus.extractEventStream<OnCharacteristicReceivedEvent>();

  Stream<OnCharacteristicWrittenEvent> get onCharacteristicWritten =>
      FlutterBluePlus.extractEventStream<OnCharacteristicWrittenEvent>();

  Stream<OnDescriptorReadEvent> get onDescriptorRead => FlutterBluePlus.extractEventStream<OnDescriptorReadEvent>();

  Stream<OnDescriptorWrittenEvent> get onDescriptorWritten =>
      FlutterBluePlus.extractEventStream<OnDescriptorWrittenEvent>();

  Stream<OnNameChangedEvent> get onNameChanged => FlutterBluePlus.extractEventStream<OnNameChangedEvent>();

  Stream<OnBondStateChangedEvent> get onBondStateChanged =>
      FlutterBluePlus.extractEventStream<OnBondStateChangedEvent>();
}

class FbpError {
  final int errorCode;
  final String errorString;
  ErrorPlatform get platform => ErrorPlatform.native;
  FbpError(this.errorCode, this.errorString);
}

//
// Mixins
//
mixin GetDeviceMixin {
  dynamic get _response;

  /// the relevant device
  BluetoothDevice get device => FlutterBluePlus.deviceForAddress(_response.remoteId);
}

mixin GetAttributeValueMixin {
  dynamic get _response;
  BluetoothAttribute get attribute;

  /// the new data
  List<int> get value => _response.value;
}

mixin GetCharacteristicMixin on GetAttributeValueMixin, GetDeviceMixin {
  /// the relevant characteristic
  BluetoothCharacteristic get characteristic => device.characteristicForIdentifier(_response.identifier);

  /// the relevant attribute
  BluetoothAttribute get attribute => characteristic;
}

mixin GetDescriptorMixin on GetAttributeValueMixin, GetDeviceMixin {
  /// the relevant descriptor
  BluetoothDescriptor get descriptor => device.descriptorForIdentifier(_response.identifier);

  /// the relevant attribute
  BluetoothAttribute get attribute => descriptor;
}

mixin GetExceptionMixin {
  BmStatus get _response;

  FbpError? get error => _response.success ? null : FbpError(_response.errorCode, _response.errorString);

  FlutterBluePlusException? exception(String method) => _response.success
      ? null
      : FlutterBluePlusException(ErrorPlatform.native, method, _response.errorCode, _response.errorString);

  void ensureSuccess(String method) {
    if (!_response.success) {
      throw exception(method)!;
    }
  }
}

//
// Event Classes
//

// On Detached From Engine
class OnDetachedFromEngineEvent {
  static const String method = "OnDetachedFromEngine";
}

// On Turn On Response
class OnTurnOnResponseEvent {
  static const String method = "OnTurnOnResponse";

  final BmTurnOnResponse _response;

  OnTurnOnResponseEvent(this._response);
  OnTurnOnResponseEvent.fromMap(Map<String, dynamic> map) : _response = BmTurnOnResponse.fromMap(map);

  /// user accepted response
  bool get userAccepted => _response.userAccepted;
}

// On Scan Response
class OnScanResponseEvent with GetExceptionMixin {
  static const String method = "OnScanResponse";

  final BmScanResponse _response;

  OnScanResponseEvent(this._response);
  OnScanResponseEvent.fromMap(Map<String, dynamic> map) : _response = BmScanResponse.fromMap(map);

  /// the new scan state
  List<ScanResult> get advertisements => _response.advertisements.map((a) => ScanResult.fromProto(a)).toList();
}

// On Connection State Changed
class OnConnectionStateChangedEvent with GetDeviceMixin {
  static const String method = "OnConnectionStateChanged";

  final BmConnectionStateResponse _response;

  OnConnectionStateChangedEvent(this._response);
  OnConnectionStateChangedEvent.fromMap(Map<String, dynamic> map) : _response = BmConnectionStateResponse.fromMap(map);

  /// the new connection state
  BluetoothConnectionState get connectionState => bmToConnectionState(_response.connectionState);

  /// the disconnect reason
  DisconnectReason? get disconnectReason => connectionState == BluetoothConnectionState.disconnected
      ? DisconnectReason(ErrorPlatform.native, _response.disconnectReasonCode, _response.disconnectReasonString)
      : null;
}

// On Adapter State Changed
class OnAdapterStateChangedEvent {
  static const String method = "OnAdapterStateChanged";

  final BmBluetoothAdapterState _response;

  OnAdapterStateChangedEvent(this._response);
  OnAdapterStateChangedEvent.fromMap(Map<String, dynamic> map) : _response = BmBluetoothAdapterState.fromMap(map);

  /// the new adapter state
  BluetoothAdapterState get adapterState => bmToAdapterState(_response.adapterState);
}

// On Mtu Changed
class OnMtuChangedEvent with GetDeviceMixin, GetExceptionMixin {
  static const String method = "OnMtuChanged";

  final BmMtuChangedResponse _response;

  OnMtuChangedEvent(this._response);
  OnMtuChangedEvent.fromMap(Map<String, dynamic> map) : _response = BmMtuChangedResponse.fromMap(map);

  /// the new mtu
  int get mtu => _response.mtu;
}

// On Read Rssi
class OnReadRssiEvent with GetDeviceMixin, GetExceptionMixin {
  static const String method = "OnReadRssi";

  final BmReadRssiResult _response;

  OnReadRssiEvent(this._response);
  OnReadRssiEvent.fromMap(Map<String, dynamic> map) : _response = BmReadRssiResult.fromMap(map);

  /// rssi
  int get rssi => _response.rssi;
}

// On Services Reset
class OnServicesResetEvent with GetDeviceMixin {
  static const String method = "OnServicesReset";

  final BmBluetoothDevice _response;

  OnServicesResetEvent(this._response);
  OnServicesResetEvent.fromMap(Map<String, dynamic> map) : _response = BmBluetoothDevice.fromMap(map);
}

// On Discovered Services
class OnDiscoveredServicesEvent with GetDeviceMixin, GetExceptionMixin {
  static const String method = "OnDiscoveredServices";

  final BmDiscoverServicesResult _response;

  OnDiscoveredServicesEvent(this._response);
  OnDiscoveredServicesEvent.fromMap(Map<String, dynamic> map) : _response = BmDiscoverServicesResult.fromMap(map);

  List<BmBluetoothService> get servicesProtos => _response.services;
}

// On Characteristic Received
class OnCharacteristicReceivedEvent
    with GetDeviceMixin, GetAttributeValueMixin, GetCharacteristicMixin, GetExceptionMixin {
  static const String method = "OnCharacteristicReceived";

  final BmCharacteristicData _response;

  OnCharacteristicReceivedEvent(this._response);
  OnCharacteristicReceivedEvent.fromMap(Map<String, dynamic> map) : _response = BmCharacteristicData.fromMap(map);
}

// On Characteristic Written
class OnCharacteristicWrittenEvent
    with GetDeviceMixin, GetAttributeValueMixin, GetCharacteristicMixin, GetExceptionMixin {
  static const String method = "OnCharacteristicWritten";

  final BmCharacteristicData _response;

  OnCharacteristicWrittenEvent(this._response);
  OnCharacteristicWrittenEvent.fromMap(Map<String, dynamic> map) : _response = BmCharacteristicData.fromMap(map);
}

// On Descriptor Received
class OnDescriptorReadEvent with GetDeviceMixin, GetAttributeValueMixin, GetDescriptorMixin, GetExceptionMixin {
  static const String method = "OnDescriptorRead";

  final BmDescriptorData _response;

  OnDescriptorReadEvent(this._response);
  OnDescriptorReadEvent.fromMap(Map<String, dynamic> map) : _response = BmDescriptorData.fromMap(map);
}

// On Descriptor Written
class OnDescriptorWrittenEvent with GetDeviceMixin, GetAttributeValueMixin, GetDescriptorMixin, GetExceptionMixin {
  static const String method = "OnDescriptorWritten";

  final BmDescriptorData _response;

  OnDescriptorWrittenEvent(this._response);
  OnDescriptorWrittenEvent.fromMap(Map<String, dynamic> map) : _response = BmDescriptorData.fromMap(map);
}

// On Name Changed
class OnNameChangedEvent with GetDeviceMixin {
  static const String method = "OnNameChanged";

  final BmNameChanged _response; // TODO: Used to be BmBluetoothDevice??

  OnNameChangedEvent(this._response);
  OnNameChangedEvent.fromMap(Map<String, dynamic> map) : _response = BmNameChanged.fromMap(map);

  /// the new name
  String? get name => _response.name; // TODO: Used to be BmBluetoothDevice??
}

// On Bond State Changed
class OnBondStateChangedEvent with GetDeviceMixin {
  static const String method = "OnBondStateChanged";

  final BmBondStateResponse _response;

  OnBondStateChangedEvent(this._response);
  OnBondStateChangedEvent.fromMap(Map<String, dynamic> map) : _response = BmBondStateResponse.fromMap(map);

  /// the new bond state
  BluetoothBondState get bondState => bmToBondState(_response.bondState);
  BluetoothBondState? get prevState => _response.prevState == null ? null : bmToBondState(_response.prevState!);
}
