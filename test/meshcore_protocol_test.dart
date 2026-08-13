import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/meshcore_protocol.dart';

void main() {
  group('MeshCoreProtocol.parseContactFrame', () {
    test('decodes a UTF-8 repeater name with Cyrillic and emoji', () {
      const name = 'Репитер 🚀';

      final contact = MeshCoreProtocol().parseContactFrame(
        _contactFrameWithName(name),
      );

      expect(contact, isNotNull);
      expect(contact!.advName, name);
    });

    test('decodes a UTF-8 name that fills the entire name field', () {
      const name = 'Репитер-Москва-МС';
      expect(utf8.encode(name), hasLength(32));

      final contact = MeshCoreProtocol().parseContactFrame(
        _contactFrameWithName(name),
      );

      expect(contact, isNotNull);
      expect(contact!.advName, name);
    });
  });
}

Uint8List _contactFrameWithName(String name) {
  final nameBytes = utf8.encode(name);
  if (nameBytes.length > 32) {
    throw ArgumentError.value(name, 'name', 'must fit in the 32-byte field');
  }

  final data = Uint8List(32 + 1 + 1 + 1 + 64 + 32);
  data[32] = ADV_TYPE_REPEATER;
  const nameOffset = 32 + 1 + 1 + 1 + 64;
  data.setRange(nameOffset, nameOffset + nameBytes.length, nameBytes);
  return data;
}
