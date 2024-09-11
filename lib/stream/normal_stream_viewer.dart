import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../theme/constants.dart';

class NormalStreamViewer extends StatefulWidget {
  final String streamUrl;

  const NormalStreamViewer({super.key, required this.streamUrl});

  @override
  _NormalStreamViewerState createState() => _NormalStreamViewerState();
}

class _NormalStreamViewerState extends State<NormalStreamViewer> {
  late VideoPlayerController _controller;
  bool _isBuffering = true;
  bool _showControls = true; // Biến để theo dõi trạng thái điều khiển

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.streamUrl))
      ..initialize().then((_) {
        setState(() {
          _isBuffering = false;
        });
        _controller.play(); // Tự động phát video
      }).catchError((error) {
        print('Error initializing video player: $error');
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _showControls
          ? AppBar(
              title: const Text('Normal Viewer'),
              flexibleSpace: Container(
                decoration: const BoxDecoration(
                  gradient: appGradient,
                ),
              ),
            )
          : null, // Ẩn AppBar khi không hiển thị điều khiển
      body: OrientationBuilder(
        builder: (context, orientation) {
          return GestureDetector(
            onVerticalDragDown: (details) {
              // Vuốt xuống để hiển thị điều khiển
              setState(() {
                _showControls = true;
              });
            },
            onTap: () {
              if (_showControls != false) {
                _showControls = false;
              } else {
                _showControls = true;
              }
              // // Ẩn hoặc hiện điều khiển khi nhấn vào màn hình
              // setState(() {
              //   _showControls = !_showControls;
              // });
            },
            child: Stack(
              children: [
                Center(
                  child: _controller.value.isInitialized
                      ? AspectRatio(
                          aspectRatio: _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        )
                      : _isBuffering
                          ? const CircularProgressIndicator()
                          : const Text('Failed to load stream'),
                ),
                if (_showControls)
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: Icon(
                            _controller.value.isPlaying
                                ? Icons.pause
                                : Icons.play_arrow,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            setState(() {
                              _controller.value.isPlaying
                                  ? _controller.pause()
                                  : _controller.play();
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.fullscreen,
                            color: Colors.white,
                          ),
                          onPressed: () {
                            // Xử lý logic fullscreen
                            _showControls = false;
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
