import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://MEHMETCANIN_IP:5117/api";

  // 1. KULLANICI BİLGİLERİNİ ÇEK
  static Future<Map<String, dynamic>?> getUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/Users/$userId'),
        headers: {"Content-Type": "application/json"},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Kullanıcı çekilemedi: $e");
      return null;
    }
  }

  // 2. SAĞLIK PROFİLİ GÜNCELLE
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
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Profil güncellenemedi: $e");
      return false;
    }
  }

  // 3. RİSK ANALİZİ
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
        return jsonDecode(response.body);
      } else {
        throw Exception("Analiz Hatası: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Bağlantı kurulamadı: $e");
    }
  }
}