part of flutter_blue_plus;

enum BmAdapterStateEnum {
  unknown, // 0
  unavailable, // 1
  unauthorized, // 2
  turningOn, // 3
  on, // 4
  turningOff, // 5
  off, // 6
}

class BmBluetoothAdapterState {
  BmAdapterStateEnum adapterState;

  BmBluetoothAdapterState({required this.adapterState});

  Map<dynamic, dynamic> toMap() => {
        'adapter_state': adapterState.index,
      };

  BmBluetoothAdapterState.fromMap(Map<dynamic, dynamic> json)
      : adapterState = BmAdapterStateEnum.values[json['adapter_state']];
}

class BmMsdFilter {
  int manufacturerId;
  List<int>? data;
  List<int>? mask;
  BmMsdFilter(this.manufacturerId, this.data, this.mask);
  Map<dynamic, dynamic> toMap() => {
        'manufacturer_id': manufacturerId,
        'data': _hexEncode(data ?? []),
        'mask': _hexEncode(mask ?? []),
      };
}

class BmServiceDataFilter {
  Uuid service;
  List<int> data;
  List<int> mask;
  BmServiceDataFilter(this.service, this.data, this.mask);
  Map<dynamic, dynamic> toMap() => {
        'service': service.string,
        'data': _hexEncode(data),
        'mask': _hexEncode(mask),
      };
}

class BmScanSettings {
  final List<Uuid> withServices;
  final List<String> withRemoteIds;
  final List<String> withNames;
  final List<String> withKeywords;
  final List<BmMsdFilter> withMsd;
  final List<BmServiceDataFilter> withServiceData;
  final bool continuousUpdates;
  final int continuousDivisor;
  final bool androidLegacy;
  final int androidScanMode;
  final bool androidUsesFineLocation;

  BmScanSettings({
    required this.withServices,
    required this.withRemoteIds,
    required this.withNames,
    required this.withKeywords,
    required this.withMsd,
    required this.withServiceData,
    required this.continuousUpdates,
    required this.continuousDivisor,
    required this.androidLegacy,
    required this.androidScanMode,
    required this.androidUsesFineLocation,
  });

  Map<dynamic, dynamic> toMap() => {
        'with_services': withServices.map((s) => s.string).toList(),
        'with_remote_ids': withRemoteIds,
        'with_names': withNames,
        'with_keywords': withKeywords,
        'with_msd': withMsd.map((d) => d.toMap()).toList(),
        'with_service_data': withServiceData.map((d) => d.toMap()).toList(),
        'continuous_updates': continuousUpdates,
        'continuous_divisor': continuousDivisor,
        'android_legacy': androidLegacy,
        'android_scan_mode': androidScanMode,
        'android_uses_fine_location': androidUsesFineLocation,
      };
}

class BmScanAdvertisement {
  final String address;
  final String? platformName;
  final String? advName;
  final bool connectable;
  final int? txPowerLevel;
  final int? appearance; // not supported on iOS / macOS
  final Map<int, List<int>> manufacturerData;
  final Map<Uuid, List<int>> serviceData;
  final List<Uuid> serviceUuids;
  final int rssi;

  BmScanAdvertisement({
    required this.address,
    required this.platformName,
    required this.advName,
    required this.connectable,
    required this.txPowerLevel,
    required this.appearance,
    required this.manufacturerData,
    required this.serviceData,
    required this.serviceUuids,
    required this.rssi,
  });

  BmScanAdvertisement.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        platformName = json['platform_name'],
        advName = json['adv_name'],
        connectable = json['connectable'] != null ? json['connectable'] != 0 : false,
        txPowerLevel = json['tx_power_level'],
        appearance = json['appearance'],
        manufacturerData =
            json['manufacturer_data']?.map<int, List<int>>((key, value) => MapEntry(key as int, _hexDecode(value))) ??
                {},
        serviceData =
            json['service_data']?.map<Uuid, List<int>>((key, value) => MapEntry(Uuid(key), _hexDecode(value))) ?? {},
        serviceUuids = json['service_uuids']?.map((v) => Uuid(v)).toList() ?? [],
        rssi = json['rssi'] ?? 0;
}

class BmStatus {
  final bool success;
  final int errorCode;
  final String errorString;

  BmStatus({
    this.success = true,
    this.errorCode = 0,
    this.errorString = "",
  });

  BmStatus.fromMap(Map<dynamic, dynamic> json)
      : success = json['success'] != 0,
        errorCode = json['error_code'] ?? 0,
        errorString = json['error_string'] ?? "";
}

