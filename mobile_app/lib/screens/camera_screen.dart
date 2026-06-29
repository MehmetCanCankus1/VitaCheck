import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/analysis_service.dart';
import 'verification_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Ana ekran: sadece çerçeve + galeri/kamera butonları
// ─────────────────────────────────────────────────────────────────────────────

class CameraScreen extends StatelessWidget {
  const CameraScreen({super.key});

  static const Color _primaryGreen = Color(0xFF2C7A4B);
  static const Color _lightGreen   = Color(0xFF4CAF50);

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final image  = await picker.pickImage(
      source:        source,
      imageQuality:  85,
      maxWidth:      1920,
    );
    if (image == null || !context.mounted) return;

    // Fotoğraf seçildi → BottomSheet aç
    await showModalBottomSheet(
      context:           context,
      isScrollControlled: true,
      backgroundColor:   Colors.transparent,
      builder: (_) => _AnalysisSheet(imagePath: image.path),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan gradyanı
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin:  Alignment.topCenter,
                end:    Alignment.bottomCenter,
                colors: [Color(0xFF1a1a2e), Color(0xFF16213e)],
              ),
            ),
          ),

          // Üst bar
          Positioned(
            top: 50, left: 16, right: 16,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const Spacer(),
                const Text(
                  'Etiketi Tara',
                  style: TextStyle(
                      color:      Colors.white,
                      fontSize:   18,
                      fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                const SizedBox(width: 48),
              ],
            ),
          ),

          // Orta: Kamera çerçevesi + yönerge
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width:  280,
                  height: 180,
                  decoration: BoxDecoration(
                    border:       Border.all(color: _lightGreen, width: 2.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Center(
                    child: Icon(Icons.document_scanner_outlined,
                        color: Colors.white24, size: 64),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Gıda etiketini fotoğrafla\nveya galeriden seç',
                  style: TextStyle(color: Colors.white54, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // Alt butonlar
          Positioned(
            bottom: 60, left: 0, right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Galeri butonu
                  _SideButton(
                    icon:    Icons.photo_library_outlined,
                    onTap:   () => _pickImage(context, ImageSource.gallery),
                  ),

                  // Kamera (ana) butonu
                  GestureDetector(
                    onTap: () => _pickImage(context, ImageSource.camera),
                    child: Container(
                      width:  76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape:  BoxShape.circle,
                        color:  _primaryGreen,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color:       _lightGreen.withValues(alpha: 0.5),
                            blurRadius:  20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 34),
                    ),
                  ),

                  // Simetri için boşluk
                  const SizedBox(width: 56),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcı: küçük yan buton
// ─────────────────────────────────────────────────────────────────────────────

class _SideButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _SideButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width:  56,
        height: 56,
        decoration: BoxDecoration(
          color:        Colors.white24,
          borderRadius: BorderRadius.circular(14),
          border:       Border.all(color: Colors.white30),
        ),
        child: Icon(icon, color: Colors.white, size: 26),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BottomSheet: Önizleme + Kategori + Porsiyon + Analizi Başlat
// ─────────────────────────────────────────────────────────────────────────────

class _AnalysisSheet extends StatefulWidget {
  final String imagePath;
  const _AnalysisSheet({required this.imagePath});

  @override
  State<_AnalysisSheet> createState() => _AnalysisSheetState();
}

class _AnalysisSheetState extends State<_AnalysisSheet> {
  static const Color _primaryGreen = Color(0xFF2C7A4B);
  static const Color _lightGreen   = Color(0xFF4CAF50);
  static const Color _bgDark       = Color(0xFF1C1C2E);
  static const Color _cardDark     = Color(0xFF252538);

  final List<String> _categories = [
    'Genel', 'Tatlı', 'Sos', 'Enerji İçeceği',
    'Alkol', 'Süt Ürünü', 'Atıştırmalık', 'Diyet/Light',
  ];

  String  _selectedCategory = 'Genel';
  final TextEditingController _portionController = TextEditingController(text: '100');
  bool    _isLoading        = false;

  @override
  void dispose() {
    _portionController.dispose();
    super.dispose();
  }

  Future<void> _startAnalysis() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);

    try {
      final portionText = _portionController.text.trim();
      final portionGram = double.tryParse(portionText) ?? 100.0;

      final results = await AnalysisService.extractOcr(
        image: File(widget.imagePath),
      );

      if (!mounted) return;

      // BottomSheet'i kapat, sonra VerificationScreen'e geç
      Navigator.pop(context);

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerificationScreen(
            imagePath: widget.imagePath,
            category: _selectedCategory,
            portionGram: portionGram,
            ocrResults: results,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:         Text('Analiz başarısız: $e'),
          backgroundColor: Colors.redAccent,
          behavior:        SnackBarBehavior.floating,
          margin:          const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      margin:  const EdgeInsets.symmetric(horizontal: 12),
      padding: EdgeInsets.only(bottom: bottomPadding + 24),
      decoration: BoxDecoration(
        color:        _bgDark,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Tutma çubuğu ────────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width:  44,
            height: 4,
            decoration: BoxDecoration(
              color:        Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // ── Başlık ──────────────────────────────────────────────────────────
          const Text(
            'Analiz Ayarları',
            style: TextStyle(
                color:      Colors.white,
                fontSize:   18,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // ── Görsel önizleme + özet bilgi ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.file(
                    File(widget.imagePath),
                    width:  80,
                    height: 80,
                    fit:    BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Fotoğraf hazır',
                        style: TextStyle(
                            color:      Colors.white,
                            fontSize:   15,
                            fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Kategori ve porsiyon seçip analizi başlatabilirsiniz.',
                        style: TextStyle(
                            color:    Colors.white.withValues(alpha: 0.5),
                            fontSize: 12,
                            height:   1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          _Divider(),
          const SizedBox(height: 20),

          // ── Kategori Seçimi ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.only(left: 20, bottom: 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Ürün Kategorisi',
                style: TextStyle(
                    color:      Colors.white.withValues(alpha: 0.7),
                    fontSize:   13,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection:  Axis.horizontal,
              padding:          const EdgeInsets.symmetric(horizontal: 20),
              itemCount:        _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final cat      = _categories[i];
                final selected = cat == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color:        selected ? _primaryGreen : _cardDark,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                        color: selected ? _lightGreen : Colors.white12,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                          color:      selected ? Colors.white : Colors.white54,
                          fontSize:   12,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 24),
          _Divider(),
          const SizedBox(height: 20),

          // ── Porsiyon Girişi ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                const Icon(Icons.scale_outlined,
                    color: Colors.white54, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Porsiyon (Gram)',
                    style: TextStyle(
                        color:    Colors.white.withValues(alpha: 0.7),
                        fontSize: 13),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    controller: _portionController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 12),
                      filled: true,
                      fillColor: _cardDark,
                      suffixText: 'g',
                      suffixStyle: const TextStyle(color: Colors.white54),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _lightGreen),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Analizi Başlat Butonu ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width:  double.infinity,
              height: 58,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startAnalysis,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isLoading ? Colors.grey.shade700 : _primaryGreen,
                  disabledBackgroundColor: Colors.grey.shade800,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  elevation: _isLoading ? 0 : 6,
                  shadowColor: _primaryGreen.withValues(alpha: 0.4),
                ),
                child: _isLoading
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width:  22,
                            height: 22,
                            child:  CircularProgressIndicator(
                                color:       Colors.white,
                                strokeWidth: 2.5),
                          ),
                          SizedBox(width: 14),
                          Text(
                            'AI analizi yapılıyor…',
                            style: TextStyle(
                                color:      Colors.white70,
                                fontSize:   16,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.auto_awesome,
                              color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Analizi Başlat',
                            style: TextStyle(
                                color:      Colors.white,
                                fontSize:   17,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Yardımcı: ince ayırıcı çizgi
// ─────────────────────────────────────────────────────────────────────────────

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 1,
        color:  Colors.white.withValues(alpha: 0.07),
      ),
    );
  }
}