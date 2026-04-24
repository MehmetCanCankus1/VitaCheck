import 'package:flutter/material.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Bu verileri ileride Mehmet Can'ın veritabanına (SQL Server) göndereceğiz
  Map<String, bool> healthSettings = {
    "Gluten Alerjisi": false,
    "Laktoz Hassasiyeti": true,
    "Diyabet (Şeker Kontrolü)": false,
    "Vegan Beslenme": false,
    "Yüksek Tansiyon (Tuz Kontrolü)": false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text("Profil ve Sağlık", style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Color(0xFFD4F0F0),
              child: Icon(Icons.person_rounded, size: 50, color: Color(0xFF20B2AA)),
            ),
            const SizedBox(height: 15),
            const Text("Hicran K.", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Software Engineering Student", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 40),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Hassasiyetlerinizi Seçin", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 15),

            // Dinamik Alerji Listesi
            ...healthSettings.keys.map((String key) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10)],
                ),
                child: CheckboxListTile(
                  title: Text(key, style: const TextStyle(fontWeight: FontWeight.w600)),
                  value: healthSettings[key],
                  activeColor: const Color(0xFF20B2AA),
                  onChanged: (bool? value) {
                    setState(() => healthSettings[key] = value!);
                  },
                ),
              );
            }).toList(),

            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Sağlık profilin güncellendi! 🌿"), backgroundColor: Color(0xFF20B2AA)),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF20B2AA),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
                child: const Text("Ayarları Kaydet", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}