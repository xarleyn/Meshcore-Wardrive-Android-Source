import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/meshcore_protocol.dart';

void main() {
  group('MeshCore command framing', () {
    final protocol = MeshCoreProtocol();

    test('APP_START contains seven reserved bytes and a UTF-8 app name', () {
      final payload = protocol.createAppStartPayload(appName: 'Wardrive 🚗');
      final frame = protocol.createCommandFrameBLE(CMD_APP_START, payload);

      expect(frame.first, CMD_APP_START);
      expect(frame.sublist(1, 8), everyElement(0));
      expect(utf8.decode(frame.sublist(8)), 'Wardrive 🚗');
      expect(frame.length, greaterThanOrEqualTo(8));
    });

    test('DEVICE_QUERY advertises the supported protocol version', () {
      expect(
        protocol.createCommandFrameBLE(
          CMD_DEVICE_QUERY,
          protocol.createDeviceQueryPayload(),
        ),
        [CMD_DEVICE_QUERY, COMPANION_PROTOCOL_VERSION],
      );
    });

    test('GET_CONTACT_BY_KEY sends command 30 and the complete public key', () {
      final publicKey = Uint8List.fromList(List.generate(32, (index) => index));
      final payload = protocol.createGetContactByKeyPayload(publicKey);
      final bleFrame = protocol.createCommandFrameBLE(
        CMD_GET_CONTACT_BY_KEY,
        payload,
      );
      final usbFrame = protocol.createCommandFrame(
        CMD_GET_CONTACT_BY_KEY,
        payload,
      );

      expect(bleFrame, [CMD_GET_CONTACT_BY_KEY, ...publicKey]);
      expect(usbFrame.sublist(0, 4), [
        FRAME_START_INBOUND,
        33,
        0,
        CMD_GET_CONTACT_BY_KEY,
      ]);
      expect(usbFrame.sublist(4), publicKey);
      expect(
        () => protocol.createGetContactByKeyPayload(Uint8List(31)),
        throwsArgumentError,
      );
    });

    test('uses current command and packet assignments', () {
      expect(CMD_SET_ADVERT_NAME, 8);
      expect(CMD_REBOOT, 19);
      expect(CMD_SET_CHANNEL, 32);
      expect(RESP_CODE_CONTACTS_START, 2);
      expect(PUSH_CODE_RAW_DATA, 0x84);
      expect(PUSH_CODE_NEW_ADVERT, 0x8A);
      expect(ADV_TYPE_SENSOR, 4);
    });
  });

  group('MeshCore transport parsing', () {
    test('buffers a split USB frame and preserves the following frame', () {
      final protocol = MeshCoreProtocol();
      final bytes = Uint8List.fromList([
        0x00,
        FRAME_START_OUTBOUND,
        3,
        0,
        RESP_CODE_OK,
        0x34,
        0x12,
        FRAME_START_OUTBOUND,
        1,
        0,
        RESP_CODE_END_OF_CONTACTS,
      ]);

      expect(protocol.parseIncomingData(bytes.sublist(0, 5)), isEmpty);
      final frames = protocol.parseIncomingData(bytes.sublist(5));

      expect(frames, hasLength(2));
      expect(frames[0].code, RESP_CODE_OK);
      expect(frames[0].data, [0x34, 0x12]);
      expect(frames[1].code, RESP_CODE_END_OF_CONTACTS);
      expect(frames[1].data, isEmpty);
    });

    test('parses one unwrapped BLE notification', () {
      final protocol = MeshCoreProtocol()..setBLEMode(true);

      final frames = protocol.parseIncomingData(
        Uint8List.fromList([PUSH_CODE_ADVERT, ...List.filled(32, 0xAB)]),
      );

      expect(frames, hasLength(1));
      expect(frames.single.code, PUSH_CODE_ADVERT);
      expect(frames.single.data, everyElement(0xAB));
    });
  });

  group('MeshCore contact frames', () {
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

    test('parses the full contact layout used by NEW_ADVERT', () {
      final frame = _contactFrameWithName(
        'Moscow relay',
        timestamp: 0x12345678,
        latitude: 55.7558,
        longitude: 37.6173,
      );

      final contact = MeshCoreProtocol().parseContactFrame(frame);

      expect(contact, isNotNull);
      expect(contact!.publicKey, List.generate(32, (index) => index));
      expect(contact.advType, ADV_TYPE_REPEATER);
      expect(contact.lastAdvert, 0x12345678);
      expect(contact.advLat, closeTo(55.7558, 0.000001));
      expect(contact.advLon, closeTo(37.6173, 0.000001));
    });

    test('rejects a contact missing its fixed 32-byte name field', () {
      expect(MeshCoreProtocol().parseContactFrame(Uint8List(130)), isNull);
    });
  });

  group('MeshCore current response layouts', () {
    final protocol = MeshCoreProtocol();

    test('control payload starts immediately after path length metadata', () {
      final publicKey = List.generate(32, (index) => 0x80 + index);
      final discoveryPayload = <int>[
        (CONTROL_SUBTYPE_DISCOVER_RESP << 4) | ADV_TYPE_REPEATER,
        0xF8,
        0x78,
        0x56,
        0x34,
        0x12,
        ...publicKey,
      ];
      final push = Uint8List.fromList([0xF8, 0xA6, 3, ...discoveryPayload]);

      final control = protocol.parseControlDataPush(push);
      final discovery = protocol.parseDiscoveryResponse(
        control!['payload'] as Uint8List,
      );

      expect(control['snr'], -2);
      expect(control['rssi'], -90);
      expect(control['path_len'], 3);
      expect(control['payload'], discoveryPayload);
      expect(discovery, isNotNull);
      expect(discovery!['node_type'], ADV_TYPE_REPEATER);
      expect(discovery['snr'], -2);
      expect(discovery['tag'], 0x12345678);
      expect(
        discovery['pubkey'],
        publicKey
            .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
            .join()
            .toUpperCase(),
      );
      expect(discovery['pubkey_bytes'], publicKey);
    });

    test('0x84 raw data uses signed int8 radio metrics, not an ACK layout', () {
      final raw = protocol.parseRawDataPush(
        Uint8List.fromList([0xF6, 0xA0, 0xFF, 1, 2, 3]),
      );

      expect(raw, isNotNull);
      expect(raw!['snr'], -2.5);
      expect(raw['rssi'], -96);
      expect(raw['reserved'], 0xFF);
      expect(raw['payload'], [1, 2, 3]);
      expect(protocol.parseRawDataPush(Uint8List(2)), isNull);
    });

    test('accepts the 13-byte login success extension', () {
      final login = protocol.parseLoginSuccessPush(
        Uint8List.fromList([
          0x02,
          1,
          2,
          3,
          4,
          5,
          6,
          0x78,
          0x56,
          0x34,
          0x12,
          0xA5,
          17,
        ]),
      );

      expect(login, isNotNull);
      expect(login!['is_admin'], isFalse);
      expect(login['pubkey_prefix'], '010203040506');
      expect(login['timestamp'], 0x12345678);
      expect(login['permissions'], 0xA5);
      expect(login['firmware_version'], 17);
    });

    test('parses protocol-13 device information', () {
      final data = Uint8List(81);
      data[0] = 13;
      data[1] = 100;
      data[2] = 8;
      _writeUint32LE(data, 3, 123456);
      _writeFixedUtf8(data, 7, 12, 'build-aug');
      _writeFixedUtf8(data, 19, 40, 'MeshCore');
      _writeFixedUtf8(data, 59, 20, '1.17.0');
      data[79] = 1;
      data[80] = 2;

      final info = protocol.parseDeviceInfoFrame(data);

      expect(info, isNotNull);
      expect(info!['firmware_protocol'], 13);
      expect(info['max_contacts'], 200);
      expect(info['max_channels'], 8);
      expect(info['ble_pin'], 123456);
      expect(info['firmware_build'], 'build-aug');
      expect(info['manufacturer'], 'MeshCore');
      expect(info['firmware_version'], '1.17.0');
      expect(info['client_repeat'], isTrue);
      expect(info['path_hash_mode'], 2);
    });

    test('parses standard and V3 channel messages', () {
      final standard = protocol.parseChannelMessageFrame(
        Uint8List.fromList([
          2,
          0xFF,
          TXT_TYPE_PLAIN,
          0x78,
          0x56,
          0x34,
          0x12,
          ...utf8.encode('Привет'),
        ]),
      );
      final v3 = protocol.parseChannelMessageFrame(
        Uint8List.fromList([
          0xF6,
          0,
          0,
          3,
          1,
          TXT_TYPE_CLI_DATA,
          4,
          3,
          2,
          1,
          ...utf8.encode('status'),
        ]),
        version3: true,
      );

      expect(standard!['channel_idx'], 2);
      expect(standard['path_len'], 0xFF);
      expect(standard['timestamp'], 0x12345678);
      expect(standard['text'], 'Привет');
      expect(standard['snr'], isNull);
      expect(v3!['channel_idx'], 3);
      expect(v3['path_len'], 1);
      expect(v3['text_type'], TXT_TYPE_CLI_DATA);
      expect(v3['timestamp'], 0x01020304);
      expect(v3['text'], 'status');
      expect(v3['snr'], -2.5);
    });

    test('parses a protocol-13 channel data datagram', () {
      final datagram = protocol.parseChannelDataFrame(
        Uint8List.fromList([
          0xF6,
          0,
          0,
          4,
          0xFF,
          0x34,
          0x12,
          3,
          0xAA,
          0xBB,
          0xCC,
        ]),
      );

      expect(datagram, isNotNull);
      expect(datagram!['snr'], -2.5);
      expect(datagram['channel_idx'], 4);
      expect(datagram['path_len'], 0xFF);
      expect(datagram['data_type'], 0x1234);
      expect(datagram['payload'], [0xAA, 0xBB, 0xCC]);
      expect(
        protocol.parseChannelDataFrame(
          Uint8List.fromList([0, 0, 0, 1, 0xFF, 1, 0, 2, 0xAA]),
        ),
        isNull,
      );
    });

    test('parses signed SNR in a Carpeater neighbours response', () {
      final response = protocol.parseBinaryResponseNeighbours(
        Uint8List.fromList([
          0,
          0x78,
          0x56,
          0x34,
          0x12,
          1,
          0,
          1,
          0,
          1,
          2,
          3,
          4,
          5,
          6,
          7,
          8,
          30,
          0,
          0,
          0,
          0xF6,
        ]),
        8,
      );

      expect(response, isNotNull);
      expect(response!['tag'], 0x12345678);
      expect(response['total_count'], 1);
      expect(response['result_count'], 1);
      final neighbours = response['neighbours'] as List<Map<String, dynamic>>;
      expect(neighbours, hasLength(1));
      expect(neighbours.single['pubkey'], '0102030405060708');
      expect(neighbours.single['heard_seconds_ago'], 30);
      expect(neighbours.single['snr'], -2.5);
    });

    test(
      'encodes and decodes UTF-8 channel names without splitting a rune',
      () {
        final payload = protocol.createSetChannelPayload(
          1,
          'Репитеры-Москвы-🚀',
          Uint8List(16),
        );
        final parsed = protocol.parseChannelInfoFrame(payload);

        expect(payload, hasLength(49));
        expect(parsed, isNotNull);
        expect(
          utf8.encode(parsed!['name'] as String).length,
          lessThanOrEqualTo(32),
        );
        expect(parsed['name'], isNot(contains('�')));
      },
    );
  });
}

