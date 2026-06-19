import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:you_app/services/base/app_log.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile(File file, String path) async {
    try {
      final ref = _storage.ref().child(path);

      // Use putFile() instead of putData().
      // This streams the file directly from the disk cache, preventing memory crashes.
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      AppLog.error('StorageService.uploadFile', e);
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      AppLog.error('StorageService.deleteFile', e);
    }
  }

  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      AppLog.error('StorageService.deleteFileByUrl', e);
    }
  }
}
