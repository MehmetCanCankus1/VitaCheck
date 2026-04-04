import 'package:flutter/material.dart';
import 'home_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          // Arka plana hafif bir gradyan verelim
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            colors: [Colors.teal, Colors.tealAccent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            const SizedBox(height: 80),
            const Icon(Icons.health_and_safety, size: 80, color: Colors.white),
            const Text("VitaCheck", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("Sağlıklı Günler Dileriz", style: TextStyle(color: Colors.white, fontSize: 18)),
            const SizedBox(height: 50),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(60), topRight: Radius.circular(60)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: Column(
                    children: <Widget>[
                      const SizedBox(height: 40),
                      // E-posta Kutusu
                      TextField(
                        decoration: InputDecoration(
                          hintText: "E-posta",
                          prefixIcon: const Icon(Icons.email, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Şifre Kutusu
                      TextField(
                        obscureText: true,
                        decoration: InputDecoration(
                          hintText: "Şifre",
                          prefixIcon: const Icon(Icons.lock, color: Colors.teal),
                        ),
                      ),
                      const SizedBox(height: 40),
                      // Giriş Yap Butonu
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () {
                            // Şimdilik doğrudan ana sayfaya atsın
                            Navigator.push(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                          },
                          child: const Text("Giriş Yap", style: TextStyle(fontSize: 18)),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextButton(
                        onPressed: () {},
                        child: const Text("Hesabınız yok mu? Kayıt Olun", style: TextStyle(color: Colors.teal)),
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}