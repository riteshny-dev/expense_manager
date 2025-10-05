import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class SecurityLogger {
  static const _storage = FlutterSecureStorage();
  static const _logKey = 'security_logs';
  static const _maxLogs = 1000; // Keep last 1000 logs

  static Future<void> log(String event, {Map<String, dynamic>? details}) async {
    try {
      final timestamp = DateTime.now();
      final log = {
        'timestamp': timestamp.toIso8601String(),
        'event': event,
        'details': details ?? {},
      };

      // Get existing logs
      final existingLogsStr = await _storage.read(key: _logKey);
      List<dynamic> logs = [];
      if (existingLogsStr != null) {
        logs = json.decode(existingLogsStr);
      }

      // Add new log and trim if necessary
      logs.add(log);
      if (logs.length > _maxLogs) {
        logs.removeRange(0, logs.length - _maxLogs);
      }

      // Save updated logs
      await _storage.write(key: _logKey, value: json.encode(logs));
    } catch (e) {
      // In case of error, we don't want to crash the app
      print('Error writing security log: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getLogs() async {
    try {
      final logsStr = await _storage.read(key: _logKey);
      if (logsStr == null) return [];
      
      final logs = json.decode(logsStr) as List;
      return logs.cast<Map<String, dynamic>>();
    } catch (e) {
      print('Error reading security logs: $e');
      return [];
    }
  }

  static Future<void> clearLogs() async {
    await _storage.delete(key: _logKey);
  }

  static String formatLogTimestamp(String timestamp) {
    final date = DateTime.parse(timestamp);
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(date);
  }
}