import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() {
  // Uygulama başlamadan önce yapılması gereken bir hazırlık varsa burada yapılır.
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VitaCheckApp());
}

class VitaCheckApp extends StatelessWidget {
  const VitaCheckApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, 
      title: 'VitaCheck Mobile',

      // MÜKEMMEL TEMA YÖNETİMİ: 
      theme: ThemeData(
        useMaterial3: true, // En yeni Android/iOS tasarım dilini kullanır
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          primary: Colors.teal,
          secondary: Colors.tealAccent,
        ),

        // Giriş kutularının (TextField) tasarımı her yerde aynı olsun
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          prefixIconColor: Colors.teal,
        ),

        // Butonların varsayılan tasarımı
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.teal,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            elevation: 2,
          ),
        ),
      ),
      
      home: const LoginScreen(),

      // Sayfa yönlendirmeleri (İleride API'leri için lazım olacak)
      routes: {
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
    );
  }
}