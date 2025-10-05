import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import '../services/security_logger.dart';

class SecureExportService {
  static Future<File> exportToPdf({
    required String fileName,
    required Future<pw.Document> Function() generateDocument,
    String? password,
  }) async {
    try {
      // Generate the PDF document
      final pdf = await generateDocument();
      
      // Get the directory for saving the file
      final dir = await _getExportDirectory();
      final file = File('${dir.path}/$fileName');

      // If password is provided, encrypt the PDF
      if (password != null && password.isNotEmpty) {
        final encryptedPdf = await pdf.save(
          onlySelected: true,
          userPassword: password,
          ownerPassword: _generateOwnerPassword(password),
        );
        await file.writeAsBytes(encryptedPdf);
        
        // Log the secure export
        await SecurityLogger.log(
          'SECURE_PDF_EXPORT',
          details: {
            'fileName': fileName,
            'isEncrypted': true,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      } else {
        await file.writeAsBytes(await pdf.save());
        
        // Log the standard export
        await SecurityLogger.log(
          'PDF_EXPORT',
          details: {
            'fileName': fileName,
            'isEncrypted': false,
            'timestamp': DateTime.now().toIso8601String(),
          },
        );
      }

      return file;
    } catch (e) {
      // Log the error
      await SecurityLogger.log(
        'PDF_EXPORT_ERROR',
        details: {
          'error': e.toString(),
          'fileName': fileName,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }

  static Future<Directory> _getExportDirectory() async {
    if (Platform.isAndroid) {
      return await getExternalStorageDirectory() ?? await getTemporaryDirectory();
    }
    return await getApplicationDocumentsDirectory();
  }

  static String _generateOwnerPassword(String userPassword) {
    // Generate a stronger owner password by hashing the user password
    final bytes = utf8.encode(userPassword + DateTime.now().toIso8601String());
    return sha256.convert(bytes).toString().substring(0, 32);
  }

  static Future<void> shareSecureFile(File file, {String? password}) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: password != null
            ? 'Encrypted PDF - Password will be shared separately'
            : 'Expense Report',
      );

      await SecurityLogger.log(
        'FILE_SHARED',
        details: {
          'fileName': file.path.split('/').last,
          'isEncrypted': password != null,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      await SecurityLogger.log(
        'FILE_SHARE_ERROR',
        details: {
          'error': e.toString(),
          'fileName': file.path.split('/').last,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
      rethrow;
    }
  }
}