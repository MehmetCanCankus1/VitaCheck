import 'package:flutter/material.dart';

class HistoryScreen extends StatelessWidget {
  HistoryScreen({super.key});

  // Şimdilik tasarım için örnek veriler koyuyoruz. 
  // Daha sonra bunları API üzerinden Mehmet Can'dan çekeceğiz.
  final List<Map<String, dynamic>> pastScans = [
    {
      "productName": "Sütlü Çikolatalı Gofret",
      "date": "25 Nisan 2026",
      "isSafe": false,
      "reason": "Günlük Şeker Sınırı Aşıldı",
      "icon": Icons.warning_amber_rounded,
      "color": Colors.orange,
    },
    {
      "productName": "Organik Yulaf Ezmesi",
      "date": "23 Nisan 2026",
      "isSafe": true,
      "reason": "Profilinize Uygun",
      "icon": Icons.check_circle_outline_rounded,
      "color": const Color(0xFF20B2AA), // Temamızın o güzel yeşili
    },
    {
      "productName": "Tam Buğday Ekmeği",
      "date": "21 Nisan 2026",
      "isSafe": false,
      "reason": "Glüten İçerir (Çölyak Riski)",
      "icon": Icons.error_outline_rounded,
      "color": Colors.redAccent,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
            "Geçmiş Analizlerim",
            style: TextStyle(color: Color(0xFF2C3E50), fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: pastScans.length,
        itemBuilder: (context, index) {
          final scan = pastScans[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: CircleAvatar(
                radius: 25,
                backgroundColor: scan["color"].withOpacity(0.15),
                child: Icon(scan["icon"], color: scan["color"], size: 28),
              ),
              title: Text(
                  scan["productName"],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(scan["reason"], style: TextStyle(color: scan["color"], fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(scan["date"], style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            ),
          );
        },
      ),
    );
  }
}