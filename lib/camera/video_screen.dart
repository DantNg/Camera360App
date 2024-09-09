import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class VideoScreen extends StatefulWidget {
  final String name;
  final String fileUrl;
  final String username;
  final String password;

  const VideoScreen({
    super.key,
    required this.name,
    required this.fileUrl,
    required this.username,
    required this.password,
  });

  @override
  State<StatefulWidget> createState() {
    return _VideoScreenState();
  }
}

class _VideoScreenState extends State<VideoScreen> {
  late VideoPlayerController _controller;
  String? videoFilePath;

  @override
  void initState() {
    super.initState();
    _loadVideo();
  }

  Future<void> _loadVideo() async {
    try {
      // Step 1: Send a request to get the 'nonce', 'realm', etc.
      final initialResponse = await http.get(Uri.parse(widget.fileUrl));

      if (initialResponse.statusCode == 401) {
        final authHeader = initialResponse.headers['www-authenticate'];

        if (authHeader != null && authHeader.startsWith('Digest ')) {
          final authDetails = _parseAuthDetails(authHeader);

          String username = widget.username;
          String password = widget.password;
          final ha1 = md5.convert(utf8.encode('$username:${authDetails["realm"]}:$password')).toString();
          final ha2 = md5.convert(utf8.encode('GET:${authDetails["uri"]}')).toString();
          final response = md5.convert(utf8.encode('$ha1:${authDetails["nonce"]}:00000001:${authDetails["cnonce"]}:${authDetails["qop"]}:$ha2')).toString();

          final digestAuthHeader = 'Digest username="$username", realm="${authDetails["realm"]}", nonce="${authDetails["nonce"]}", uri="${authDetails["uri"]}", algorithm="MD5", response="$response", qop=${authDetails["qop"]}, nc=00000001, cnonce="${authDetails["cnonce"]}"';

          // Step 3: Send the authenticated request and load video data
          final authenticatedResponse = await http.get(
            Uri.parse(widget.fileUrl),
            headers: {
              'Authorization': digestAuthHeader,
            },
          );

          if (authenticatedResponse.statusCode == 200) {
            await _saveVideoToFile(authenticatedResponse.bodyBytes);
            _initializeVideoPlayer();
          } else {
            throw Exception('Failed to load video with auth: ${authenticatedResponse.statusCode}');
          }
        }
      } else if (initialResponse.statusCode == 200) {
        await _saveVideoToFile(initialResponse.bodyBytes);
        _initializeVideoPlayer();
      }
    } catch (e) {
      print('Error loading video: $e');
    }
  }

  Future<void> _saveVideoToFile(Uint8List videoBytes) async {
    final tempDir = await getTemporaryDirectory();
    final videoFile = File('${tempDir.path}/video.mp4');
    await videoFile.writeAsBytes(videoBytes);
    videoFilePath = videoFile.path;
  }

  void _initializeVideoPlayer() {
    _controller = VideoPlayerController.file(File(videoFilePath!));
    _controller.initialize().then((_) {
      setState(() {});
    });
  }

  Map<String, String> _parseAuthDetails(String authHeader) {
    final authParams = authHeader.substring(7).split(', ').map((param) {
      final parts = param.split('=');
      final key = parts[0];
      final value = parts[1].replaceAll('"', '');
      return MapEntry(key, value);
    });

    return Map<String, String>.fromEntries(authParams);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video: ${widget.name}'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: videoFilePath == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  _controller
                      .seekTo(Duration.zero)
                      .then((_) => _controller.play());
                },
                icon: const Icon(Icons.refresh),
              ),
              IconButton(
                onPressed: () {
                  _controller.play();
                },
                icon: const Icon(Icons.play_arrow),
              ),
              IconButton(
                onPressed: () {
                  _controller.pause();
                },
                icon: const Icon(Icons.pause),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
