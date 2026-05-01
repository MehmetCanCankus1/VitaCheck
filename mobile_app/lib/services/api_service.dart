import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5117/api";

  static const Map<String, String> _headers = {
    "Content-Type": "application/json",
  };

  // 1. KULLANICI BİLGİLERİNİ ÇEK
  static Future<Map<String, dynamic>?> getUser(int userId) async {
    try {
      final response = await http
          .get(
        Uri.parse('$baseUrl/Users/$userId'),
        headers: _headers,
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      debugPrint("Kullanıcı bulunamadı: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("Kullanıcı çekilemedi: $e");
      return null;
    }
  }

  // 2. KULLANICI OLUŞTUR
  static Future<Map<String, dynamic>?> createUser({
    required String name,
    required String chronicDisease,
    required double dailySugarLimit,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Users'),
        headers: _headers,
        body: jsonEncode({
          "name": name,
          "chronicDisease": chronicDisease,
          "dailySugarLimit": dailySugarLimit,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      }
      debugPrint("Kullanıcı oluşturulamadı: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("Kullanıcı oluşturulamadı: $e");
      return null;
    }
  }

  // 3. SAĞLIK PROFİLİ GÜNCELLE
  static Future<bool> updateHealthProfile({
    required int userId,
    required String chronicDisease,
    required double dailySugarLimit,
  }) async {
    try {
      final response = await http
          .put(
        Uri.parse('$baseUrl/Users/$userId/health-profile'),
        headers: _headers,
        body: jsonEncode({
          "chronicDisease": chronicDisease,
          "dailySugarLimit": dailySugarLimit,
        }),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint("Profil güncelleme: ${response.statusCode} - ${response.body}");
      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Profil güncellenemedi: $e");
      return false;
    }
  }

  // 4. RİSK ANALİZİ
  static Future<Map<String, dynamic>> checkProductRisk({
    required int userId,
    required String barcode,
    required double sugarAmount,
    required bool hasGluten,
  }) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Analysis/check-risk'),
        headers: _headers,
        body: jsonEncode({
          "userId": userId,
          "barcode": barcode,
          "sugarAmount": sugarAmount,
          "hasGluten": hasGluten,
        }),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint("Risk analizi: ${response.statusCode} - ${response.body}");

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception("Kullanıcı bulunamadı.");
      } else {
        throw Exception("Analiz hatası: ${response.statusCode}");
      }
    } catch (e) {
      throw Exception("Bağlantı kurulamadı: $e");
    }
  }
}