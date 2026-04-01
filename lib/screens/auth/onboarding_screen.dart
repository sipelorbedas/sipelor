import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intro_slider/intro_slider.dart';
import '../../constants/app_colors.dart';
import '../../services/onboarding_service.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<ContentConfig> _buildSlides() {
    return [
      // Slide 1: Welcome
      ContentConfig(
        title: "Selamat Datang di SIPELOR BEDAS",
        description:
            "Sistem Informasi Pemesanan Lapangan Olahraga Berbasis Digital dan Smart. Booking lapangan jadi mudah dan cepat!",
        pathImage: "assets/images/sipelor.png",
        backgroundColor: Colors.white,
        styleTitle: GoogleFonts.nunitoSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        styleDescription: GoogleFonts.nunitoSans(
          fontSize: 16,
          color: AppColors.secondaryDark,
          height: 1.5,
        ),
        marginTitle: const EdgeInsets.only(top: 40, bottom: 20),
        marginDescription: const EdgeInsets.symmetric(horizontal: 30),
        maxLineTextDescription: 5,
        centerWidget: Container(
          margin: const EdgeInsets.only(top: 40, bottom: 30),
          child: Image.asset(
            "assets/images/sipelor.png",
            width: 200,
            height: 200,
          ),
        ),
      ),

      // Slide 2: Browse Venues
      ContentConfig(
        title: "Pilih Lapangan Favorit",
        description:
            "Jelajahi berbagai venue olahraga di Stadion Si Jalak Harupat. Lihat detail, foto, rating, dan harga dengan mudah.",
        pathImage: "assets/images/stadium_jalak_harupat.jpg",
        backgroundColor: Colors.white,
        styleTitle: GoogleFonts.nunitoSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        styleDescription: GoogleFonts.nunitoSans(
          fontSize: 16,
          color: AppColors.secondaryDark,
          height: 1.5,
        ),
        marginTitle: const EdgeInsets.only(top: 40, bottom: 20),
        marginDescription: const EdgeInsets.symmetric(horizontal: 30),
        maxLineTextDescription: 5,
        centerWidget: Container(
          margin: const EdgeInsets.only(top: 40, bottom: 30),
          child: Icon(Icons.stadium, size: 150, color: AppColors.primaryDark),
        ),
      ),

      // Slide 3: Easy Booking
      ContentConfig(
        title: "Booking Super Mudah",
        description:
            "Pilih tanggal, waktu, dan durasi sesuai kebutuhan. Upload bukti transfer dan tunggu konfirmasi admin.",
        pathImage: "assets/images/sipelor.png",
        backgroundColor: Colors.white,
        styleTitle: GoogleFonts.nunitoSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        styleDescription: GoogleFonts.nunitoSans(
          fontSize: 16,
          color: AppColors.secondaryDark,
          height: 1.5,
        ),
        marginTitle: const EdgeInsets.only(top: 40, bottom: 20),
        marginDescription: const EdgeInsets.symmetric(horizontal: 30),
        maxLineTextDescription: 5,
        centerWidget: Container(
          margin: const EdgeInsets.only(top: 40, bottom: 30),
          child: Icon(
            Icons.event_available,
            size: 150,
            color: AppColors.primaryDark,
          ),
        ),
      ),

      // Slide 4: E-Ticket
      ContentConfig(
        title: "Download E-Tiket",
        description:
            "Setelah booking dikonfirmasi, download E-Tiket langsung dari aplikasi. Tunjukkan saat datang ke venue!",
        pathImage: "assets/images/sipelor.png",
        backgroundColor: Colors.white,
        styleTitle: GoogleFonts.nunitoSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        styleDescription: GoogleFonts.nunitoSans(
          fontSize: 16,
          color: AppColors.secondaryDark,
          height: 1.5,
        ),
        marginTitle: const EdgeInsets.only(top: 40, bottom: 20),
        marginDescription: const EdgeInsets.symmetric(horizontal: 30),
        maxLineTextDescription: 5,
        centerWidget: Container(
          margin: const EdgeInsets.only(top: 40, bottom: 30),
          child: Icon(Icons.qr_code_2, size: 150, color: AppColors.primaryDark),
        ),
      ),

      // Slide 5: Chat & Review
      ContentConfig(
        title: "Chat & Beri Review",
        description:
            "Hubungi admin via chat jika ada pertanyaan. Setelah selesai, beri review untuk membantu pengguna lain!",
        pathImage: "assets/images/sipelor.png",
        backgroundColor: Colors.white,
        styleTitle: GoogleFonts.nunitoSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
        styleDescription: GoogleFonts.nunitoSans(
          fontSize: 16,
          color: AppColors.secondaryDark,
          height: 1.5,
        ),
        marginTitle: const EdgeInsets.only(top: 40, bottom: 20),
        marginDescription: const EdgeInsets.symmetric(horizontal: 30),
        maxLineTextDescription: 5,
        centerWidget: Container(
          margin: const EdgeInsets.only(top: 40, bottom: 30),
          child: Icon(
            Icons.chat_bubble,
            size: 150,
            color: AppColors.primaryDark,
          ),
        ),
      ),
    ];
  }

  void _onDonePressed() async {
    // Always mark onboarding as seen when done
    await OnboardingService.markOnboardingAsSeen();
    widget.onFinish();
  }

  void _onSkipPressed() async {
    // Always mark as seen when skipping
    await OnboardingService.markOnboardingAsSeen();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IntroSlider(
          key: UniqueKey(),
          listContentConfig: _buildSlides(),

          // Skip button configuration
          renderSkipBtn: Text(
            'Lewati',
            style: GoogleFonts.nunitoSans(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.secondaryDark,
            ),
          ),
          onSkipPress: _onSkipPressed,

          // Navigation buttons
          renderNextBtn: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              'Next',
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),

          renderDoneBtn: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(25),
            ),
            child: Text(
              'Mulai',
              style: GoogleFonts.nunitoSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          onDonePress: _onDonePressed,
          
          // Behavior
          isShowSkipBtn: true,
          isShowPrevBtn: false,
          isShowDoneBtn: true,
          isScrollable: true,
        ),
      ),
    );
  }
}