Uint8List _contactFrameWithName(
  String name, {
  int? timestamp,
  double? latitude,
  double? longitude,
}) {
  final nameBytes = utf8.encode(name);
  if (nameBytes.length > 32) {
    throw ArgumentError.value(name, 'name', 'must fit in the 32-byte field');
  }

  final hasPosition =
      timestamp != null && latitude != null && longitude != null;
  final data = Uint8List(131 + (hasPosition ? 12 : 0));
  data.setRange(0, 32, List.generate(32, (index) => index));
  data[32] = ADV_TYPE_REPEATER;
  const nameOffset = 32 + 1 + 1 + 1 + 64;
  data.setRange(nameOffset, nameOffset + nameBytes.length, nameBytes);
  if (hasPosition) {
    _writeUint32LE(data, 131, timestamp);
    _writeUint32LE(data, 135, (latitude * 1000000).round());
    _writeUint32LE(data, 139, (longitude * 1000000).round());
  }
  return data;
}

void _writeFixedUtf8(Uint8List target, int offset, int length, String value) {
  final bytes = utf8.encode(value);
  if (bytes.length > length) throw ArgumentError('value is too long');
  target.setRange(offset, offset + bytes.length, bytes);
}

void _writeUint32LE(Uint8List target, int offset, int value) {
  target[offset] = value & 0xFF;
  target[offset + 1] = (value >> 8) & 0xFF;
  target[offset + 2] = (value >> 16) & 0xFF;
  target[offset + 3] = (value >> 24) & 0xFF;
}
