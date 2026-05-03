import 'dart:convert';
import 'dart:io';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';

class BackupService {
  static const List<String> _boxNames = [
    'load_services',
    'drivers',
    'cars',
    'sellers',
    'customers',
    'load_types',
    'payments',
    'maintenances',
    'car_expenses',
    'logistics_cos',
    'bank_accounts'
  ];

  static Future<void> createBackup() async {
    Map<String, dynamic> backupData = {};

    for (String boxName in _boxNames) {
      final box = Hive.box(boxName);
      backupData[boxName] = box.toMap();
    }

    final String jsonString = jsonEncode(backupData);
    final directory = await getTemporaryDirectory();
    final String fileName = "khatoonbar_backup_${DateTime.now().millisecondsSinceEpoch}.json";
    final File file = File('${directory.path}/$fileName');
    
    await file.writeAsString(jsonString);

    await Share.shareXFiles([XFile(file.path)], text: 'فایل پشتیبان خاتون بار');
  }

  static Future<bool> restoreBackup() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) return false;

    try {
      final File file = File(result.files.single.path!);
      final String jsonString = await file.readAsString();
      final Map<String, dynamic> backupData = jsonDecode(jsonString);

      for (String boxName in _boxNames) {
        if (backupData.containsKey(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          final Map<String, dynamic> data = Map<String, dynamic>.from(backupData[boxName]);
          for (var entry in data.entries) {
            await box.put(entry.key, entry.value);
          }
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }
}
