import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Kullanıcının girdiği verileri yakalayan kontrolcüler
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 50.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo ve Başlık Alanı
              const Center(
                child: Icon(Icons.health_and_safety, size: 100, color: Colors.green),
              ),
              const SizedBox(height: 30),
              const Text(
                "VitaCheck'e\nHoş Geldiniz",
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text(
                "Gıda etiketlerini taramak ve sağlığınızı korumak için giriş yapın.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),

              // Email Input Alanı
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.email_outlined, color: Colors.green),
                  labelText: "E-Posta Adresi",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Şifre Input Alanı
              TextField(
                controller: _passwordController,
                obscureText: true, // Şifreyi noktalı şekilde gizler
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.green),
                  labelText: "Şifre",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.green, width: 2),
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Şifremi Unuttum Metni
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {},
                  child: const Text("Şifremi Unuttum?", style: TextStyle(color: Colors.green)),
                ),
              ),
              const SizedBox(height: 20),

              // Giriş Yap Butonu
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    // API bağlantısını yapacağımız yer burası!
                    print("Giriş yapılıyor... Email: ${_emailController.text}");
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 3,
                  ),
                  child: const Text("Giriş Yap", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 30),

              // Kayıt Ol Yönlendirmesi
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Hesabınız yok mu?", style: TextStyle(color: Colors.grey)),
                  TextButton(
                    onPressed: () {},
                    child: const Text("Kayıt Ol", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}