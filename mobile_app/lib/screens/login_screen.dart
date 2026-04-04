import 'package:flutter/material.dart';
import 'home_screen.dart'; // Yönleneceğimiz sayfayı içe aktarıyoruz

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Üst Logo
              const Icon(Icons.health_and_safety, size: 100, color: Colors.green),
              const SizedBox(height: 20),

              // Karşılama Başlığı
              const Text(
                'VitaCheck\'e Hoş Geldiniz',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 40),

              // E-posta Giriş Alanı
              TextField(
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'E-posta',
                  prefixIcon: const Icon(Icons.email, color: Colors.green),
                ),
              ),
              const SizedBox(height: 16),

              // Şifre Giriş Alanı
              TextField(
                obscureText: true, // Metni gizler (***)
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  labelText: 'Şifre',
                  prefixIcon: const Icon(Icons.lock, color: Colors.green),
                ),
              ),
              const SizedBox(height: 30),

              // Giriş Yap Butonu
              SizedBox(
                width: double.infinity, // Ekran genişliğine yayar
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    // Butona basıldığında Ana Sayfaya (HomeScreen) yönlendirir
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                    );
                  },
                  child: const Text(
                    'Giriş Yap',
                    style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 