class BmScanResponse extends BmStatus {
  final List<BmScanAdvertisement> advertisements;

  BmScanResponse.fromMap(Map<dynamic, dynamic> json)
      : advertisements = json['advertisements']
            .map<BmScanAdvertisement>((v) => BmScanAdvertisement.fromMap(v as Map<dynamic, dynamic>))
            .toList(),
        super.fromMap(json);
}

class BmConnectRequest {
  String address;
  bool autoConnect;

  BmConnectRequest({
    required this.address,
    required this.autoConnect,
  });

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'auto_connect': autoConnect ? 1 : 0,
      };
}

class BmBluetoothDevice {
  String address;
  String? platformName;

  BmBluetoothDevice.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        platformName = json['platform_name'];
}

class BmNameChanged {
  final String address;
  final String name;

  BmNameChanged.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        name = json['name'];
}

class BmBluetoothService {
  final Uuid uuid;
  final int index;
  final bool isPrimary;
  List<BmBluetoothCharacteristic> characteristics;
  List<String> includedServices;

  BmBluetoothService.fromMap(Map<dynamic, dynamic> json)
      : uuid = Uuid(json['uuid']),
        index = json['index'],
        isPrimary = json['primary'] != 0,
        characteristics = (json['characteristics'] as List<dynamic>)
            .map<BmBluetoothCharacteristic>((v) => BmBluetoothCharacteristic.fromMap(v))
            .toList(),
        includedServices = (json['included_services'] as List<dynamic>).map((v) => v as String).toList();
}

class BmBluetoothCharacteristic {
  final Uuid uuid;
  final int index;
  List<BmBluetoothDescriptor> descriptors;
  BmCharacteristicProperties properties;

  BmBluetoothCharacteristic.fromMap(Map<dynamic, dynamic> json)
      : uuid = Uuid(json['uuid']),
        index = json['index'],
        descriptors = (json['descriptors'] as List<dynamic>).map((v) => BmBluetoothDescriptor.fromMap(v)).toList(),
        properties = BmCharacteristicProperties.fromMap(json['properties']);
}

class BmBluetoothDescriptor {
  final Uuid uuid;

  BmBluetoothDescriptor.fromMap(Map<dynamic, dynamic> json) : uuid = Uuid(json['uuid']);
}

class BmCharacteristicProperties {
  bool broadcast;
  bool read;
  bool writeWithoutResponse;
  bool write;
  bool notify;
  bool indicate;
  bool authenticatedSignedWrites;
  bool extendedProperties;
  bool notifyEncryptionRequired;
  bool indicateEncryptionRequired;

  BmCharacteristicProperties.fromMap(Map<dynamic, dynamic> json)
      : broadcast = json['broadcast'] != 0,
        read = json['read'] != 0,
        writeWithoutResponse = json['write_without_response'] != 0,
        write = json['write'] != 0,
        notify = json['notify'] != 0,
        indicate = json['indicate'] != 0,
        authenticatedSignedWrites = json['authenticated_signed_writes'] != 0,
        extendedProperties = json['extended_properties'] != 0,
        notifyEncryptionRequired = json['notify_encryption_required'] != 0,
        indicateEncryptionRequired = json['indicate_encryption_required'] != 0;
}

class BmDiscoverServicesResult extends BmStatus {
  final String address;
  final List<BmBluetoothService> services;

  BmDiscoverServicesResult.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        services = (json['services'] as List<dynamic>)
            .map((e) => BmBluetoothService.fromMap(e as Map<dynamic, dynamic>))
            .toList(),
        super.fromMap(json);
}

class BmReadCharacteristicRequest {
  final String address;
  final String identifier;

  BmReadCharacteristicRequest({
    required this.address,
    required this.identifier,
  });

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'identifier': identifier,
      };
}

class BmCharacteristicData extends BmStatus {
  final String address;
  final String identifier;
  final List<int> value;

  BmCharacteristicData.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        identifier = json['identifier'],
        value = _hexDecode(json['value']),
        super.fromMap(json);
}

class BmReadDescriptorRequest {
  final String address;
  final String identifier;

  BmReadDescriptorRequest({
    required this.address,
    required this.identifier,
  });

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'identifier': identifier,
      };
}

enum BmWriteType {
  withResponse,
  withoutResponse,
}

class BmWriteCharacteristicRequest {
  final String address;
  final String identifier;
  final BmWriteType writeType;
  final bool allowLongWrite;
  final List<int> value;

