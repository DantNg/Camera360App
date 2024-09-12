import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class StreamSetting extends StatefulWidget {
  const StreamSetting({super.key});

  @override
  _StreamSettingState createState() => _StreamSettingState();
}

class _StreamSettingState extends State<StreamSetting> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    // Chỉ hỗ trợ WebView cho Android và iOS
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted) // Kích hoạt JavaScript
      ..loadRequest(Uri.parse('http://192.168.0.100:8888/')); // Tải URL trang web
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Setting'),
      ),
      body: WebViewWidget(controller: _controller), // WebView nhúng trang web
    );
  }
}
