import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:io';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  String? _lastCapturedImagePath;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  // Cihazdaki kameraları tespit eden ve başlatan ana fonksiyon
  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // Arka kamerayı (index 0) seçiyoruz
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false, // Mikrofon izniyle uğraşmamak için kapattık
        );

        await _controller!.initialize();

        if (!mounted) return;

        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint("Kamera başlatma hatası: $e");
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _controller == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.teal)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("VitaCheck Analiz"),
        backgroundColor: Colors.teal,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // 1. Canlı Kamera Önizleme
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 2. Kamera Üzerindeki Kılavuz Çerçeve (Profesyonel görünüm için)
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.teal.withOpacity(0.5), width: 2),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),

          // 3. Alt Kontrol Paneli
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 150,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Ürünü çerçevenin içine hizalayın",
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 20),
                  // Deklanşör Butonu
                  FloatingActionButton(
                    backgroundColor: Colors.teal,
                    onPressed: () async {
                      try {
                        final image = await _controller!.takePicture();
                        setState(() {
                          _lastCapturedImagePath = image.path;
                        });

                        // Fotoğraf çekildiğinde kullanıcıya bilgi ver
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Fotoğraf çekildi! Analiz için gönderiliyor..."),
                              backgroundColor: Colors.teal,
                            ),
                          );
                        }

                        // Mehmet Can backend'i hazırladığında burada 'image.path' 
                        // dosyasını backend'e göndereceğiz.
                      } catch (e) {
                        debugPrint("Fotoğraf çekme hatası: $e");
                      }
                    },
                    child: const Icon(Icons.camera_alt, size: 30),
                  ),
                ],
              ),
            ),
          ),

          // 4. Eğer çekildiyse son fotoğrafın küçük önizlemesi (Sol alt köşe)
          if (_lastCapturedImagePath != null)
            Positioned(
              left: 20,
              bottom: 40,
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                  image: DecorationImage(
                    image: FileImage(File(_lastCapturedImagePath!)),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
} 