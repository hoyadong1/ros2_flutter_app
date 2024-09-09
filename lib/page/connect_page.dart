import 'dart:async';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'control_screen.dart'; // 제어 페이지 임포트

class ConnectPage extends StatefulWidget {
  @override
  _ConnectPageState createState() => _ConnectPageState();
}

class _ConnectPageState extends State<ConnectPage> with TickerProviderStateMixin {
  final TextEditingController _ipController = TextEditingController();
  final TextEditingController _portController = TextEditingController();
  WebSocketChannel? channel;
  bool isConnecting = false;
  String? errorMessage;
  StreamSubscription? _subscription;

  late AnimationController _buttonController;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _buttonController.dispose();
    _fadeController.dispose();
    _ipController.dispose();
    _portController.dispose();
    super.dispose();
  }

  void connectToRos2() {
    setState(() {
      isConnecting = true;
      errorMessage = null;
    });

    final ip = _ipController.text.trim();
    final port = _portController.text.trim();

    try {
      final uri = Uri.parse('ws://$ip:$port');
      channel = WebSocketChannel.connect(uri);

      // 서버로 테스트 메시지를 보내고 응답 확인
      channel!.sink.add('{"op": "subscribe", "topic": "/rosout"}');

      _subscription = channel!.stream.listen(
            (data) {
          // 서버로부터 정상적인 응답이 오면 제어 페이지로 이동
          if (data.toString().contains('msg')) {
            _fadeController.forward().then((_) {
              Navigator.pushReplacement(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      ControlScreen(channel: channel!),
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    var begin = 0.0;
                    var end = 1.0;
                    var curve = Curves.easeInOut;
                    var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                    return FadeTransition(opacity: animation.drive(tween), child: child);
                  },
                ),
              );
            });
          } else {
            setState(() {
              errorMessage = 'Unexpected response: $data';
              isConnecting = false;
              _subscription?.cancel();
              channel?.sink.close();
            });
          }
        },
        onError: (error) {
          setState(() {
            errorMessage = 'Failed to connect: $error';
            isConnecting = false;
            _subscription?.cancel();
            channel?.sink.close();
          });
        },
      );

      // 일정 시간 내에 응답이 없으면 타임아웃
      Future.delayed(Duration(seconds: 5), () {
        if (isConnecting) {
          setState(() {
            errorMessage = 'Connection timed out.';
            isConnecting = false;
            _subscription?.cancel();
            channel?.sink.close();
          });
        }
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to connect: $e';
        isConnecting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connect to robot')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _ipController,
                  decoration: InputDecoration(
                    labelText: 'Robot IP',
                    border: InputBorder.none,
                  ),
                ),
              ),
              SizedBox(height: 16),
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.blueAccent),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _portController,
                  decoration: InputDecoration(
                    labelText: 'Robot Port',
                    border: InputBorder.none,
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              SizedBox(height: 16),
              isConnecting
                  ? CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: connectToRos2,
                child: Text('Connect'),
              ),
              SizedBox(height: 16),
              if (errorMessage != null)
                Text(
                  errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
