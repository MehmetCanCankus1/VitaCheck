import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "VitaCheck",
          style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold, fontSize: 24),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              "Merhaba Hicran 👋",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
            ),
            const SizedBox(height: 8),
            const Text(
              "Bugün hangi ürünü analiz etmek istersin?",
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 40),
            ElevatedButton.icon(
              onPressed: () {
                // Kamera ekranı kodunu buraya bağlayacağız
              },
              icon: const Icon(Icons.document_scanner_rounded, size: 32, color: Colors.white),
              label: const Text("Barkod veya İçerik Tara", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF20B2AA),
                padding: const EdgeInsets.symmetric(vertical: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                elevation: 4,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => HistoryScreen()));
              },
              icon: const Icon(Icons.history_rounded, size: 28, color: Color(0xFF20B2AA)),
              label: const Text("Geçmiş Analizlerim", style: TextStyle(fontSize: 18, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 1,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              },
              icon: const Icon(Icons.person_outline_rounded, size: 28, color: Color(0xFF20B2AA)),
              label: const Text("Sağlık Profilim", style: TextStyle(fontSize: 18, color: Color(0xFF2C3E50), fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                elevation: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}