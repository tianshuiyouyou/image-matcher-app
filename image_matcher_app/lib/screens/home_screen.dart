import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/image_hash.dart';
import '../utils/db_helper.dart';
import 'import_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _resultText = '点击下方按钮开始匹配';
  bool _isLoading = false;

  Future<void> _matchImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: source);
    if (picked == null) return;

    setState(() => _isLoading = true);
    try {
      Uint8List imageBytes = await picked.readAsBytes();
      int queryHash = ImageHash.computeHash(imageBytes);
      
      List<ImageData> library = await DBHelper.loadLibrary();
      if (library.isEmpty) {
        setState(() => _resultText = '请先导入图库（点击右上角图标）');
        return;
      }

      String bestMatch = '未找到匹配图片';
      int minDistance = 15;
      int matchedHash = 0;
      
      for (var item in library) {
        int dist = ImageHash.hammingDistance(queryHash, item.hashValue);
        if (dist < minDistance) {
          minDistance = dist;
          bestMatch = item.correctName;
          matchedHash = item.hashValue;
        }
      }

      double similarity = (1 - minDistance / 64) * 100;
      setState(() {
        _resultText = minDistance < 15
            ? '✅ $bestMatch\n相似度：${similarity.toStringAsFixed(1)}%'
            : '❌ 未在库中找到匹配图片\n（最相似汉明距离：$minDistance）';
      });
    } catch (e) {
      setState(() => _resultText = '识别失败：$e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('图片匹配器'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              );
              // 刷新（无需操作）
            },
            tooltip: '导入图库',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: () async {
              await DBHelper.clearLibrary();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已清空图库')),
              );
            },
            tooltip: '清空图库',
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Text(
                  _resultText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20),
                ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _matchImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('拍照'),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _matchImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('相册'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
