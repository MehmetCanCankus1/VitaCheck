import 'package:flutter/material.dart';
import 'screens/login_screen.dart'; // Yaptığımız login ekranını çağırdık

void main() {
  runApp(const VitaCheckApp());
}

class VitaCheckApp extends StatelessWidget {
  const VitaCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Sağ üstteki o kırmızı "Debug" bandını kaldırır
      title: 'VitaCheck Mobile App 🚀', // İlk commitimiz için güncellediğimiz başlık
      theme: ThemeData(
        primarySwatch: Colors.green, // Uygulamanın ana tema rengi
      ),
      home: const LoginScreen(), // Uygulamanın açılacağı ilk ekran
    );
  }
} 