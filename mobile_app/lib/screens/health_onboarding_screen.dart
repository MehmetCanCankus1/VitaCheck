import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class HealthOnboardingScreen extends StatefulWidget {
  const HealthOnboardingScreen({super.key});

  @override
  State<HealthOnboardingScreen> createState() => _HealthOnboardingScreenState();
}

class _HealthOnboardingScreenState extends State<HealthOnboardingScreen> {
  bool hasDiabetes = false;
  bool hasObesity = false;
  bool hasHypertension = false;
  bool hasHyperlipidemia = false;
  bool hasCardiovascularRisk = false;
  bool hasKidneyDiseaseRisk = false;
  bool hasMetabolicSyndromeRisk = false;
  bool hasFattyLiverRisk = false;
  bool hasProteinEnergyDeficiency = false;
  bool hasMineralImbalance = false;

  bool _isLoading = false;
  bool _isFetchingUser = true;
  
  Map<String, dynamic>? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await ApiService.getUser(ApiService.requireUserId);
      if (mounted) {
        setState(() {
          _currentUser = user;
          _isFetchingUser = false;
        });
      }
    } catch (e) {
      debugPrint("Kullanıcı yüklenirken hata: $e");
      if (mounted) {
        setState(() => _isFetchingUser = false);
      }
    }
  }

  Widget _buildHealthToggle(String title, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10)],
      ),
      child: SwitchListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        value: value,
        activeThumbColor: const Color(0xFF2C7A4B),
        onChanged: onChanged,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  Future<void> _completeProfile() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Kullanıcı bilgileri yüklenemedi.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final success = await ApiService.updateHealthProfile(
        userId: ApiService.requireUserId,
        age: _currentUser!['age'] ?? 0,
        height: (_currentUser!['height'] ?? 0).toDouble(),
        weight: (_currentUser!['weight'] ?? 0).toDouble(),
        dailySugarLimit: (_currentUser!['dailySugarLimit'] ?? 50.0).toDouble(),
        hasDiabetes: hasDiabetes,
        hasObesity: hasObesity,
        hasHypertension: hasHypertension,
        hasHyperlipidemia: hasHyperlipidemia,
        hasCardiovascularRisk: hasCardiovascularRisk,
        hasKidneyDiseaseRisk: hasKidneyDiseaseRisk,
        hasMetabolicSyndromeRisk: hasMetabolicSyndromeRisk,
        hasFattyLiverRisk: hasFattyLiverRisk,
        hasProteinEnergyDeficiency: hasProteinEnergyDeficiency,
        hasMineralImbalance: hasMineralImbalance,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Güncelleme başarısız oldu.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Hata: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isFetchingUser
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF2C7A4B)))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    const Text(
                      "VitaCheck'e Hoş Geldin! 🎉",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Sana en doğru analizleri sunabilmemiz için lütfen sağlık hassasiyetlerini belirt.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: ListView(
                        children: [
                          _buildHealthToggle("1. Diyabet", hasDiabetes, (val) => setState(() => hasDiabetes = val)),
                          _buildHealthToggle("2. Obezite", hasObesity, (val) => setState(() => hasObesity = val)),
                          _buildHealthToggle("3. Hipertansiyon", hasHypertension, (val) => setState(() => hasHypertension = val)),
                          _buildHealthToggle("4. Hiperlipidemi", hasHyperlipidemia, (val) => setState(() => hasHyperlipidemia = val)),
                          _buildHealthToggle("5. Kardiyovasküler Hastalık Riski", hasCardiovascularRisk, (val) => setState(() => hasCardiovascularRisk = val)),
                          _buildHealthToggle("6. Böbrek Hastalığı Riski", hasKidneyDiseaseRisk, (val) => setState(() => hasKidneyDiseaseRisk = val)),
                          _buildHealthToggle("7. Metabolik Sendrom Riski", hasMetabolicSyndromeRisk, (val) => setState(() => hasMetabolicSyndromeRisk = val)),
                          _buildHealthToggle("8. Karaciğer Yağlanması Riski", hasFattyLiverRisk, (val) => setState(() => hasFattyLiverRisk = val)),
                          _buildHealthToggle("9. Protein/Enerji Yetersizliği Riski", hasProteinEnergyDeficiency, (val) => setState(() => hasProteinEnergyDeficiency = val)),
                          _buildHealthToggle("10. Mineral Dengesizliği Riski", hasMineralImbalance, (val) => setState(() => hasMineralImbalance = val)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _completeProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2C7A4B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                "Profilimi Tamamla ve Başla",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
      ),
    );
  }
}
