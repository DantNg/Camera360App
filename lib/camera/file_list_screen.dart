import 'dart:convert';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'video_screen.dart';
import 'photo_screen.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'panorama/panorama_photo_screen.dart';
import 'package:http_auth/http_auth.dart';

// Định nghĩa lớp FileInfo để xử lý dữ liệu JSON từ response
class FileInfo {
  final String name;
  final String fileUrl;
  final Uint8List? thumbnail;
  final String? dateTimeZone;
  final int? recordTime;
  final int? size;
  FileInfo({
    required this.name,
    required this.fileUrl,
    this.thumbnail,
    this.dateTimeZone,
    this.recordTime,
    this.size,
  });

  factory FileInfo.fromJson(Map<String, dynamic> json) {
    return FileInfo(
      name: json['name'],
      fileUrl: json['fileUrl'],
      thumbnail:
          json['thumbnail'] != null ? base64Decode(json['thumbnail']) : null,
      dateTimeZone: json['dateTimeZone'] != null ? json['dateTimeZone'] : null,
      recordTime: json['_recordTime'] != null ? json['_recordTime'] : null,
      size: json['size'] != null ? json['size'] : null,
    );
  }
}

class FileListScreen extends StatefulWidget {
  final String endpoint;
  final String username;
  final String password;
  const FileListScreen({
    super.key,
    required this.endpoint,
    required this.username,
    required this.password,
  });

  @override
  State<StatefulWidget> createState() {
    return _FileListScreen();
  }
}

class _FileListScreen extends State<FileListScreen> {
  List<FileInfo> _fileInfoList = [];
  Set<int> _selectedFiles = Set<int>(); // Set to store selected file indices
  String? _cachedNonce;
  String? _cachedRealm;
  String? _cachedQop;
  String? _cachedUri;
  late final String _endpoint;
  late final String _username;
  late final String _password;
  @override
  void initState() {
    super.initState();
    // Initialize the variables with the values passed from the parent class
    _endpoint = widget.endpoint;
    _username = widget.username;
    _password = widget.password;
    getFileList();
  }

