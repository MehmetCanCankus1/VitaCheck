import 'package:flutter/material.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final List<Map<String, dynamic>> pastScans = [
    {
      "productName": "Sütlü Çikolatalı Gofret",
      "date": "29 Nisan 2026",
      "group": "Bugün",
      "isSafe": false,
      "reason": "Günlük Şeker Sınırı Aşıldı",
      "icon": Icons.warning_amber_rounded,
      "color": Colors.orange,
    },
    {
      "productName": "Organik Yulaf Ezmesi",
      "date": "27 Nisan 2026",
      "group": "Bu Hafta",
      "isSafe": true,
      "reason": "Profilinize Uygun",
      "icon": Icons.check_circle_outline_rounded,
      "color": Color(0xFF2C7A4B),
    },
    {
      "productName": "Tam Buğday Ekmeği",
      "date": "25 Nisan 2026",
      "group": "Bu Hafta",
      "isSafe": false,
      "reason": "Glüten İçerir (Çölyak Riski)",
      "icon": Icons.error_outline_rounded,
      "color": Colors.redAccent,
    },
    {
      "productName": "Doğal Badem Sütü",
      "date": "20 Nisan 2026",
      "group": "Daha Önce",
      "isSafe": true,
      "reason": "Profilinize Uygun",
      "icon": Icons.check_circle_outline_rounded,
      "color": Color(0xFF2C7A4B),
    },
  ];

  Map<String, List<Map<String, dynamic>>> _groupedScans() {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var scan in pastScans) {
      final group = scan["group"] as String;
      grouped.putIfAbsent(group, () => []).add(scan);
    }
    return grouped;
  }

  void _deleteScan(Map<String, dynamic> scan) {
    setState(() {
      pastScans.remove(scan);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${scan["productName"]} silindi'),
        backgroundColor: const Color(0xFF2C7A4B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Geri Al',
          textColor: Colors.white,
          onPressed: () {
            setState(() {
              pastScans.add(scan);
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedScans();
    final groupOrder = ["Bugün", "Bu Hafta", "Daha Önce"];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Geçmiş Analizlerim",
          style: TextStyle(
            color: Color(0xFF2C3E50),
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF2C3E50)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: pastScans.isEmpty
          ? _buildEmptyState()
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [
          for (final group in groupOrder)
            if (grouped.containsKey(group)) ...[
              _buildGroupHeader(group),
              const SizedBox(height: 8),
              for (final scan in grouped[group]!)
                _buildScanCard(scan),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2C7A4B),
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildScanCard(Map<String, dynamic> scan) {
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteScan(scan),
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 28),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: CircleAvatar(
            radius: 25,
            backgroundColor: (scan["color"] as Color).withOpacity(0.15),
            child: Icon(scan["icon"], color: scan["color"], size: 28),
          ),
          title: Text(
            scan["productName"],
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scan["reason"],
                  style: TextStyle(
                    color: scan["color"],
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  scan["date"],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text(
            "Henüz tarama yapılmadı",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "İlk ürününü taramak için kameraya git",
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}