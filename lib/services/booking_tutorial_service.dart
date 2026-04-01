import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import 'onboarding_service.dart';

/// Service to show spotlight tutorial for first booking
class BookingTutorialService {
  static TutorialCoachMark? _tutorialCoachMark;

  /// Show tutorial for booking confirmation screen
  static Future<void> showBookingTutorial({
    required BuildContext context,
    required GlobalKey dateKey,
    required GlobalKey timeKey,
    required GlobalKey durationKey,
    required GlobalKey confirmButtonKey,
  }) async {
    // Check if user has already seen the tutorial
    final hasSeen = await OnboardingService.hasSeenBookingTutorial();
    if (hasSeen) {
      if (kDebugMode) print('📚 User has already seen booking tutorial, skipping');
      return;
    }

    // Small delay to ensure widgets are rendered
    await Future.delayed(const Duration(milliseconds: 500));

    final targets = <TargetFocus>[];

    // Target 1: Date selection
    targets.add(
      TargetFocus(
        identify: "date-select",
        keyTarget: dateKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📅 Pilih Tanggal',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap untuk memilih tanggal booking. Tanggal yang tidak tersedia akan ditandai merah.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 2: Time selection
    targets.add(
      TargetFocus(
        identify: "time-select",
        keyTarget: timeKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏰ Pilih Waktu',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Pilih jam mulai booking. Sistem akan menampilkan waktu yang tersedia.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 3: Duration selection
    targets.add(
      TargetFocus(
        identify: "duration-select",
        keyTarget: durationKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏱️ Pilih Durasi',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tentukan berapa jam Anda ingin booking. Harga akan otomatis dihitung.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 4: Confirm button
    targets.add(
      TargetFocus(
        identify: "confirm-button",
        keyTarget: confirmButtonKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Konfirmasi Booking',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Setelah semua terisi, tap tombol ini untuk lanjut ke pembayaran. Upload bukti transfer untuk konfirmasi.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primaryDark,
      paddingFocus: 10,
      opacityShadow: 0.8,
      textSkip: "LEWATI",
      textStyleSkip: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      onFinish: () {
        if (kDebugMode) print('📚 Booking tutorial finished');
        OnboardingService.markBookingTutorialAsSeen();
      },
      onSkip: () {
        if (kDebugMode) print('📚 Booking tutorial skipped');
        OnboardingService.markBookingTutorialAsSeen();
        return true;
      },
    );

    if (context.mounted) {
      _tutorialCoachMark?.show(context: context);
    }
  }

  /// Show tutorial for venue detail screen
  static Future<void> showVenueDetailTutorial({
    required BuildContext context,
    required GlobalKey imageKey,
    required GlobalKey ratingKey,
    required GlobalKey bookButtonKey,
  }) async {
    // Check if user has already seen the tutorial
    final hasSeen = await OnboardingService.hasSeenBookingTutorial();
    if (hasSeen) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 500));

    final targets = <TargetFocus>[];

    // Target 1: Image gallery
    targets.add(
      TargetFocus(
        identify: "image-gallery",
        keyTarget: imageKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📸 Galeri Foto',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Swipe untuk melihat foto-foto venue dari berbagai sudut.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 2: Rating & reviews
    targets.add(
      TargetFocus(
        identify: "rating-section",
        keyTarget: ratingKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⭐ Rating & Review',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Lihat rating dan review dari pengguna lain untuk membantu keputusan Anda.',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    // Target 3: Book button
    targets.add(
      TargetFocus(
        identify: "book-button",
        keyTarget: bookButtonKey,
        alignSkip: Alignment.topRight,
        shape: ShapeLightFocus.RRect,
        radius: 10,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            builder: (context, controller) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎯 Booking Sekarang',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Tap tombol ini untuk mulai proses booking. Mudah dan cepat!',
                      style: GoogleFonts.nunitoSans(
                        fontSize: 14,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );

    _tutorialCoachMark = TutorialCoachMark(
      targets: targets,
      colorShadow: AppColors.primaryDark,
      paddingFocus: 10,
      opacityShadow: 0.8,
      textSkip: "LEWATI",
      textStyleSkip: GoogleFonts.nunitoSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
      onFinish: () {
        OnboardingService.markBookingTutorialAsSeen();
      },
      onSkip: () {
        OnboardingService.markBookingTutorialAsSeen();
        return true;
      },
    );

    if (context.mounted) {
      _tutorialCoachMark?.show(context: context);
    }
  }

  /// Dispose tutorial
  static void dispose() {
    _tutorialCoachMark = null;
  }
}
