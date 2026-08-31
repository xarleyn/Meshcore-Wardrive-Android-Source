import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meshcore_wardrive/services/screenshot_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('saver_gallery');
  const service = ScreenshotService();

  final capturedCalls = <MethodCall>[];

  void mockSaverGallery(Object? result) {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          capturedCalls.add(call);
          return result;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    capturedCalls.clear();
  });

  test('saves with a MediaStore-safe Android relative path', () async {
    mockSaverGallery(<String, dynamic>{
      'isSuccess': true,
      'errorMessage': null,
    });

    final saved = await service.saveToGallery(
      Uint8List.fromList([1, 2, 3]),
      'shot.png',
    );

    expect(saved, isTrue);
    expect(capturedCalls, hasLength(1));
    final call = capturedCalls.single;
    expect(call.method, 'saveImageToGallery');
    expect(call.arguments['fileName'], 'shot.png');
    // MediaStore rejects relative paths that do not start with a primary
    // directory (Pictures, DCIM, Download, ...); an invalid path crashes the
    // app inside the gallery plugin.
    expect(call.arguments['relativePath'], 'Pictures/MeshCore');
  });

  test('reports a failed save', () async {
    mockSaverGallery(<String, dynamic>{
      'isSuccess': false,
      'errorMessage': 'Couldn\'t save the image',
    });

    final saved = await service.saveToGallery(
      Uint8List.fromList([1, 2, 3]),
      'shot.png',
    );

    expect(saved, isFalse);
  });
}
