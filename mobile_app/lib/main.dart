import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    print("Kamera yüklenirken hata oluştu: $e");
  }

  runApp(VitaCheckApp(cameras: cameras));
}

class VitaCheckApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const VitaCheckApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitaCheck',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF20B2AA)),
        useMaterial3: true,
      ),
      // Uygulama artık direkt Kayıt Ol ekranıyla başlayacak patron.
      home: const RegisterScreen(), 
    );
  }
}