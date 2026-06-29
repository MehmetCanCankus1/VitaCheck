import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ApiService {
  static int? currentUserId;
  static String? currentUserName;
  static String? profilePhotoBase64;

  static int get requireUserId {
    if (currentUserId == null) {
      throw Exception('Kullanıcı ID bulunamadı, lütfen tekrar giriş yapın.');
    }
    return currentUserId!;
  }

  static void logout() {
    currentUserId = null;
    currentUserName = null;
    profilePhotoBase64 = null;
  }

  // ── Backend Adresi ────────────────────────────────────────────────────────
  // Android emülatörü    → 10.0.2.2   (host makinenin loopback'i)
  // iOS Simülatörü       → localhost  (aynı makinede çalışır)
  // Fiziksel cihaz (WiFi)→ Mac'in yerel ağ IP'si (10.192.254.42)
  //
  // Fiziksel cihazda test için aşağıdaki satırı aktif et:
  // static const String baseUrl = "http://10.192.254.42:5117/api";
  static const String baseUrl = "http://10.0.2.2:5117/api";

  static const Map<String, String> _headers = {
    "Content-Type": "application/json",
  };

  // 1. KULLANICI BİLGİLERİNİ ÇEK
  static Future<Map<String, dynamic>?> getUser(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Users/$userId'), headers: _headers)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("Hata: $e");
      return null;
    }
  }

  // 2. KULLANICI OLUŞTUR (YENİ MİMARİ)
  static Future<Map<String, dynamic>?> createUser({
    required String name,
    required String email,
    required String password,
    required int age,
    required double height,
    required double weight,
    double dailySugarLimit = 50.0,
  }) async {
    logout(); // Eski oturumu temizle
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Users'),
        headers: _headers,
        body: jsonEncode({
          "name": name,
          "email": email, // C#'ta açtığın yeni sütun
          "password": password, // C#'ta açtığın yeni sütun
          "age": age, // C#'ta açtığın yeni sütun
          "height": height, // C#'ta açtığın yeni sütun
          "weight": weight, // C#'ta açtığın yeni sütun
          "dailySugarLimit": dailySugarLimit,
          "hasDiabetes": false,
          "hasObesity": false,
          "hasHypertension": false,
          "hasHyperlipidemia": false,
          "hasCardiovascularRisk": false,
          "hasKidneyDiseaseRisk": false,
          "hasMetabolicSyndromeRisk": false,
          "hasFattyLiverRisk": false,
          "hasProteinEnergyDeficiency": false,
          "hasMineralImbalance": false,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['id'];
        currentUserName = data['name'];
        profilePhotoBase64 = data['profilePhoto'];
        return data;
      }
      var errorData = jsonDecode(response.body); 
      throw Exception(errorData['message'] ?? 'Bu e-posta adresi zaten kullanımda.');
    } catch (e) {
      debugPrint("Kullanıcı oluşturma hatası: $e");
      rethrow;
    }
  }

  // 4. KULLANICI GİRİŞİ (LOGIN)
  static Future<bool> login(String email, String password) async {
    logout(); // Eski oturumu temizle
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Users/login'),
        headers: _headers,
        body: jsonEncode({
          "email": email,
          "password": password,
        }),
      )
          .timeout(const Duration(seconds: 10));

      debugPrint("Login Cevabı: ${response.statusCode}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        currentUserId = data['id'];
        currentUserName = data['name'];
        profilePhotoBase64 = data['profilePhoto'];
        return true;
      } else {
        debugPrint("Login Başarısız. Kod: ${response.statusCode}, Gelen: ${response.body}");
        return false;
      }
    } catch (e) {
      debugPrint("Login Çöktü: $e");
      return false;
    }
  }

  static Future<void> updateProfilePhoto(File imageFile) async {
    if (currentUserId == null) throw Exception('Kullanıcı bulunamadı.');
    String base64Image = base64Encode(await imageFile.readAsBytes());

    var response = await http.post(
      Uri.parse('$baseUrl/Users/update-photo'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'userId': currentUserId,
        'photoBase64': base64Image
      }),
    );

    if (response.statusCode == 200) {
      profilePhotoBase64 = base64Image;
    } else {
      var error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Fotoğraf güncellenemedi.');
    }
  }

  static Future<void> updateCredentials(int userId, String name, String? oldPassword, String? newPassword) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Users/update-credentials'),
        headers: _headers,
        body: jsonEncode({
          "userId": userId,
          "name": name,
          "oldPassword": oldPassword,
          "newPassword": newPassword,
        }),
      )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        currentUserName = name;
        return;
      }
      var errorData = jsonDecode(response.body);
      throw Exception(errorData['message'] ?? 'Bir hata oluştu.');
    } catch (e) {
      debugPrint("Kullanıcı güncelleme hatası: $e");
      rethrow;
    }
  }

  // 3. SAĞLIK PROFİLİ GÜNCELLE
  static Future<bool> updateHealthProfile({
    required int userId,
    required int age,
    required double height,
    required double weight,
    String? email,
    String? password,
    required double dailySugarLimit,
    required bool hasDiabetes,
    required bool hasObesity,
    required bool hasHypertension,
    required bool hasHyperlipidemia,
    required bool hasCardiovascularRisk,
    required bool hasKidneyDiseaseRisk,
    required bool hasMetabolicSyndromeRisk,
    required bool hasFattyLiverRisk,
    required bool hasProteinEnergyDeficiency,
    required bool hasMineralImbalance,
  }) async {
    try {
      final Map<String, dynamic> requestBody = {
        "age": age,
        "height": height,
        "weight": weight,
        "dailySugarLimit": dailySugarLimit,
        "hasDiabetes": hasDiabetes,
        "hasObesity": hasObesity,
        "hasHypertension": hasHypertension,
        "hasHyperlipidemia": hasHyperlipidemia,
        "hasCardiovascularRisk": hasCardiovascularRisk,
        "hasKidneyDiseaseRisk": hasKidneyDiseaseRisk,
        "hasMetabolicSyndromeRisk": hasMetabolicSyndromeRisk,
        "hasFattyLiverRisk": hasFattyLiverRisk,
        "hasProteinEnergyDeficiency": hasProteinEnergyDeficiency,
        "hasMineralImbalance": hasMineralImbalance,
      };

      if (email != null && email.isNotEmpty) requestBody["email"] = email;
      if (password != null && password.isNotEmpty) requestBody["password"] = password;

      final response = await http
          .put(
        Uri.parse('$baseUrl/Users/$userId/health-profile'),
        headers: _headers,
        body: jsonEncode(requestBody),
      )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 4. SU MİKTARINI GETİR
  static Future<int> getTodayWater(int userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/Users/$userId/water-today'))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['count'] ?? 0;
      }
      return 0;
    } catch (e) {
      debugPrint("Su bilgisi alınamadı: $e");
      return 0;
    }
  }

  // 5. SU MİKTARINI GÜNCELLE
  static Future<bool> updateWater(int userId, int count) async {
    try {
      final response = await http
          .post(
        Uri.parse('$baseUrl/Users/update-water'),
        headers: _headers,
        body: jsonEncode({
          "userId": userId,
          "count": count,
        }),
      )
          .timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint("Su güncellenemedi: $e");
      return false;
    }
  }
}