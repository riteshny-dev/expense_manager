import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _keyHiveEncryption = 'hive_encryption_key';
  
  // Generate a secure encryption key
  static Future<List<int>> generateSecureKey() async {
    final key = List<int>.generate(32, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    final keyHash = sha256.convert(key).bytes;
    await _storage.write(
      key: _keyHiveEncryption,
      value: base64.encode(keyHash),
    );
    return keyHash;
  }

  // Get the encryption key, generate if not exists
  static Future<List<int>> getEncryptionKey() async {
    final storedKey = await _storage.read(key: _keyHiveEncryption);
    if (storedKey != null) {
      return base64.decode(storedKey);
    }
    return generateSecureKey();
  }

  // Clear all secure storage
  static Future<void> clearSecureStorage() async {
    await _storage.deleteAll();
  }
}