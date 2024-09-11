import 'package:flutter/material.dart';
import '../panorama/panorama_photo_screen.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/constants.dart';
class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  _LibraryScreenState createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PanoramaPhotoScreen(imagePath: pickedFile.path),
        ),
      );
    } else {
      // Handle the case where no image was selected
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image selected')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Image'),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: appGradient,
          ),
        ),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: _pickImage,
          child: const Text('Pick an Image from Library'),
        ),
      ),
    );
  }
}