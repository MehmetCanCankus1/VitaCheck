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
    "Laktoz Hassasiyeti": false,
    "Diyabet (Şeker Kontrolü)": false,
    "Vegan Beslenme": false,
    "Yüksek Tansiyon (Tuz Kontrolü)": false,
    "Çölyak Hastalığı": false,
  };

  final List<String> _allergyOptions = [
    "Fıstık", "Fındık", "Süt", "Yumurta", "Buğday",
    "Soya", "Balık", "Kabuklu Deniz Ürünleri", "Susam",
  ];
  final List<String> _selectedAllergies = [];

  final TextEditingController _medicationController = TextEditingController();
  final List<String> _medications = [];

  final TextEditingController _ageController = TextEditingController(text: "22");
  final TextEditingController _heightController = TextEditingController(text: "165");
  final TextEditingController _weightController = TextEditingController(text: "58");
  final TextEditingController _notesController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final user = await ApiService.getUser(1);
    if (user != null && mounted) {
      final chronicDiseases = (user['chronicDisease'] as String?) ?? "";
      setState(() {
        healthSettings.forEach((key, _) {
          healthSettings[key] = chronicDiseases.contains(key);
        });
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
    _medicationController.dispose();
    super.dispose();
  }

  void _addMedication() {
    final text = _medicationController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _medications.add(text);
        _medicationController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF4F9F9),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF2C7A4B)),
        ),
      );
    }

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

                  _buildSectionTitle("Alerjik Olduğu Gıdalar"),
                  const SizedBox(height: 12),
                  _buildAllergySection(),
                  const SizedBox(height: 20),

                  _buildSectionTitle("İlaç Kullanımı"),
                  const SizedBox(height: 12),
                  _buildMedicationSection(),
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

                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(color: Color(0xFF2C7A4B)),
                          ),
                        );

                        final success = await ApiService.updateHealthProfile(
                          userId: 1,
                          chronicDisease: selectedDiseases,
                          dailySugarLimit: 50.0,
                        );

                        if (!mounted) return;
                        Navigator.pop(context);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              success
                                  ? "Sağlık profilin güncellendi! 🌿"
                                  : "Bağlantı kurulamadı, tekrar dene.",
                            ),
                            backgroundColor: success ? const Color(0xFF2C7A4B) : Colors.red,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.save_rounded, color: Colors.white),
                      label: const Text(
                        "Profili Kaydet",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C7A4B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

  Widget _buildAllergySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergyOptions.map((allergy) {
              final selected = _selectedAllergies.contains(allergy);
              return GestureDetector(
                onTap: () => setState(() {
                  if (selected) {
                    _selectedAllergies.remove(allergy);
                  } else {
                    _selectedAllergies.add(allergy);
                  }
                }),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF2C7A4B) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFF2C7A4B) : Colors.grey.shade300,
                    ),
                  ),
                  child: Text(
                    allergy,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.grey.shade700,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedAllergies.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              "Seçilenler: ${_selectedAllergies.join(', ')}",
              style: const TextStyle(color: Color(0xFF2C7A4B), fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMedicationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _medicationController,
                  decoration: InputDecoration(
                    hintText: "Örn: Metformin 500mg, günde 2",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 13),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFF2C7A4B)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _addMedication,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                    color: Color(0xFF2C7A4B),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_medications.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._medications.asMap().entries.map((entry) => Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2C7A4B).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.medication_rounded, color: Color(0xFF2C7A4B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: const TextStyle(fontSize: 13, color: Color(0xFF2C3E50)),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _medications.removeAt(entry.key)),
                    child: const Icon(Icons.close, color: Colors.red, size: 18),
                  ),
                ],
              ),
            )),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                "Henüz ilaç eklenmedi",
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
    );
  }

  Widget _buildInputCard(String label, TextEditingController controller, String unit) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
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
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C3E50)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: bmiColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                bmiValue.toStringAsFixed(1),
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: bmiColor),
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
                Text(bmiLabel,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: bmiColor)),
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
        color: const Color(0xFF2C7A4B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2C7A4B).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.local_fire_department_rounded, color: Color(0xFF2C7A4B), size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Günlük Hedef Kalori",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                "$targetCalorie kcal",
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2C7A4B)),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: SwitchListTile(
        title: Text(key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        value: healthSettings[key]!,
        activeThumbColor: const Color(0xFF2C7A4B),
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
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12)],
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