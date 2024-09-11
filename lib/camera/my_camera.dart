import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:theta_client_flutter/theta_client_flutter.dart';
import 'package:theta_client_flutter/digest_auth.dart';
import '/camera/capture_video_screen.dart';
import '/camera/file_list_screen.dart';
import '/camera/message_box.dart';
import '/camera/take_picture_screen.dart';
import '/theme/constants.dart'; // Import your custom theme

class MyCamera extends StatefulWidget {
  const MyCamera({super.key});

  @override
  State<MyCamera> createState() => _MyCameraState();
}

class _MyCameraState extends State<MyCamera> with WidgetsBindingObserver {
  String _platformVersion = 'Unknown';
  final _thetaClientFlutter = ThetaClientFlutter();
  bool _isInitTheta = false;
  bool _initializing = false;
  ThetaModel? _thetaModel;

  String _endpoint = '';
  String _username = '';
  String _password = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initPlatformState();
    loadCameraSettings(); // Load stored camera settings
    initTheta();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
        setState(() {
          _isInitTheta = false;
        });
        break;
      default:
        break;
    }
  }

  Future<void> initPlatformState() async {
    String platformVersion;
    try {
      platformVersion = await _thetaClientFlutter.getPlatformVersion() ??
          'Unknown platform version';
    } on PlatformException {
      platformVersion = 'Failed to get platform version.';
    }

    if (!mounted) return;

    setState(() {
      _platformVersion = platformVersion;
    });
  }

  Future<void> loadCameraSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _endpoint = prefs.getString('camera_endpoint') ?? '';
      _username = prefs.getString('camera_username') ?? '';
      _password = prefs.getString('camera_password') ?? '';
    });
  }

  Future<void> saveCameraSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('camera_endpoint', _endpoint);
    await prefs.setString('camera_username', _username);
    await prefs.setString('camera_password', _password);
  }

  Future<void> initTheta() async {
    if (_initializing) {
      return;
    }
    bool isInitTheta;
    ThetaModel? thetaModel;
    try {
      _initializing = true;
      isInitTheta = await _thetaClientFlutter.isInitialized();
      debugPrint('start initialize');

      // Thêm https:// nếu người dùng chưa nhập
      if (!_endpoint.startsWith('http://') &&
          !_endpoint.startsWith('http://')) {
        _endpoint = 'http://$_endpoint';
      }

      // Kiểm tra và thêm cổng nếu không có
      if (!_endpoint.contains(':')) {
        _endpoint += ':80';
      }

      final config = ThetaConfig();
      config.clientMode = DigestAuth(_username, _password);
      await _thetaClientFlutter.initialize(_endpoint, config);
      thetaModel = await _thetaClientFlutter.getThetaModel();
      isInitTheta = true;
    } on PlatformException {
      if (!mounted) return;
      debugPrint('Error. init');
      isInitTheta = false;
      MessageBox.show(context, 'Initialize error.');
    } finally {
      _initializing = false;
    }

    if (!mounted) return;

    setState(() {
      _isInitTheta = isInitTheta;
      _thetaModel = thetaModel;
    });
  }

  void showConnectDialog(BuildContext context) {
    TextEditingController endpointController =
        TextEditingController(text: _endpoint);
    TextEditingController usernameController =
        TextEditingController(text: _username);
    TextEditingController passwordController =
        TextEditingController(text: _password);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Connect to Camera'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: endpointController,
                decoration: const InputDecoration(labelText: 'Camera IP/Endpoint'),
                keyboardType:
                    TextInputType.url, // Đảm bảo người dùng nhập đúng định dạng
              ),
              const SizedBox(height: 20),
              TextField(
                controller: usernameController,
                decoration: const InputDecoration(labelText: 'Username'),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.blue, // Change this to your desired text color
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _endpoint = endpointController.text;
                  _username = usernameController.text;
                  _password = passwordController.text;
                });
                saveCameraSettings();
                Navigator.of(context).pop();
                initTheta();
              },
              child: const Text(
                'Connect',
                style: TextStyle(
                  color: Colors.blue, // Change this to your desired text color
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Ricoh Theta Z1',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.black,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            backgroundColor: Colors.white,
            textStyle: const TextStyle(fontSize: 18),
          ),
        ),
      ),
      home: Home(
        platformVersion: _platformVersion,
        isInitialized: _isInitTheta,
        connectTheta: () => showConnectDialog(context),
        thetaModel: _thetaModel,
        endpoint: _endpoint,
        username: _username,
        password: _password,
      ),
    );
  }
}

class Home extends StatelessWidget {
  final String platformVersion;
  final bool isInitialized;
  final Function connectTheta;
  final ThetaModel? thetaModel;
  final String endpoint;
  final String username;
  final String password;

  const Home({
    super.key,
    required this.platformVersion,
    required this.isInitialized,
    required this.connectTheta,
    required this.thetaModel,
    required this.endpoint,
    required this.username,
    required this.password,

  });

  @override
  Widget build(BuildContext context) {
    String cameraStatus =
        isInitialized ? 'Camera Connected: $thetaModel' : 'Camera Disconnected';

    final double buttonSize = MediaQuery.of(context).size.width * 0.7;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ricoh Theta Z1'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: appGradient,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: const AssetImage(
                "assets/background_theta_z1.jpg"), // Đường dẫn đến ảnh nền
            fit: BoxFit.cover, // Căn chỉnh ảnh nền
            colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.6),
                BlendMode.darken), // Tạo lớp phủ màu đen
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Platform Version: $platformVersion',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                cameraStatus,
                style: TextStyle(
                  color: isInitialized ? Colors.greenAccent : Colors.redAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: isInitialized ? null : () => connectTheta(),
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      Size(buttonSize, 60), // Đặt kích thước nút đều nhau
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
                child: const Text(
                  'Connect',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: !isInitialized
                    ? null
                    : () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => TakePictureScreen(
                              username: username,
                              password: password,
                            )));
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      Size(buttonSize, 60), // Đặt kích thước nút đều nhau
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
                child: const Text(
                  'Take Picture',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: !isInitialized
                    ? null
                    : () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => CaptureVideoScreen(
                              username: username,
                              password: password,
                            )));
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      Size(buttonSize, 60), // Đặt kích thước nút đều nhau
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
                child: const Text(
                  'Capture Video',
                  style: TextStyle(color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: !isInitialized
                    ? null
                    : () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => FileListScreen(
                              endpoint: endpoint,
                              username: username,
                              password: password,
                            )));
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize:
                      Size(buttonSize, 60), // Đặt kích thước nút đều nhau
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  backgroundColor: Colors.white.withOpacity(0.1),
                ),
                child: const Text(
                  'File List',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
