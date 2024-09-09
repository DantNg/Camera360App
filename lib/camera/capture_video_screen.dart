import 'video_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:theta_client_flutter/theta_client_flutter.dart';
import 'package:panorama_viewer/panorama_viewer.dart'; // Import Panorama Viewer

import 'message_box.dart';

class CaptureVideoScreen extends StatefulWidget {
  final String username;
  final String password;
  const CaptureVideoScreen({
    super.key,
    required this.username,
    required this.password,
  });

  @override
  State<StatefulWidget> createState() {
    return _CaptureVideoScreen();
  }
}

class _CaptureVideoScreen extends State<CaptureVideoScreen>
    with WidgetsBindingObserver {
  final _thetaClientFlutter = ThetaClientFlutter();

  Uint8List frameData = Uint8List(0);
  bool previewing = false;
  bool shooting = false;
  bool panoramaMode = false; // Thêm trạng thái để theo dõi chế độ panorama
  VideoCaptureBuilder? builder;
  VideoCapture? videoCapture;
  VideoCapturing? videoCapturing;

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
    debugPrint('close CaptureVideo');
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
          title: Text('Capture Video'),
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
              child: Center(
                child: shooting
                    ? const Text(
                        'Capturing...',
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      )
                    : (panoramaMode
                        ? PanoramaViewer(
                            child: Image.memory(
                              frameData,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Image.memory(
                            frameData,
                            errorBuilder: (a, b, c) {
                              return Container(
                                color: Colors.black,
                              );
                            },
                            gaplessPlayback: true,
                          )),
              ),
            ),
            Container(
              alignment: const Alignment(0, 0.8),
              child: MaterialButton(
                height: 80,
                shape: const CircleBorder(),
                color: shooting ? Colors.white : Colors.red,
                onPressed: () {
                  if (shooting) {
                    stopVideoCapture();
                    return;
                  }
                  startVideoCapture();
                },
                child: Icon(
                  shooting ? Icons.stop : Icons.videocam,
                  color: Colors.black,
                  size: 40,
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

  void initialize() {
    debugPrint('init CaptureVideo');
    builder = _thetaClientFlutter.getVideoCaptureBuilder();
    builder!.build().then((value) {
      videoCapture = value;
      debugPrint('Ready VideoCapture');
      Future.delayed(const Duration(milliseconds: 500), () {}).then((value) {
        if (!panoramaMode) {
          startLivePreview();
        }
      });
    }).onError((error, stackTrace) {
      MessageBox.show(context, 'Error VideoCaptureBuilder', () {
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
      debugPrint('Error getLivePreview.');
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

  void startVideoCapture() {
    if (videoCapture == null) {
      return;
    }
    if (shooting) {
      debugPrint('already shooting');
      return;
    }
    setState(() {
      shooting = true;
    });

    stopLivePreview();

    videoCapturing = videoCapture?.startCapture((fileUrl) {
      setState(() {
        shooting = false;
      });
      debugPrint('capture video: $fileUrl');
      if (!mounted) return;

      if (fileUrl != null) {
        final uri = Uri.parse(fileUrl);
        Navigator.of(context)
            .push(MaterialPageRoute(
                builder: (_) => VideoScreen(
                      name: uri.pathSegments.last,
                      fileUrl: fileUrl,
                      username: widget.username,
                      password: widget.password,
                    )))
            .then((value) => startLivePreview());
      }
    }, (exception) {
      setState(() {
        shooting = false;
      });
      startLivePreview();
      debugPrint(exception.toString());
    }, onStopFailed: (exception) {
      debugPrint(exception.toString());
      MessageBox.show(context, 'Error. stopCapture.\n$exception');
    });
  }

  void stopVideoCapture() {
    if (!shooting || videoCapturing == null) {
      debugPrint('Not start capture.');
      return;
    }
    debugPrint("stopVideoCapture");
    videoCapturing!.stopCapture();
  }
}
