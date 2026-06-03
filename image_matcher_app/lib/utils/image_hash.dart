import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageHash {
  /// 计算64位平均哈希（aHash）
  static int computeHash(Uint8List imageBytes) {
    img.Image? image = img.decodeImage(imageBytes);
    if (image == null) throw Exception('无效图片格式');
    
    // 缩放至8x8像素
    img.Image resized = img.copyResize(image, width: 8, height: 8);
    // 转为灰度图
    img.Image grayscale = img.grayscale(resized);
    
    // 计算平均灰度值
    int total = 0;
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        total += grayscale.getPixel(x, y).r;
      }
    }
    int avg = total ~/ 64;
    
    // 生成哈希值
    int hash = 0;
    for (int y = 0; y < 8; y++) {
      for (int x = 0; x < 8; x++) {
        int bit = (grayscale.getPixel(x, y).r >= avg) ? 1 : 0;
        hash = (hash << 1) | bit;
      }
    }
    return hash;
  }
  
  /// 汉明距离
  static int hammingDistance(int hash1, int hash2) {
    return (hash1 ^ hash2).toRadixString(2).replaceAll('0', '').length;
  }
}
