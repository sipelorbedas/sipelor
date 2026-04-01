import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../../constants/app_colors.dart';
import '../../screens/venue/venue_list_screen.dart';
import '../../utils/optimized_image.dart';

class HomeHeader extends StatefulWidget {
  final String userName;
  final String? avatarUrl;

  const HomeHeader({
    super.key,
    required this.userName,
    this.avatarUrl,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    // Request microphone permission at runtime before initializing speech
    final micStatus = await Permission.microphone.request();
    if (!micStatus.isGranted) {
      // Permission denied — leave _speechAvailable = false
      return;
    }

    final available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          if (mounted) setState(() => _isListening = false);
        }
      },
      onError: (error) {
        if (mounted) setState(() => _isListening = false);
      },
    );
    if (mounted) setState(() => _speechAvailable = available);
  }

  void _navigateToSearch({String initialQuery = ''}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VenueListScreen(
          initialQuery: initialQuery,
          autoFocus: initialQuery.isEmpty,
        ),
      ),
    );
  }

  Future<void> _startVoiceSearch() async {
    // If not yet available, try to initialize again (user may have just granted permission)
    if (!_speechAvailable) {
      await _initSpeech();
    }

    if (!_speechAvailable) {
      if (!mounted) return;
      final micStatus = await Permission.microphone.status;
      final message = micStatus.isPermanentlyDenied
          ? 'Izin mikrofon ditolak. Aktifkan di Pengaturan > Aplikasi > SIPELOR BEDAS.'
          : micStatus.isDenied
              ? 'Izin mikrofon diperlukan untuk pencarian suara.'
              : 'Pencarian suara tidak tersedia di perangkat ini.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          action: micStatus.isPermanentlyDenied
              ? SnackBarAction(
                  label: 'Pengaturan',
                  textColor: Colors.white,
                  onPressed: openAppSettings,
                )
              : null,
        ),
      );
      return;
    }

    if (_isListening) {
      await _speech.stop();
      if (mounted) setState(() => _isListening = false);
      return;
    }

    // Show listening bottom sheet
    _showListeningSheet();

    setState(() => _isListening = true);
    await _speech.listen(
      onResult: (result) {
        if (result.finalResult && result.recognizedWords.isNotEmpty) {
          final query = result.recognizedWords;
          _speech.stop();
          if (mounted) {
            setState(() => _isListening = false);
            Navigator.pop(context); // close bottom sheet
            _navigateToSearch(initialQuery: query);
          }
        }
      },
      localeId: 'id_ID',
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _showListeningSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _ListeningSheet(
        onCancel: () {
          _speech.stop();
          if (mounted) setState(() => _isListening = false);
        },
      ),
    ).then((_) {
      if (_isListening) {
        _speech.stop();
        if (mounted) setState(() => _isListening = false);
      }
    });
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.headerBg,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.headerBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              // User & Notification Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                          ? OptimizedAvatar(
                              imageUrl: widget.avatarUrl!,
                              radius: 18,
                            )
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Image.asset(
                                'assets/images/user_avatar.png',
                                width: 36,
                                height: 36,
                                fit: BoxFit.cover,
                              ),
                            ),
                      const SizedBox(width: 10),
                      Text(
                        'Halo, ${widget.userName}',
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Mau sewa lapangan dimana ?',
                style: GoogleFonts.mulish(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 15),
              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.searchBarBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    // Search icon — tap opens VenueListScreen
                    GestureDetector(
                      onTap: () => _navigateToSearch(),
                      child: SvgPicture.asset(
                        'assets/icons/search_icon.svg',
                        width: 19,
                        height: 18,
                        colorFilter: ColorFilter.mode(
                          Colors.black.withOpacity(0.74),
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Placeholder text — tap opens VenueListScreen
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _navigateToSearch(),
                        child: Text(
                          'Cari Lapangan.....',
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.placeholderText,
                          ),
                        ),
                      ),
                    ),
                    // Mic icon — tap starts voice search
                    GestureDetector(
                      onTap: _startVoiceSearch,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isListening
                            ? Icon(
                                Icons.mic,
                                key: const ValueKey('mic_active'),
                                size: 24,
                                color: Colors.red.shade400,
                              )
                            : SvgPicture.asset(
                                'assets/icons/voice_icon.svg',
                                key: const ValueKey('mic_idle'),
                                width: 24,
                                height: 24,
                                colorFilter: ColorFilter.mode(
                                  Colors.black.withOpacity(0.74),
                                  BlendMode.srcIn,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Listening bottom sheet ────────────────────────────
class _ListeningSheet extends StatelessWidget {
  final VoidCallback onCancel;
  const _ListeningSheet({required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pulsing mic icon
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.9, end: 1.1),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeInOut,
            builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.mic, size: 36, color: Colors.red.shade400),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Sedang mendengarkan...',
            style: GoogleFonts.mulish(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ucapkan nama lapangan yang ingin dicari',
            style: GoogleFonts.mulish(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              onCancel();
              Navigator.pop(context);
            },
            child: Text(
              'Batal',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
