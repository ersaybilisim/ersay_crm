import 'dart:async';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'main_screen.dart';
import '../services/fcm_service.dart';

const int _hareketsizlikDakika = 10;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  static const Color primaryYellow = Color(0xFFFFC400);
  static const Color darkYellow = Color(0xFFE0A800);
  static const Color blackColor = Color(0xFF111111);
  static const Color softBg = Color(0xFFF8F8F8);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;
  bool obscurePassword = true;

  Future<void> login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      _showMessage('Kullanıcı adı ve şifre giriniz.');
      return;
    }

    if (isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => isLoading = true);

    try {
      final result = await AuthService.login(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (result.success) {
        await FcmService.registerToken();

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const InactivityWrapper(child: MainScreen()),
          ),
        );
      } else {
        _showMessage(result.errorMessage ?? 'Giriş başarısız.');
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('Giriş hatası: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginScreen.softBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            children: [
              const SizedBox(height: 40),
              Image.asset(
                'images/ersay_logo_1.png',
                height: 82,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              const Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: 'Birlikte '),
                    TextSpan(
                      text: 'hedefliyoruz',
                      style: TextStyle(
                        color: LoginScreen.primaryYellow,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: ', birlikte '),
                    TextSpan(
                      text: 'başarıyoruz!\n',
                      style: TextStyle(
                        color: LoginScreen.primaryYellow,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: 'Her görüşme bir '),
                    TextSpan(
                      text: 'fırsat',
                      style: TextStyle(
                        color: LoginScreen.primaryYellow,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(text: ', her adım bir '),
                    TextSpan(
                      text: 'başarıdır.',
                      style: TextStyle(
                        color: LoginScreen.primaryYellow,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Color(0xFF444444),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Hoş geldiniz',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: LoginScreen.blackColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Hesabınıza giriş yaparak devam edin.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF667085)),
                    ),
                    const SizedBox(height: 28),
                    _LoginInput(
                      controller: usernameController,
                      label: 'E-posta veya Kullanıcı Adı',
                      hint: 'E-posta veya kullanıcı adınızı girin',
                      icon: Icons.mail_outline_rounded,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 20),
                    _LoginInput(
                      controller: passwordController,
                      label: 'Şifre',
                      hint: 'Şifrenizi girin',
                      icon: Icons.lock_outline_rounded,
                      obscureText: obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => login(),
                      suffixIcon: obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      onSuffixTap: () {
                        setState(() => obscurePassword = !obscurePassword);
                      },
                    ),
                    const SizedBox(height: 28),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : login,
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: LoginScreen.primaryYellow,
                          disabledBackgroundColor: LoginScreen.primaryYellow
                              .withOpacity(0.6),
                          foregroundColor: LoginScreen.blackColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class InactivityWrapper extends StatefulWidget {
  final Widget child;

  const InactivityWrapper({super.key, required this.child});

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;
  static const _sure = Duration(minutes: _hareketsizlikDakika);

  @override
  void initState() {
    super.initState();
    _resetTimer();
  }

  void _resetTimer() {
    _timer?.cancel();
    _timer = Timer(_sure, _oturumKapat);
  }

  Future<void> _oturumKapat() async {
    await AuthService.logout();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.lock_clock_outlined, color: Color(0xFFD88900)),
            SizedBox(width: 10),
            Text(
              'Oturum Süresi Doldu',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
          ],
        ),
        content: Text(
          '$_hareketsizlikDakika dakika hareketsiz kaldınız.\n'
          'Güvenliğiniz için oturumunuz kapatıldı.',
          style: const TextStyle(fontSize: 14, color: Color(0xFF444444)),
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: LoginScreen.primaryYellow,
              foregroundColor: Colors.black,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Tekrar Giriş Yap',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      child: widget.child,
    );
  }
}

class _LoginInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  const _LoginInput({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixTap,
    this.textInputAction,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 9),
        TextField(
          controller: controller,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.black),
            suffixIcon: suffixIcon == null
                ? null
                : IconButton(
                    onPressed: onSuffixTap,
                    icon: Icon(suffixIcon, color: Colors.black),
                  ),
            hintStyle: const TextStyle(color: Color(0xFF98A2B3), fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 17,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFD0D5DD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: LoginScreen.primaryYellow,
                width: 1.8,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
