import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Hafif gri, temiz bir arka plan
      appBar: AppBar(
        title: const Text("VitaCheck Panel", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.person_outline)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Merhaba Hicran! 👋",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal),
            ),
            const Text("Bugün kendini nasıl hissediyorsun?", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 25),

            // Gösterge Kartları (Sağlık Uygulaması Havası Verir)
            Row(
              children: [
                _buildStatCard("Nabız", "72 bpm", Icons.favorite, Colors.redAccent),
                const SizedBox(width: 15),
                _buildStatCard("Adım", "4.520", Icons.directions_walk, Colors.orange),
              ],
            ),
            const SizedBox(height: 25),

            // ANA GÖREV: Kamera Modülü Kartı
            const Text("İşlemler", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),

            GestureDetector(
              onTap: () {
                // Birazdan buraya Kamera sayfasını bağlayacağız!
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Kamera Modülü Hazırlanıyor...")),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.teal.withOpacity(0.1), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt, color: Colors.teal, size: 30),
                    ),
                    const SizedBox(width: 20),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Kamerayı Başlat", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text("Analiz için fotoğraf çekin", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Küçük Bilgi Kartları İçin Yardımcı Widget
  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.grey, fontSize: 14)),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}