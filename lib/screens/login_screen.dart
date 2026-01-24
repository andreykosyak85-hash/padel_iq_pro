import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'auth_screen.dart';
import 'matches_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = Supabase.instance.client.auth;
  final LocalAuthentication _localAuth = LocalAuthentication();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkSessionAndBiometrics();
  }

  // 1. Проверка сессии при старте
  Future<void> _checkSessionAndBiometrics() async {
    await Future.delayed(const Duration(milliseconds: 500)); // Небольшая пауза для плавности

    final session = _auth.currentSession;
    
    if (session != null) {
      // Если пользователь уже вошел в систему ранее -> Просим биометрию (Замок)
      if (!kIsWeb) {
        final authenticated = await _tryBiometricUnlock();
        if (authenticated) {
          _goToApp();
        }
        // Если не прошел биометрию — остаемся на экране входа
      } else {
        _goToApp();
      }
    }
  }

  // 2. Логика Биометрии
  Future<bool> _tryBiometricUnlock() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      if (!canCheck) return true; // Если нет сканера, пропускаем

      return await _localAuth.authenticate(
        localizedReason: 'Подтвердите вход в Padel MVP',
        options: const AuthenticationOptions(
          biometricOnly: true, 
          stickyAuth: true,
        ),
      );
    } catch (e) {
      debugPrint("Ошибка биометрии: $e");
      return false; 
    }
  }

  // 3. Вход через Google
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка Google: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 4. Вход через Apple
  Future<void> _signInWithApple() async {
    try {
      await _auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: 'io.supabase.flutter://login-callback',
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Ошибка Apple: $e")));
    }
  }

  void _goToApp() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MatchesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Премиум градиент
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F172A), Color(0xFF1E293B)], 
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isLoading) ...[
                   const CircularProgressIndicator(color: Color(0xFF2F80ED)),
                   const SizedBox(height: 20),
                   const Text("Вход...", style: TextStyle(color: Colors.white)),
                ] else ...[
                  // Логотип
                  Image.asset('assets/logo.png', height: 120), 
                  const SizedBox(height: 20),
                  const Text(
                    "PADEL MVP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "ТВОЙ ПУТЬ К ПОБЕДЕ",
                    style: TextStyle(color: Colors.grey[400], fontSize: 12, letterSpacing: 4.0),
                  ),
                  
                  const Spacer(),

                  // Кнопки входа
                  _LoginButton(
                    icon: Icons.g_mobiledata, 
                    text: "Войти через Google",
                    color: Colors.white,
                    textColor: Colors.black,
                    onTap: _signInWithGoogle,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  if (!kIsWeb && Theme.of(context).platform == TargetPlatform.iOS)
                    _LoginButton(
                      icon: Icons.apple,
                      text: "Войти через Apple",
                      color: Colors.black,
                      textColor: Colors.white,
                      onTap: _signInWithApple,
                    ),
                  
                  if (!kIsWeb && Theme.of(context).platform == TargetPlatform.iOS)
                    const SizedBox(height: 12),

                  _LoginButton(
                    icon: Icons.email_outlined,
                    text: "Войти по Email",
                    color: const Color(0xFF2F80ED), // Фирменный синий
                    textColor: Colors.white,
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AuthScreen())),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  TextButton(
                    onPressed: _goToApp, 
                    child: Text(
                      "Пропустить вход (Демо)",
                      style: TextStyle(color: Colors.grey[500], fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 40),
                ]
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Виджет красивой кнопки
class _LoginButton extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Color textColor;
  final VoidCallback onTap;

  const _LoginButton({
    required this.icon,
    required this.text,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: textColor, size: 28),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}