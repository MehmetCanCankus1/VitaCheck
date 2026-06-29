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
    debugPrint("Kamera yüklenirken hata: $e");
  }

  runApp(VitaCheckApp(cameras: cameras));
}

class NoOverscrollBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child; // Animasyon veya gölge/stretch efekti eklemeden direkt döndür
  }

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const ClampingScrollPhysics(); // Bounce (yaylanma) efektini kapat
  }
}

class VitaCheckApp extends StatelessWidget {
  final List<CameraDescription> cameras;
  const VitaCheckApp({super.key, required this.cameras});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VitaCheck',
      scrollBehavior: NoOverscrollBehavior(),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF20B2AA)),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
      routes: {
        '/home':     (context) => const HomeScreen(),
        '/login':    (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}