import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:process_run/shell.dart';

// Method to take a photo using the system camera (Linux)
Future<String?> takePhotoLinux() async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/captured_image.jpg';

  try {
    var shell = Shell();
    await shell.run('cheese --capture-image');  // Opens Cheese (GNOME's camera app)

    return filePath; // Path where the image is saved
  } catch (e) {
    print("Error opening camera: $e");
    return null;
  }
}

// Method to pick an image from the gallery (Linux)
Future<String?> pickImageLinux() async {
  final directory = await getApplicationDocumentsDirectory();
  final filePath = '${directory.path}/selected_image.jpg';

  try {
    var shell = Shell();
    await shell.run('xdg-open ~/Pictures');  // Opens the Pictures folder

    return filePath; // Path where the selected image is saved
  } catch (e) {
    print("Error opening gallery: $e");
    return null;
  }
}

// Widget to display a button for selecting/taking images
class ImageCaptureScreen extends StatefulWidget {
  @override
  _ImageCaptureScreenState createState() => _ImageCaptureScreenState();
}

class _ImageCaptureScreenState extends State<ImageCaptureScreen> {
  String? _imagePath;

  Future<void> _captureImage(bool isCamera) async {
    String? imagePath = isCamera ? await takePhotoLinux() : await pickImageLinux();

    if (imagePath != null) {
      setState(() {
        _imagePath = imagePath;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Capture or Select Image")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imagePath != null)
              Column(
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Image.file(File(_imagePath!), fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _imagePath = null;
                      });
                    },
                    child: const Text("Remove Image"),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _captureImage(true),
              icon: const Icon(Icons.camera_alt),
              label: const Text("Take Photo"),
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: () => _captureImage(false),
              icon: const Icon(Icons.image),
              label: const Text("Pick from Gallery"),
            ),
          ],
        ),
      ),
    );
  }
}
