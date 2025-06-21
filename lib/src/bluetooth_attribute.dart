// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of flutter_blue_plus;

abstract class BluetoothAttribute {
  final BluetoothDevice device;
  final Uuid uuid;
  final int? index;

  BluetoothAttribute({
    required this.device,
    required this.uuid,
    this.index,
  });

  BluetoothAttribute? get _parentAttribute => null;

  String get identifier => "$uuid:$index";

  String get identifierPath =>
      _parentAttribute != null ? "${_parentAttribute!.identifierPath}/$identifier" : identifier;
}
