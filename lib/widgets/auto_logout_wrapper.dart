import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auto_logout_service.dart';

class AutoLogoutWrapper extends StatefulWidget {
  final Widget child;

  const AutoLogoutWrapper({
    super.key,
    required this.child,
  });

  @override
  State<AutoLogoutWrapper> createState() => _AutoLogoutWrapperState();
}

class _AutoLogoutWrapperState extends State<AutoLogoutWrapper>
    with WidgetsBindingObserver {
  final AutoLogoutService _autoLogoutService = AutoLogoutService();
  // FIX: Debounce pointer events agar onUserActivity tidak dipanggil ribuan kali saat scroll
  Timer? _debounceTimer;
  static const _kDebounceDelay = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize auto logout service after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoLogoutService.initialize(context);
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _autoLogoutService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Reset timer when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      _autoLogoutService.onUserActivity();
    }
  }

  void _handleUserInteraction() {
    // Debounce: batalkan timer sebelumnya, buat yang baru
    // Mencegah ribuan panggilan onUserActivity saat scroll/drag
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_kDebounceDelay, () {
      _autoLogoutService.onUserActivity();
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Hapus Listener wrapper — GestureDetector + NotificationListener sudah
    // mencakup semua interaksi (tap, pan, scroll). Listener di dalam GestureDetector
    // menyebabkan _handleUserInteraction() dipanggil dua kali per event (redundant).
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: _handleUserInteraction,
      onPanDown: (_) => _handleUserInteraction(),
      onScaleStart: (_) => _handleUserInteraction(),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          _handleUserInteraction();
          return false;
        },
        child: widget.child,
      ),
    );
  }
}
