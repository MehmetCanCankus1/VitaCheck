import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("VitaCheck", style: TextStyle(color: Color(0xFF20B2AA), fontWeight: FontWeight.w900)),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/profile'),
            child: const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: CircleAvatar(backgroundColor: Color(0xFFD4F0F0), child: Icon(Icons.person_outline_rounded, color: Color(0xFF20B2AA))),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Hoş geldin, Hicran! 🌿", style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: Color(0xFF2C3E50))),
            const SizedBox(height: 30),
            Container(
              width: double.infinity, padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(color: const Color(0xFF20B2AA), borderRadius: BorderRadius.circular(30)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Sağlık Durumun", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  const SizedBox(height: 10),
                  const Text("Harika gidiyorsun! 🌟", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 25),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatItem("Şeker", "Güvenli", Icons.check_circle_outline),
                      _buildStatItem("Glüten", "Yok", Icons.eco_outlined),
                      _buildStatItem("Analiz", "3 Ürün", Icons.document_scanner_outlined),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 35),
            const Text("Hızlı İşlemler", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Row(
              children: [
                _buildActionCard(context, "Barkod\nTara", Icons.qr_code_scanner_rounded, const Color(0xFFFFE0B2), const Color(0xFFF57C00)),
                const SizedBox(width: 15),
                _buildActionCard(context, "Fotoğraf\nAnalizi", Icons.camera_alt_rounded, const Color(0xFFC8E6C9), const Color(0xFF388E3C), isCamera: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(children: [Icon(icon, color: Colors.white), const SizedBox(height: 8), Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12))]);
  }

  Widget _buildActionCard(BuildContext context, String title, IconData icon, Color bgColor, Color iconColor, {bool isCamera = false}) {
    return Expanded(
      child: GestureDetector(
        onTap: () { if (isCamera) Navigator.pushNamed(context, '/camera'); },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
          child: Column(children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle), child: Icon(icon, color: iconColor, size: 32)), const SizedBox(height: 16), Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }
}