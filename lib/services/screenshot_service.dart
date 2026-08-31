import 'dart:typed_data';

import 'package:saver_gallery/saver_gallery.dart';

/// Saves captured map screenshots into the device gallery.
///
/// The Android relative path must start with a MediaStore primary directory
/// such as `Pictures`. A bare custom folder name makes MediaStore reject the
/// insert, and the gallery plugin then dies with an unhandled native
/// exception, crashing the whole app.
class ScreenshotService {
  /// Gallery folder used for coverage screenshots.
  ///
  /// Must keep the `Pictures/` prefix on Android; see the class docs.
  static const String galleryRelativePath = 'Pictures/MeshCore';

  const ScreenshotService();

  /// Stores [imageBytes] in the gallery under [fileName] and returns whether
  /// the save succeeded.
  Future<bool> saveToGallery(Uint8List imageBytes, String fileName) async {
    final result = await SaverGallery.saveImage(
      imageBytes,
      quality: 100,
      fileName: fileName,
      androidRelativePath: galleryRelativePath,
      skipIfExists: false,
    );
    return result.isSuccess;
  }
}
