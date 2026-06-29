import 'package:flutter/material.dart';
import '../services/analysis_service.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String imagePath;
  final String category;
  final double portionGram;
  final Map<String, OcrNutrient> ocrResults;

  const VerificationScreen({
    super.key,
    required this.imagePath,
    required this.category,
    required this.portionGram,
    required this.ocrResults,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  static const Color _bgDark = Color(0xFF13131A);
  static const Color _cardDark = Color(0xFF1E1E2A);
  static const Color _accentGreen = Color(0xFF10B981);
  static const Color _accentRed = Color(0xFFEF4444);

  final Map<String, TextEditingController> _controllers = {};
  final Map<String, String> _units = {};

  String _selectedCategory = 'Genel';
  final List<String> _categories = ['Atıştırmalık', 'Süt Ürünü', 'İçecek', 'Tatlı', 'Sos', 'Genel'];

  final Map<String, bool> _diseases = {
    '1. Diyabet': false,
    '2. Obezite': false,
    '3. Hipertansiyon': false,
    '4. Hiperlipidemi': false,
    '5. Kardiyovasküler Hastalık Riski': false,
    '6. Böbrek Hastalığı Riski': false,
    '7. Metabolik Sendrom Riski': false,
    '8. Karaciğer Yağlanması Riski': false,
    '9. Protein/Enerji Yetersizliği Riski': false,
    '10. Mineral Dengesizliği Riski': false,
  };

  int _age = 0;
  int _height = 0;
  int _weight = 0;

  bool _isLoading = false;

  final Map<String, String> _knownNutrients = {
    'Energy_kcal': 'Enerji (kcal)',
    'Energy_kJ': 'Enerji (kJ)',
    'Fat_g': 'Yağ (g)',
    'SaturatedFat_g': 'Doymuş Yağ (g)',
    'Carbohydrate_g': 'Karbonhidrat (g)',
    'Sugar_g': 'Şeker (g)',
    'Fiber_g': 'Lif (g)',
    'Protein_g': 'Protein (g)',
    'Salt_g': 'Tuz (g)',
    'Sodium_mg': 'Sodyum (mg)',
    'Potassium_mg': 'Potasyum (mg)',
    'Calcium_mg': 'Kalsiyum (mg)'
  };

  @override
  void initState() {
    super.initState();
    
    _loadUserProfile();

    if (_categories.contains(widget.category)) {
      _selectedCategory = widget.category;
    } else {
      _selectedCategory = 'Genel';
    }

    // Gelen verileri controller'lara aktar
    widget.ocrResults.forEach((key, nutrient) {
      _addNutrientField(key, nutrient.per100g, nutrient.unit);
    });
    
    // Kesinlikle Şeker, Doymuş Yağ ve Lif alanlarını ekle
    final requiredKeys = ['Sugar_g', 'SaturatedFat_g', 'Fiber_g'];
    for (var k in requiredKeys) {
      if (!_controllers.containsKey(k)) {
        _addNutrientField(k, null, 'g');
      }
    }
  }

  Future<void> _loadUserProfile() async {
    try {
      if (ApiService.currentUserId == null) return;
      final user = await ApiService.getUser(ApiService.currentUserId!);
      if (user != null && mounted) {
        setState(() {
          _age = user['age'] ?? 0;
          _height = (user['height'] as num?)?.toInt() ?? 0;
          _weight = (user['weight'] as num?)?.toInt() ?? 0;

          _diseases['1. Diyabet'] = user['hasDiabetes'] ?? false;
          _diseases['2. Obezite'] = user['hasObesity'] ?? false;
          _diseases['3. Hipertansiyon'] = user['hasHypertension'] ?? false;
          _diseases['4. Hiperlipidemi'] = user['hasHyperlipidemia'] ?? false;
          _diseases['5. Kardiyovasküler Hastalık Riski'] = user['hasCardiovascularRisk'] ?? false;
          _diseases['6. Böbrek Hastalığı Riski'] = user['hasKidneyDiseaseRisk'] ?? false;
          _diseases['7. Metabolik Sendrom Riski'] = user['hasMetabolicSyndromeRisk'] ?? false;
          _diseases['8. Karaciğer Yağlanması Riski'] = user['hasFattyLiverRisk'] ?? false;
          _diseases['9. Protein/Enerji Yetersizliği Riski'] = user['hasProteinEnergyDeficiency'] ?? false;
          _diseases['10. Mineral Dengesizliği Riski'] = user['hasMineralImbalance'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Profil verisi yüklenirken hata: $e");
    }
  }

  void _addNutrientField(String key, double? value, String unit) {
    if (!_controllers.containsKey(key)) {
      _controllers[key] = TextEditingController(
        text: value != null ? value.toStringAsFixed(1) : '',
      );
      _units[key] = unit;
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _showAddNutrientDialog() {
    String selectedKey = _knownNutrients.keys.first;
    final valueController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: _cardDark,
              title: const Text('Eksik Besin Ekle', style: TextStyle(color: Colors.white)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<String>(
                    value: selectedKey,
                    dropdownColor: _cardDark,
                    isExpanded: true,
                    style: const TextStyle(color: Colors.white),
                    items: _knownNutrients.entries.map((e) {
                      return DropdownMenuItem(
                        value: e.key,
                        child: Text(e.value),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => selectedKey = val);
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: valueController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Değer (100g için)',
                      labelStyle: TextStyle(color: Colors.white54),
                      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
                      focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: _accentGreen)),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal', style: TextStyle(color: Colors.white54)),
                ),
                TextButton(
                  onPressed: () {
                    final val = double.tryParse(valueController.text);
                    if (val != null) {
                      setState(() {
                        // Birimi otomatik bul (Örn: _g, _mg, _kcal)
                        String unit = selectedKey.split('_').last;
                        _addNutrientField(selectedKey, val, unit);
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Ekle', style: TextStyle(color: _accentGreen)),
                ),
              ],
            );
          }
        );
      },
    );
  }

  Future<void> _submitData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final updatedData = <String, OcrNutrient>{};
      for (var entry in _controllers.entries) {
        final val = double.tryParse(entry.value.text.trim());
        if (val != null) {
          updatedData[entry.key] = OcrNutrient(
            per100g: val,
            unit: _units[entry.key] ?? '',
          );
        }
      }

      final activeDiseases = _diseases.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      final result = await AnalysisService.generateReport(
        ocrData: updatedData,
        category: _selectedCategory,
        portionGram: widget.portionGram,
        diseases: activeDiseases,
        age: _age,
        height: _height,
        weight: _weight,
      );

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: _accentRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Veri Doğrulama', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Ürün Kategorisi'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        dropdownColor: _cardDark,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        items: _categories.map((String cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }).toList(),
                        onChanged: (String? newVal) {
                          if (newVal != null) {
                            setState(() {
                              _selectedCategory = newVal;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildSectionTitle('Besin Değerleri (100g)'),
                  const SizedBox(height: 8),
                  const Text(
                    'OCR sistemi tarafından okunan 100 gramlık değerler. Hatalı olanları düzeltebilir veya eksikleri ekleyebilirsiniz.',
                    style: TextStyle(color: Colors.white54, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Lütfen paketin üzerindeki 100g sütunundaki değerleri giriniz.',
                            style: TextStyle(color: Colors.amber, fontSize: 13, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // TextFields for nutrients
                  ..._controllers.entries.map((e) => _buildNutrientRow(e.key, e.value)),

                  const SizedBox(height: 12),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: _showAddNutrientDialog,
                      icon: const Icon(Icons.add, color: _accentGreen),
                      label: const Text('Yeni Ekle', style: TextStyle(color: _accentGreen)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: _accentGreen),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Sağlık Hassasiyetleri'),
                  const SizedBox(height: 8),
                  Container(
                    height: 320,
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        children: _diseases.keys.map((key) {
                          return SwitchListTile(
                            title: Text(key, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                            value: _diseases[key]!,
                            activeColor: _accentGreen,
                            onChanged: (val) => setState(() => _diseases[key] = val),
                          );
                        }).toList(),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Porsiyon Onayı'),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Seçilen Porsiyon:', style: TextStyle(color: Colors.white70)),
                        Text('${widget.portionGram.toStringAsFixed(1)} g', style: const TextStyle(color: _accentGreen, fontSize: 18, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Verileri Onayla ve Raporu Al',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: _accentGreen),
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
        color: Colors.white,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildNutrientRow(String key, TextEditingController controller) {
    final displayName = _knownNutrients[key] ?? key;
    final isEnergy = key == 'Energy_kcal';
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              displayName,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: _cardDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: isEnergy ? 'Lütfen kcal değerini giriniz' : null,
                  hintStyle: const TextStyle(color: Colors.white30, fontSize: 10),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: () {
              setState(() {
                _controllers.remove(key);
              });
            },
            icon: const Icon(Icons.delete_outline, color: Colors.white30),
          )
        ],
      ),
    );
  }
}
