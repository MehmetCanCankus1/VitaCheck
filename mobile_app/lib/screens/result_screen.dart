import 'package:flutter/material.dart';
import '../services/analysis_service.dart';

class ResultScreen extends StatefulWidget {
  final AnalysisResult result;

  const ResultScreen({super.key, required this.result});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {

  Color _scoreColor(String level) {
    if (level == 'düşük') return Colors.green;
    if (level == 'orta')  return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(String level) {
    if (level == 'düşük')  return 'Güvenli Tüketim ✅';
    if (level == 'orta')   return 'Dikkatli Tüket ⚠️';
    return 'Riskli Tüketim ❌';
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: CustomScrollView(
        slivers: [
          // ── AppBar ─────────────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end:   Alignment.bottomCenter,
                    colors: [Color(0xFF2C7A4B), Color(0xFF20B2AA)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 40),
                      const Icon(Icons.fastfood_rounded,
                          size: 70, color: Colors.white),
                      const SizedBox(height: 10),
                      Text(
                        r.category.isNotEmpty ? r.category : 'Ürün Analizi',
                        style: const TextStyle(
                          color:      Colors.white,
                          fontSize:   22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _scoreLabel(r.overallRiskLevel),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. ML Risk Profili (gerçek veriler)
                  if (r.mlRisks.isNotEmpty) ...[
                    _buildRiskProfile(r.mlRisks),
                    const SizedBox(height: 20),
                  ],

                  // 2. Besin Değerleri (OCR'dan gelen gerçek veriler)
                  const Text(
                    'Besin Değerleri',
                    style: TextStyle(
                        fontSize:   18,
                        fontWeight: FontWeight.bold,
                        color:      Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 12),
                  _buildNutrientTable(r),
                  const SizedBox(height: 20),

                  // 3. Doktor Tavsiyesi (Gemini'den gelen gerçek metin)
                  _buildDoctorAdvice(r.doctorAdvice),
                  const SizedBox(height: 30),

                  // 4. Yeni Analiz Butonu
                  SizedBox(
                    width:  double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          Navigator.popUntil(
                              context, ModalRoute.withName('/home')),
                      icon:  const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text(
                        'Yeni Analiz Yap',
                        style: TextStyle(
                            color:      Colors.white,
                            fontSize:   18,
                            fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C7A4B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── ML Risk Profili ────────────────────────────────────────────────────────
  Widget _buildRiskProfile(List<MlRiskItem> risks) {
    // En yüksek 5 riski göster
    final top5 = [...risks]
      ..sort((a, b) => b.riskScore.compareTo(a.riskScore));
    final display = top5.take(5).toList();

    Color levelColor(String level) {
      if (level == 'düşük')  return Colors.green;
      if (level == 'orta')   return Colors.orange;
      return Colors.red;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color:        Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color:      Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset:     const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ML Risk Analizi',
            style: TextStyle(
                fontSize:   16,
                fontWeight: FontWeight.bold,
                color:      Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 16),
          ...display.map((item) {
            final color = levelColor(item.level);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(item.disease,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color:      Color(0xFF2C3E50))),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color:        color.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '%${item.riskScore.toStringAsFixed(0)} ${item.level}',
                          style: TextStyle(
                              color:      color,
                              fontWeight: FontWeight.bold,
                              fontSize:   11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value:           item.riskScore / 100,
                      minHeight:       8,
                      backgroundColor: color.withOpacity(0.1),
                      color:           color,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Besin Değerleri Tablosu ────────────────────────────────────────────────
  Widget _buildNutrientTable(AnalysisResult r) {
    // Gösterilecek besinler: label, değer, birim
    final nutrients = <Map<String, String>>[
      if (r.energyKcal != null && r.energyKcal! > 0)
        {'label': 'Enerji', 'value': r.energyKcal!.toStringAsFixed(1), 'unit': 'kcal'},
      if (r.carbohydrate != null && r.carbohydrate! > 0)
        {'label': 'Karbonhidrat', 'value': r.carbohydrate!.toStringAsFixed(1), 'unit': 'g'},
      if (r.protein != null && r.protein! > 0)
        {'label': 'Protein', 'value': r.protein!.toStringAsFixed(1), 'unit': 'g'},
      if (r.fat != null && r.fat! > 0)
        {'label': 'Yağ', 'value': r.fat!.toStringAsFixed(1), 'unit': 'g'},
      if (r.saturatedFat != null && r.saturatedFat! > 0)
        {'label': 'Doymuş Yağ', 'value': r.saturatedFat!.toStringAsFixed(1), 'unit': 'g'},
      if (r.sugar != null && r.sugar! > 0)
        {'label': 'Şeker', 'value': r.sugar!.toStringAsFixed(1), 'unit': 'g'},
      if (r.fiber != null && r.fiber! > 0)
        {'label': 'Lif', 'value': r.fiber!.toStringAsFixed(1), 'unit': 'g'},
      if (r.salt != null && r.salt! > 0)
        {'label': 'Tuz', 'value': r.salt!.toStringAsFixed(1), 'unit': 'g'},
      if (r.sodium != null && r.sodium! > 0)
        {'label': 'Sodyum', 'value': r.sodium!.toStringAsFixed(1), 'unit': 'mg'},
      if (r.potassium != null && r.potassium! > 0)
        {'label': 'Potasyum', 'value': r.potassium!.toStringAsFixed(1), 'unit': 'mg'},
      if (r.calcium != null && r.calcium! > 0)
        {'label': 'Kalsiyum', 'value': r.calcium!.toStringAsFixed(1), 'unit': 'mg'},
    ];

    if (nutrients.isEmpty) {
      return Container(
        padding:     const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Center(
          child: Text('OCR besin verisi okunamadı.',
              style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          // Başlık satırı
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2C7A4B).withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft:  Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 3,
                    child: Text(
                      '${r.portionGram.toInt()}g Porsiyonda',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize:   13,
                          color:      Color(0xFF2C7A4B)),
                    )),
                const Expanded(
                    flex: 2,
                    child: Text('Miktar',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 13))),
              ],
            ),
          ),
          // Satırlar
          ...nutrients.map((n) => Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 13),
                decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(color: Colors.grey.shade100)),
                ),
                child: Row(
                  children: [
                    Expanded(
                        flex: 3,
                        child: Text(n['label']!,
                            style: const TextStyle(
                                color: Color(0xFF2C3E50)))),
                    Expanded(
                      flex: 2,
                      child: Text(
                        '${n['value']} ${n['unit']}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2C3E50)),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  // ── Doktor Tavsiyesi ───────────────────────────────────────────────────────
  Widget _buildDoctorAdvice(String advice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end:   Alignment.bottomRight,
          colors: [
            const Color(0xFF2C7A4B).withOpacity(0.06),
            const Color(0xFF20B2AA).withOpacity(0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
            color: const Color(0xFF2C7A4B).withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome,
                  color: Color(0xFF2C7A4B), size: 22),
              SizedBox(width: 8),
              Text(
                'VitaCheck Analiz Raporu',
                style: TextStyle(
                    fontSize:   16,
                    fontWeight: FontWeight.bold,
                    color:      Color(0xFF2C3E50)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            advice.isNotEmpty
                ? advice
                : 'Doktor tavsiyesi alınamadı.',
            style: const TextStyle(
                color:  Color(0xFF4A4A4A),
                fontSize: 14,
                height:   1.6),
          ),
        ],
      ),
    );
  }
}