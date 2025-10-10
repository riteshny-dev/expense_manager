import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class FileService {
  static Future<String?> getDownloadPath() async {
    Directory? directory;
    try {
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getDownloadsDirectory();
      }
      return directory?.path;
    } catch (e) {
      return null;
    }
  }

  static Future<void> sharePdfFile(String filePath, String text) async {
    await Share.shareXFiles([XFile(filePath)], text: text);
  }
}