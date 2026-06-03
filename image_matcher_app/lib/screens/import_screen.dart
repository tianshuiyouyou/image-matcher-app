import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import '../utils/image_hash.dart';
import '../utils/db_helper.dart';
import '../models/image_data.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  bool _isImporting = false;

  Future<void> _importLibrary() async {
    setState(() => _isImporting = true);
    try {
      // 1. 选择Excel文件
      FilePickerResult? excelResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
      );
      if (excelResult == null) return;

      // 2. 选择ZIP压缩包
      FilePickerResult? zipResult = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );
      if (zipResult == null) return;

      // 3. 解析Excel
      var bytes = excelResult.files.first.bytes;
      var excel = Excel.decodeBytes(bytes!);
      var sheet = excel.tables[excel.tables.keys.first];
      Map<String, String> nameMapping = {};
      for (var row in sheet.rows.skip(1)) { // 跳过表头
        String fileName = row[0]?.value?.toString() ?? '';
        String correctName = row[1]?.value?.toString() ?? '';
        if (fileName.isNotEmpty && correctName.isNotEmpty) {
          nameMapping[fileName] = correctName;
        }
      }

      if (nameMapping.isEmpty) throw Exception('Excel 中没有有效数据');

      // 4. 解压ZIP并计算哈希
      var zipBytes = zipResult.files.first.bytes;
      Archive archive = ZipDecoder().decodeBytes(zipBytes!);
      List<ImageData> library = [];
      int processed = 0;

      for (var file in archive) {
        if (file.isFile && _isImageFile(file.name)) {
          String fileName = file.name.split('/').last;
          if (nameMapping.containsKey(fileName)) {
            Uint8List fileBytes = file.content as Uint8List;
            int hash = ImageHash.computeHash(fileBytes);
            library.add(ImageData(
              fileName: fileName,
              correctName: nameMapping[fileName]!,
              hashValue: hash,
            ));
            processed++;
          }
        }
      }

      if (library.isEmpty) throw Exception('ZIP中没有找到匹配Excel记录的图片');

      await DBHelper.saveLibrary(library);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入成功！共 ${library.length} 张图片')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败：$e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  bool _isImageFile(String name) {
    final ext = name.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'bmp', 'webp'].contains(ext);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('导入图库')),
      body: Center(
        child: _isImporting
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('正在处理，请稍候...'),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.cloud_upload, size: 80, color: Colors.blue),
                  const SizedBox(height: 20),
                  const Text(
                    '请准备以下文件：\n1. Excel（第一列图片文件名，第二列正确名称）\n2. ZIP压缩包（包含所有对应图片）',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton.icon(
                    onPressed: _importLibrary,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('选择文件并导入'),
                  ),
                ],
              ),
      ),
    );
  }
}
