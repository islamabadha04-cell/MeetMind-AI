import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/colors.dart';
import '../core/localization/language_provider.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'emily@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _nameController = TextEditingController();
  bool _isSignUp = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _submit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password.')),
      );
      return;
    }

    if (_isSignUp) {
      final name = _nameController.text.trim();
      final success = await ref
          .read(authProvider.notifier)
          .register(email, password, name.isNotEmpty ? name : 'New User');
      if (!success && mounted) {
        final err =
            ref.read(authProvider).errorMessage ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error));
      }
    } else {
      final success =
          await ref.read(authProvider.notifier).login(email, password);
      if (!success && mounted) {
        final err = ref.read(authProvider).errorMessage ?? 'Login failed';
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err), backgroundColor: AppColors.error));
      }
    }
  }

  void _signInWithGoogle() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!success && mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'Google Sign-In cancelled';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err), backgroundColor: AppColors.error),
      );
    }
  }

  void _loginAsGuest() async {
    final success = await ref.read(authProvider.notifier).loginAsGuest();
    if (!success && mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'Guest login failed';
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(languageProvider);
    final authState = ref.watch(authProvider);
    final isUrdu = lang == AppLanguage.urdu;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Directionality(
      textDirection: isUrdu ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0B0E1B) : AppColors.bgLight,
            gradient: isDark
                ? const RadialGradient(
                    center: Alignment(0, -0.6),
                    radius: 1.2,
                    colors: [
                      Color(0xFF1E1744),
                      Color(0xFF0B0E1B),
                    ],
                  )
                : null,
          ),
          child: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon with Cosmic Glow
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: AppColors.heroGradient,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                              blurRadius: 28,
                              spreadRadius: 2,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.psychology,
                            size: 46, color: Colors.white),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.get('app_name', lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : AppColors.textMainLight,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      AppStrings.get('greeting_subtitle', lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isDark ? const Color(0xFF94A3B8) : Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Language Switcher Chips
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _langChip('English', AppLanguage.english, lang, isDark),
                        const SizedBox(width: 8),
                        _langChip('اردو (Nastaliq)', AppLanguage.urdu, lang, isDark),
                        const SizedBox(width: 8),
                        _langChip('Roman Urdu', AppLanguage.romanUrdu, lang, isDark),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Authentication Container
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF141728) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF262C47)
                              : const Color(0xFFE2E8F0),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(22),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            _isSignUp
                                ? 'Create MeetMind Account'
                                : AppStrings.get('login_title', lang),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : AppColors.textMainLight,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_isSignUp) ...[
                            TextField(
                              controller: _nameController,
                              style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87),
                              decoration: InputDecoration(
                                labelText: 'Full Name',
                                prefixIcon: const Icon(Icons.person_outline),
                                filled: isDark,
                                fillColor: const Color(0xFF0E111E),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: isDark,
                              fillColor: const Color(0xFF0E111E),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: isDark,
                              fillColor: const Color(0xFF0E111E),
                              suffixIcon: IconButton(
                                icon: Icon(_obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Primary Email / Password Action Button
                          Container(
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: AppColors.buttonGradient,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                                  blurRadius: 14,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: authState.isLoading ? null : _submit,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : Text(
                                      _isSignUp
                                          ? 'Create Account'
                                          : AppStrings.get('btn_login', lang),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Divider: OR CONTINUE WITH
                          Row(
                            children: [
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? const Color(0xFF262C47)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text(
                                  AppStrings.get('auth_or_divider', lang),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.8,
                                    color: isDark
                                        ? const Color(0xFF64748B)
                                        : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Divider(
                                  color: isDark
                                      ? const Color(0xFF262C47)
                                      : const Color(0xFFE2E8F0),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Native Google Sign-In Button
                          OutlinedButton.icon(
                            icon: const GoogleLogoIcon(size: 18),
                            label: Text(
                              AppStrings.get('btn_google_signin', lang),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF2E3554)
                                    : const Color(0xFFCBD5E1),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              backgroundColor: isDark
                                  ? const Color(0xFF1A1F36)
                                  : Colors.grey.shade50,
                            ),
                            onPressed:
                                authState.isLoading ? null : _signInWithGoogle,
                          ),
                          const SizedBox(height: 10),

                          // Demo Reviewer Quick Login Button
                          OutlinedButton.icon(
                            icon: const Icon(Icons.badge_outlined, size: 18),
                            label: Text(
                              AppStrings.get('btn_demo_guest', lang),
                              style: const TextStyle(fontSize: 13),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              side: BorderSide(
                                color: isDark
                                    ? const Color(0xFF2E3554).withValues(alpha: 0.6)
                                    : const Color(0xFFE2E8F0),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed:
                                authState.isLoading ? null : _loginAsGuest,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),
                    Center(
                      child: TextButton(
                        onPressed: () => setState(() => _isSignUp = !_isSignUp),
                        child: Text(
                          _isSignUp
                              ? 'Already have an account? Sign In'
                              : "Don't have an account? Sign Up",
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? const Color(0xFFA78BFA)
                                : AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _langChip(
      String label, AppLanguage target, AppLanguage current, bool isDark) {
    final isSelected = target == current;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected
              ? (isDark ? Colors.white : AppColors.primary)
              : (isDark ? const Color(0xFF94A3B8) : Colors.grey.shade700),
        ),
      ),
      selected: isSelected,
      onSelected: (_) =>
          ref.read(languageProvider.notifier).setLanguage(target),
      selectedColor: isDark
          ? const Color(0xFF7C3AED).withValues(alpha: 0.3)
          : AppColors.primary.withValues(alpha: 0.15),
      backgroundColor: isDark ? const Color(0xFF141728) : Colors.grey.shade200,
      side: BorderSide(
        color: isSelected
            ? const Color(0xFF7C3AED)
            : (isDark ? const Color(0xFF262C47) : Colors.transparent),
      ),
    );
  }
}

/// Standalone 4-color Google G icon painter (0 assets, 0 network dependencies)
class GoogleLogoIcon extends StatelessWidget {
  final double size;
  const GoogleLogoIcon({super.key, this.size = 20});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;
    final center = Offset(w / 2, h / 2);
    final radius = w / 2;

    final paintBlue = Paint()..color = const Color(0xFF4285F4);
    final paintRed = Paint()..color = const Color(0xFFEA4335);
    final paintYellow = Paint()..color = const Color(0xFFFBBC05);
    final paintGreen = Paint()..color = const Color(0xFF34A853);

    // Draw Google 4-color arcs
    final rect = Rect.fromCircle(center: center, radius: radius * 0.85);

    // Red arc (top)
    paintRed.style = PaintingStyle.stroke;
    paintRed.strokeWidth = radius * 0.35;
    canvas.drawArc(rect, -2.35, 1.57, false, paintRed);

    // Yellow arc (left)
    paintYellow.style = PaintingStyle.stroke;
    paintYellow.strokeWidth = radius * 0.35;
    canvas.drawArc(rect, -3.92, 1.57, false, paintYellow);

    // Green arc (bottom)
    paintGreen.style = PaintingStyle.stroke;
    paintGreen.strokeWidth = radius * 0.35;
    canvas.drawArc(rect, 0.78, 1.57, false, paintGreen);

    // Blue arc & horizontal bar (right)
    paintBlue.style = PaintingStyle.stroke;
    paintBlue.strokeWidth = radius * 0.35;
    canvas.drawArc(rect, -0.78, 1.56, false, paintBlue);

    // Blue horizontal crossbar
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(center.dx - radius * 0.1, center.dy - radius * 0.18,
          radius * 0.95, radius * 0.36),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
