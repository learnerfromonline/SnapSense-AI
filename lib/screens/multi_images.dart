import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:genai/model/data.dart';
import 'package:genai/screens/navigation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/services.dart'; // for Clipboard
import 'package:photo_view/photo_view.dart';
import 'package:photo_view/photo_view_gallery.dart';
import 'package:shimmer/shimmer.dart';

class MultiImagePromptScreen extends StatefulWidget {
  @override
  State<MultiImagePromptScreen> createState() => _MultiImagePromptScreenState();
}

class _MultiImagePromptScreenState extends State<MultiImagePromptScreen>
    with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  List<Uint8List> _imageBytesList = [];
  List<String> _imageNames = [];
  String _prompt = '';
  String? _responseText;
  bool _loading = false;
  bool _isMultipleImages = false; // Toggle for single/multiple images
  AnimationController? _controller;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _controller!, curve: Curves.easeInOut),
    );
    _controller!.forward();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    if (_isMultipleImages) {
      List<Uint8List> bytesList = List.from(_imageBytesList);
      List<String> namesList = List.from(_imageNames);

      if (source == ImageSource.gallery) {
        final List<XFile> images = await _picker.pickMultiImage();
        if (images.isNotEmpty) {
          for (var image in images) {
            final bytes = await image.readAsBytes();
            bytesList.add(bytes);
            namesList.add(image.name);
          }
        }
      } else {
        // Camera source

        final XFile? image =
            await _picker.pickImage(source: ImageSource.camera);
        if (image != null) {
          final bytes = await image.readAsBytes();
          bytesList.add(bytes);
          namesList.add(image.name);
        }
      }

      if (bytesList.isNotEmpty) {
        setState(() {
          _imageBytesList = bytesList;
          _imageNames = namesList;
          _controller?.reset();
          _controller?.forward();
        });
      }
    } else {
      final XFile? image = await _picker.pickImage(source: source);
      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytesList = [bytes];
          _imageNames = [image.name];
          _controller?.reset();
          _controller?.forward();
        });
      }
    }
  }

  Future<void> _sendToGemini() async {
    if (_imageBytesList.isEmpty || _prompt.isEmpty) return;

    setState(() {
      _loading = true;
    });

    String apiKey = api_key; // Replace with your actual API key
    String model = 'gemini-2.0-flash-lite';
    final Uri uri = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=$apiKey');

    List<Map<String, dynamic>> imageParts = _imageBytesList.map((bytes) {
      final base64Image = base64Encode(bytes);
      return {
        "inline_data": {
          "mime_type": "image/jpeg",
          "data": base64Image,
        }
      };
    }).toList();

    final Map<String, dynamic> requestPayload = {
      "contents": [
        {
          "role": "user",
          "parts": [
            {"text": _prompt},
            ...imageParts,
          ]
        }
      ]
    };

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(requestPayload),
    );

    setState(() {
      _loading = false;
    });

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final text = data['candidates']?[0]?['content']?['parts']?[0]?['text'];
      setState(() {
        _responseText = text ?? 'No response from model.';
        _controller?.reset();
        _controller?.forward();
      });
    } else {
      setState(() {
        _responseText = 'Error: ${response.statusCode}\n${response.body}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0A0E21),
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'SnapSense ',
              style: TextStyle(
                color: Color(0xFF00FFFF),
                fontWeight: FontWeight.bold,
                fontSize: 24,
                fontFamily: 'Orbitron',
                letterSpacing: 2,
              ),
            ),
            Text(
              'AI',
              style: TextStyle(
                color: Color(0xFFFF007A),
                fontWeight: FontWeight.bold,
                fontSize: 24,
                fontFamily: 'Orbitron',
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A3D), Color(0xFF0A0E21)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          AnimatedContainer(
            duration: Duration(seconds: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0E21).withOpacity(0.8),
                  Color(0xFF1A1A3D).withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (_imageBytesList.isNotEmpty &&
                    _fadeAnimation != null &&
                    _slideAnimation != null)
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Container(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _imageBytesList.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: EdgeInsets.only(right: 8),
                              child: Container(
                                width: 200,
                                decoration: BoxDecoration(
                                  border: Border.all(
                                      color: Color(0xFF00FFFF), width: 2),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF00FFFF).withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: InteractiveViewer(
                                    panEnabled: true,
                                    scaleEnabled: true,
                                    minScale: 0.5,
                                    maxScale: 4.0,
                                    child: GestureDetector(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (context) => Dialog(
                                            elevation: 3,
                                            backgroundColor: Colors.black,
                                            insetPadding: EdgeInsets.zero,
                                            child: PhotoViewGallery.builder(
                                              itemCount: _imageBytesList.length,
                                              builder: (context, galleryIndex) {
                                                return PhotoViewGalleryPageOptions(
                                                  imageProvider: MemoryImage(
                                                      _imageBytesList[
                                                          galleryIndex]),
                                                  minScale:
                                                      PhotoViewComputedScale
                                                              .contained *
                                                          0.5,
                                                  maxScale:
                                                      PhotoViewComputedScale
                                                              .covered *
                                                          4.0,
                                                );
                                              },
                                              scrollPhysics:
                                                  BouncingScrollPhysics(),
                                              backgroundDecoration:
                                                  BoxDecoration(
                                                color: const Color.fromARGB(118, 0, 0, 0),
                                              ),
                                              pageController: PageController(
                                                  initialPage: index),
                                            ),
                                          ),
                                        );
                                      },
                                      child: Image.memory(
                                        _imageBytesList[index],
                                        fit: BoxFit.fill,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 24),
                if (_fadeAnimation != null && _slideAnimation != null)
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.indigo,
                              Color(0xFF1A1A3D),
                              Color(0xFF2A2A5D),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _imageBytesList.isNotEmpty
                            ? TextField(
                                autocorrect: true,
                                style: TextStyle(color: Colors.white),
                                decoration: InputDecoration(
                                  labelText:
                                      'Ask Me About Image${_isMultipleImages ? "s" : ""}',
                                  labelStyle: TextStyle(
                                    color: Color(0xFF00FFFF),
                                    fontFamily: 'Orbitron',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  contentPadding: EdgeInsets.all(16),
                                  filled: true,
                                  fillColor: Colors.transparent,
                                ),
                                onChanged: (val) => _prompt = val,
                              )
                            : SizedBox(),
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                if (_fadeAnimation != null && _slideAnimation != null)
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _isMultipleImages,
                            onChanged: (value) {
                              setState(() {
                                _isMultipleImages = value ?? false;
                                _imageBytesList = [];
                                _imageNames = [];
                              });
                            },
                            activeColor: Color(0xFF00FFFF),
                            checkColor: Colors.black,
                            side: BorderSide(
                              color: Color(0xFFFF007A),
                              width: 2,
                            ),
                          ),
                          // Spacer(),
                          Container(
                            margin: EdgeInsets.only(right: 10, left: 12),
                            child: Text(
                              'Enable Multiple Images',
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 16),
                if (_fadeAnimation != null && _slideAnimation != null)
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildCyberButton(
                            icon: Icons.photo,
                            label: _isMultipleImages ? 'Multi Pick' : 'Gallery',
                            onPressed: () => _pickImage(ImageSource.gallery),
                            color: Color(0xFF00FFFF),
                          ),
                          _buildCyberButton(
                            icon: Icons.camera_alt,
                            label: 'Camera',
                            onPressed: () => _pickImage(ImageSource.camera),
                            color: Color(0xFFFF007A),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 24),
                if (_fadeAnimation != null && _slideAnimation != null)
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Center(
                        child: _buildCyberButton(
                          icon: Icons.arrow_forward_ios,
                          label: 'Tell Me',
                          onPressed: _sendToGemini,
                          color: Color(0xFF00FF88),
                          isLarge: true,
                        ),
                      ),
                    ),
                  ),
                if (_loading &&
                    _fadeAnimation != null &&
                    _slideAnimation != null)
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Container(
                        margin: EdgeInsets.only(top: 24),
                        child: Shimmer.fromColors(
                          baseColor: Color(0xFF1A1A3D),
                          highlightColor: Color(0xFF00FFFF).withOpacity(0.3),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 20,
                                width: 100,
                                decoration: BoxDecoration(
                                  color: Color(0xFF2A2A5D),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              SizedBox(height: 16),
                              Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: Color(0xFF2A2A5D),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: Color(0xFF00FFFF), width: 1),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  )
                else if (_responseText != null &&
                    _fadeAnimation != null &&
                    _slideAnimation != null)
                  FadeTransition(
                    opacity: _fadeAnimation!,
                    child: SlideTransition(
                      position: _slideAnimation!,
                      child: Container(
                        margin: EdgeInsets.only(top: 24),
                        padding: EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFF1A1A3D), Color(0xFF2A2A5D)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border:
                              Border.all(color: Color(0xFF00FFFF), width: 1),
                          boxShadow: [
                            BoxShadow(
                              color: Color(0xFF00FFFF).withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  "Response:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF00FFFF),
                                    fontFamily: 'Orbitron',
                                  ),
                                ),
                                Spacer(),
                                IconButton(
                                  icon: Icon(Icons.copy,
                                      color: Color(0xFFFF007A)),
                                  tooltip: 'Copy Response',
                                  onPressed: () {
                                    Clipboard.setData(
                                        ClipboardData(text: _responseText!));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Response copied to clipboard",
                                          style: TextStyle(
                                              color: Color(0xFF00FFFF)),
                                        ),
                                        backgroundColor: Color(0xFF1A1A3D),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            SizedBox(height: 8),
                            SelectableText(
                              _responseText!,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                                fontFamily: 'Orbitron',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCyberButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isLarge = false,
  }) {
    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.7), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.5),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: isLarge ? 24 : 16,
              vertical: isLarge ? 16 : 12,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.black, size: isLarge ? 28 : 24),
                SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.black,
                    fontFamily: 'Orbitron',
                    fontWeight: FontWeight.bold,
                    fontSize: isLarge ? 18 : 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
