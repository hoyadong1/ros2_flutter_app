import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'connect_page.dart'; // ConnectPage 임포트

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse('https://mobilio.io/'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer( // 사이드바 추가
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueAccent, Colors.lightBlueAccent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.transparent,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: AssetImage('assets/icon/1024.png'), // 로고 이미지 추가
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Mobilio',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                    Text(
                      'AI Technology for Human Safety',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                margin: EdgeInsets.all(10),
                padding: EdgeInsets.all(5),
              ),
              _buildMenuItem(Icons.home, '홈', () {
                // 홈 페이지로 이동
              }),
              _buildMenuItem(Icons.important_devices, '로봇 연결', () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ConnectPage()));
              }),
              _buildMenuItem(Icons.settings, '설정', () {
                // 설정 페이지로 이동
              }),
            ],
          ),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller), // 웹뷰 추가
          Positioned(
            top: 40, // 햄버거 아이콘 위치
            left: 10,
            child: Builder( // Builder로 감싸서 적절한 context 제공
              builder: (context) {
                return IconButton(
                  icon: Icon(Icons.menu, size: 30, color: Colors.blueAccent),
                  onPressed: () {
                    Scaffold.of(context).openDrawer(); // 햄버거 아이콘을 누르면 사이드바 열기
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(
        title,
        style: TextStyle(color: Colors.white),
      ),
      onTap: onTap,
    );
  }
}
