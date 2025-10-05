import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import '../services/security_logger.dart';
import '../services/secure_storage_service.dart';

class BackupService {
  static const String _backupFileName = 'expense_manager_backup.enc';
  
  static Future<File> createBackup(String password) async {
    try {
      final backupData = <String, dynamic>{
        'timestamp': DateTime.now().toIso8601String(),
        'boxes': <String, dynamic>{},
      };

      // Get all box names
      final boxes = ['expenses', 'settings', 'receivables_payables', 'tomorrow_tasks'];
      
      // Export each box
      for (final boxName in boxes) {
        final box = await Hive.openBox(boxName);
        final boxData = box.toMap();
        backupData['boxes'][boxName] = boxData;
        await box.close();
      }

      // Convert to JSON and encrypt
      final jsonData = json.encode(backupData);
      final encryptedData = await _encryptData(jsonData, password);
      
      // Save to file
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$_backupFileName');
      await file.writeAsBytes(encryptedData);

      await SecurityLogger.log(
        'BACKUP_CREATED',
        details: {
          'timestamp': DateTime.now().toIso8601String(),
          'boxesBackedUp': boxes,
        },
      );

      return file;
    } catch (e) {
      await SecurityLogger.log(
        'BACKUP_ERROR',
        details: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }

  static Future<void> restoreBackup(File backupFile, String password) async {
    try {
      // Read and decrypt backup
      final encryptedData = await backupFile.readAsBytes();
      final jsonData = await _decryptData(encryptedData, password);
      final backupData = json.decode(jsonData);

      // Validate backup format
      if (!backupData.containsKey('boxes') || !backupData.containsKey('timestamp')) {
        throw FormatException('Invalid backup format');
      }

      // Clear existing data
      for (final boxName in backupData['boxes'].keys) {
        final box = await Hive.openBox(boxName);
        await box.clear();
        
        // Restore data
        final boxData = backupData['boxes'][boxName];
        for (final key in boxData.keys) {
          await box.put(key, boxData[key]);
        }
        
        await box.close();
      }

      await SecurityLogger.log(
        'BACKUP_RESTORED',
        details: {
          'timestamp': DateTime.now().toIso8601String(),
          'backupDate': backupData['timestamp'],
          'boxesRestored': backupData['boxes'].keys.toList(),
        },
      );
    } catch (e) {
      await SecurityLogger.log(
        'RESTORE_ERROR',
        details: {
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }

  static Future<List<int>> _encryptData(String data, String password) async {
    final key = await _deriveKey(password);
    final iv = List<int>.generate(16, (i) => DateTime.now().millisecondsSinceEpoch % 256);
    final cipher = await SecureStorageService.getEncryptionKey();
    
    // Implement your encryption logic here using the key, IV, and cipher
    // This is a placeholder - you should use proper encryption
    final encrypted = base64.encode(utf8.encode(data));
    return utf8.encode(encrypted);
  }

  static Future<String> _decryptData(List<int> encryptedData, String password) async {
    final key = await _deriveKey(password);
    
    // Implement your decryption logic here
    // This is a placeholder - you should use proper decryption
    final decrypted = utf8.decode(encryptedData);
    return utf8.decode(base64.decode(decrypted));
  }

  static Future<List<int>> _deriveKey(String password) async {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).bytes;
  }
}