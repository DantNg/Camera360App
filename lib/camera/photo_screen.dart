import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:panorama_viewer/panorama_viewer.dart';
import 'package:http_auth/http_auth.dart';
class PhotoScreen extends StatefulWidget {
  final String name;
  final String fileUrl;
  final String username;
  final String password;

  const PhotoScreen({
    super.key,
    required this.name,
    required this.fileUrl,
    required this.username,
    required this.password,
  });

  @override
  _PhotoScreenState createState() => _PhotoScreenState();
}

class _PhotoScreenState extends State<PhotoScreen> {
  Uint8List? imageData;
  late final String _username;
  late final String _password;
  @override
  void initState() {
    super.initState();
    _username = widget.username;
    _password = widget.password;
    _loadImage();
  }

  Future<void> _loadImage() async {
    var client = DigestAuthClient(_username, _password); // Use DigestAuthClient with username and password

    try {
      // Send the authenticated request using DigestAuthClient
      final authenticatedResponse = await client.get(Uri.parse(widget.fileUrl));

      if (authenticatedResponse.statusCode == 200) {
        setState(() {
          imageData = authenticatedResponse.bodyBytes; // Set image data if request is successful
        });
      } else {
        debugPrint('Failed to load image with auth: ${authenticatedResponse.statusCode}');
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Photo: ${widget.name}')),
      body: Center(
        child: imageData == null
            ? const CircularProgressIndicator() // Hiển thị khi đang tải ảnh
            : PanoramaViewer(
          child: Image.memory(imageData!), // Hiển thị ảnh sau khi tải xong
        ),
      ),
    );
  }
}
