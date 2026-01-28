import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb; 
import 'dart:io' show Platform; 

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = Supabase.instance.client.auth;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _isRegister = false;
  bool _isReset = false;

  // --- ЛОГИКА EMAIL/ПАРОЛЬ ---
  Future<void> _submit() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    if (email.isEmpty) return _msg("Введите Email", true);
    if (!_isReset && password.length < 6) {
      return _msg("Пароль от 6 символов", true);
    }

    setState(() => _isLoading = true);

    try {
      if (_isReset) {
        // Исправленный редирект для сброса пароля
        await _auth.resetPasswordForEmail(email,
            redirectTo: kIsWeb ? null : 'io.supabase.padeliq://login-callback');
        _msg("Ссылка сброса отправлена!", false);
        setState(() => _isReset = false);
      } else if (_isRegister) {
        await _auth.signUp(email: email, password: password);
        if (mounted) _msg("Регистрация успешна!", false);
      } else {
        await _auth.signInWithPassword(email: email, password: password);
        // Задержка для Android
        await Future.delayed(const Duration(milliseconds: 500));
      }
    } on AuthException catch (e) {
      _msg(e.message, true);
    } catch (e) {
      _msg("Ошибка: $e", true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- ЛОГИКА СОЦСЕТЕЙ (Google / Apple) ---
  Future<void> _socialAuth(OAuthProvider provider) async {
    // 🛡 ЗАЩИТА: Если это Apple и мы на Android — показываем сообщение и выходим
    if (provider == OAuthProvider.apple && !kIsWeb && Platform.isAndroid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Вход через Apple доступен только на устройствах iOS"),
          backgroundColor: Colors.grey,
        ),
      );
      return; 
    }

    setState(() => _isLoading = true);
    try {
      await _auth.signInWithOAuth(
        provider,
        // Универсальный Deep Link для Android (Google)
        redirectTo: kIsWeb ? null : 'io.supabase.padeliq://login-callback',
      );
    } catch (e) {
      _msg("Ошибка входа: $e", true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _msg(String txt, bool err) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(txt), backgroundColor: err ? Colors.red : Colors.green));
  }

  @override
  Widget build(BuildContext context) {
    String title =
        _isReset ? "Сброс пароля" : (_isRegister ? "Регистрация" : "Вход");

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white)),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ЛОГОТИП
              Center(
                child: Image.asset(
                  'assets/logo.png',
                  height: 150, // Вернул 150, как было в твоем коде
                  frameBuilder:
                      (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded || frame != null) return child;
                    return const SizedBox(height: 150);
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.sports_tennis,
                        size: 80, color: Color(0xFFccff00));
                  },
                ),
              ),
              const SizedBox(height: 20),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              const SizedBox(height: 40),

              _Input(
                  controller: _emailController,
                  label: "Email",
                  icon: Icons.email_outlined),
              const SizedBox(height: 16),

              if (!_isReset)
                _Input(
                    controller: _passwordController,
                    label: "Пароль",
                    icon: Icons.lock_outline,
                    isPass: true),
              const SizedBox(height: 24),

              // КНОПКА EMAIL
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2F80ED),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isReset
                              ? "Отправить"
                              : (_isRegister ? "Создать аккаунт" : "Войти"),
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold)),
                ),
              ),

              if (!_isReset) ...[
                const SizedBox(height: 30),
                const Row(children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Text("Или войти через",
                          style: TextStyle(color: Colors.grey))),
                  Expanded(child: Divider(color: Colors.white24)),
                ]),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _SocialBtn(
                        label: "Google",
                        color: Colors.white,
                        textColor: Colors.black,
                        icon: Icons.g_mobiledata,
                        onTap: () => _socialAuth(OAuthProvider.google),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: _SocialBtn(
                        label: "Apple",
                        color: Colors.black,
                        textColor: Colors.white,
                        icon: Icons.apple,
                        onTap: () => _socialAuth(OAuthProvider.apple),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 30),

              if (!_isReset) ...[
                TextButton(
                    onPressed: () => setState(() => _isReset = true),
                    child: const Text("Забыли пароль?",
                        style: TextStyle(color: Colors.grey))),
                TextButton(
                    onPressed: () => setState(() => _isRegister = !_isRegister),
                    child: Text(
                        _isRegister
                            ? "Уже есть аккаунт? Войти"
                            : "Нет аккаунта? Создать",
                        style: const TextStyle(color: Color(0xFF2F80ED)))),
              ] else
                TextButton(
                    onPressed: () => setState(() => _isReset = false),
                    child: const Text("Вернуться",
                        style: TextStyle(color: Color(0xFF2F80ED)))),
            ],
          ),
        ),
      ),
    );
  }
}

// Поле ввода
class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool isPass;
  const _Input(
      {required this.controller,
      required this.label,
      required this.icon,
      this.isPass = false});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.grey),
        filled: true,
        fillColor: const Color(0xFF1E293B),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none),
      ),
    );
  }
}

// Кнопка соцсети
class _SocialBtn extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;
  final VoidCallback onTap;

  const _SocialBtn({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: textColor, size: 28),
        label: Text(label,
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: color == Colors.black
              ? const BorderSide(color: Colors.white24)
              : null,
        ),
      ),
    );
  }
}