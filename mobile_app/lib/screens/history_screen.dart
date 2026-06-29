import 'package:flutter/material.dart';

import '../services/analysis_service.dart';
import 'result_screen.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<List<AnalysisResult>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = AnalysisService.fetchHistory(limit: 50);
  }

  Map<String, List<AnalysisResult>> _groupedScans(List<AnalysisResult> scans) {
    final Map<String, List<AnalysisResult>> grouped = {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    for (var scan in scans) {
      final scanDate = DateTime(scan.scannedAt.year, scan.scannedAt.month, scan.scannedAt.day);
      final diff = today.difference(scanDate).inDays;
      
      String group;
      if (diff == 0) {
        group = "Bugün";
      } else if (diff <= 7) {
        group = "Bu Hafta";
      } else {
        group = "Daha Önce";
      }
      grouped.putIfAbsent(group, () => []).add(scan);
    }
    return grouped;
  }

  void _deleteScan(AnalysisResult scan) {
    // API deletion endpoint not provided, leaving as visual delete or no-op for now.
    // For this task, we will just show a snackbar. We can't synchronously update FutureBuilder easily without refetch.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Silme işlemi şu anda API destekli değil.'),
        backgroundColor: const Color(0xFF2C7A4B),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
      body: FutureBuilder<List<AnalysisResult>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text("Hata: ${snapshot.error}"));
          }
          
          final pastScans = snapshot.data ?? [];
          if (pastScans.isEmpty) {
            return _buildEmptyState();
          }

          final grouped = _groupedScans(pastScans);
          final groupOrder = ["Bugün", "Bu Hafta", "Daha Önce"];

          return ListView(
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
          );
        },
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

  Widget _buildScanCard(AnalysisResult scan) {
    final isSafe = scan.overallRiskLevel == 'düşük';
    final color = isSafe ? const Color(0xFF2C7A4B) : (scan.overallRiskLevel == 'orta' ? Colors.orange : Colors.red);
    final icon = isSafe ? Icons.check_circle_outline_rounded : (scan.overallRiskLevel == 'orta' ? Icons.warning_amber_rounded : Icons.error_outline_rounded);
    final dateStr = DateFormat('dd.MM.yyyy HH:mm').format(scan.scannedAt);
    final reason = scan.topRiskDisease.isNotEmpty ? scan.topRiskDisease : scan.overallRiskLevel.toUpperCase();
    final productName = scan.category.isNotEmpty ? scan.category : 'Ürün Analizi';

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: scan)));
      },
      child: Dismissible(
        key: Key(scan.scanId.toString()),
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
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color, size: 28),
            ),
            title: Text(
              productName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reason,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dateStr,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
          ),
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
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0),
            child: Text(
              "Henüz bir analiz yapmadınız. İlk ürününüzü taramak için butona tıklayın.",
              style: TextStyle(color: Colors.grey, height: 1.5),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}