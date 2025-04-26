import 'dart:typed_data';
import 'package:firebase_vertexai/firebase_vertexai.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
// import 'package:image_gallery_saver/image_gallery_saver.dart';

class ImagePickerScreen extends StatefulWidget {
  const ImagePickerScreen({super.key});

  @override
  State<ImagePickerScreen> createState() => _ImagePickerScreenState();
}

class _ImagePickerScreenState extends State<ImagePickerScreen> {
  
  Uint8List? _imageBytes;

  Future<void> pickImage(ImageSource source) async {
    // Request permissions first
    await _requestPermissions();

    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);
    

    if (image != null) {
      Uint8List bytes = await image.readAsBytes();
      setState(() {
        _imageBytes = bytes;
      });

    
    }
    // if(source == ImageSource.camera && await Permission.mediaLibrary.request().isGranted){
    //   ImageGallerySaver.saveImage(
    //     _imageBytes!,
    //     quality: 100,name: image!.name,
    //   );
    // }
    print("hai hello $_imageBytes");
    
  }
  late final GenerativeModel model;

  @override
  void initState() {
    super.initState();
    final apiKey = dotenv.env['GEMINI_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GEMINI_API_KEY is not set in .env file');
    }
    // Use the named constructor
    // _model = GenerativeModel(apiKey: apiKey, modelName: _modelName);
  }
   late GenerativeModel _model;
  // Remove _visionModel
  String _outputText = 'No response yet.';
  final TextEditingController _promptController = TextEditingController();
  bool _isLoading = false;
  final String _modelName = 'gemini-2.0-flash-lite'; 

  Future<void> _requestPermissions() async {
    final cameraPermission = await Permission.camera.request();
    final storagePermission = await Permission.photos.request();

    if (!cameraPermission.isGranted || !storagePermission.isGranted) {
      // Handle the case where permissions are denied
      print('Permissions not granted');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Pick or Capture Image')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _imageBytes != null
              ? Image.memory(_imageBytes!, height: 250)
              : const Text('No image selected'),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton.icon(
                onPressed: () => pickImage(ImageSource.camera),
                icon: Icon(Icons.camera),
                label: Text("Camera"),
              ),
              ElevatedButton.icon(
                onPressed: () => pickImage(ImageSource.gallery),
                icon: Icon(Icons.photo_library),
                label: Text("Gallery"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Metadata{
  Uint8List? _imageBytes;
  String name = "";
  String description = "";
  List<String> Suggestions = [];
}
