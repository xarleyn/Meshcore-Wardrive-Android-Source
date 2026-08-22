import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/meshcore_protocol.dart';

// These are specification tests, not implementation-shaped unit tests.
// Keep the byte vectors independent from MeshCoreProtocol's encoders.
// Primary sources used for the vectors and numeric assignments:
// - https://github.com/meshcore-dev/MeshCore/blob/d92964352441e53b93e8667b802e04f6e072b39e/docs/companion_protocol.md
// - https://github.com/meshcore-dev/MeshCore/blob/d92964352441e53b93e8667b802e04f6e072b39e/examples/companion_radio/MyMesh.cpp
// - https://github.com/meshcore-dev/MeshCore/blob/d92964352441e53b93e8667b802e04f6e072b39e/docs/payloads.md
// - https://github.com/meshcore-dev/meshcore.js/blob/1c142946f9597d60fc634afd9a681f546792b0d5/src/constants.js

void main() {
  group('MeshCore protocol number registry', () {
    test('app-to-radio command bytes match companion firmware', () {
      expect(
        <String, int>{
          'APP_START': CMD_APP_START,
          'SEND_MESSAGE': CMD_SEND_MESSAGE,
          'SEND_CHANNEL_MESSAGE': CMD_SEND_CHANNEL_MESSAGE,
          'GET_CONTACTS': CMD_GET_CONTACTS,
          'GET_DEVICE_TIME': CMD_GET_DEVICE_TIME,
          'SET_DEVICE_TIME': CMD_SET_DEVICE_TIME,
          'SEND_SELF_ADVERT': CMD_SEND_SELF_ADVERT,
          'SET_ADVERT_NAME': CMD_SET_ADVERT_NAME,
          'ADD_UPDATE_CONTACT': CMD_ADD_UPDATE_CONTACT,
          'SYNC_NEXT_MESSAGE': CMD_SYNC_NEXT_MESSAGE,
          'SET_RADIO_PARAMS': CMD_SET_RADIO_PARAMS,
          'SET_RADIO_TX_POWER': CMD_SET_RADIO_TX_POWER,
          'RESET_PATH': CMD_RESET_PATH,
          'SET_ADVERT_LATLON': CMD_SET_ADVERT_LATLON,
          'REMOVE_CONTACT': CMD_REMOVE_CONTACT,
          'SHARE_CONTACT': CMD_SHARE_CONTACT,
          'EXPORT_CONTACT': CMD_EXPORT_CONTACT,
          'IMPORT_CONTACT': CMD_IMPORT_CONTACT,
          'REBOOT': CMD_REBOOT,
          'GET_BATT_AND_STORAGE': CMD_GET_BATT_AND_STORAGE,
          'SET_TUNING_PARAMS': CMD_SET_TUNING_PARAMS,
          'DEVICE_QUERY': CMD_DEVICE_QUERY,
          'EXPORT_PRIVATE_KEY': CMD_EXPORT_PRIVATE_KEY,
          'IMPORT_PRIVATE_KEY': CMD_IMPORT_PRIVATE_KEY,
          'SEND_RAW_DATA': CMD_SEND_RAW_DATA,
          'SEND_LOGIN': CMD_SEND_LOGIN,
          'SEND_STATUS_REQ': CMD_SEND_STATUS_REQ,
          'HAS_CONNECTION': CMD_HAS_CONNECTION,
          'LOGOUT': CMD_LOGOUT,
          'GET_CONTACT_BY_KEY': CMD_GET_CONTACT_BY_KEY,
          'GET_CHANNEL': CMD_GET_CHANNEL,
          'SET_CHANNEL': CMD_SET_CHANNEL,
          'SIGN_START': CMD_SIGN_START,
          'SIGN_DATA': CMD_SIGN_DATA,
          'SIGN_FINISH': CMD_SIGN_FINISH,
          'SEND_TRACE_PATH': CMD_SEND_TRACE_PATH,
          'SET_DEVICE_PIN': CMD_SET_DEVICE_PIN,
          'SET_OTHER_PARAMS': CMD_SET_OTHER_PARAMS,
          'SEND_TELEMETRY_REQ': CMD_SEND_TELEMETRY_REQ,
          'GET_CUSTOM_VARS': CMD_GET_CUSTOM_VARS,
          'SET_CUSTOM_VAR': CMD_SET_CUSTOM_VAR,
          'GET_ADVERT_PATH': CMD_GET_ADVERT_PATH,
          'GET_TUNING_PARAMS': CMD_GET_TUNING_PARAMS,
          'SEND_BINARY_REQ': CMD_SEND_BINARY_REQ,
          'FACTORY_RESET': CMD_FACTORY_RESET,
          'SEND_PATH_DISCOVERY_REQ': CMD_SEND_PATH_DISCOVERY_REQ,
          'SET_FLOOD_SCOPE_KEY': CMD_SET_FLOOD_SCOPE_KEY,
          'SEND_CONTROL_DATA': CMD_SEND_CONTROL_DATA,
          'GET_STATS': CMD_GET_STATS,
          'SEND_ANON_REQ': CMD_SEND_ANON_REQ,
          'SET_AUTOADD_CONFIG': CMD_SET_AUTOADD_CONFIG,
          'GET_AUTOADD_CONFIG': CMD_GET_AUTOADD_CONFIG,
          'GET_ALLOWED_REPEAT_FREQ': CMD_GET_ALLOWED_REPEAT_FREQ,
          'SET_PATH_HASH_MODE': CMD_SET_PATH_HASH_MODE,
          'SEND_CHANNEL_DATA': CMD_SEND_CHANNEL_DATA,
          'SET_DEFAULT_FLOOD_SCOPE': CMD_SET_DEFAULT_FLOOD_SCOPE,
          'GET_DEFAULT_FLOOD_SCOPE': CMD_GET_DEFAULT_FLOOD_SCOPE,
          'SEND_RAW_PACKET': CMD_SEND_RAW_PACKET,
        },
        <String, int>{
          'APP_START': 1,
          'SEND_MESSAGE': 2,
          'SEND_CHANNEL_MESSAGE': 3,
          'GET_CONTACTS': 4,
          'GET_DEVICE_TIME': 5,
          'SET_DEVICE_TIME': 6,
          'SEND_SELF_ADVERT': 7,
          'SET_ADVERT_NAME': 8,
          'ADD_UPDATE_CONTACT': 9,
          'SYNC_NEXT_MESSAGE': 10,
          'SET_RADIO_PARAMS': 11,
          'SET_RADIO_TX_POWER': 12,
          'RESET_PATH': 13,
          'SET_ADVERT_LATLON': 14,
          'REMOVE_CONTACT': 15,
          'SHARE_CONTACT': 16,
          'EXPORT_CONTACT': 17,
          'IMPORT_CONTACT': 18,
          'REBOOT': 19,
          'GET_BATT_AND_STORAGE': 20,
          'SET_TUNING_PARAMS': 21,
          'DEVICE_QUERY': 22,
          'EXPORT_PRIVATE_KEY': 23,
          'IMPORT_PRIVATE_KEY': 24,
          'SEND_RAW_DATA': 25,
          'SEND_LOGIN': 26,
          'SEND_STATUS_REQ': 27,
          'HAS_CONNECTION': 28,
          'LOGOUT': 29,
          'GET_CONTACT_BY_KEY': 30,
          'GET_CHANNEL': 31,
          'SET_CHANNEL': 32,
          'SIGN_START': 33,
          'SIGN_DATA': 34,
          'SIGN_FINISH': 35,
          'SEND_TRACE_PATH': 36,
          'SET_DEVICE_PIN': 37,
          'SET_OTHER_PARAMS': 38,
          'SEND_TELEMETRY_REQ': 39,
          'GET_CUSTOM_VARS': 40,
          'SET_CUSTOM_VAR': 41,
          'GET_ADVERT_PATH': 42,
          'GET_TUNING_PARAMS': 43,
          'SEND_BINARY_REQ': 50,
          'FACTORY_RESET': 51,
          'SEND_PATH_DISCOVERY_REQ': 52,
          'SET_FLOOD_SCOPE_KEY': 54,
          'SEND_CONTROL_DATA': 55,
          'GET_STATS': 56,
          'SEND_ANON_REQ': 57,
          'SET_AUTOADD_CONFIG': 58,
          'GET_AUTOADD_CONFIG': 59,
          'GET_ALLOWED_REPEAT_FREQ': 60,
          'SET_PATH_HASH_MODE': 61,
          'SEND_CHANNEL_DATA': 62,
          'SET_DEFAULT_FLOOD_SCOPE': 63,
          'GET_DEFAULT_FLOOD_SCOPE': 64,
          'SEND_RAW_PACKET': 65,
        },
      );
    });

    test('radio-to-app response and push bytes match companion firmware', () {
      expect(
        <String, int>{
          'OK': RESP_CODE_OK,
          'ERR': RESP_CODE_ERR,
          'CONTACTS_START': RESP_CODE_CONTACTS_START,
          'CONTACT': RESP_CODE_CONTACT,
          'END_OF_CONTACTS': RESP_CODE_END_OF_CONTACTS,
          'SELF_INFO': RESP_CODE_SELF_INFO,
          'SENT': RESP_CODE_SENT,
          'CONTACT_MSG_RECV': RESP_CODE_CONTACT_MSG_RECV,
          'CHANNEL_MSG_RECV': RESP_CODE_CHANNEL_MSG_RECV,
          'CURRENT_TIME': RESP_CODE_CURRENT_TIME,
          'NO_MORE_MESSAGES': RESP_CODE_NO_MORE_MESSAGES,
          'EXPORT_CONTACT': RESP_CODE_EXPORT_CONTACT,
          'BATT_AND_STORAGE': RESP_CODE_BATT_AND_STORAGE,
          'DEVICE_INFO': RESP_CODE_DEVICE_INFO,
          'PRIVATE_KEY': RESP_CODE_PRIVATE_KEY,
          'DISABLED': RESP_CODE_DISABLED,
          'CONTACT_MSG_RECV_V3': RESP_CODE_CONTACT_MSG_RECV_V3,
          'CHANNEL_MSG_RECV_V3': RESP_CODE_CHANNEL_MSG_RECV_V3,
          'CHANNEL_INFO': RESP_CODE_CHANNEL_INFO,
          'SIGN_START': RESP_CODE_SIGN_START,
          'SIGNATURE': RESP_CODE_SIGNATURE,
          'CUSTOM_VARS': RESP_CODE_CUSTOM_VARS,
          'ADVERT_PATH': RESP_CODE_ADVERT_PATH,
          'TUNING_PARAMS': RESP_CODE_TUNING_PARAMS,
          'STATS': RESP_CODE_STATS,
          'AUTOADD_CONFIG': RESP_CODE_AUTOADD_CONFIG,
          'ALLOWED_REPEAT_FREQ': RESP_CODE_ALLOWED_REPEAT_FREQ,
          'CHANNEL_DATA_RECV': RESP_CODE_CHANNEL_DATA_RECV,
          'DEFAULT_FLOOD_SCOPE': RESP_CODE_DEFAULT_FLOOD_SCOPE,
        },
        <String, int>{
          'OK': 0,
          'ERR': 1,
          'CONTACTS_START': 2,
          'CONTACT': 3,
          'END_OF_CONTACTS': 4,
          'SELF_INFO': 5,
          'SENT': 6,
          'CONTACT_MSG_RECV': 7,
          'CHANNEL_MSG_RECV': 8,
          'CURRENT_TIME': 9,
          'NO_MORE_MESSAGES': 10,
          'EXPORT_CONTACT': 11,
          'BATT_AND_STORAGE': 12,
          'DEVICE_INFO': 13,
          'PRIVATE_KEY': 14,
          'DISABLED': 15,
          'CONTACT_MSG_RECV_V3': 16,
          'CHANNEL_MSG_RECV_V3': 17,
          'CHANNEL_INFO': 18,
          'SIGN_START': 19,
          'SIGNATURE': 20,
          'CUSTOM_VARS': 21,
          'ADVERT_PATH': 22,
          'TUNING_PARAMS': 23,
          'STATS': 24,
          'AUTOADD_CONFIG': 25,
          'ALLOWED_REPEAT_FREQ': 26,
          'CHANNEL_DATA_RECV': 27,
          'DEFAULT_FLOOD_SCOPE': 28,
        },
      );

      expect(
        <String, int>{
          'ADVERT': PUSH_CODE_ADVERT,
          'PATH_UPDATED': PUSH_CODE_PATH_UPDATED,
          'SEND_CONFIRMED': PUSH_CODE_SEND_CONFIRMED,
          'MSG_WAITING': PUSH_CODE_MSG_WAITING,
          'RAW_DATA': PUSH_CODE_RAW_DATA,
          'LOGIN_SUCCESS': PUSH_CODE_LOGIN_SUCCESS,
          'LOGIN_FAIL': PUSH_CODE_LOGIN_FAIL,
          'STATUS_RESPONSE': PUSH_CODE_STATUS_RESPONSE,
          'LOG_RX_DATA': PUSH_CODE_LOG_RX_DATA,
          'TRACE_DATA': PUSH_CODE_TRACE_DATA,
          'NEW_ADVERT': PUSH_CODE_NEW_ADVERT,
          'TELEMETRY_RESPONSE': PUSH_CODE_TELEMETRY_RESPONSE,
          'BINARY_RESPONSE': PUSH_CODE_BINARY_RESPONSE,
          'PATH_DISCOVERY_RESPONSE': PUSH_CODE_PATH_DISCOVERY_RESPONSE,
          'CONTROL_DATA': PUSH_CODE_CONTROL_DATA,
          'CONTACT_DELETED': PUSH_CODE_CONTACT_DELETED,
          'CONTACTS_FULL': PUSH_CODE_CONTACTS_FULL,
        },
        <String, int>{
          'ADVERT': 0x80,
          'PATH_UPDATED': 0x81,
          'SEND_CONFIRMED': 0x82,
          'MSG_WAITING': 0x83,
          'RAW_DATA': 0x84,
          'LOGIN_SUCCESS': 0x85,
          'LOGIN_FAIL': 0x86,
          'STATUS_RESPONSE': 0x87,
          'LOG_RX_DATA': 0x88,
          'TRACE_DATA': 0x89,
          'NEW_ADVERT': 0x8A,
          'TELEMETRY_RESPONSE': 0x8B,
          'BINARY_RESPONSE': 0x8C,
          'PATH_DISCOVERY_RESPONSE': 0x8D,
          'CONTROL_DATA': 0x8E,
          'CONTACT_DELETED': 0x8F,
          'CONTACTS_FULL': 0x90,
        },
      );
    });

    test('error, advert, text, and control subtype bytes are pinned', () {
      expect(
        [
          ERR_CODE_UNSUPPORTED_CMD,
          ERR_CODE_NOT_FOUND,
          ERR_CODE_TABLE_FULL,
          ERR_CODE_BAD_STATE,
          ERR_CODE_FILE_IO_ERROR,
          ERR_CODE_ILLEGAL_ARG,
        ],
        [1, 2, 3, 4, 5, 6],
      );
      expect(
        [
          ADV_TYPE_NONE,
          ADV_TYPE_CHAT,
          ADV_TYPE_REPEATER,
          ADV_TYPE_ROOM_SERVER,
          ADV_TYPE_SENSOR,
        ],
        [0, 1, 2, 3, 4],
      );
      expect(
        [TXT_TYPE_PLAIN, TXT_TYPE_CLI_DATA, TXT_TYPE_SIGNED_PLAIN],
        [0, 1, 2],
      );
      expect(
        [CONTROL_SUBTYPE_DISCOVER_REQ, CONTROL_SUBTYPE_DISCOVER_RESP],
        [0x08, 0x09],
      );
    });
  });

  group('documented app-to-radio golden frames', () {
    final protocol = MeshCoreProtocol();

    test('APP_START is command, seven reserved bytes, then UTF-8 name', () {
      final payload = protocol.createAppStartPayload(appName: 'MCCLI');

      expect(
        protocol.createCommandFrameBLE(CMD_APP_START, payload),
        _hex('01 00 00 00 00 00 00 00 4D 43 43 4C 49'),
      );
    });

    test('DEVICE_QUERY requests response layout v3, not firmware v13', () {
      expect(COMPANION_APP_TARGET_VERSION, 3);
      expect(
        protocol.createCommandFrameBLE(
          CMD_DEVICE_QUERY,
          protocol.createDeviceQueryPayload(),
        ),
        _hex('16 03'),
      );
    });

    test(
      'channel text matches the exact UTF-8, timestamp, and no-NUL layout',
      () {
        final payload = protocol.createChannelMessagePayload(
          1,
          'Привет',
          senderTimestamp: 1234567890,
        );

        expect(
          protocol.createCommandFrameBLE(CMD_SEND_CHANNEL_MESSAGE, payload),
          _hex(
            '03 00 01 D2 02 96 49 '
            'D0 9F D1 80 D0 B8 D0 B2 D0 B5 D1 82',
          ),
        );
      },
    );

    test('channel name is a 32-byte null-terminated UTF-8 field', () {
      final payload = protocol.createSetChannelPayload(
        7,
        '12345678901234567890123456789012',
        Uint8List.fromList(List<int>.generate(16, (index) => 0xA0 + index)),
      );

      expect(payload, hasLength(49));
      expect(payload[0], 7);
      expect(
        utf8.decode(payload.sublist(1, 32)),
        '1234567890123456789012345678901',
      );
      expect(payload[32], 0);
      expect(
        payload.sublist(33),
        _hex('A0 A1 A2 A3 A4 A5 A6 A7 A8 A9 AA AB AC AD AE AF'),
      );
    });

    test('advert latitude and longitude are signed int32 little-endian', () {
      expect(
        protocol.createPositionPayload(55.7558, 37.6173),
        _hex('18 C4 52 03 94 FE 3D 02'),
      );
      expect(
        protocol.createPositionPayload(-33.8688, 151.2093),
        _hex('00 34 FB FD 54 45 03 09'),
      );
      expect(
        () => protocol.createPositionPayload(90.000001, 0),
        throwsArgumentError,
      );
      expect(
        () => protocol.createPositionPayload(0, double.nan),
        throwsArgumentError,
      );
    });

    test('DISCOVER_REQ pins flags, repeater filter, tag, and since fields', () {
      expect(
        protocol.createDiscoveryRequestPayload(0x12345678),
        _hex('81 04 78 56 34 12 00 00 00 00'),
      );
      expect(
        protocol.createDiscoveryRequestPayload(0x12345678, prefixOnly: false),
        _hex('80 04 78 56 34 12 00 00 00 00'),
      );
    });

    test('channel indexes outside firmware slots are rejected', () {
      expect(() => protocol.createGetChannelPayload(-1), throwsArgumentError);
      expect(() => protocol.createGetChannelPayload(8), throwsArgumentError);
      expect(
        () => protocol.createChannelMessagePayload(8, 'invalid'),
        throwsArgumentError,
      );
    });
  });

  group('USB and BLE transport contract', () {
    test('USB command wrapper is <, uint16-LE length, command, payload', () {
      final payload = Uint8List.fromList(List<int>.generate(175, (i) => i));
      final frame = MeshCoreProtocol().createCommandFrame(0x22, payload);

      expect(COMPANION_MAX_FRAME_SIZE, 176);
      expect(frame.sublist(0, 4), _hex('3C B0 00 22'));
      expect(frame, hasLength(3 + 176));
      expect(frame.sublist(4), payload);
      expect(
        () => MeshCoreProtocol().createCommandFrame(0x22, Uint8List(176)),
        throwsArgumentError,
      );
    });

    test('USB parser resynchronizes and works at every chunk boundary', () {
      final wireBytes = Uint8List.fromList([
        0x99,
        FRAME_START_OUTBOUND,
        3,
        0,
        RESP_CODE_OK,
        FRAME_START_OUTBOUND,
        0x7F,
        FRAME_START_OUTBOUND,
        1,
        0,
        RESP_CODE_END_OF_CONTACTS,
      ]);

      for (var split = 0; split <= wireBytes.length; split++) {
        final protocol = MeshCoreProtocol();
        final frames = <MeshCoreFrame>[
          ...protocol.parseIncomingData(wireBytes.sublist(0, split)),
          ...protocol.parseIncomingData(wireBytes.sublist(split)),
        ];

        expect(frames, hasLength(2), reason: 'split=$split');
        expect(frames[0].code, RESP_CODE_OK, reason: 'split=$split');
        expect(frames[0].data, _hex('3E 7F'), reason: 'split=$split');
        expect(
          frames[1].code,
          RESP_CODE_END_OF_CONTACTS,
          reason: 'split=$split',
        );
        expect(frames[1].data, isEmpty, reason: 'split=$split');
      }
    });

    test('zero-length serial noise cannot swallow the next valid frame', () {
      final frames = MeshCoreProtocol().parseIncomingData(
        Uint8List.fromList([
          FRAME_START_OUTBOUND,
          0,
          0,
          FRAME_START_OUTBOUND,
          1,
          0,
          RESP_CODE_OK,
        ]),
      );

      expect(frames, hasLength(1));
      expect(frames.single.code, RESP_CODE_OK);
    });

    test('impossible serial length resynchronizes at the next marker', () {
      final frames = MeshCoreProtocol().parseIncomingData(
        _hex('3E FF FF 12 34 3E 01 00 00'),
      );

      expect(frames, hasLength(1));
      expect(frames.single.code, RESP_CODE_OK);
    });

    test('each BLE notification is one unwrapped protocol frame', () {
      final protocol = MeshCoreProtocol()..setBLEMode(true);

      final first = protocol.parseIncomingData(_hex('00 78 56 34 12'));
      final second = protocol.parseIncomingData(_hex('04'));

      expect(first.single.code, RESP_CODE_OK);
      expect(first.single.data, _hex('78 56 34 12'));
      expect(second.single.code, RESP_CODE_END_OF_CONTACTS);
      expect(second.single.data, isEmpty);
    });
  });

  group('documented radio-to-app golden payloads', () {
    final protocol = MeshCoreProtocol();

    test('CONTACT exposes every fixed and optional firmware field', () {
      final payload = Uint8List(147);
      payload.setRange(0, 32, List<int>.generate(32, (index) => index));
      payload[32] = ADV_TYPE_REPEATER;
      payload[33] = 0xA5;
      payload[34] = 0x42;
      payload.setRange(35, 99, List<int>.generate(64, (index) => 0x80 + index));
      final name = utf8.encode('Relay 🚀');
      payload.setRange(99, 99 + name.length, name);
      _writeUint32LE(payload, 131, 0x12345678);
      _writeInt32LE(payload, 135, -33868800);
      _writeInt32LE(payload, 139, 151209300);
      _writeUint32LE(payload, 143, 0x89ABCDEF);

      final contact = protocol.parseContactFrame(payload);

      expect(contact, isNotNull);
      expect(contact!.publicKey, List<int>.generate(32, (index) => index));
      expect(contact.advType, ADV_TYPE_REPEATER);
      expect(contact.flags, 0xA5);
      expect(contact.outPathLen, 0x42);
      expect(contact.outPath, List<int>.generate(64, (index) => 0x80 + index));
      expect(contact.advName, 'Relay 🚀');
      expect(contact.lastAdvert, 0x12345678);
      expect(contact.advLat, closeTo(-33.8688, 0.0000001));
      expect(contact.advLon, closeTo(151.2093, 0.0000001));
      expect(contact.lastModified, 0x89ABCDEF);
    });

    test('SELF_INFO exposes the complete 57-byte fixed layout', () {
      final name = utf8.encode('Узел 🚗');
      final payload = Uint8List(57 + name.length);
      payload[0] = ADV_TYPE_CHAT;
      payload[1] = 20;
      payload[2] = 30;
      payload.setRange(3, 35, List<int>.generate(32, (index) => 0x20 + index));
      _writeInt32LE(payload, 35, -33868800);
      _writeInt32LE(payload, 39, 151209300);
      payload[43] = 2;
      payload[44] = 1;
      payload[45] = (2 << 4) | (1 << 2) | 3;
      payload[46] = 1;
      _writeUint32LE(payload, 47, 869525);
      _writeUint32LE(payload, 51, 250000);
      payload[55] = 10;
      payload[56] = 5;
      payload.setRange(57, payload.length, name);

      final info = protocol.parseSelfInfoFrame(payload);

      expect(info, isNotNull);
      expect(info!['adv_type'], ADV_TYPE_CHAT);
      expect(info['tx_power'], 20);
      expect(info['max_tx_power'], 30);
      expect(
        info['public_key'],
        List<int>.generate(32, (index) => 0x20 + index),
      );
      expect(info['adv_lat'], closeTo(-33.8688, 0.0000001));
      expect(info['adv_lon'], closeTo(151.2093, 0.0000001));
      expect(info['multi_acks'], 2);
      expect(info['adv_loc_policy'], 1);
      expect(info['telemetry_mode_env'], 2);
      expect(info['telemetry_mode_loc'], 1);
      expect(info['telemetry_mode_base'], 3);
      expect(info['manual_add_contacts'], isTrue);
      expect(info['radio_freq'], 869.525);
      expect(info['radio_bw'], 250.0);
      expect(info['radio_sf'], 10);
      expect(info['radio_cr'], 5);
      expect(info['name'], 'Узел 🚗');
      expect(protocol.parseSelfInfoFrame(Uint8List(56)), isNull);
    });

    test('CONTROL_DATA and DISCOVER_RESP preserve quarter-dB SNR', () {
      final responsePayload = Uint8List.fromList([
        0x92,
        0xF6,
        0x78,
        0x56,
        0x34,
        0x12,
        ...List<int>.generate(8, (index) => 0xA0 + index),
      ]);
      final control = protocol.parseControlDataPush(
        Uint8List.fromList([0xF7, 0xA6, 0x43, ...responsePayload]),
      );
      final discovery = protocol.parseDiscoveryResponse(
        control!['payload'] as Uint8List,
      );

      expect(control['snr'], -2.25);
      expect(control['rssi'], -90);
      expect(control['path_len'], 0x43);
      expect(discovery, isNotNull);
      expect(discovery!['node_type'], ADV_TYPE_REPEATER);
      expect(discovery['snr'], -2.5);
      expect(discovery['tag'], 0x12345678);
      expect(discovery['pubkey'], 'A0A1A2A3A4A5A6A7');
    });

    test('DISCOVER_RESP accepts only documented 8- or 32-byte node IDs', () {
      Uint8List responseWithKeyLength(int length) => Uint8List.fromList([
        0x92,
        0,
        1,
        0,
        0,
        0,
        ...List<int>.filled(length, 0xAA),
      ]);

      expect(
        protocol.parseDiscoveryResponse(responseWithKeyLength(8)),
        isNotNull,
      );
      expect(
        protocol.parseDiscoveryResponse(responseWithKeyLength(32)),
        isNotNull,
      );
      expect(protocol.parseDiscoveryResponse(responseWithKeyLength(7)), isNull);
      expect(protocol.parseDiscoveryResponse(responseWithKeyLength(9)), isNull);
    });

    test(
      'CHANNEL_DATA uses fixed metadata offsets and declared data length',
      () {
        final parsed = protocol.parseChannelDataFrame(
          _hex('F7 AA BB 07 FF 34 12 03 DE AD BE'),
        );

        expect(parsed, isNotNull);
        expect(parsed!['snr'], -2.25);
        expect(parsed['channel_idx'], 7);
        expect(parsed['path_len'], 0xFF);
        expect(parsed['data_type'], 0x1234);
        expect(parsed['payload'], _hex('DE AD BE'));
      },
    );
  });
}

Uint8List _hex(String value) => Uint8List.fromList(
  value
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => int.parse(part, radix: 16))
      .toList(),
);

void _writeUint32LE(Uint8List target, int offset, int value) {
  target[offset] = value & 0xFF;
  target[offset + 1] = (value >> 8) & 0xFF;
  target[offset + 2] = (value >> 16) & 0xFF;
  target[offset + 3] = (value >> 24) & 0xFF;
}

void _writeInt32LE(Uint8List target, int offset, int value) {
  _writeUint32LE(target, offset, value);
}
