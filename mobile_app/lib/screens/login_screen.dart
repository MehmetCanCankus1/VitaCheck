import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: Stack(
        children: [
          Positioned(
            top: -80, left: -80,
            child: Container(width: 250, height: 250, decoration: const BoxDecoration(color: Color(0xFFCCEFDF), shape: BoxShape.circle)),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25, right: -100,
            child: Container(width: 200, height: 200, decoration: const BoxDecoration(color: Color(0xFFD4F0F0), shape: BoxShape.circle)),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))]),
                          child: const Icon(Icons.eco_rounded, size: 40, color: Color(0xFF2E8B57)),
                        ),
                        const SizedBox(width: 20),
                        const Expanded(child: Text("Merhaba! 👋", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF2C3E50)))),
                      ],
                    ),
                    const SizedBox(height: 30),
                    const Text("VitaCheck", style: TextStyle(fontSize: 38, fontWeight: FontWeight.w900, color: Color(0xFF20B2AA), letterSpacing: -1)),
                    const Text("Kişisel gıda ve sağlık asistanın.", style: TextStyle(fontSize: 18, color: Color(0xFF7F8C8D), fontWeight: FontWeight.w500)),
                    const SizedBox(height: 50),
                    _buildSoftTextField(controller: _emailController, hint: "E-posta Adresin", icon: Icons.alternate_email_rounded),
                    const SizedBox(height: 20),
                    _buildSoftTextField(controller: _passwordController, hint: "Şifren", icon: Icons.lock_outline_rounded, isPassword: true),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity, height: 60,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF20B2AA), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                        child: const Text("Giriş Yap", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
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

  Widget _buildSoftTextField({required TextEditingController controller, required String hint, required IconData icon, bool isPassword = false}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10))]),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFF20B2AA)),
          suffixIcon: isPassword ? IconButton(icon: Icon(_isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded), onPressed: () => setState(() => _isObscure = !_isObscure)) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }
}