  BmWriteCharacteristicRequest({
    required this.address,
    required this.identifier,
    required this.writeType,
    required this.allowLongWrite,
    required this.value,
  });

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'identifier': identifier,
        'write_type': writeType.index,
        'allow_long_write': allowLongWrite ? 1 : 0,
        'value': _hexEncode(value),
      };
}

class BmWriteDescriptorRequest {
  final String address;
  final String identifier;
  final List<int> value;

  BmWriteDescriptorRequest({
    required this.address,
    required this.identifier,
    required this.value,
  });

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'identifier': identifier,
        'value': _hexEncode(value),
      };
}

class BmDescriptorData extends BmStatus {
  final String address;
  final String identifier;
  final List<int> value;

  BmDescriptorData.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        identifier = json['identifier'],
        value = _hexDecode(json['value']),
        super.fromMap(json);
}

class BmSetNotifyValueRequest {
  final String address;
  final String identifier;
  final bool forceIndications;
  final bool enable;

  BmSetNotifyValueRequest({
    required this.address,
    required this.identifier,
    required this.forceIndications,
    required this.enable,
  });

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'identifier': identifier,
        'force_indications': forceIndications,
        'enable': enable,
      };
}

enum BmConnectionStateEnum {
  disconnected, // 0
  connected, // 1
}

class BmConnectionStateResponse {
  final String address;
  final BmConnectionStateEnum connectionState;
  final int? disconnectReasonCode;
  final String? disconnectReasonString;

  BmConnectionStateResponse.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        connectionState = BmConnectionStateEnum.values[json['connection_state'] as int],
        disconnectReasonCode = json['disconnect_reason_code'],
        disconnectReasonString = json['disconnect_reason_string'];
}

class BmDevicesList {
  final List<BmBluetoothDevice> devices;

  BmDevicesList.fromMap(Map<dynamic, dynamic> json) : devices = json['devices'].map(BmBluetoothDevice.fromMap).toList();
}

class BmMtuChangeRequest {
  final String address;
  final int mtu;

  BmMtuChangeRequest({required this.address, required this.mtu});

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'mtu': mtu,
      };
}

class BmMtuChangedResponse extends BmStatus {
  final String address;
  final int mtu;

  BmMtuChangedResponse({
    required this.address,
    required this.mtu,
  }) : super();

  BmMtuChangedResponse.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        mtu = json['mtu'],
        super.fromMap(json);
}

class BmReadRssiResult extends BmStatus {
  final String address;
  final int rssi;

  BmReadRssiResult.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        rssi = json['rssi'],
        super.fromMap(json);
}

enum BmConnectionPriorityEnum {
  balanced, // 0
  high, // 1
  lowPower, // 2
}

class BmConnectionPriorityRequest {
  final String address;
  final BmConnectionPriorityEnum connectionPriority;

  BmConnectionPriorityRequest({
    required this.address,
    required this.connectionPriority,
  });

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'connection_priority': connectionPriority.index,
      };
}

class BmPreferredPhy {
  final String address;
  final int txPhy;
  final int rxPhy;
  final int phyOptions;

  BmPreferredPhy({
    required this.address,
    required this.txPhy,
    required this.rxPhy,
    required this.phyOptions,
  });

  Map<dynamic, dynamic> toMap() => {
        'remote_id': address,
        'tx_phy': txPhy,
        'rx_phy': rxPhy,
        'phy_options': phyOptions,
      };

  BmPreferredPhy.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        txPhy = json['tx_phy'],
        rxPhy = json['rx_phy'],
        phyOptions = json['phy_options'];
}

enum BmBondStateEnum {
  none, // 0
  bonding, // 1
  bonded, // 2
}

class BmBondStateResponse {
  final String address;
  final BmBondStateEnum bondState;
  final BmBondStateEnum? prevState;

  BmBondStateResponse.fromMap(Map<dynamic, dynamic> json)
      : address = json['remote_id'],
        bondState = BmBondStateEnum.values[json['bond_state']],
        prevState = json['prev_state'] != null ? BmBondStateEnum.values[json['prev_state']] : null;
}

// BmTurnOnResponse
class BmTurnOnResponse {
  bool userAccepted;

  BmTurnOnResponse.fromMap(Map<dynamic, dynamic> json) : userAccepted = json['user_accepted'] != 0;
}

// random number defined by flutter blue plus.
// Ideally it should not conflict with iOS or Android error codes.
int bmUserCanceledErrorCode = 23789258;
