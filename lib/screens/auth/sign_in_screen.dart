import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../widgets/custom_input_field.dart';
import '../../widgets/animated_gradient_button.dart';
import '../../services/supabase_service.dart';
import '../../services/biometric_auth_service.dart';
import '../../services/rate_limiter_service.dart';
import '../../services/server_rate_limiter_service.dart';
import '../../services/security_education_service.dart';
import '../../services/social_auth_service.dart';
import '../../services/password_service.dart';
import '../../services/security_event_notification_service.dart';
import '../../services/onboarding_service.dart';
import '../../utils/auth_guard.dart';
import 'onboarding_screen.dart';
import '../info/privacy_policy_screen.dart';
import '../info/services_agreement_screen.dart';
import '../../utils/password_validator.dart';
import '../../utils/input_sanitizer.dart';
import '../../widgets/security_warning_dialog.dart';

class SignInScreen extends StatefulWidget {
  final VoidCallback? onSwitchToSignUp;

  const SignInScreen({super.key, this.onSwitchToSignUp});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  late GlobalKey<FormState> _formKey;
  bool _isLoading = false;
  bool _biometricEnabled = false;
  String _biometricTypeName = 'Biometrik';

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
    _formKey = GlobalKey<FormState>();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    final enabled = await BiometricAuthService.isBiometricEnabled();
    final typeName = await BiometricAuthService.getBiometricTypeName();

