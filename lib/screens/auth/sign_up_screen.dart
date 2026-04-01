import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/animated_gradient_button.dart';
import '../../services/supabase_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/password_validator.dart';
import '../../utils/input_sanitizer.dart';
import '../../utils/auth_guard.dart';
import 'onboarding_screen.dart';
import '../info/privacy_policy_screen.dart';
import '../info/terms_of_service_screen.dart';

class SignUpScreen extends StatefulWidget {
  final VoidCallback? onSwitchToSignIn;

  const SignUpScreen({super.key, this.onSwitchToSignIn});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  late TextEditingController _emailController;
  late TextEditingController _nameController;
  late TextEditingController _passwordController;
  late GlobalKey<FormState> _formKey;
  bool _isLoading = false;
  bool _agreedToTerms = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _formKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final availableHeight = screenHeight - topPadding - bottomPadding;

    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      body: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  const SizedBox(height: 1),
                  Image.asset(
                    'assets/images/sipelor.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 1),

                  // Welcome text
                  Text(
                    'Get Started Free',
                    style: AppTextStyles.lightHeadingLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Free Forever. No Credit Card Needed',
                    style: AppTextStyles.lightLabelText,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email field
                        CustomInputField(
                          label: 'Email Address',
                          placeholder: 'yourname@gmail.com',
                          iconPath: 'assets/icons/email_icon.svg',
                          controller: _emailController,
                          isLightTheme: true,
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Email is required';
                            }
                            if (!RegExp(
                              r'^[^@]+@[^@]+\.[^@]+',
                            ).hasMatch(value)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Username field
                        CustomInputField(
                          label: 'Username',
                          placeholder: 'username',
                          iconPath: 'assets/icons/user_icon.svg',
                          controller: _nameController,
                          isLightTheme: true,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Username is required';
                            }
                            if (value.length < 3) {
                              return 'Username must be at least 3 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),

                        // Password field
                        CustomInputField(
                          label: 'Password',
                          placeholder: '••••••••',
                          iconPath: 'assets/icons/lock_icon.svg',
                          isPassword: true,
                          controller: _passwordController,
                          showPasswordStrength: true,
                          isLightTheme: true,
                          validator: (value) {
                            return PasswordValidator.validate(
                              value,
                              isSignUp: true,
                            );
                          },
                        ),
                        const SizedBox(height: 8),

                        // Password requirements
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Passwords must have at least 8 characters and include a mix of uppercase letters, lowercase letters, numbers, and symbols.',
                            style: AppTextStyles.lightSubLabelText.copyWith(
                              fontSize: 11,
                              color: AppColors.darkSecondaryText.withOpacity(
                                0.8,
                              ),
                              height: 1.4,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Terms agreement
                        _buildAgreementCheckbox(),
                        const SizedBox(height: 20),

                        // Sign up button
                        AnimatedGradientButton(
                          text: 'Sign up',
                          onPressed: _handleSignUp,
                          isLoading: _isLoading,
                          gradientColors: const [
                            Color.fromARGB(255, 0, 113, 72),
                            Color.fromARGB(255, 0, 117, 164),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Or sign up with divider
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.darkLabelText.withOpacity(0.3),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Or sign up with',
                        style: AppTextStyles.lightDividerText,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color.fromARGB(
                            255,
                            95,
                            94,
                            94,
                          ).withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Gmail sign up button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : () {},
                      icon: SvgPicture.asset(
                        'assets/icons/google_button.svg',
                        width: 24,
                        height: 24,
                      ),
                      label: Text(
                        'Sign Up With Gmail',
                        style: AppTextStyles.lightLabelText.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1F1F1F),
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: Colors.white,
                        side: BorderSide(
                          color: AppColors.darkLabelText.withOpacity(0.3),
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Sign in link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: AppTextStyles.lightLabelText,
                      ),
                      GestureDetector(
                        onTap: widget.onSwitchToSignIn,
                        child: Text(
                          'Sign in',
                          style: AppTextStyles.lightLabelText.copyWith(
                            color: const Color.fromARGB(255, 0, 14, 212),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Agreement checkbox ────────────────────────────────────────────────────

  Widget _buildAgreementCheckbox() {
    const accentColor = Color.fromARGB(255, 0, 113, 72);
    const linkColor = Color.fromARGB(255, 0, 14, 212);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _agreedToTerms,
            activeColor: accentColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
            onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _agreedToTerms = !_agreedToTerms),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.lightSubLabelText.copyWith(
                  fontSize: 12,
                  color: AppColors.darkSecondaryText,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'Saya telah membaca dan menyetujui '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                      child: Text(
                        'Kebijakan Privasi',
                        style: AppTextStyles.lightSubLabelText.copyWith(
                          fontSize: 12,
                          color: linkColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: linkColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' dan '),
                  WidgetSpan(
                    alignment: PlaceholderAlignment.baseline,
                    baseline: TextBaseline.alphabetic,
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      ),
                      child: Text(
                        'Syarat & Ketentuan',
                        style: AppTextStyles.lightSubLabelText.copyWith(
                          fontSize: 12,
                          color: linkColor,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: linkColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const TextSpan(text: ' SIPELOR BEDAS.'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Sign-up handler ───────────────────────────────────────────────────────

  Future<void> _handleSignUp() async {
    if (kDebugMode) print('🔵 [SignUpScreen] _handleSignUp called');

    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) print('❌ [SignUpScreen] Form validation failed');
      return;
    }

    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Harap setujui Kebijakan Privasi dan Syarat & Ketentuan terlebih dahulu.',
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim().toLowerCase();
      final password = _passwordController.text.trim();
      final username = InputSanitizer.sanitizeUsername(
        _nameController.text.trim(),
      );

      // Sanity checks
      if (InputSanitizer.containsMaliciousPattern(username) ||
          InputSanitizer.containsMaliciousPattern(email)) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Input mengandung karakter tidak valid'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final emailError = InputSanitizer.validateEmail(email);
      if (emailError != null) throw Exception(emailError);

      if (username.isEmpty) {
        throw Exception(
          'Username tidak valid. Gunakan huruf, angka, underscore, atau hyphen.',
        );
      }

      if (kDebugMode) {
        print('📝 [SignUpScreen] Attempting signup:');
        print('   - Email: $email');
        print('   - Username: $username');
      }

      // 1️⃣ Register user with Supabase (email auth)
      final response = await SupabaseService.signUp(
        email: email,
        password: password,
        username: username,
      );

      if (kDebugMode) {
        print('✅ [SignUpScreen] Signup successful! User: ${response.user?.id}');
        print(
          '   Session: ${response.session != null ? "EXISTS" : "NULL (email conf required)"}',
        );
      }

      if (!mounted) return;

      await _showSuccessDialog();
      if (!mounted) return;

      final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();
      if (!hasSeenOnboarding && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => OnboardingScreen(
              onFinish: () => AuthGuard.navigateByRole(context),
            ),
          ),
        );
      } else if (mounted) {
        await AuthGuard.navigateByRole(context);
      }
    } on AuthApiException catch (e) {
      if (kDebugMode) {
        print('❌ [SignUpScreen] Auth API exception: ${e.message}');
        print('   Status: ${e.statusCode}, Code: ${e.code}');
      }

      if (mounted) {
        String errorMessage;
        IconData errorIcon = Icons.error_outline;
        Color backgroundColor = Colors.red;
        String? errorDetails;

        if (e.statusCode == '429' ||
            e.code == 'over_email_send_rate_limit' ||
            e.message.toLowerCase().contains('rate limit')) {
          errorMessage = 'Terlalu Banyak Permintaan';
          errorDetails =
              'Server membatasi permintaan untuk mencegah spam.\n\n'
              '• Tunggu beberapa menit dan coba lagi\n'
              '• Atau gunakan email yang berbeda';
          errorIcon = Icons.schedule;
          backgroundColor = Colors.orange;
        } else if (e.statusCode == '422' ||
            e.code == 'user_already_exists' ||
            e.message.toLowerCase().contains('already') ||
            e.message.toLowerCase().contains('registered') ||
            e.message.toLowerCase().contains('duplicate')) {
          errorMessage = 'Email Sudah Terdaftar';
          errorDetails =
              'Email "${_emailController.text.trim()}" sudah digunakan.\n\n'
              '• Login dengan akun yang ada\n'
              '• Atau gunakan email yang berbeda\n'
              '• Atau gunakan "Lupa Password" jika lupa password';
          errorIcon = Icons.person_outline;
        } else if (e.message.toLowerCase().contains('invalid email')) {
          errorMessage = 'Format Email Tidak Valid';
          errorDetails =
              'Pastikan email dalam format yang benar:\nexample@domain.com';
          errorIcon = Icons.email_outlined;
        } else if (e.message.toLowerCase().contains('password')) {
          errorMessage = 'Password Tidak Memenuhi Syarat';
          errorDetails =
              'Password harus:\n'
              '• Minimal 8 karakter\n'
              '• Kombinasi huruf, angka, dan simbol';
          errorIcon = Icons.lock_outline;
        } else {
          errorMessage = 'Pendaftaran Gagal';
          errorDetails = e.message;
        }

        _showErrorDialog(
          title: errorMessage,
          message: errorDetails,
          icon: errorIcon,
          backgroundColor: backgroundColor,
        );
      }
    } on AuthException catch (e) {
      if (kDebugMode) print('❌ [SignUpScreen] Auth exception: ${e.message}');
      if (mounted) {
        _showErrorDialog(
          title: 'Pendaftaran Gagal',
          message: e.message,
          icon: Icons.error_outline,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      if (kDebugMode) print('❌ [SignUpScreen] Error: $e (${e.runtimeType})');
      if (mounted) {
        String msg = e.toString();
        if (msg.contains('already exists')) {
          msg = 'Email sudah terdaftar. Silakan login.';
        } else if (msg.contains('AuthException')) {
          msg = msg
              .replaceAll('AuthException: ', '')
              .replaceAll('Exception: ', '');
        }
        _showErrorDialog(
          title: 'Terjadi Kesalahan',
          message: msg,
          icon: Icons.error_outline,
          backgroundColor: Colors.red,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────

  Future<void> _showErrorDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color backgroundColor,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: backgroundColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: backgroundColor),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              SingleChildScrollView(
                child: Text(
                  message,
                  textAlign: TextAlign.left,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: backgroundColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'OK',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 48,
                  color: Color(0xFF25D366),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Pembuatan Akun Berhasil!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Akun Anda telah dibuat. Silakan lanjutkan ke halaman berikutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Lanjutkan ke Verifikasi',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
