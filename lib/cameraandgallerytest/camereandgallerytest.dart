import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class ImagePickerExample extends StatefulWidget {
  @override
  _ImagePickerExampleState createState() => _ImagePickerExampleState();
}

class _ImagePickerExampleState extends State<ImagePickerExample> {
  Uint8List? _imageBytes;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile =
        await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      // Read the file as bytes
      final File file = File(pickedFile.path);
      final Uint8List bytes = await file.readAsBytes();

      setState(() {
        _imageBytes = bytes;
      });

      // Save the image bytes for later use
      await _saveImageWithId(bytes, 'unique_image_id');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Image Picker Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_imageBytes != null)
              Image.memory(
                _imageBytes!,
                height: 200,
              )
            else
              Text('No image selected'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _pickImage,
              child: Text('Pick Image'),
            ),
            ElevatedButton(
              onPressed: () async {
                Uint8List? imageBytes = await _loadImageWithId('image_id');
                if (imageBytes != null) {
                  setState(() {
                    _imageBytes = imageBytes;
                  });
                }
              },
              child: Text('Load Saved Image'),
            ),
          ],
        ),
      ),
    );
  }

  // Save with unique name
  Future<void> _saveImageWithId(Uint8List bytes, String imageId) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/image_$imageId.png';
    final File file = File(path);
    await file.writeAsBytes(bytes);
  }

// Load specific image
  Future<Uint8List?> _loadImageWithId(String imageId) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = '${directory.path}/image_$imageId.png';
    final File file = File(path);

    if (await file.exists()) {
      return file.readAsBytes();
    }
    return null;
  }
}

  // Storage functions below