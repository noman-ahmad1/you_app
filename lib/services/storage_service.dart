import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String?> uploadFile(File file, String path) async {
    try {
      print('Uploading file to: $path');
      final ref = _storage.ref().child(path);

      // Use putFile() instead of putData().
      // This streams the file directly from the disk cache, preventing memory crashes.
      final uploadTask = ref.putFile(file);

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      print('File uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading file to storage: $e');
      rethrow;
    }
  }

  Future<void> deleteFile(String path) async {
    try {
      final ref = _storage.ref().child(path);
      await ref.delete();
    } catch (e) {
      print('Error deleting file from storage: $e');
    }
  }

  Future<void> deleteFileByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      print('Error deleting file from storage by url: $e');
    }
  }
}
