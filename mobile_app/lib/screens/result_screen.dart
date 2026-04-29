import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  const ResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: CustomScrollView(
        slivers: [
          // 1. Üst Alan: Ürün Resmi ve Başlık
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF20B2AA), Color(0xFF00695C)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.fastfood_rounded, size: 80, color: Colors.white),
                      const SizedBox(height: 10),
                      const Text(
                        "Yulaf Ezmesi - Gold Seri",
                        style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. Sağlık Skoru (Büyük ve Gösterişli)
                  _buildHealthScoreCard(),
                  const SizedBox(height: 25),

                  // 3. Makro Besin Tablosu (Grafiksel Görünüm)
                  const Text("Besin Değerleri Dağılımı", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildMacroDistribution(),
                  const SizedBox(height: 25),

                  // 4. Katkı Maddesi ve İçerik Analizi (Mehmet Can'ın verileri)
                  const Text("İçerik Analizi (AI)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 15),
                  _buildIngredientTable(),
                  const SizedBox(height: 25),

                  // 5. Alerjen Uyarıları (Yusuf'un AI verileri)
                  _buildAllergyAlerts(),
                  const SizedBox(height: 40),

                  // 6. Ana Sayfaya Dön Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/home')),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF20B2AA),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text(
                        "Yeni Analiz Yap",
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Sağlık Skoru Widget'ı
  Widget _buildHealthScoreCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20)],
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 80,
                height: 80,
                child: CircularProgressIndicator(
                  value: 0.85,
                  strokeWidth: 10,
                  backgroundColor: Colors.grey.shade200,
                  color: Colors.green,
                ),
              ),
              const Text("85", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ),
          const SizedBox(width: 25),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Besin Puanı", style: TextStyle(color: Colors.grey)),
                Text("Mükemmel Seçim!", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50))),
                Text("Vücudun için gereken mineralleri içeriyor.", style: TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Makro Besin Dağılım Grafiği (Çubuk Grafik Simülasyonu)
  Widget _buildMacroDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: Column(
        children: [
          _macroBar("Karbonhidrat", 0.65, Colors.orange),
          const SizedBox(height: 15),
          _macroBar("Protein", 0.20, Colors.blue),
          const SizedBox(height: 15),
          _macroBar("Yağ Oranı", 0.15, Colors.redAccent),
        ],
      ),
    );
  }

  Widget _macroBar(String label, double percent, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text("%${(percent * 100).toInt()}", style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: percent,
            minHeight: 12,
            backgroundColor: color.withOpacity(0.1),
            color: color,
          ),
        ),
      ],
    );
  }

  // İçerik Tablosu (Tablo görünümü)
  Widget _buildIngredientTable() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(25)),
      child: DataTable(
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text("İçerik", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Miktar", style: TextStyle(fontWeight: FontWeight.bold))),
          DataColumn(label: Text("Durum", style: TextStyle(fontWeight: FontWeight.bold))),
        ],
        rows: [
          _dataRow("Şeker", "1.2g", "Düşük", Colors.green),
          _dataRow("Lif", "8.5g", "Yüksek", Colors.blue),
          _dataRow("E202", "Tespit", "Riskli", Colors.red),
          _dataRow("Sodyum", "0.2g", "Normal", Colors.green),
        ],
      ),
    );
  }

  DataRow _dataRow(String name, String amount, String status, Color color) {
    return DataRow(cells: [
      DataCell(Text(name)),
      DataCell(Text(amount)),
      DataCell(Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
      )),
    ]);
  }

  // Alerjen Uyarı Kartı
  Widget _buildAllergyAlerts() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 40),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Alerjen Uyarısı!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                Text("Bu ürün eser miktarda Gluten içerebilir.", style: TextStyle(color: Colors.redAccent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}