import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model: OcrNutrient (Extract Yanıtı)
// ─────────────────────────────────────────────────────────────────────────────

class OcrNutrient {
  final double? per100g;
  final String unit;

  const OcrNutrient({
    this.per100g,
    required this.unit,
  });

  factory OcrNutrient.fromJson(Map<String, dynamic> json) => OcrNutrient(
        per100g: (json['per_100g'] as num?)?.toDouble(),
        unit:    json['unit'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'per_100g': per100g,
        'unit': unit,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// Model: AnalysisResult
// Backend'den dönen ScanResultResponseDto'nun birebir Dart karşılığı
// ─────────────────────────────────────────────────────────────────────────────

class MlRiskItem {
  final String disease;
  final double riskScore;
  final String level;

  const MlRiskItem({
    required this.disease,
    required this.riskScore,
    required this.level,
  });

  factory MlRiskItem.fromJson(Map<String, dynamic> json) => MlRiskItem(
        disease:   (json['disease'] ?? json['Disease'] ?? json['disease_name']) as String? ?? '',
        riskScore: ((json['riskScore'] ?? json['RiskScore'] ?? json['risk_score']) as num?)?.toDouble() ?? 0.0,
        level:     (json['level'] ?? json['Level'] ?? json['risk_level']) as String? ?? 'düşük',
      );
}

class AnalysisResult {
  final int scanId;
  final DateTime scannedAt;
  final String category;
  final double portionGram;

  // OCR besin değerleri (porsiyona göre ölçeklenmiş)
  final double? energyKcal;
  final double? fat;
  final double? saturatedFat;
  final double? sugar;
  final double? protein;
  final double? salt;
  final double? carbohydrate;
  final double? fiber;
  final double? sodium;
  final double? potassium;
  final double? calcium;

  // ML risk özeti
  final double topRiskScore;
  final String topRiskDisease;
  final String overallRiskLevel;
  final List<MlRiskItem> mlRisks;

  // Doktor tavsiyesi
  final String doctorAdvice;

  const AnalysisResult({
    required this.scanId,
    required this.scannedAt,
    required this.category,
    required this.portionGram,
    this.energyKcal,
    this.fat,
    this.saturatedFat,
    this.sugar,
    this.protein,
    this.salt,
    this.carbohydrate,
    this.fiber,
    this.sodium,
    this.potassium,
    this.calcium,
    required this.topRiskScore,
    required this.topRiskDisease,
    required this.overallRiskLevel,
    required this.mlRisks,
    required this.doctorAdvice,
  });

  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    // mlRisks listesi
    final risksRaw = (json['mlRisks'] ?? json['MlRisks'] ?? json['ml_risks']) as List<dynamic>? ?? [];
    final risks = risksRaw
        .map((e) => MlRiskItem.fromJson(e as Map<String, dynamic>))
        .toList();

    return AnalysisResult(
      scanId:           (json['scanId'] ?? json['ScanId'] ?? json['scan_id']) as int? ?? 0,
      scannedAt:        DateTime.tryParse((json['scannedAt'] ?? json['ScannedAt'] ?? json['scanned_at']) as String? ?? '') ??
                            DateTime.now(),
      category:         (json['category'] ?? json['Category']) as String? ?? '',
      portionGram:      ((json['portionGram'] ?? json['PortionGram'] ?? json['portion_gram']) as num?)?.toDouble() ?? 100.0,
      energyKcal:       ((json['energyKcal'] ?? json['EnergyKcal'] ?? json['energy_kcal'] ?? json['energy']) as num?)?.toDouble(),
      fat:              ((json['fat'] ?? json['Fat'] ?? json['fat_g']) as num?)?.toDouble(),
      saturatedFat:     ((json['saturatedFat'] ?? json['SaturatedFat'] ?? json['saturated_fat'] ?? json['saturated_fat_g']) as num?)?.toDouble(),
      sugar:            ((json['sugar'] ?? json['Sugar'] ?? json['sugar_g']) as num?)?.toDouble(),
      protein:          ((json['protein'] ?? json['Protein'] ?? json['protein_g']) as num?)?.toDouble(),
      salt:             ((json['salt'] ?? json['Salt'] ?? json['salt_g']) as num?)?.toDouble(),
      carbohydrate:     ((json['carbohydrate'] ?? json['Carbohydrate'] ?? json['carbohydrate_g']) as num?)?.toDouble(),
      fiber:            ((json['fiber'] ?? json['Fiber'] ?? json['fiber_g']) as num?)?.toDouble(),
      sodium:           ((json['sodium'] ?? json['Sodium'] ?? json['sodium_mg']) as num?)?.toDouble(),
      potassium:        ((json['potassium'] ?? json['Potassium'] ?? json['potassium_mg']) as num?)?.toDouble(),
      calcium:          ((json['calcium'] ?? json['Calcium'] ?? json['calcium_mg']) as num?)?.toDouble(),
      topRiskScore:     ((json['topRiskScore'] ?? json['TopRiskScore'] ?? json['top_risk_score']) as num?)?.toDouble() ?? 0.0,
      topRiskDisease:   (json['topRiskDisease'] ?? json['TopRiskDisease'] ?? json['top_risk_disease']) as String? ?? '',
      overallRiskLevel: (json['overallRiskLevel'] ?? json['OverallRiskLevel'] ?? json['overall_risk_level']) as String? ?? 'düşük',
      mlRisks:          risks,
      doctorAdvice:     (json['doctorAdvice'] ?? json['DoctorAdvice'] ?? json['doctor_advice']) as String? ?? '',
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Servis: AnalysisService
// ─────────────────────────────────────────────────────────────────────────────

class AnalysisService {
  // ── Backend adresi ────────────────────────────────────────────────────────
  // Android emülatörü için 10.0.2.2 (host makinenin loopback'i),
  // Fiziksel cihaz / iOS simülatörü için Mac'in yerel ağ IP'si kullanılır.
  // ApiService.baseUrl ile aynı host'u kullanıyoruz — tek yerden yönetilir.
  static String get _baseUrl => ApiService.baseUrl;

  /// Fotoğrafı gönderip 100g bazındaki OCR değerlerini çeker (Aşama 1)
  static Future<Map<String, OcrNutrient>> extractOcr({required File image}) async {
    final uri = Uri.parse('$_baseUrl/analysis/extract-ocr');
    final request = http.MultipartRequest('POST', uri);
    
    request.files.add(await http.MultipartFile.fromPath('photo', image.path));

    debugPrint('[AnalysisService] POST $uri (Extract OCR)');

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception('Sunucu zaman aşımına uğradı (OCR).'),
      );
    } on SocketException catch (e) {
      throw Exception('Sunucuya bağlanılamadı: ${e.message}');
    }

    final responseBody = await streamedResponse.stream.bytesToString();
    
    if (streamedResponse.statusCode != 200) {
      throw Exception('OCR başarısız (${streamedResponse.statusCode}): $responseBody');
    }

    try {
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final results = json['ocr_results'] as Map<String, dynamic>? ?? {};
      
      return results.map((key, value) => MapEntry(
            key,
            OcrNutrient.fromJson(value as Map<String, dynamic>),
          ));
    } catch (e) {
      throw Exception('OCR yanıtı işlenemedi: $e');
    }
  }

  /// Onaylanan verilerle ML ve Gemini analizini başlatıp sonucu alır (Aşama 2)
  static Future<AnalysisResult> generateReport({
    required Map<String, OcrNutrient> ocrData,
    required String category,
    required double portionGram,
    required List<String> diseases,
    required int age,
    required int height,
    required int weight,
  }) async {
    final userId = ApiService.requireUserId;
    final uri = Uri.parse('$_baseUrl/analysis/generate-report');

    final requestBody = {
      'userId': userId,
      'category': category,
      'portion_g': portionGram,
      '100g_nutrients': ocrData.map((k, v) => MapEntry(k, v.toJson())),
      'diseases': diseases,
      'age': age,
      'height': height,
      'weight': weight,
    };

    debugPrint('[AnalysisService] POST $uri (Generate Report)');

    try {
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      ).timeout(
        const Duration(seconds: 90),
        onTimeout: () => throw Exception('Sunucu zaman aşımına uğradı (Rapor).'),
      );

      if (response.statusCode != 200) {
        throw Exception('Rapor başarısız (${response.statusCode}): ${response.body}');
      }

      return AnalysisResult.fromJson(jsonDecode(response.body));
    } on SocketException catch (e) {
      throw Exception('Sunucuya bağlanılamadı: ${e.message}');
    }
  }

  /// Kullanıcının geçmiş taramalarını getirir.
  static Future<List<AnalysisResult>> fetchHistory({int limit = 20}) async {
    final userId = ApiService.requireUserId;
    final uri = Uri.parse(
      '$_baseUrl/analysis/history/$userId?limit=$limit',
    );

    try {
      final response = await http
          .get(uri)
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final list = jsonDecode(response.body) as List<dynamic>;
        return list
            .map((e) => AnalysisResult.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      throw Exception('Geçmiş alınamadı (${response.statusCode})');
    } on SocketException catch (e) {
      throw Exception('Sunucuya bağlanılamadı: ${e.message}');
    }
  }

}
