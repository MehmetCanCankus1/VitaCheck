import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

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

  // Sabit verileri (22, 165, 58) SİLDİK! Artık kutular boş gelecek.
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await ApiService.getUser(ApiService.requireUserId);
      
      if (user == null) {
        debugPrint("HATA: API'den veri dönmedi!");
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Veritabanında 1 numaralı kullanıcı bulunamadı!")),
          );
        }
        return;
      }

      debugPrint("DEBUG: Gelen Ham Veri -> \$user");
      
      if (mounted) {
        setState(() {
          _ageController.text = (user['age'] ?? user['Age'] ?? 0).toString();
          _heightController.text = (user['height'] ?? user['Height'] ?? 0).toString();
          _weightController.text = (user['weight'] ?? user['Weight'] ?? 0).toString();
          
          hasDiabetes = user['hasDiabetes'] ?? false;
          hasObesity = user['hasObesity'] ?? false;
          hasHypertension = user['hasHypertension'] ?? false;
          hasHyperlipidemia = user['hasHyperlipidemia'] ?? false;
          hasCardiovascularRisk = user['hasCardiovascularRisk'] ?? false;
          hasKidneyDiseaseRisk = user['hasKidneyDiseaseRisk'] ?? false;
          hasMetabolicSyndromeRisk = user['hasMetabolicSyndromeRisk'] ?? false;
          hasFattyLiverRisk = user['hasFattyLiverRisk'] ?? false;
          hasProteinEnergyDeficiency = user['hasProteinEnergyDeficiency'] ?? false;
          hasMineralImbalance = user['hasMineralImbalance'] ?? false;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Hata yakalandı: \$e");
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Veritabanında 1 numaralı kullanıcı bulunamadı!")),
        );
      }
    }
  }

  double get bmi {
    final height = double.tryParse(_heightController.text) ?? 0;
    final weight = double.tryParse(_weightController.text) ?? 0;
    if (height == 0 || weight == 0) return 0;
    return weight / ((height / 100) * (height / 100));
  }

  // Veri yoksa hata vermemesi için "Veri Bekleniyor" durumlarını ekledik
  String get bmiLabel {
    if (bmi == 0) return "Veri Bekleniyor";
    if (bmi < 18.5) return "Zayıf";
    if (bmi < 25) return "Normal";
    if (bmi < 30) return "Fazla Kilolu";
    return "Obez";
  }

  Color get bmiColor {
    if (bmi == 0) return Colors.grey;
    if (bmi < 18.5) return Colors.blue;
    if (bmi < 25) return Colors.green;
    if (bmi < 30) return Colors.orange;
    return Colors.red;
  }

  int get targetCalorie {
    final weight = double.tryParse(_weightController.text) ?? 0;
    final height = double.tryParse(_heightController.text) ?? 0;
    final age = double.tryParse(_ageController.text) ?? 0;
    if (weight == 0 || height == 0 || age == 0) return 0;
    return (10 * weight + 6.25 * height - 5 * age + 5).toInt();
  }

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      try {
        await ApiService.updateProfilePhoto(File(pickedFile.path));
        setState(() {}); // Arayüzün yeni resmi çizmesi için
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
        }
      }
    }
    if (mounted) Navigator.pop(context);
  }

  void _showPhotoPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                title: const Text("Galeriden Seç", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _pickImage(ImageSource.gallery),
              ),
              const SizedBox(height: 10),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: Colors.green),
                ),
                title: const Text("Kamerayı Kullan", style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () => _pickImage(ImageSource.camera),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  void _showEditProfileSheet(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final _nameController = TextEditingController(text: ApiService.currentUserName ?? "");
    final _oldPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final passwordRegex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^A-Za-z0-9]).{8,}$');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 24,
                right: 24,
                top: 24,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          decoration: const BoxDecoration(
                            color: Colors.black26,
                            borderRadius: BorderRadius.all(Radius.circular(10)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        "Profilimi Düzenle",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Ad Soyad",
                          prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF2C7A4B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C7A4B), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ad Soyad boş bırakılamaz!';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _oldPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Eski Şifre",
                          prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF2C7A4B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C7A4B), width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _newPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Yeni Şifre",
                          prefixIcon: const Icon(Icons.lock_reset, color: Color(0xFF2C7A4B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C7A4B), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value != null && value.isNotEmpty) {
                            if (!passwordRegex.hasMatch(value)) {
                              return 'En az 8 karakter, büyük/küçük harf, rakam ve özel karakter içermelidir.';
                            }
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: InputDecoration(
                          labelText: "Yeni Şifre (Tekrar)",
                          prefixIcon: const Icon(Icons.lock_reset, color: Color(0xFF2C7A4B)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF2C7A4B), width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (_newPasswordController.text.isNotEmpty && value != _newPasswordController.text) {
                            return 'Şifreler birbiriyle eşleşmiyor.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (!_formKey.currentState!.validate()) return;

                            final oldPass = _oldPasswordController.text.isNotEmpty ? _oldPasswordController.text : null;
                            final newPass = _newPasswordController.text.isNotEmpty ? _newPasswordController.text : null;

                            try {
                              await ApiService.updateCredentials(
                                ApiService.requireUserId,
                                _nameController.text.trim(),
                                oldPass,
                                newPass,
                              );
                              
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profil başarıyla güncellendi!"), backgroundColor: Colors.green));
                              setState(() {}); // Sayfadaki ismin değişmesi için
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red));
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2C7A4B),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            "Değişiklikleri Uygula",
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
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
            expandedHeight: 250,
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
                    GestureDetector(
                      onTap: () => _showPhotoPicker(context),
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white24,
                            backgroundImage: ApiService.profilePhotoBase64 != null && ApiService.profilePhotoBase64!.isNotEmpty
                                ? MemoryImage(base64Decode(ApiService.profilePhotoBase64!))
                                : null,
                            child: ApiService.profilePhotoBase64 == null || ApiService.profilePhotoBase64!.isEmpty
                                ? const Icon(Icons.add_a_photo, size: 40, color: Colors.white70)
                                : null,
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF2C7A4B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      ApiService.currentUserName ?? "Kullanıcı",
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Kişisel Sağlık Asistanım",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () => _showEditProfileSheet(context),
                      icon: const Icon(Icons.edit, size: 16, color: Colors.white),
                      label: const Text(
                        "Profilimi Düzenle",
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white70),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                        minimumSize: const Size(0, 32),
                      ),
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
                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        if (!mounted) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(
                            child: CircularProgressIndicator(color: Color(0xFF2C7A4B)),
                          ),
                        );

                        final success = await ApiService.updateHealthProfile(
                          userId: ApiService.requireUserId,
                          age: int.tryParse(_ageController.text.trim()) ?? 0,
                          height: double.tryParse(_heightController.text.trim()) ?? 0.0,
                          weight: double.tryParse(_weightController.text.trim()) ?? 0.0,
                          dailySugarLimit: 50.0,
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

                  // Çıkış Yap Butonu
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        ApiService.logout();
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                      },
                      icon: const Icon(Icons.logout_rounded, color: Colors.red),
                      label: const Text(
                        "Hesaptan Çıkış Yap",
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        backgroundColor: Colors.red.withValues(alpha: 0.05),
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
            // Sen her sayı girdiğinde ekranı yenileyip BMI'ı hesaplayacak kod:
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              hintText: "0",
              hintStyle: TextStyle(color: Colors.grey.shade300),
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
              color: bmiValue == 0 ? Colors.grey.shade200 : bmiColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                bmiValue == 0 ? "-" : bmiValue.toStringAsFixed(1),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: bmiColor)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: bmiValue == 0 ? 0 : (bmiValue / 40).clamp(0.0, 1.0),
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
    final cal = targetCalorie;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C7A4B).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2C7A4B).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.local_fire_department_rounded, 
            color: cal == 0 ? Colors.grey : const Color(0xFF2C7A4B), size: 40),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Günlük Hedef Kalori",
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(
                cal == 0 ? "Hesaplanıyor..." : "$cal kcal",
                style: TextStyle(
                  fontSize: cal == 0 ? 18 : 24, 
                  fontWeight: FontWeight.bold, 
                  color: cal == 0 ? Colors.grey : const Color(0xFF2C7A4B)
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

}