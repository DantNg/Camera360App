import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:http_auth/http_auth.dart'; // Thư viện Digest Authentication

class CameraStreamService {
  final String ipAddress;
  final String username;
  final String password;

  CameraStreamService({
    required this.ipAddress,
    required this.username,
    required this.password,
  });

  // URL để setup chế độ stream
  String get setupUrl => 'http://$ipAddress/osc/commands/execute';

  // URL để bắt đầu hoặc dừng stream
  String get startStopUrl => 'http://$ipAddress:8888?start_stream';

  // Phương thức để setup stream với Digest Auth
  Future<bool> setupStream() async {
    // Tạo đối tượng DigestAuthClient
    final digestAuth = DigestAuthClient(username, password);

    // Body request JSON
    final body = jsonEncode({
      "name": "camera._pluginControl",
      "parameters": {
        "action": "boot",
        "plugin": "com.theta360.cloudstreaming"
      }
    });

    // Gửi request POST với Digest Auth
    final response = await digestAuth.post(
      Uri.parse(setupUrl),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    // Kiểm tra phản hồi từ server
    if (response.statusCode == 200) {
      print('Stream setup successful');
      return true;
    } else {
      print('Failed to setup stream: ${response.statusCode}');
      return false;
    }
  }

  // Phương thức để bắt đầu hoặc dừng stream với Digest Auth
  Future<bool> startStopStream(bool start) async {
    // Tạo đối tượng DigestAuthClient
    final digestAuth = DigestAuthClient(username, password);

    // Tạo URL với tham số start_stream hoặc stop_stream
    final action = start ? 'start_stream' : 'start_stream';
    final url = 'http://$ipAddress:8888/start_streaming';

    // Gửi request GET với Digest Auth
    final response = await digestAuth.post(
      Uri.parse(url),
    );

    // Kiểm tra phản hồi từ server
    if (response.statusCode == 200) {
      print('${start ? 'Start' : 'Stop'} stream successful');
      return true;
    } else {
      print('Failed to ${start ? 'start' : 'stop'} stream: ${response.statusCode}');
      return false;
    }
  }
}
