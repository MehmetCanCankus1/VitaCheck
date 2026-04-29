import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, bool> healthSettings = {
    "Gluten Alerjisi": false,
    "Laktoz Hassasiyeti": true,
    "Diyabet (Şeker Kontrolü)": false,
    "Vegan Beslenme": false,
    "Yüksek Tansiyon (Tuz Kontrolü)": false,
    "Çölyak Hastalığı": false,
  };

  final TextEditingController _ageController = TextEditingController(text: "22");
  final TextEditingController _heightController = TextEditingController(text: "165");
  final TextEditingController _weightController = TextEditingController(text: "58");
  final TextEditingController _notesController = TextEditingController();

  double get bmi {
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (height == 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  String get bmiLabel {
    if (bmi < 18.5) return "Zayıf";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Fazla Kilolu";
    return "Obez";
  }

  Color get bmiColor {
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  int get targetCalorie {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final age = double.tryParse(_ageController.text) ?? 0;
    return (10 * weight + 6.25 * height - 5 * age + 5).toInt();
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF2C7A4B),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF2C7A4B), Color(0xFF20B2AA)],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Stack(
                      children: [
                        const CircleAvatar(
                          radius: 45,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.person_rounded, size: 50, color: Colors.white),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF2C7A4B)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Hicran K.",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const Text(
                      "Software Engineering Student",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Vücut Bilgileri"),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildInputCard("Yaş", _ageController, "yıl")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInputCard("Boy", _heightController, "cm")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildInputCard("Kilo", _weightController, "kg")),
                    ],
                  ),
                  const SizedBox(height: 20),

                  _buildBMICard(),
                  const SizedBox(height: 20),

                  _buildCalorieCard(),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Sağlık Hassasiyetleri"),
                  const SizedBox(height: 12),
                  ...healthSettings.keys.map((key) => _buildHealthToggle(key)),
                  const SizedBox(height: 20),

                  _buildSectionTitle("Hastalık Geçmişi Notları"),
                  const SizedBox(height: 12),
                  _buildNotesField(),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final selectedDiseases = healthSettings.entries
                            .where((e) => e.value)
                            .map((e) => e.key)
                            .join(", ");

                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(
                                color: Color(0xFF2C7A4B)),
                          ),
                        );

                        final success = await ApiService.updateHealthProfile(
                          userId: 1,
                          chronicDisease: selectedDiseases,
                          dailySugarLimit: 50.0,
                        );

                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? "Sağlık profilin güncellendi! 🌿"
                                  : "Bağlantı kurulamadı, tekrar dene.",
                            ),
                            backgroundColor:
                            success ? const Color(0xFF2C7A4B) : Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text(
                        "Profili Kaydet",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Color(0xFF2C3E50),
      ),
    );
  }

  Widget _buildInputCard(String label, TextEditingController controller, String unit) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              suffix: Text(unit, style: const TextStyle(color: Colors.grey, fontSize: 11)),
            ),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2C3E50),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBMICard() {
    final bmiValue = bmi;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bmiColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                bmiValue.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: bmiColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Vücut Kitle İndeksi (BMI)",
                    style: TextStyle(color: Colors.grey, fontSize: 13)),
                Text(
                  bmiLabel,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: bmiColor,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: (bmiValue / 40).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    color: bmiColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C7A4B).withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2C7A4B).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded,
              color: Color(0xFF2C7A4B), size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Günlük Hedef Kalori",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                "$targetCalorie kcal",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2C7A4B),
                ),
              ),
              const Text("Bazal metabolik hızınıza göre",
                  style: TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHealthToggle(String key) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: SwitchListTile(
        title: Text(key,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        value: healthSettings[key]!,
        activeColor: const Color(0xFF2C7A4B),
        onChanged: (val) => setState(() => healthSettings[key] = val),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Widget _buildNotesField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
      ),
      child: TextField(
        controller: _notesController,
        maxLines: 4,
        decoration: InputDecoration(
          hintText: "Örn: 2019'dan beri tip 2 diyabet, metformin kullanıyorum...",
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}