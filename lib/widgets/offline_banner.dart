import 'dart:async';
import 'package:flutter/material.dart';
import '../services/connectivity_service.dart';
import '../services/offline_cache_service.dart';

/// Banner yang muncul otomatis saat koneksi internet terputus.
///
/// Menampilkan pesan offline + waktu terakhir data disinkronkan.
/// Hilang otomatis saat koneksi kembali.
///
/// Cara pakai — cukup tambahkan ke Column di atas konten:
/// ```dart
/// Column(
///   children: [
///     const OfflineBanner(),
///     Expanded(child: yourContent),
///   ],
/// )
/// ```
class OfflineBanner extends StatefulWidget {
  /// Key cache untuk menampilkan waktu sync terakhir (opsional)
  final String? cacheKey;

  const OfflineBanner({super.key, this.cacheKey});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late bool _isOnline;
  late AnimationController _animController;
  late Animation<double> _heightAnim;
  StreamSubscription<bool>? _sub;

  @override
  void initState() {
    super.initState();
    _isOnline = ConnectivityService().isOnline;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeInOut,
    );

    if (!_isOnline) _animController.forward();

    _sub = ConnectivityService().onConnectivityChanged.listen((online) {
      if (!mounted) return;
      setState(() => _isOnline = online);
      if (online) {
        _animController.reverse();
      } else {
        _animController.forward();
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _animController.dispose();
    super.dispose();
  }

  String get _lastSync {
    if (widget.cacheKey == null) return '';
    return OfflineCacheService().getLastSyncDescription(widget.cacheKey!);
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _heightAnim,
      axisAlignment: -1,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF5D4037), // coklat gelap — tidak konflik dgn warna brand
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(
                Icons.wifi_off_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Tidak ada koneksi internet',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    if (widget.cacheKey != null)
                      Text(
                        'Menampilkan data tersimpan · $_lastSync',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ),
              // Dot pulsing indicator
              _PulsingDot(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dot merah pulsing sebagai indikator offline
class _PulsingDot extends StatefulWidget {
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 10,
        height: 10,
        decoration: const BoxDecoration(
          color: Color(0xFFFF5252),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
