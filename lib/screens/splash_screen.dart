import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'user/home_screen.dart';

/// Branded splash screen yang muncul segera setelah Flutter engine siap.
///
/// Flow:
///  1. Logo SIPELOR muncul dengan animasi fade + scale
///  2. Nama app dan tagline muncul dengan delay
///  3. Loading dots beranimasi
///  4. Setelah [_kMinDisplayDuration], navigate ke HomeScreen atau AuthScreen
///     berdasarkan status auth Supabase
///
/// Native splash (Android launch_background.xml) menggunakan warna yang sama
/// (#1A1A2E) sehingga transisi native → Flutter tampak mulus tanpa flash putih.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Waktu minimum splash ditampilkan agar animasi sempat terlihat
  static const _kMinDisplayDuration = Duration(milliseconds: 2400);

  // Warna yang sama dengan native splash agar tidak ada flash
  static const _kBgColor = Color(0xFF1A1A2E);
  static const _kAccent = Color(0xFF7C3AED); // deep purple
  static const _kSubAccent = Color(0xFFE94560); // red accent

  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _dotsController;

  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;
  late Animation<double> _taglineFade;

  @override
  void initState() {
    super.initState();

    // Paksa status bar & navigation bar gelap agar menyatu
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        systemNavigationBarColor: _kBgColor,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
    );

    _setupAnimations();
    _startSequence();
  }

  void _setupAnimations() {
    // Logo: fade-in + scale dari 0.6 → 1.0
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _logoFade = CurvedAnimation(parent: _logoController, curve: Curves.easeOut);
    _logoScale = Tween<double>(begin: 0.65, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    // Nama + tagline: slide-up + fade-in
    _textController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _textFade = CurvedAnimation(parent: _textController, curve: Curves.easeOut);
    _textSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _textController, curve: Curves.easeOutCubic),
        );

    _taglineFade = CurvedAnimation(
      parent: _textController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );

    // Dots: repeat animasi loading
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  Future<void> _startSequence() async {
    // Step 1: Logo muncul
    await Future.delayed(const Duration(milliseconds: 200));
    if (mounted) _logoController.forward();

    // Step 2: Teks muncul setelah logo selesai
    await Future.delayed(const Duration(milliseconds: 700));
    if (mounted) _textController.forward();

    // Step 3: Tunggu durasi minimum splash
    await Future.delayed(_kMinDisplayDuration);

    // Step 4: Navigate ke halaman yang sesuai
    if (mounted) _navigateNext();
  }

  void _navigateNext() {
    // Always navigate to HomeScreen first after splash
    _pushReplacement(const HomeScreen());
  }

  void _pushReplacement(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, animation, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBgColor,
      body: Stack(
        children: [
          // Background gradient halus
          _buildBackground(),

          // Konten utama
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Logo
                _buildLogo(),

                const SizedBox(height: 28),

                // Nama app + tagline
                _buildAppName(),

                const Spacer(flex: 3),

                // Loading dots
                _buildLoadingDots(),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.2),
          radius: 1.2,
          colors: [
            Color(0xFF2D1B69), // ungu tua di tengah
            Color(0xFF1A1A2E), // gelap di tepi
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return FadeTransition(
      opacity: _logoFade,
      child: ScaleTransition(
        scale: _logoScale,
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _kAccent.withOpacity(0.4),
                blurRadius: 40,
                spreadRadius: 8,
              ),
              BoxShadow(
                color: _kSubAccent.withOpacity(0.2),
                blurRadius: 60,
                spreadRadius: 2,
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Image.asset('assets/images/sipelor.png', fit: BoxFit.contain),
        ),
      ),
    );
  }

  Widget _buildAppName() {
    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textFade,
        child: Column(
          children: [
            // Nama utama
            ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0xFFFFFFFF), Color(0xFFBBB0FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
              child: const Text(
                'SIPELOR BEDAS',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 3,
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Divider tipis berwarna
            Container(
              width: 60,
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [_kAccent, _kSubAccent]),
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            const SizedBox(height: 10),

            // Tagline
            FadeTransition(
              opacity: _taglineFade,
              child: const Text(
                'Sistem Penyewaan Lapangan Olahraga\nDISPORA Kabupaten Bandung',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white54,
                  height: 1.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingDots() {
    return AnimatedBuilder(
      animation: _dotsController,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            // Setiap dot punya phase berbeda (0, 1/3, 2/3)
            final phase = ((_dotsController.value + i / 3) % 1.0);
            final scale = 0.5 + 0.5 * _dotCurve(phase);
            final opacity = 0.3 + 0.7 * _dotCurve(phase);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: i == 1 ? _kSubAccent : _kAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  /// Kurva sinus untuk animasi bouncing dots
  double _dotCurve(double t) {
    // Puncak di t=0, menurun ke tepi
    return (1.0 - (2 * t - 1).abs()).clamp(0.0, 1.0);
  }
}
