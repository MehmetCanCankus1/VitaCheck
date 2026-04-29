import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isObscure = true;
  bool _isLoading = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9F9),
      body: Stack(
        children: [
          // Arka plan daireler
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 250, height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFFCCEFDF),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.25, right: -100,
            child: Container(
              width: 200, height: 200,
              decoration: const BoxDecoration(
                color: Color(0xFFD4F0F0),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -60, left: -40,
            child: Container(
              width: 180, height: 180,
              decoration: const BoxDecoration(
                color: Color(0xFFCCEFDF),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // İçerik
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Logo + Hoşgeldin
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Icon(Icons.eco_rounded, size: 40, color: Color(0xFF2E8B57)),
                            ),
                            const SizedBox(width: 20),
                            const Expanded(
                              child: Text(
                                "Merhaba! 👋",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF2C3E50),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 30),

                        const Text(
                          "VitaCheck",
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF20B2AA),
                            letterSpacing: -1,
                          ),
                        ),
                        const Text(
                          "Kişisel gıda ve sağlık asistanın.",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF7F8C8D),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 50),

                        // E-posta
                        _buildSoftTextField(
                          controller: _emailController,
                          hint: "E-posta Adresin",
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 16),

                        // Şifre
                        _buildSoftTextField(
                          controller: _passwordController,
                          hint: "Şifren",
                          icon: Icons.lock_outline_rounded,
                          isPassword: true,
                        ),

                        // Şifremi unuttum
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {},
                            child: const Text(
                              "Şifremi Unuttum",
                              style: TextStyle(
                                color: Color(0xFF20B2AA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Giriş Yap butonu
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF20B2AA),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              elevation: 4,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                                : const Text(
                              "Giriş Yap",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Kayıt ol linki
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              "Hesabın yok mu?",
                              style: TextStyle(color: Color(0xFF7F8C8D)),
                            ),
                            TextButton(
                              onPressed: () {
                                // Navigator.pushNamed(context, '/register');
                              },
                              child: const Text(
                                "Kayıt Ol",
                                style: TextStyle(
                                  color: Color(0xFF20B2AA),
                                  fontWeight: FontWeight.bold,
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
        ],
      ),
    );
  }

  Widget _buildSoftTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword ? _isObscure : false,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: Color(0xFFB2BABB)),
          prefixIcon: Icon(icon, color: const Color(0xFF20B2AA)),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isObscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
              color: Colors.grey,
            ),
            onPressed: () => setState(() => _isObscure = !_isObscure),
          )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        ),
      ),
    );
  }
}