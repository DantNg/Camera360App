import 'package:flutter/material.dart';
import 'package:panorama_viewer/panorama_viewer.dart';
import 'dart:io';

class PanoramaPhotoScreen extends StatelessWidget {
  final String imagePath;

  const PanoramaPhotoScreen({super.key, required this.imagePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panorama Viewer'),
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
      body: OrientationBuilder(
        builder: (context, orientation) {
          return Stack(
            children: [
              PanoramaViewer(
                animSpeed: 1.0,
                child: Image.file(File(imagePath)),
              ),
              Positioned(
                bottom: 20,
                left: 20,
                child: FloatingActionButton(
                  onPressed: () {
                    // Add your functionality here
                  },
                  backgroundColor: Colors.blueAccent,
                  child: const Icon(Icons.fullscreen),
                ),
              ),
              if (orientation == Orientation.portrait)
                const Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'Use two fingers to rotate',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            blurRadius: 10.0,
                            color: Colors.black,
                            offset: Offset(2.0, 2.0),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
