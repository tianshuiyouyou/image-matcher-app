import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const ImageMatcherApp());
}

class ImageMatcherApp extends StatelessWidget {
  const ImageMatcherApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '图片匹配器',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
