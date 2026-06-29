import 'dart:convert';
import 'package:flutter/material.dart';
import 'profile_screen.dart';
import 'history_screen.dart';
import 'camera_screen.dart';
import '../services/api_service.dart';
import '../services/analysis_service.dart';
import 'package:intl/intl.dart';
import 'result_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  int _waterCount = 0; // içilen bardak sayısı
  int _waterGoal = 8;
  String _userName = "Kullanıcı";
  List<AnalysisResult> _recentScans = [];

  final List<String> dailyTips = [
    "Ketçap, mayonez ve salata soslarının içinde beklediğinden çok daha fazla gizli şeker bulunur.",
    "Su içmeyi unutuyorsan, masanda her zaman dolu bir bardak bulundur. Bu taktik tüketimi %30 artırır!",
    "Paketlerdeki 'İlave şeker içermez' yazısı aldatıcı olabilir. Ürünün kendi meyve şekeri de kan şekerini yükseltir.",
    "Günlük tuz limitini aşmamak için paketli kuruyemişler yerine çiğ ve kavrulmamış olanları tercih et.",
    "Her esmer ekmek tam buğday değildir. Gerçek tam buğday için içindekilerde ilk sırada 'Tam Buğday Unu' yazmalıdır.",
    "Meyve suyu içmek yerine meyvenin kendisini ye. Lifleri kaybetmemek kan şekerini dengede tutar.",
    "Yemekten 20 dakika önce bir bardak su içmek, sofrada daha hızlı doymana yardımcı olur.",
    "Bir ürünün 'İçindekiler' listesinde ilk sırada yazan madde, o ürünün içinde en çok bulunan maddedir.",
    "Şekersiz veya 'Zero' gazlı içeceklerdeki yapay tatlandırıcılar, beyni kandırarak daha çok acıkmana sebep olabilir.",
    "Konserve ve turşularda raf ömrünü uzatmak için gizli ve yüksek miktarda tuz (sodyum) kullanılır.",
    "Yemekten sonra atacağın 15 dakikalık hafif bir adım, sindirimi rahatlatır ve kan şekerini düşürür.",
    "Ceviz, badem ve zeytinyağı gibi sağlıklı yağlar seni uzun süre tok tutar.",
    "Uyku eksikliği iştah hormonlarını tetikler. Günde 7 saatten az uyumak tatlı krizlerine yol açabilir.",
    "Gün içinde içtiğin çay ve kahveler su yerine geçmez, aksine vücuttan su atılmasına (ödem) sebep olur.",
    "Marketlerde satılan meyveli yoğurtlar adeta birer tatlıdır. Yoğurdunu evde taze meyveyle kendin karıştır.",
    "Porsiyon kontrolü yapmakta zorlanıyorsan, yemeklerini daha küçük tabaklarda servis etmeyi dene.",
    "Kahvaltıda yulaf ezmesi tüketmek, içerdiği yüksek lif sayesinde seni öğlene kadar tok tutar.",
    "%70 ve üzeri kakao içeren bitter çikolatalar, ölçülü tüketildiğinde harika bir antioksidan kaynağıdır.",
    "Gece atıştırma isteği geldiğinde önce bir bardak su veya papatya çayı iç, bazen susuzluk açlıkla karışır.",
    "Fast food menülerindeki 'Sadece 10 TL farkla büyük boy' teklifleri, aslında fazladan 500 kalori almaktır.",
    "Masum görünen bir salatayı, üzerine döktüğün mayonezli soslar bir kalori bombasına çevirebilir.",
    "Yemekleri yavaş yemek ve çok çiğnemek, beynine 'doydum' sinyalinin daha çabuk gitmesini sağlar.",
    "Tatlı krizlerinde şerbetli tatlılar yerine sütlü tatlıları (sütlaç, puding) tercih etmek kan şekerini daha az yorar.",
    "Karbonhidratları tek başına değil, yanında bir proteinle tüket (Örn: Elma ve ceviz). Kan şekerin fırlamaz.",
    "Üzerinde 'Diyet' veya 'Light' yazan ürünler sıfır kalori demek değildir, porsiyon kontrolünü elden bırakma.",
    "Tabağının ne kadar renkli olduğuna dikkat et. Farklı renklerdeki sebzeler farklı vitaminleri temsil eder.",
    "Paketli atıştırmalıklardaki Çin Tuzu (MSG), doyma hissini baskılayarak paketin tamamını bitirmene sebep olur.",
    "Haftada en az bir gün balık tüketmek, kalp ve beyin sağlığın için gerekli Omega-3 yağ asitlerini sağlar.",
    "Cips veya bisküvi yerine porsiyonu abartılmamış kuru meyveler hem tatlı ihtiyacını keser hem enerji verir.",
    "Kendini uzun süre aç bırakmak (şok diyetler) metabolizmanı yavaşlatır ve sonraki öğünde daha çok yedirir.",
  ];

  String get _todayMotivation {
    // 2024 başından bugüne geçen gün sayısı — aylar 28/30/31 çekse de kusursuz döner
    final int passedDays = DateTime.now().difference(DateTime(2024, 1, 1)).inDays;
    return dailyTips[passedDays % dailyTips.length];
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
    _loadData();
  }

  Future<void> _loadData() async {
    final userId = ApiService.requireUserId;
    
    // Su ve Kullanıcı bilgisi
    final water = await ApiService.getTodayWater(userId);
    final user = await ApiService.getUser(userId);

    int goal = 8;
    String fetchedName = "Kullanıcı";
    if (user != null) {
      fetchedName = user['name'] ?? user['Name'] ?? "Kullanıcı";
      fetchedName = fetchedName.split(' ')[0]; // Sadece ilk isim
      
      // (Kilo * 0.033) / 0.25
      final weight = double.tryParse(user['weight']?.toString() ?? user['Weight']?.toString() ?? '0') ?? 0.0;
      if (weight > 0) {
        goal = ((weight * 0.033) / 0.25).round();
      }
    }

    List<AnalysisResult> history = [];
    try {
      history = await AnalysisService.fetchHistory(limit: 3);
    } catch (e) {
      debugPrint("Geçmiş alınamadı: $e");
    }

    if (mounted) {
      setState(() {
        _waterCount = water;
        _waterGoal = goal;
        _userName = fetchedName;
        _recentScans = history;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: CustomScrollView(
        slivers: [
          // Üst gradient header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF2C7A4B),
            automaticallyImplyLeading: false,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2C7A4B), Color(0xFF20B2AA)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Merhaba $_userName 👋",
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          const Text(
                                            "Vücudun için en iyisini seç! ✨",
                                            style: TextStyle(
                                                color: Colors.white70, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    GestureDetector(
                                      onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const ProfileScreen()),
                                  ).then((_) => _loadData()),
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: Colors.white, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.white24,
                                      backgroundImage: ApiService.profilePhotoBase64 != null && ApiService.profilePhotoBase64!.isNotEmpty
                                          ? MemoryImage(base64Decode(ApiService.profilePhotoBase64!))
                                          : null,
                                      child: ApiService.profilePhotoBase64 == null || ApiService.profilePhotoBase64!.isNotEmpty == false
                                          ? const Icon(Icons.person_rounded, color: Colors.white, size: 28)
                                          : null,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ana tarama butonu
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CameraScreen()),
                      ),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF2C7A4B), Color(0xFF20B2AA)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF2C7A4B).withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(18),
                              ),
                              child: const Icon(
                                Icons.document_scanner_rounded,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Ürün Tara",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    "Barkod veya içerik etiketini analiz et",
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded,
                                color: Colors.white70, size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Su takibi widget'ı
                    _buildWaterTracker(),
                    const SizedBox(height: 24),

                    // Hızlı erişim
                    const Text(
                      "Hızlı Erişim",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: _buildQuickCard(
                            context,
                            icon: Icons.history_rounded,
                            title: "Geçmiş\nAnalizlerim",
                            subtitle: "Tümünü Gör",
                            color: const Color(0xFF3498DB),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => HistoryScreen()),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildQuickCard(
                            context,
                            icon: Icons.person_outline_rounded,
                            title: "Sağlık\nProfilim",
                            subtitle: "Güncelle",
                            color: const Color(0xFF9B59B6),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProfileScreen()),
                            ).then((_) => _loadData()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Günlük ipucu
                    const Text(
                      "Günün İpucu",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildTipCard(),
                    const SizedBox(height: 24),

                    // Son analizler
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Son Analizler",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2C3E50),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => HistoryScreen()),
                          ),
                          child: const Text("Tümünü Gör",
                              style: TextStyle(color: Color(0xFF2C7A4B))),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_recentScans.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Text(
                          "Henüz bir analiz yapmadınız. İlk ürününüzü taramak için butona tıklayın.",
                          style: TextStyle(color: Colors.grey, height: 1.5),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._recentScans.map((scan) {
                        final isSafe = scan.overallRiskLevel == 'düşük';
                        final color = isSafe ? const Color(0xFF2C7A4B) : (scan.overallRiskLevel == 'orta' ? Colors.orange : Colors.red);
                        final icon = isSafe ? Icons.check_circle_outline_rounded : (scan.overallRiskLevel == 'orta' ? Icons.warning_amber_rounded : Icons.error_outline_rounded);
                        final dateStr = DateFormat('dd.MM.yyyy').format(scan.scannedAt);
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _buildRecentScan(
                            scan.category.isNotEmpty ? scan.category : 'Ürün Analizi',
                            dateStr,
                            isSafe,
                            scan.topRiskDisease.isNotEmpty ? scan.topRiskDisease : scan.overallRiskLevel.toUpperCase(),
                            color,
                            icon,
                            scan
                          ),
                        );
                      }).toList(),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Su takibi widget'ı
  Widget _buildWaterTracker() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop_rounded,
                        color: Colors.blue, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Günlük Su Takibi",
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2C3E50)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Her bardak 250 ml su içermektedir",
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                "$_waterCount / $_waterGoal bardak",
                style: const TextStyle(
                    color: Colors.blue,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Su bardakları
          Wrap(
            spacing: 12.0,
            runSpacing: 12.0,
            alignment: WrapAlignment.start,
            children: List.generate(_waterGoal, (i) {
              final filled = i < _waterCount;
              return GestureDetector(
                onTap: () async {
                  int newCount = _waterCount;
                  if (filled && i == _waterCount - 1) {
                    newCount--;
                  } else if (!filled && i == _waterCount) {
                    newCount++;
                  }
                  
                  if (newCount != _waterCount) {
                    setState(() {
                      _waterCount = newCount;
                    });
                    await ApiService.updateWater(ApiService.requireUserId, newCount);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 30,
                  height: 40,
                  decoration: BoxDecoration(
                    color: filled
                        ? Colors.blue
                        : Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: filled
                            ? Colors.blue
                            : Colors.blue.withOpacity(0.3)),
                  ),
                  child: Icon(
                    Icons.water_drop_rounded,
                    color: filled ? Colors.white : Colors.blue.withOpacity(0.3),
                    size: 18,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _waterCount / _waterGoal,
              minHeight: 8,
              backgroundColor: Colors.blue.withOpacity(0.1),
              color: Colors.blue,
            ),
          ),
          const SizedBox(height: 16),
          // Kişiselleştirilmiş Su Tavsiyesi
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2C7A4B).withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded, size: 20, color: Color(0xFF2C7A4B)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _waterCount >= _waterGoal
                        ? "Bugünkü su hedefine ulaştın! Gerçek bir VitaCheck şampiyonusun. 🔥"
                        : (_waterCount >= _waterGoal / 2)
                            ? "Harika gidiyorsun! Vücudun sana teşekkür ediyor. 🙌"
                            : "Su içmek metabolizmanı hızlandırır, bir bardak daha içmeye ne dersin? 💧",
                    style: const TextStyle(
                      color: Color(0xFF2C7A4B),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildQuickCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFF2C3E50),
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _buildTipCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFF2C7A4B).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2C7A4B).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.lightbulb_outline_rounded,
                color: Color(0xFF2C7A4B), size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Biliyor muydun?",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C7A4B),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _todayMotivation,
                  style: const TextStyle(color: Color(0xFF2C3E50), fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentScan(
      String name,
      String date,
      bool isSafe,
      String reason,
      Color color,
      IconData icon,
      AnalysisResult result,
      ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => ResultScreen(result: result)));
      },
      child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2C3E50))),
                Text(reason,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text(date,
              style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ],
      ),
    ));
  }
}