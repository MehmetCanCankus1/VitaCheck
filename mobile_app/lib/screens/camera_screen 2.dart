import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool _isCapturing = false;

  static const Color _primaryGreen = Color(0xFF2C7A4B);
  static const Color _lightGreen = Color(0xFF4CAF50);

  Future<void> _takePicture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image != null && mounted) {
        Navigator.pushNamed(context, '/result', arguments: image.path);
      }
    } catch (e) {
      debugPrint('Fotoğraf çekilemedi: $e');
    } finally {
      if (mounted) setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null && mounted) {
      Navigator.pushNamed(context, '/result', arguments: image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              ),
            ),
          ),

          // Üst bar
          Positioned(
            top: 50, left: 16, right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'Etiketi Tara',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Orta alan - çerçeve
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(color: _lightGreen, width: 2.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Icon(Icons.camera_alt_outlined,
                        color: Colors.white30, size: 60),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gıda etiketini fotoğrafla veya galeriden seç',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Alt kontroller
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Galeri butonu
                  GestureDetector(
                    onTap: _pickFromGallery,
                    child: Container(
                      width: 56, height: 56,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Icon(Icons.photo_library_outlined,
                          color: Colors.white, size: 28),
                    ),
                  ),

                  // Kamera butonu
                  GestureDetector(
                    onTap: _takePicture,
                    child: Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _isCapturing ? Colors.grey : _primaryGreen,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: _lightGreen.withOpacity(0.5),
                            blurRadius: 16,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: _isCapturing
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Icon(Icons.camera_alt,
                          color: Colors.white, size: 34),
                    ),
                  ),

                  const SizedBox(width: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}