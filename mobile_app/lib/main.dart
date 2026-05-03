import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'screens/result_screen.dart';
import 'screens/register_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  List<CameraDescription> cameras = [];
  try {
    cameras = await availableCameras();
  } catch (e) {
    debugPrint("Kamera yüklenirken hata: $e");
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
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/result': (context) => const ResultScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}