    if (mounted) {
      setState(() {
        _biometricEnabled = enabled;
        _biometricTypeName = typeName;
      });
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  SizedBox(height: 0),
                  Image.asset(
                    'assets/images/sipelor.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),
                  SizedBox(height: 0),

                  // Welcome text
                  Text(
                    'SELAMAT DATANG',
                    style: AppTextStyles.lightHeadingLarge,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Sistem Informasi Penyewaan Lapangan Olahraga \n di Kabupaten Bandung',
                    style: AppTextStyles.lightLabelText,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 32),

                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Username field
                        CustomInputField(
                          label: 'Username',
                          placeholder: 'Enter your username',
                          iconPath: 'assets/icons/user_icon.svg',
                          controller: _usernameController,
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
                        SizedBox(height: 20),

                        // Password field
                        CustomInputField(
                          label: 'Password',
                          placeholder: '••••••••',
                          iconPath: 'assets/icons/lock_icon.svg',
                          isPassword: true,
                          controller: _passwordController,
                          isLightTheme: true,
                          validator: (value) {
                            // Use new password validator (less strict for sign in)
                            return PasswordValidator.validate(
                              value,
                              isSignUp: false,
                            );
                          },
                        ),
                        SizedBox(height: 12),

                        // Forgot Password — disabled, contact admin instead
                        Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Lupa password? Hubungi Admin Support',
                            style: AppTextStyles.lightForgotPasswordText.copyWith(
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),

                        // Sign In button
                        AnimatedGradientButton(
                          text: 'Sign in',
                          onPressed: _handleSignIn,
                          isLoading: _isLoading,
                          gradientColors: const [
                            Color.fromARGB(255, 0, 113, 72),
                            Color.fromARGB(255, 0, 117, 164),
                          ],
                        ),

                        // Biometric Login button
                        if (_biometricEnabled) ...[
                          SizedBox(height: 16),
                          OutlinedButton.icon(
                            onPressed: _isLoading
                                ? null
                                : _handleBiometricLogin,
                            icon: Icon(
                              _biometricTypeName == 'Face ID'
                                  ? Icons.face
                                  : Icons.fingerprint,
                              color: const Color.fromARGB(255, 0, 113, 72),
                            ),
                            label: Text(
                              'Login dengan $_biometricTypeName',
                              style: AppTextStyles.lightLabelText.copyWith(
                                color: const Color.fromARGB(255, 0, 113, 72),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 16,
                              ),
                              side: const BorderSide(
                                color: Color.fromARGB(255, 0, 113, 72),
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(height: 32),

                  // Or continue with
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.darkLabelText.withOpacity(0.3),
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Or continue with',
                        style: AppTextStyles.lightDividerText,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.darkLabelText.withOpacity(0.3),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Gmail sign in button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _isLoading ? null : _handleGoogleSignIn,
                      icon: SvgPicture.asset(
                        'assets/icons/google_button.svg',
                        width: 24,
                        height: 24,
                      ),
                      label: Text(
                        'Sign In With Gmail',
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
                  SizedBox(height: 20),

                  // Sign up link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Don't have an account? ",
                        style: AppTextStyles.lightLabelText,
                      ),
                      GestureDetector(
                        onTap: widget.onSwitchToSignUp,
                        child: Text(
                          'Sign up',
                          style: AppTextStyles.lightLabelText.copyWith(
                            color: const Color.fromARGB(255, 0, 14, 212),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),

                  // Service Agreement and Privacy Statement
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: GoogleFonts.mulish(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: AppColors.secondaryDark,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By selecting Sign In, I agree to the ',
                          ),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const ServicesAgreementScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Sipelor Bedas Services Agreement',
                                style: GoogleFonts.mulish(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 0, 113, 72),
                                  decoration: TextDecoration.underline,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: ' and '),
                          WidgetSpan(
                            child: GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const PrivacyPolicyScreen(),
                                  ),
                                );
                              },
                              child: Text(
                                'Privacy Statement',
                                style: GoogleFonts.mulish(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color.fromARGB(255, 0, 113, 72),
                                  decoration: TextDecoration.underline,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Copyright text
                  Text(
                    '© 2026 Dev Dispora Kabupaten Bandung',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryDark.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleSignIn() async {
    if (kDebugMode) {
      if (kDebugMode) print('🔵 [SignInScreen] _handleSignIn called');
    }

    if (!_formKey.currentState!.validate()) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignInScreen] Form validation failed');
      }
      return;
    }

    if (kDebugMode) {
      if (kDebugMode) print('✅ [SignInScreen] Form validation passed');
    }

    setState(() {
      _isLoading = true;
    });

    // Sanitize username input (declare outside try-catch for error handling access)
    final username = InputSanitizer.sanitizeUsername(
      _usernameController.text.trim(),
    );
    final password = _passwordController.text.trim();

    // Check for malicious patterns
    if (InputSanitizer.containsMaliciousPattern(username) ||
        InputSanitizer.containsMaliciousPattern(password)) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Input mengandung karakter tidak valid'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      // Check rate limit before attempting login (server-side primary, local fallback)
      final serverRateLimiter = ServerRateLimiterService();
      final canAttempt = await serverRateLimiter.checkLogin(username);
      final rateLimiter = RateLimiterService();

      if (!canAttempt) {
        final blockedDuration = rateLimiter.getBlockedDuration(
          'login_$username',
        );
        final minutes = blockedDuration?.inMinutes ?? 30;
        throw Exception(
          'Terlalu banyak percobaan login. Akun diblokir selama $minutes menit. '
          'Silakan coba lagi nanti.',
        );
      }

      if (kDebugMode) {
        if (kDebugMode) print('📝 [SignInScreen] Attempting signin:');
        if (kDebugMode) print('   - Username: $username');
        if (kDebugMode) print('   - Password: ${password.replaceAll(RegExp(r'.'), '*')}');
        final remaining = rateLimiter.getRemainingAttempts(
          key: 'login_$username',
          maxAttempts: 5,
          window: const Duration(minutes: 15),
        );
        if (kDebugMode) print('   - Remaining attempts: $remaining');
      }

      await SupabaseService.signIn(username: username, password: password);

      // Reset rate limit on successful login (synchronous, no await needed)
      rateLimiter.resetAttempts('login_$username');

      // FIX: Run tracking in background — don't await so we don't delay navigation
      final currentUser = SupabaseService.currentUser;
      if (currentUser != null && currentUser.email != null) {
        // Fire-and-forget: security tracking should not block navigation
        SecurityEventNotificationService.resetFailedLoginCount().catchError((_) {});
        SecurityEventNotificationService.trackLogin(
          userId: currentUser.id,
          email: currentUser.email!,
        ).catchError((_) {});
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SignInScreen] Signin successful!');
      }

      if (mounted) {
        // Check if this is first login and show security warning
        final isFirstLogin = await SecurityEducationService.isFirstLogin();

        if (isFirstLogin) {
          // Show security warning dialog
          await SecurityWarningDialog.show(context);
          // Mark as shown
          await SecurityEducationService.markFirstLoginShown();
        }

        // Check if user has seen onboarding
        final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();

        if (!hasSeenOnboarding && mounted) {
          // Show onboarding for first-time users
          if (kDebugMode) {
            if (kDebugMode) print('📚 [SignInScreen] First-time user, showing onboarding');
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                onFinish: () {
                  // After onboarding, navigate based on role
                  AuthGuard.navigateByRole(context);
                },
              ),
            ),
          );
        } else {
          // FIX: `onAuthStateChange` in MyApp already handles navigation to /home.
          // Only navigate here if the auth listener hasn't fired yet (i.e., still mounted).
          // Using pushNamedAndRemoveUntil to be consistent with onAuthStateChange behaviour.
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignInScreen] Error: $e');
      }

      if (mounted) {
        String errorMessage = e.toString();

        // Clean up error message formatting
        errorMessage = errorMessage
            .replaceAll('Exception: ', '')
            .replaceAll('AuthException: ', '')
            .replaceAll('PostgrestException: ', '');

        // Track failed login attempts for invalid credentials
        if (errorMessage.contains('Invalid login') ||
            errorMessage.contains('Invalid password') ||
            errorMessage.contains('Invalid email or password')) {
          errorMessage = 'Invalid username or password';

          // Track failed login attempt
          await SecurityEventNotificationService.trackFailedLogin(
            email: username,
          );
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    if (kDebugMode) {
      if (kDebugMode) print('🔵 [SignInScreen] _handleBiometricLogin called');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Authenticate with biometric
      final authenticated = await BiometricAuthService.authenticate(
        reason: 'Login ke akun Anda',
      );

      if (!authenticated) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [SignInScreen] Biometric authentication failed');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Autentikasi biometrik gagal'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Get saved credentials
      final credentials = await BiometricAuthService.getSavedCredentials();
      if (credentials == null) {
        if (kDebugMode) {
          if (kDebugMode) print('❌ [SignInScreen] No saved credentials found');
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Kredensial tidak ditemukan. Silakan login manual.',
              ),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
        return;
      }

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SignInScreen] Credentials retrieved, attempting signin');
      }

      // Sign in with saved credentials
      await SupabaseService.signIn(
        username: credentials['username']!,
        password: credentials['password']!,
      );

      if (kDebugMode) {
        if (kDebugMode) print('✅ [SignInScreen] Biometric signin successful!');
      }

      if (mounted) {
        // Check if this is first login and show security warning
        final isFirstLogin = await SecurityEducationService.isFirstLogin();

        if (isFirstLogin) {
          // Show security warning dialog
          await SecurityWarningDialog.show(context);
          // Mark as shown
          await SecurityEducationService.markFirstLoginShown();
        }

        // Check if user has seen onboarding
        final hasSeenOnboarding = await OnboardingService.hasSeenOnboarding();

        if (!hasSeenOnboarding && mounted) {
          // Show onboarding for first-time users
          if (kDebugMode) {
            if (kDebugMode) {
              print(
              '📚 [SignInScreen] First-time user (biometric), showing onboarding',
            );
            }
          }

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => OnboardingScreen(
                onFinish: () {
                  // After onboarding, navigate based on role
                  AuthGuard.navigateByRole(context);
                },
              ),
            ),
          );
        } else {
          // Navigate based on user role
          if (mounted) {
            await AuthGuard.navigateByRole(context);
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignInScreen] Biometric login error: $e');
      }

      if (mounted) {
        String errorMessage = e.toString();

        // Clean up error message formatting
        errorMessage = errorMessage
            .replaceAll('Exception: ', '')
            .replaceAll('AuthException: ', '')
            .replaceAll('PostgrestException: ', '');

        // Handle specific error messages for biometric login
        if (errorMessage.contains('Username not found') ||
            errorMessage.contains('Invalid login') ||
            errorMessage.contains('Invalid password') ||
            errorMessage.contains('Account configuration error')) {
          errorMessage =
              'Kredensial tersimpan tidak valid. Silakan login manual.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleGoogleSignIn() async {
    if (kDebugMode) {
      if (kDebugMode) print('🔵 [SignInScreen] Google sign-in initiated');
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final success = await SocialAuthService.signInWithGoogle();

      if (!success) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Google sign-in failed. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('❌ [SignInScreen] Google sign-in error: $e');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Reset Password'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter your email to receive a password reset link'),
                const SizedBox(height: 16),
                TextField(
                  controller: emailController,
                  enabled: !isLoading,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setDialogState(() => isLoading = true);

                        final error =
                            await PasswordService.requestPasswordReset(
                              email: emailController.text.trim(),
                            );

                        if (mounted) {
                          Navigator.pop(context);

                          if (error == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Password reset link sent to your email (if registered)',
                                ),
                                backgroundColor: Colors.green,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                child: isLoading
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send Link'),
              ),
            ],
          );
        },
      ),
    );
  }
}
