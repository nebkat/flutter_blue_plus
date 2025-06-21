// Copyright 2017-2023, Charles Weinberger & Paul DeMarco.
// All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of flutter_blue_plus;

// Supports 16-bit, 32-bit, or 128-bit UUIDs
class Uuid {
  final List<int> bytes;

  const Uuid.empty() : bytes = const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];

  const Uuid.fromBytes(this.bytes)
      : assert(bytes.length == 2 || bytes.length == 4 || bytes.length == 16, "UUID must be 16, 32, or 128 bits long");

  factory Uuid(String input) {
    if (input.length == 4 || input.length == 8) {
      return Uuid.fromBytes(_tryHexDecode(input) ?? (throw FormatException("UUID invalid hex", input)));
    } else if (input.length == 36) {
      if (input[8] != '-' || input[13] != '-' || input[18] != '-' || input[23] != '-') {
        throw FormatException("UUID 128-bit must be in the format XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX", input);
      }
      input = input.replaceAll('-', '');
      return Uuid.fromBytes(_tryHexDecode(input) ?? (throw FormatException("UUID invalid hex", input)));
    } else {
      throw FormatException("UUID must be 4, 8, or 36 characters long", input);
    }
  }

  // 128-bit representation
  String get string128 => switch (bytes.length) {
        2 => '0000${_hexEncode(bytes)}-0000-1000-8000-00805f9b34fb'.toLowerCase(),
        4 => '${_hexEncode(bytes)}-0000-1000-8000-00805f9b34fb'.toLowerCase(),
        _ => "${_hexEncode(bytes.sublist(0, 4))}-"
                "${_hexEncode(bytes.sublist(4, 6))}-"
                "${_hexEncode(bytes.sublist(6, 8))}-"
                "${_hexEncode(bytes.sublist(8, 10))}-"
                "${_hexEncode(bytes.sublist(10, 16))}"
            .toLowerCase(),
      };

  // Shortest representation
  String get string => switch (bytes.length) {
        2 || 4 => _hexEncode(bytes),
        _ => string128,
      };

  @override
  String toString() => string;

  @override
  operator ==(other) => other is Uuid && hashCode == other.hashCode;

  @override
  int get hashCode => bytes.hashCode;
}
