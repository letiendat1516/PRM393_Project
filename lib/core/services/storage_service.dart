import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';

class StorageService {
  StorageService(this._storage);
  final FirebaseStorage _storage;

  Future<({String path, String url})> uploadResume({
    required String uid,
    required String resumeId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = 'resumes/$uid/$resumeId-$fileName';
    final ref = _storage.ref(path);
    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    final url = await ref.getDownloadURL();
    return (path: path, url: url);
  }

  Future<({String path, String url})> uploadImage({
    required String folder,
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final path = '$folder/$uid/$fileName';
    final ref = _storage.ref(path);
    await ref.putData(bytes, SettableMetadata(contentType: 'image/*'));
    final url = await ref.getDownloadURL();
    return (path: path, url: url);
  }

  Future<void> delete(String path) async {
    try {
      await _storage.ref(path).delete();
    } catch (_) {
      // ignore: object may already be gone
    }
  }
}
