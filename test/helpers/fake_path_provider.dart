import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Points the path_provider method channel at [directory], so services that
/// persist files (application documents, temporary and external storage
/// directories) all resolve to paths inside it.
void installFakePathProvider(Directory directory) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
        const MethodChannel('plugins.flutter.io/path_provider'),
        (call) async => directory.path,
      );
}