  Future<void> getFileList() async {
    try {
      final url = Uri.parse('$_endpoint/osc/commands/execute');

      // Bước 1: Gửi yêu cầu không có xác thực để nhận thông tin xác thực
      final initialResponse = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: jsonEncode({
          'name': 'camera.listFiles',
          'parameters': {
            'fileType': 'all', // Lấy tất cả các loại file
            'entryCount': 10000, // Số lượng file tối đa
            'maxThumbSize': 160, // Kích thước tối đa của thumbnail
          },
        }),
      );

      // Kiểm tra nếu phản hồi yêu cầu xác thực
      if (initialResponse.statusCode == 401) {
        final authHeader = initialResponse.headers['www-authenticate'];
        if (authHeader != null && authHeader.startsWith('Digest ')) {
          _cacheAuthDetails(authHeader);

          // Bước 2: Tạo header xác thực và gửi lại yêu cầu
          final authHeaderWithDigest =
              _generateDigestAuthHeader('POST', url.path);
          final authenticatedResponse = await http.post(
            url,
            headers: {
              'Content-Type': 'application/json; charset=utf-8',
              'Authorization': authHeaderWithDigest,
            },
            body: jsonEncode({
              'name': 'camera.listFiles',
              'parameters': {
                'fileType': 'all', // Lấy tất cả các loại file
                'entryCount': 10000, // Số lượng file tối đa
                'maxThumbSize': 160, // Kích thước tối đa của thumbnail
              },
            }),
          );

          if (authenticatedResponse.statusCode == 200) {
            final jsonResponse = jsonDecode(authenticatedResponse.body);
            final fileList = jsonResponse['results']['entries'] as List;

            setState(() {
              _fileInfoList =
                  fileList.map((json) => FileInfo.fromJson(json)).toList();
            });
          } else {
            throw Exception(
                'Failed to list files with auth: ${authenticatedResponse.statusCode}, body: ${authenticatedResponse.body}');
          }
        } else {
          throw Exception('Failed to get authentication details.');
        }
      } else if (initialResponse.statusCode == 200) {
        // Trường hợp không cần xác thực
        final jsonResponse = jsonDecode(initialResponse.body);
        final fileList = jsonResponse['results']['entries'] as List;

        setState(() {
          _fileInfoList =
              fileList.map((json) => FileInfo.fromJson(json)).toList();
        });
      } else {
        throw Exception(
            'Failed to list files: ${initialResponse.statusCode}, body: ${initialResponse.body}');
      }
    } catch (e) {
      _showAlert('Error listing files: $e');
    }
  }

  void _cacheAuthDetails(String authHeader) {
    final authDetails = _parseAuthDetails(authHeader);
    _cachedNonce = authDetails['nonce'];
    _cachedRealm = authDetails['realm'];
    _cachedQop = authDetails['qop'];
    _cachedUri = authDetails['uri'];
  }

  String _generateDigestAuthHeader(String method, String uri) {
    String username = _username;
    String password = _password;
    final ha1 = md5
        .convert(utf8.encode('$username:$_cachedRealm:$password'))
        .toString();
    final ha2 = md5.convert(utf8.encode('$method:$uri')).toString();
    final response = md5
        .convert(utf8
            .encode('$ha1:$_cachedNonce:00000001:$_cachedUri:$_cachedQop:$ha2'))
        .toString();

    return 'Digest username="$username", realm="$_cachedRealm", nonce="$_cachedNonce", uri="$uri", algorithm="MD5", response="$response", qop=$_cachedQop, nc=00000001, cnonce="$_cachedUri"';
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

  void _showAlert(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('File List')),
      body: _fileInfoList.isEmpty
          ? const Center(
              child: Text(
                'No files available.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            )
          : ListView.builder(
              itemCount: _fileInfoList.length,
              itemBuilder: (context, index) {
                final fileInfo = _fileInfoList[index];
                final isSelected = _selectedFiles.contains(index);

                return ListTile(
                  title: Text(
                    fileInfo.name,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Created: ${fileInfo.dateTimeZone}', // Show creation time
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Duration: ${fileInfo.recordTime.toString()}', // Show duration
                        style: const TextStyle(color: Colors.grey),
                      ),
                      Text(
                        'Size: ${(fileInfo.size != null ? (fileInfo.size! / 1048576).toStringAsFixed(2) : 'Unknown')} MB', // Show size
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  onTap: () async {
                    final fileUrl = fileInfo.fileUrl;
                    try {
                      final tempDir =
                          await getTemporaryDirectory(); // Lấy thư mục tạm
                      final tempFilePath = '${tempDir.path}/${fileInfo.name}';

                      // Tải ảnh về thư mục tạm
                      var client = DigestAuthClient(_username, _password);
                      final response = await client.get(Uri.parse(fileUrl));
                      final tempFile = File(tempFilePath);
                      await tempFile.writeAsBytes(response.bodyBytes);

                      // Chuyển đến màn hình xem ảnh Panorama
                      await Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => fileUrl.endsWith('.MP4')
                            ? VideoScreen(
                                name: fileInfo.name,
                                fileUrl: fileUrl,
                                username: _username,
                                password: _password,
                              )
                            : PanoramaPhotoScreen(imagePath: tempFilePath),
                      ));

                      // Xóa file tạm sau khi quay lại
                      await tempFile.delete();
                      print('Temp file deleted: $tempFilePath');
                    } catch (e) {
                      print('Error opening image: $e');
                    }
                  },
                  leading: fileInfo.thumbnail != null
                      ? Image.memory(
                          fileInfo.thumbnail!,
                          width: 128,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          width: 128,
                          height: 128,
                          color: Colors.grey,
                          child: const Icon(Icons.broken_image),
                        ),
                  trailing: Checkbox(
                    value: isSelected,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _selectedFiles.add(index);
                        } else {
                          _selectedFiles.remove(index);
                        }
                      });
                    },
                  ),
                );
              },
            ),
      floatingActionButton: _selectedFiles.isNotEmpty
          ? FloatingActionButton(
              onPressed: () {
                // Handle download of selected files
                _downloadSelectedFiles();
              },
              child: Icon(Icons.download),
            )
          : null,
    );
  }

  Future<void> _downloadSelectedFiles() async {
    for (int index in _selectedFiles) {
      final fileInfo = _fileInfoList[index];
      final fileUrl = fileInfo.fileUrl;
      final fileName = fileInfo.name;
      var client = DigestAuthClient(_username, _password);
      try {
        final initialResponse = await client.get(Uri.parse(fileUrl));

        if (initialResponse.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final folderPath = '/storage/emulated/0/Pictures/Camera360';
          final filePath = '$folderPath/$fileName';

          // Create the folder if it doesn't exist
          final folder = Directory(folderPath);
          if (!await folder.exists()) {
            await folder.create(recursive: true);
          }

          final file = File(filePath);
          await file.writeAsBytes(initialResponse.bodyBytes);

          // Hiển thị thông báo tải xuống thành công
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('File downloaded: $filePath'),
              ),
            );
          }
        }
      } catch (e) {
        print('Error downloading file: $e');
      }
    }
  }
}
