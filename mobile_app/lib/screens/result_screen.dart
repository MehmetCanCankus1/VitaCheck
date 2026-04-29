import 'package:flutter/material.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scoreAnim;

  final double healthScore = 0.85;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scoreAnim = Tween<double>(begin: 0, end: healthScore).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Color _scoreColor(double score) {
    if (score >= 0.7) return Colors.green;
    if (score >= 0.4) return Colors.orange;
    return Colors.red;
  }

  String _scoreLabel(double score) {
    if (score >= 0.7) return "Mükemmel Seçim! ✅";
    if (score >= 0.4) return "Dikkatli Tüketin ⚠️";
    return "Önerilmez ❌";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2C7A4B), Color(0xFF20B2AA)],
                  ),
                ),
                child: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: 40),
                      Icon(Icons.fastfood_rounded, size: 70, color: Colors.white),
                      SizedBox(height: 10),
                      Text(
                        "Yulaf Ezmesi - Gold Seri",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Analiz Tamamlandı",
                        style: TextStyle(color: Colors.white70, fontSize: 14),
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
                  // 1. Animasyonlu Skor
                  _buildAnimatedScore(),
                  const SizedBox(height: 20),

                  // 2. Profil Uyum Durumu
                  _buildProfileCompatibility(),
                  const SizedBox(height: 20),

                  // 3. Makro Besin
                  const Text(
                    "Besin Değerleri",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 12),
                  _buildMacroDistribution(),
                  const SizedBox(height: 20),

                  // 4. İçerik Analizi
                  const Text(
                    "İçerik Analizi (AI)",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
                  ),
                  const SizedBox(height: 12),
                  _buildIngredientTable(),
                  const SizedBox(height: 20),

                  // 5. Alerjen Uyarısı
                  _buildAllergyAlert(),
                  const SizedBox(height: 20),

                  // 6. Egzersiz Önerisi
                  _buildExerciseSuggestion(),
                  const SizedBox(height: 30),

                  // 7. Buton
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.popUntil(
                          context, ModalRoute.withName('/home')),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: const Text(
                        "Yeni Analiz Yap",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
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

  // Animasyonlu Skor Kartı
  Widget _buildAnimatedScore() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _scoreAnim,
            builder: (context, child) {
              final color = _scoreColor(_scoreAnim.value);
              return Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 90,
                    height: 90,
                    child: CircularProgressIndicator(
                      value: _scoreAnim.value,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey.shade200,
                      color: color,
                    ),
                  ),
                  Text(
                    "${(_scoreAnim.value * 100).toInt()}",
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: color),
                  ),
                ],
              );
            },
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Besin Puanı",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  _scoreLabel(healthScore),
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor(healthScore)),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Günlük beslenme için uygun.",
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Profil Uyum Durumu
  Widget _buildProfileCompatibility() {
    final profiles = [
      {"label": "Diyabet", "safe": true},
      {"label": "Çölyak", "safe": false},
      {"label": "Hipertansiyon", "safe": true},
      {"label": "Laktoz İnt.", "safe": true},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Profilinize Uygunluk",
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2C3E50)),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: profiles.map((p) {
              final safe = p["safe"] as bool;
              return Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: safe
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: safe
                          ? Colors.green.shade200
                          : Colors.red.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      safe ? Icons.check_circle : Icons.cancel,
                      size: 16,
                      color: safe ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      p["label"] as String,
                      style: TextStyle(
                          color: safe ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                          fontSize: 13),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // Makro Dağılım
  Widget _buildMacroDistribution() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          _macroBar("Karbonhidrat", 0.65, Colors.orange),
          const SizedBox(height: 14),
          _macroBar("Protein", 0.20, const Color(0xFF2C7A4B)),
          const SizedBox(height: 14),
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
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF2C3E50))),
            Text("%${(percent * 100).toInt()}",
                style:
                TextStyle(color: color, fontWeight: FontWeight.bold)),
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

  // İçerik Tablosu
  Widget _buildIngredientTable() {
    final ingredients = [
      {"name": "Şeker", "amount": "1.2g", "status": "Düşük", "safe": true},
      {"name": "Lif", "amount": "8.5g", "status": "Yüksek", "safe": true},
      {"name": "E202", "amount": "Tespit", "status": "Riskli", "safe": false},
      {"name": "Sodyum", "amount": "0.2g", "status": "Normal", "safe": true},
    ];

    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        children: [
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF2C7A4B).withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: const Row(
              children: [
                Expanded(
                    child: Text("İçerik",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text("Miktar",
                        style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(
                    child: Text("Durum",
                        style: TextStyle(fontWeight: FontWeight.bold))),
              ],
            ),
          ),
          ...ingredients.map((i) {
            final safe = i["safe"] as bool;
            final color = safe ? Colors.green : Colors.red;
            return Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Text(i["name"] as String,
                          style: const TextStyle(color: Color(0xFF2C3E50)))),
                  Expanded(
                      child: Text(i["amount"] as String,
                          style: const TextStyle(color: Colors.grey))),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Text(
                        i["status"] as String,
                        style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12),
                      ),
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

  // Alerjen Uyarısı
  Widget _buildAllergyAlert() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEBEE),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.red, size: 40),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Alerjen Uyarısı!",
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.red)),
                Text(
                    "Bu ürün eser miktarda Gluten içerebilir. Çölyak hastalarına önerilmez.",
                    style:
                    TextStyle(color: Colors.redAccent, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Egzersiz Önerisi
  Widget _buildExerciseSuggestion() {
    final exercises = [
      {"icon": Icons.directions_walk, "name": "Yürüyüş", "duration": "25 dk"},
      {"icon": Icons.pool, "name": "Yüzme", "duration": "15 dk"},
      {"icon": Icons.fitness_center, "name": "Hafif Egzersiz", "duration": "20 dk"},
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.directions_run, color: Color(0xFF2C7A4B)),
              SizedBox(width: 8),
              Text(
                "Egzersiz Önerisi",
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C3E50)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            "Bu öğünü dengelemek için önerilen aktiviteler:",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: exercises.map((e) {
              return Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C7A4B).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(e["icon"] as IconData,
                        color: const Color(0xFF2C7A4B), size: 28),
                  ),
                  const SizedBox(height: 8),
                  Text(e["name"] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: Color(0xFF2C3E50))),
                  Text(e["duration"] as String,
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12)),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}