import 'package:flutter/material.dart';
import 'normal_stream_viewer.dart';  // Import file chứa NormalStreamViewer nếu nó nằm ở file riêng
import 'panorama_stream_viewer.dart';  // Import file chứa PanoramaStreamViewer nếu nó nằm ở file riêng
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/constants.dart';
class StreamPlayer extends StatefulWidget {
  const StreamPlayer({super.key});

  @override
  _StreamPlayerState createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  final TextEditingController _urlController = TextEditingController();
  bool _didShowDialog = false;  // Để đảm bảo popup chỉ được hiển thị một lần
  String _streamUrl ="";
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didShowDialog) {
      _didShowDialog = true;
      _showUrlInputDialog();
    }
  }

  // Hàm tải IP đã lưu từ shared_preferences
  Future<void> _loadSavedIp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString('savedIp');
    if (savedIp != null && savedIp.isNotEmpty) {
      if (mounted) {  // Kiểm tra widget có còn tồn tại trước khi gọi setState
        setState(() {
          _streamUrl = 'http://$savedIp:8080/hls/theta_stream.m3u8';
        });
      }
    }
  }


  // Hàm lưu IP vào shared_preferences
  Future<void> _saveIp(String ip) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('savedIp', ip);
  }

  // Hiển thị dialog nhập IP và lưu nó
  void _showUrlInputDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false, // Không cho đóng popup khi bấm ngoài
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Stream IP Address'),
            content: TextField(
              controller: _urlController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter IP (e.g. 192.168.0.110)',
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_urlController.text.isNotEmpty) {
                    // Ghép nối IP với đường dẫn cố định
                    final fullUrl = 'http://${_urlController.text}:8080/hls/theta_stream.m3u8';

                    // Ghi nhớ IP vào shared_preferences
                    _saveIp(_urlController.text);

                    // Gán URL đầy đủ vào nơi cần dùng
                    setState(() {
                      _streamUrl = fullUrl;
                    });

                    Navigator.of(context).pop(); // Đóng popup
                  }
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ricoh Theta Z1 Streaming'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: appGradient,
          ),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                if (_urlController.text.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>  NormalStreamViewer(
                        streamUrl: _streamUrl, // Sử dụng URL từ người dùng nhập
                      ),
                    ),
                  );
                } else {
                  _showUrlInputDialog(); // Nhắc người dùng nhập URL nếu chưa có
                }
              },
              child: const Text('Watch Normal Stream'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_urlController.text.isNotEmpty) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>  PanoramaStreamViewer(
                        streamUrl: _streamUrl, // Sử dụng URL từ người dùng nhập
                      ),
                    ),
                  );
                } else {
                  _showUrlInputDialog(); // Nhắc người dùng nhập URL nếu chưa có
                }
              },
              child: const Text('Watch Panorama Stream'),
            ),
          ],
        ),
      ),
    );
  }
}
