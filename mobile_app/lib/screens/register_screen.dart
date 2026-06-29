import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'health_onboarding_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Tüm yeni alanlar için kontrolcülerimizi ekledik
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  
  bool _isLoading = false;
  bool _isObscure = true; // Şifreyi gizle/göster için
  bool _isTermsAccepted = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Hicran'ın tasarım stilini bozmadan kodu temiz tutmak için özel bir yardımcı widget ürettik
  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF2C7A4B)),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: Colors.grey,
                  ),
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                )
              : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFF2C7A4B), width: 2),
          ),
        ),
      ),
    );
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Kullanım Koşulları ve Sağlık Beyanı",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: const SingleChildScrollView(
          child: Text(
            "VitaCheck uygulaması tarafından sağlanan gıda analizleri, "
            "yapay zeka (OCR) teknolojisi ile etiket okumaya dayanmaktadır "
            "ve %100 doğruluk garanti etmez.\n\n"
            "Uygulama tıbbi bir tavsiye vermez, doktor veya diyetisyen "
            "yerine geçmez.\n\n"
            "Alerjiniz veya ciddi bir rahatsızlığınız varsa, lütfen "
            "tüketmeden önce ürün ambalajını kendiniz kontrol ediniz.\n\n"
            "Olası yanılma paylarından ve doğabilecek sağlık sorunlarından "
            "VitaCheck ve geliştiricileri sorumlu tutulamaz.",
            style: TextStyle(fontSize: 14, height: 1.5, color: Colors.black87),
          ),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() => _isTermsAccepted = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C7A4B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("Okudum, Onaylıyorum", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: SafeArea(
        child: Center(
          // Klavye açılınca ekran taşmasın diye sayfayı kaydırılabilir yaptık
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.health_and_safety_rounded,
                    size: 80, color: Color(0xFF2C7A4B)),
                const SizedBox(height: 24),
                const Text(
                  "Hesap Oluştur",
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2C3E50)),
                ),
                const SizedBox(height: 8),
                const Text(
                  "VitaCheck'e hoş geldiniz",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                const SizedBox(height: 40),

                // ---- VİTRİNİMİZ BURADA BAŞLIYOR ----
                _buildInputField(
                  controller: _nameController,
                  hint: "Adınız ve Soyadınız",
                  icon: Icons.person_rounded,
                ),
                
                _buildInputField(
                  controller: _emailController,
                  hint: "E-posta Adresi",
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                ),
                
                _buildInputField(
                  controller: _passwordController,
                  hint: "Şifre",
                  icon: Icons.lock_outline_rounded,
                  isPassword: true,
                ),

                // Yaş, Boy ve Kiloyu ekranı çok uzatmamak için çok şık bir şekilde yan yana dizdik
                Row(
                  children: [
                    Expanded(
                      child: _buildInputField(
                        controller: _ageController,
                        hint: "Yaş",
                        icon: Icons.calendar_today_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInputField(
                        controller: _heightController,
                        hint: "Boy",
                        icon: Icons.height_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildInputField(
                        controller: _weightController,
                        hint: "Kilo",
                        icon: Icons.monitor_weight_rounded,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Kullanıcı Sözleşmesi Onay Kutusu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Checkbox(
                      value: _isTermsAccepted,
                      activeColor: const Color(0xFF2C7A4B),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (bool? value) {
                        if (value == true) {
                          _showTermsDialog();
                        } else {
                          setState(() => _isTermsAccepted = false);
                        }
                      },
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: _showTermsDialog,
                        child: const Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: "Kullanım Koşulları ve Sağlık Beyanı",
                                style: TextStyle(
                                  color: Color(0xFF2C7A4B),
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              TextSpan(
                                text: "'nı okudum, onaylıyorum.",
                                style: TextStyle(color: Colors.black87, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () async {
                            // Sözleşme Kontrolü
                            if (!_isTermsAccepted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lütfen kayıt olmadan önce sözleşmeyi onaylayın.')),
                              );
                              return;
                            }

                            // Basit Doğrulama: Boş alan varsa uyarı ver
                            if (_nameController.text.trim().isEmpty || 
                                _emailController.text.trim().isEmpty || 
                                _passwordController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Lütfen zorunlu alanları doldurun!")),
                              );
                              return;
                            }

                            final passwordRegex = RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^A-Za-z0-9]).{8,}$');
                            if (!passwordRegex.hasMatch(_passwordController.text.trim())) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Şifre en az 8 karakter olmalı, büyük/küçük harf, rakam ve özel karakter içermelidir.")),
                              );
                              return;
                            }

                            final age = int.tryParse(_ageController.text.trim()) ?? 0;
                            final height = double.tryParse(_heightController.text.trim()) ?? 0.0;
                            final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;

                            if (_ageController.text.trim().isEmpty || age == 0 ||
                                _heightController.text.trim().isEmpty || height == 0 ||
                                _weightController.text.trim().isEmpty || weight == 0) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Lütfen yaş, boy ve kilo bilgilerini eksiksiz girin!")),
                              );
                              return;
                            }

                            setState(() => _isLoading = true);

                            try {
                              final user = await ApiService.createUser(
                                name: _nameController.text.trim(),
                                email: _emailController.text.trim(),
                                password: _passwordController.text.trim(),
                                age: age,
                                height: height,
                                weight: weight,
                              );

                              setState(() => _isLoading = false);
                              
                              if (!mounted) return;
                              
                              if (user != null) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const HealthOnboardingScreen()),
                                );
                              }
                            } catch (e) {
                              setState(() => _isLoading = false);
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2C7A4B),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("Kayıt Ol",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Zaten hesabım var, giriş yap",
                      style: TextStyle(color: Color(0xFF2C7A4B))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}