import 'package:flutter/material.dart';
import 'package:video_360/video_360.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;

class Video360FromAssets extends StatefulWidget {
  final String username;
  final String password;
  const Video360FromAssets({
    super.key,
    required this.username,
    required this.password,
  });
  @override
  _Video360FromAssetsState createState() => _Video360FromAssetsState();
}

class _Video360FromAssetsState extends State<Video360FromAssets> {
  late Video360Controller _controller;
  String? _videoPath;
  String durationText = '';
  String totalText = '';

  @override
  void initState() {
    super.initState();
    _loadVideoFromAssets();
  }

  Future<void> _loadVideoFromAssets() async {
    // Đọc file video từ thư mục assets
    final byteData = await rootBundle.load('assets/video/5813045141655.mp4');

    // Lấy đường dẫn thư mục tạm thời của ứng dụng
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/5813045141655.mp4');

    // Ghi nội dung file vào thư mục tạm thời
    await file.writeAsBytes(byteData.buffer.asUint8List());

    // Cập nhật đường dẫn video
    setState(() {
      _videoPath = file.path;
      _controller = Video360Controller(
        id: 0,
        url: _videoPath!,
      );
    });
  }

  // Hàm này sẽ được gọi khi Video360View được khởi tạo
  void _onVideo360ViewCreated(Video360Controller controller) {
    _controller = controller;
    _controller.play();
  }

  @override
  void dispose() {
    // Dừng video trước khi huỷ bỏ controller
    _controller.stop(); // Hoặc _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var statusBar = MediaQuery
        .of(context)
        .padding
        .top;

    var width = MediaQuery
        .of(context)
        .size
        .width;
    var height = MediaQuery
        .of(context)
        .size
        .height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Video 360 Plugin example app'),
      ),
      body: Stack(
        children: [
          Center(
            child: Container(
              width: width,
              height: height,
              child: Video360View(
                onVideo360ViewCreated: _onVideo360ViewCreated,
                url: _videoPath!,
                onPlayInfo: (Video360PlayInfo info) {
                  setState(() {
                    durationText = info.duration.toString();
                    totalText = info.total.toString();
                  });
                },
              ),
            ),
          ),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MaterialButton(
                    onPressed: () {
                      _controller?.play();
                    },
                    color: Colors.grey[100],
                    child: Text('Play'),
                  ),
                  MaterialButton(
                    onPressed: () {
                      _controller?.stop();
                    },
                    color: Colors.grey[100],
                    child: Text('Stop'),
                  ),
                  MaterialButton(
                    onPressed: () {
                      _controller?.reset();
                    },
                    color: Colors.grey[100],
                    child: Text('Reset'),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  MaterialButton(
                    onPressed: () {
                      _controller?.seekTo(-2000);
                    },
                    color: Colors.grey[100],
                    child: Text('<<'),
                  ),
                  MaterialButton(
                    onPressed: () {
                      _controller?.seekTo(2000);
                    },
                    color: Colors.grey[100],
                    child: Text('>>'),
                  ),

                ],
              )
            ],
          )
        ],
      ),
    );
  }
}