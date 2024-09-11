import 'message_box.dart';
import 'photo_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:theta_client_flutter/theta_client_flutter.dart';
import 'package:panorama_viewer/panorama_viewer.dart'; // Import Panorama Viewer

class TakePictureScreen extends StatefulWidget {
  final String username;
  final String password;
  const TakePictureScreen({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<StatefulWidget> createState() {
    return _TakePictureScreen();
  }
}

class _TakePictureScreen extends State<TakePictureScreen>
    with WidgetsBindingObserver {
  final _thetaClientFlutter = ThetaClientFlutter();

  Uint8List frameData = Uint8List(0);
  bool previewing = false;
  bool shooting = false;
  bool panoramaMode = false; // Track the current mode
  PhotoCaptureBuilder? builder;
  PhotoCapture? photoCapture;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    initialize();
  }

  @override
  void deactivate() {
    WidgetsBinding.instance.removeObserver(this);
    stopLivePreview();
    super.deactivate();
    debugPrint('close TakePicture');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        onResume();
        break;
      case AppLifecycleState.paused:
        onPause();
        break;
      default:
        break;
    }
  }

  void onResume() {
    debugPrint('onResume');
    _thetaClientFlutter.isInitialized().then((isInit) {
      if (isInit && !panoramaMode) {
        startLivePreview();
      }
    });
  }

  void onPause() {
    debugPrint('onPause');
    stopLivePreview();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Take Picture'),
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
        body: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              color: Colors.black,
              padding: const EdgeInsets.all(8.0), // Optional padding for better appearance
              child: Column(
                children: [
                  Expanded(
                    child: shooting
                        ? const Center(
                      child: Text(
                        'Take Picture...',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                    )
                        : (panoramaMode
                        ? PanoramaViewer(
                      child: Image.memory(
                        frameData,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Center( // Thay thế Expanded bằng Center hoặc Align
                      child: Image.memory(
                        frameData,
                        fit: BoxFit.fill,
                        errorBuilder: (a, b, c) {
                          return Container(
                            color: Colors.black,
                          );
                        },
                        gaplessPlayback: true,
                      ),
                    )),
                  ),
                ],
              ),
            ),
            Align(
              alignment: const Alignment(0, 0.8),
              child: MaterialButton(
                height: 80,
                shape: const CircleBorder(),
                color: Colors.white,
                onPressed: () {
                  if (shooting) {
                    debugPrint('already shooting');
                    return;
                  }
                  takePicture();
                },
                child: const Icon(
                  Icons.camera_alt, // Biểu tượng máy ảnh
                  size: 40, // Kích thước biểu tượng
                  color: Colors.black, // Màu của biểu tượng
                ),
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            setState(() {
              panoramaMode = !panoramaMode;
            });
          },
          child: Icon(panoramaMode
              ? Icons.panorama
              : Icons.panorama_photosphere_rounded),
        ),
      ),
      onPopInvoked: (didPop) async {
        backButtonPress(context);
      },
    );
  }

  Future<bool> backButtonPress(BuildContext context) async {
    debugPrint('backButtonPress');
    stopLivePreview();
    return true;
  }

  void initialize() async {
    debugPrint('init TakePicture');
    // initialize PhotoCapture
    builder = _thetaClientFlutter.getPhotoCaptureBuilder();
    builder!.build().then((value) {
      photoCapture = value;
      debugPrint('Ready PhotoCapture');
      Future.delayed(const Duration(milliseconds: 500), () {}).then((value) {
        // Wait because it can fail.
        if (!panoramaMode) {
          startLivePreview();
        }
      });
    }).onError((error, stackTrace) {
      MessageBox.show(context, 'Error PhotoCaptureBuilder', () {
        backScreen();
      });
    });

    debugPrint('initializing...');
  }

  bool frameHandler(Uint8List frameData) {
    if (!mounted) return false;
    setState(() {
      this.frameData = frameData;
    });
    return previewing;
  }

  void startLivePreview() {
    if (panoramaMode) return;
    previewing = true;
    _thetaClientFlutter.getLivePreview(frameHandler).then((value) {
      debugPrint('LivePreview end.');
    }).onError((error, stackTrace) {
      debugPrint('Error getLivePreview.$error');
      MessageBox.show(context, 'Error getLivePreview', () {
        backScreen();
      });
    });
    debugPrint('LivePreview starting..');
  }

  void stopLivePreview() {
    previewing = false;
  }

  void backScreen() {
    stopLivePreview();
    Navigator.pop(context);
  }

  void takePicture() {
    if (shooting) {
      debugPrint('already shooting');
      return;
    }
    setState(() {
      shooting = true;
    });

    // Stops while shooting is in progress
    stopLivePreview();

    photoCapture!.takePicture((fileUrl) {
      setState(() {
        shooting = false;
      });
      debugPrint('take picture: $fileUrl');
      if (!mounted) return;
      if (fileUrl != null) {
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => PhotoScreen(
                      name: 'Take Picture',
                      fileUrl: fileUrl,
                      username:
                          widget.username, //Authentication with camera username
                      password:
                          widget.password, //Authentication with camera password
                    )))
            .then((value) => startLivePreview());
      } else {
        setState(() {
          shooting = true;
        });
        debugPrint('takePicture canceled.');
      }
    }, (exception) {
      setState(() {
        shooting = false;
      });
      debugPrint(exception.toString());
    }, onCapturing: (status) {
      debugPrint("onCapturing: $status");
    });
  }
}
