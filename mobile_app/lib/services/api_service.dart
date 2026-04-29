import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Mehmet Can'ın sana vereceği Ngrok veya Canlı Sunucu Adresi
  static const String baseUrl = "http://MEHMETCANIN_IP:5117/api";

  // 1. KULLANICI PROFİLİ GÜNCELLEME (UsersController'a gider)
  static Future<bool> updateHealthProfile({
    required int userId,
    required String chronicDisease,
    required double dailySugarLimit,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/Users/$userId/health-profile'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "chronicDisease": chronicDisease,
          "dailySugarLimit": dailySugarLimit,
        }),
      );

      return response.statusCode == 200; // Başarılıysa true döner
    } catch (e) {
      print("Profil güncellenemedi: $e");
      return false;
    }
  }

  // 2. RİSK ANALİZİ (AnalysisController'a gider - Yusuf'un verileriyle çalışır)
  static Future<Map<String, dynamic>> checkProductRisk({
    required int userId,
    required String barcode,
    required bool hasGluten,
    required double sugarAmount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/Analysis/check-risk'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "userId": userId,
          "barcode": barcode,
          "hasGluten": hasGluten,
          "sugarAmount": sugarAmount,
        }),
      );

      if (response.statusCode == 200) {
        // Gelen yanıt: { isSafe: true/false, warningMessage: "..." }
        return jsonDecode(response.body);
      } else {
        throw Exception("Analiz Hatası: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Bağlantı kurulamadı: $e");
    }
  }
}