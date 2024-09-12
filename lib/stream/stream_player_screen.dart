import 'package:flutter/material.dart';
import 'normal_stream_viewer.dart';
import 'panorama_stream_viewer.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/constants.dart';
import 'camera_stream_service.dart';
import 'stream_setting.dart';

class StreamPlayer extends StatefulWidget {
  const StreamPlayer({super.key});

  @override
  _StreamPlayerState createState() => _StreamPlayerState();
}

class _StreamPlayerState extends State<StreamPlayer> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _ipController =
      TextEditingController(); // Controller cho IP của camera
  bool _didShowDialog = false; // Để đảm bảo popup chỉ được hiển thị một lần
  String _streamServerIP = "";
  bool _isStreaming = false; // Kiểm soát trạng thái stream (start/stop)

  @override
  void initState() {
    super.initState();
    _loadServerIp();
    _loadCameraIp();

  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didShowDialog) {
      _didShowDialog = true;
      _showUrlInputDialog(); // Hiển thị popup nhập URL của server stream khi ứng dụng khởi động
    }
  }

// Hàm lưu IP của Server Stream vào shared_preferences
  Future<void> _saveServerIp(String ip) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_ip', ip);
  }

// Hàm tải IP của Server Stream từ shared_preferences
  Future<void> _loadServerIp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString('server_ip');
    if (savedIp != null && savedIp.isNotEmpty) {
      setState(() {
        _urlController.text = savedIp; // Điền sẵn IP vào trường nhập
        _streamServerIP = savedIp; // Gán giá trị đã lưu vào biến
      });
    }
  }

// Hàm lưu IP của Camera vào shared_preferences
  Future<void> _saveCameraIp(String ip) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('camera_ip', ip);
  }

// Hàm tải IP của Camera từ shared_preferences
  Future<void> _loadCameraIp() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedIp = prefs.getString('camera_ip');
    if (savedIp != null && savedIp.isNotEmpty) {
      setState(() {
        _ipController.text = savedIp; // Điền sẵn IP vào trường nhập
      });
    }
  }

// Hiển thị dialog nhập URL của server stream
  void _showUrlInputDialog() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showDialog(
        context: context,
        barrierDismissible: false, // Không cho đóng popup khi bấm ngoài
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Enter Stream Server IP'),
            content: TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'Enter Server URL (e.g. http://192.168.0.110:8080)',
              ),
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  if (_urlController.text.isNotEmpty) {
                    // Ghi nhớ URL vào shared_preferences
                    _saveServerIp(_urlController.text);

                    // Gán URL đầy đủ vào nơi cần dùng
                    setState(() {
                      _streamServerIP = _urlController.text;
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

// Hiển thị dialog nhập IP của camera
  void _showIpInputDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter Camera IP Address'),
          content: TextField(
            controller: _ipController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Enter IP (e.g. 192.168.0.110)',
            ),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                if (_ipController.text.isNotEmpty) {
                  // Lưu IP của Camera vào shared_preferences
                  _saveCameraIp(_ipController.text);
                  Navigator.of(context).pop(); // Đóng popup
                  _StartStreamMode(); // Bắt đầu stream sau khi nhập IP
                }
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
  // Bắt đầu hoặc dừng stream
  Future<void> _StartStreamMode() async {
    if (!_isStreaming) {
      // Khởi tạo service với IP của camera
      final streamService = CameraStreamService(
        ipAddress: _ipController.text,
        username: 'THETAYN30104243',
        password: '30104243',
      );

      // Thiết lập chế độ stream
      bool setupSuccess = await streamService.setupStream();
      if (setupSuccess) {}
    } else {}
  }

  Future<void> _StartStream() async {
    print(_ipController.text);
    if(_ipController.text.isEmpty){
      _showIpInputDialog();
    }
    // Khởi tạo service với IP của camera
    final streamService = CameraStreamService(
      ipAddress: _ipController.text,
      username: 'THETAYN30104243',
      password: '30104243',
    );

    // Nếu thiết lập thành công, bắt đầu stream
    bool startStreamSucces = await streamService.startStopStream(true);
    if (startStreamSucces) {
      setState(() {
        _isStreaming = true;
      });
    } else {
      setState(() {
        _isStreaming = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Đặt màu nền thành màu trắng
      appBar: AppBar(
        title: const Text(
          'Ricoh Theta Z1 Streaming',
          style: TextStyle(
            color: Colors.black, // Đổi màu chữ của AppBar
          ),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: appGradient,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0), // Khoảng cách từ các cạnh
        child: GridView.count(
          crossAxisCount: 2, // Chia làm 2 cột, tổng cộng 4 ô vuông
          crossAxisSpacing: 16, // Khoảng cách giữa các cột
          mainAxisSpacing: 16, // Khoảng cách giữa các hàng
          children: [
            // Ô 1: Turn On Stream Mode
            _buildGridButton(
              icon: Icons.wifi_tethering,
              label: 'Turn On Stream Mode',
              color: Colors.blueAccent,
              onPressed: _showIpInputDialog,
            ),
            // Ô 2: Start/Stop Stream
            _buildGridButton(
              icon: _isStreaming ? Icons.stop_circle : Icons.play_circle,
              label: _isStreaming ? 'Stop Stream' : 'Start Stream',
              color: _isStreaming ? Colors.redAccent : Colors.green,
              onPressed: _StartStream,
            ),
            // Ô 3: Watch Normal Stream
            _buildGridButton(
              icon: Icons.tv,
              label: 'Watch Normal Stream',
              color: Colors.orangeAccent,
              onPressed: () {
                if (_urlController.text.isNotEmpty) {
                  var _url = 'http://'+_streamServerIP+':8080/hls/theta_stream.m3u8';
                  print(_url);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => NormalStreamViewer(
                        streamUrl: _url,
                      ),
                    ),
                  );
                } else {
                  _showUrlInputDialog(); // Nhắc người dùng nhập URL nếu chưa có
                }
              },
            ),
            // Ô 4: Watch Panorama Stream
            _buildGridButton(
              icon: Icons.panorama_photosphere,
              label: 'Watch Panorama Stream',
              color: Colors.purpleAccent,
              onPressed: () {
                if (_urlController.text.isNotEmpty) {
                  var _url = 'http://'+_streamServerIP+':8080/hls/theta_stream.m3u8';
                  print(_url);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => PanoramaStreamViewer(
                        streamUrl: _url,
                      ),
                    ),
                  );
                } else {
                  _showUrlInputDialog(); // Nhắc người dùng nhập URL nếu chưa có
                }
              },
            ),
          ],
        ),
      ),
    );
  }

// Hàm xây dựng các ô vuông chứa nút với icon và text
  Widget _buildGridButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20), // Làm bo tròn các góc
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3), // Màu bóng đổ
            blurRadius: 10,
            offset: const Offset(0, 5), // Bóng đổ theo chiều dọc
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20), // Bo tròn nút
          ),
          padding: const EdgeInsets.all(16), // Khoảng cách padding cho nút
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 40, // Kích thước icon lớn
              color: Colors.white, // Đổi màu icon thành màu trắng
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white, // Đổi màu chữ thành màu trắng
              ),
            ),
          ],
        ),
      ),
    );
  }


}
