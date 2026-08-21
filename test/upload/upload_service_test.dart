import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/upload_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Meshcoretel upload defaults', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('selects the Russian endpoint for Russian locales', () {
      expect(
        UploadService.defaultApiUrlForLocale('ru_RU'),
        UploadService.defaultRuApiUrl,
      );
    });

    test('selects the global endpoint for other locales', () {
      expect(
        UploadService.defaultApiUrlForLocale('en_US'),
        UploadService.defaultGlobalApiUrl,
      );
    });

    test('uses Meshcoretel as the implicit endpoint and selection', () async {
      final service = UploadService();

      final endpoints = await service.getUploadEndpoints();
      expect(endpoints.single.name, UploadService.defaultEndpointName);
      expect(
        endpoints.single.url,
        anyOf(UploadService.defaultRuApiUrl, UploadService.defaultGlobalApiUrl),
      );
      expect(await service.getSelectedEndpoints(), [
        UploadService.defaultEndpointName,
      ]);
    });

    test('migrates the old implicit Default selection name', () async {
      SharedPreferences.setMockInitialValues({
        'selected_endpoints': jsonEncode(['Default']),
      });

      expect(await UploadService().getSelectedEndpoints(), [
        UploadService.defaultEndpointName,
      ]);
    });
  });
}
