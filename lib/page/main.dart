import 'package:flutter/material.dart';
import 'package:get/get.dart'; // GetX 임포트
import 'main_page.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp( // MaterialApp 대신 GetMaterialApp 사용
      title: 'ROS 2 Control',
      debugShowCheckedModeBanner: false,
      home: MainPage(), // 초기 페이지를 MainPage로 설정
    );
  }
}
