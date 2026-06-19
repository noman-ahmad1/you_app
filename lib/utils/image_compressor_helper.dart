import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:you_app/services/base/app_log.dart';

class ImageCompressorHelper {
  /// Compresses an image file and returns the compressed File.
  /// If compression fails, it returns the original file.
  static Future<File> compressImage(File file) async {
    try {
      final dir = await getTemporaryDirectory();
      final targetPath =
          '${dir.absolute.path}/temp_${DateTime.now().millisecondsSinceEpoch}.jpg';

      var result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 70, // 70% quality is a good balance for saving space
        minWidth: 1000,
        minHeight: 1000,
        format: CompressFormat.jpeg,
      );

      if (result != null) {
        final compressedFile = File(result.path);
        
        return compressedFile;
      }
    } catch (e) {
      AppLog.error('ImageCompressorHelper.compressImage', e);
    }

    // Return the original file if compression fails or result is null
    return file;
  }
}
