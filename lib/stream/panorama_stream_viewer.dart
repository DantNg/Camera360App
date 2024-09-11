import 'package:flutter/material.dart';
import 'package:video_360/video_360.dart';
import '../theme/constants.dart';

class PanoramaStreamViewer extends StatefulWidget {
  final String streamUrl;
  const PanoramaStreamViewer({super.key, required this.streamUrl});

  @override
  _PanoramaStreamViewerState createState() => _PanoramaStreamViewerState();
}

class _PanoramaStreamViewerState extends State<PanoramaStreamViewer> {
  Video360Controller? controller;

  String durationText = '';
  String totalText = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width;
    var height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panorama Viewer'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: appGradient,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Video 360 Viewer
          Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Video360View(
                onVideo360ViewCreated: _onVideo360ViewCreated,
                url: widget.streamUrl,
                onPlayInfo: (Video360PlayInfo info) {
                  setState(() {
                    durationText = _formatDuration(info.duration);
                    totalText = _formatDuration(info.total);
                  });
                },
              ),
            ),
          ),
          // Control Panel
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              children: [
                // Control buttons for Play, Stop, Reset, Jump
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(Icons.play_arrow, "Play", () {
                      controller?.play();
                    }),
                    _buildControlButton(Icons.stop, "Stop", () {
                      controller?.stop();
                    }),
                    _buildControlButton(Icons.refresh, "Reset", () {
                      controller?.reset();
                    }),
                  ],
                ),
                const SizedBox(height: 10),
                // Seek Buttons and Duration
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildControlButton(Icons.fast_rewind, "Rewind", () {
                      controller?.seekTo(-2000);
                    }),
                    _buildControlButton(Icons.fast_forward, "Forward", () {
                      controller?.seekTo(2000);
                    }),
                    _buildDurationDisplay(durationText, totalText),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Method to format the duration
  String _formatDuration(int milliseconds) {
    int seconds = (milliseconds / 1000).floor();
    int minutes = (seconds / 60).floor();
    seconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // Widget to build a control button
  Widget _buildControlButton(
      IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        label,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      ),
      onPressed: onPressed,
    );
  }

  // Widget to display the current duration and total duration
  Widget _buildDurationDisplay(String current, String total) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 5,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Text(
        '$current / $total',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  _onVideo360ViewCreated(Video360Controller? controller) {
    this.controller = controller;
    this.controller?.play();
  }
}
