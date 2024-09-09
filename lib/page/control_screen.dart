import 'dart:async';
import 'dart:convert'; // JSON encoding을 위한 import
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_joystick/flutter_joystick.dart'; // 조이스틱 라이브러리

class ControlScreen extends StatefulWidget {
  final WebSocketChannel channel;

  ControlScreen({required this.channel});

  @override
  _ControlScreenState createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  bool isWebSocketClosed = false; // WebSocket 연결 상태
  double linearVelocity = 0.0; // 조이스틱의 선형 속도 값
  double angularVelocity = 0.0; // 조이스틱의 각속도 값
  double maxLinearSpeed = 1.0; // 최대 선형 속도
  double maxAngularSpeed = 1.0; // 최대 각속도

  @override
  void initState() {
    super.initState();

    // WebSocket 닫힘 감지
    widget.channel.sink.done.then((_) {
      setState(() {
        isWebSocketClosed = true;
      });
    });

    // /cmd_vel 토픽을 광고
    advertiseCmdVel();
  }

  // /cmd_vel 토픽을 광고하는 함수
  void advertiseCmdVel() {
    final advertiseMessage = {
      "op": "advertise",
      "topic": "/cmd_vel",
      "type": "geometry_msgs/Twist"
    };
    widget.channel.sink.add(jsonEncode(advertiseMessage)); // 광고 메시지 전송
    print("Advertised /cmd_vel topic");
  }

  // /cmd_vel 토픽에 명령을 발행하는 함수
  void sendCommand() {
    if (!isWebSocketClosed && widget.channel.closeCode == null) {
      final command = {
        "op": "publish",
        "topic": "/cmd_vel",
        "msg": {
          "linear": {"x": -linearVelocity * maxLinearSpeed, "y": 0.0, "z": 0.0}, // 속도 조절 적용
          "angular": {"x": 0.0, "y": 0.0, "z": -angularVelocity * maxAngularSpeed} // 각속도 조절 적용 (좌우 반전)
        }
      };
      widget.channel.sink.add(jsonEncode(command)); // JSON 직렬화 후 전송
      print("Command sent: $command");
    } else {
      print("WebSocket connection is closed. Cannot send data.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ROS 2 Control')),
      body: Column(
        children: [
          // 상단 60% 화면 영역
          Flexible(
            flex: 6, // 60% 영역 차지
            child: Container(
              padding: EdgeInsets.all(16.0),
              color: Colors.grey[200],
              child: Stack(
                children: [
                  // 왼쪽 상단: 조이스틱으로 바뀌는 현재 속도
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Text(
                      'Speed:\nLinear: ${(-linearVelocity).toStringAsFixed(2)} m/s\nAngular: ${angularVelocity.toStringAsFixed(2)} rad/s',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16), // 상단과 하단 간격 추가

          // 하단 조종 부분 - 3줄로 나누기
          Flexible(
            flex: 4, // 40% 영역 차지
            child: Column(
              children: [
                // 첫 번째 줄 - 맥스 스피드와 조이스틱
                Expanded(
                  child: Row(
                    children: [
                      // Max Speed 텍스트 부분 박스
                      Expanded(
                        child: Container(
                          padding: EdgeInsets.all(12.0),
                          margin: EdgeInsets.all(8.0),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                spreadRadius: 3,
                                blurRadius: 5,
                                offset: Offset(0, 3), // 그림자 방향
                              ),
                            ],
                          ),
                          child: Text(
                            'Max Speed:\nLinear: ${maxLinearSpeed.toStringAsFixed(2)} m/s\nAngular: ${maxAngularSpeed.toStringAsFixed(2)} rad/s',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      // 조이스틱 영역 박스
                      Container(
                        padding: EdgeInsets.all(10.0),
                        margin: EdgeInsets.all(6.0),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 3,
                              blurRadius: 5,
                              offset: Offset(0, 3), // 그림자 방향
                            ),
                          ],
                        ),
                        // 조이스틱 크기 조절
                        width: 90,
                        height: 90,
                        child: Joystick(
                          mode: JoystickMode.all, // 조이스틱 모든 방향 허용
                          listener: (details) {
                            setState(() {
                              linearVelocity = details.y; // 전후 방향
                              angularVelocity = details.x; // 좌우 회전
                            });
                            sendCommand();
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                // 두 번째 줄 - Max Linear Speed 슬라이더
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    margin: EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset: Offset(0, 3), // 그림자 방향
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Max Linear Speed',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: maxLinearSpeed,
                          min: 0.1,
                          max: 5.0,
                          divisions: 49,
                          label: '${maxLinearSpeed.toStringAsFixed(2)} m/s',
                          onChanged: (value) {
                            setState(() {
                              maxLinearSpeed = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // 세 번째 줄 - Max Angular Speed 슬라이더
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(10.0),
                    margin: EdgeInsets.all(6.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 3,
                          blurRadius: 5,
                          offset: Offset(0, 3), // 그림자 방향
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Max Angular Speed',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        Slider(
                          value: maxAngularSpeed,
                          min: 0.1,
                          max: 5.0,
                          divisions: 49,
                          label: '${maxAngularSpeed.toStringAsFixed(2)} rad/s',
                          onChanged: (value) {
                            setState(() {
                              maxAngularSpeed = value;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.channel.sink.close();
    super.dispose();
  }
}
