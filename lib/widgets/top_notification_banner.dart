import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:vibration/vibration.dart';

/// Custom notification banner that slides from top
class TopNotificationBanner {
  static OverlayEntry? _currentOverlay;
  static bool _isShowing = false;

  /// Show a success notification banner
  static void showSuccess({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
    bool vibrate = true,
  }) {
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: const LinearGradient(
        colors: [
          Color.fromARGB(255, 0, 113, 72),
          Color.fromARGB(255, 0, 117, 164),
        ],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      iconColor: Colors.white,
      onTap: onTap,
      duration: duration,
      playSound: playSound,
      vibrate: vibrate,
    );
  }

  /// Show a completed/neutral notification banner (gray gradient)
  static void showCompleted({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
    bool vibrate = true,
  }) {
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.check_circle,
      backgroundColor: const LinearGradient(
        colors: [Color(0xFF616161), Color(0xFF9E9E9E)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      iconColor: Colors.white,
      onTap: onTap,
      duration: duration,
      playSound: playSound,
      vibrate: vibrate,
    );
  }

  /// Show an info notification banner
  static void showInfo({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
    bool vibrate = true,
  }) {
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.info,
      backgroundColor: const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      iconColor: Colors.white,
      onTap: onTap,
      duration: duration,
      playSound: playSound,
      vibrate: vibrate,
    );
  }

  /// Show a warning notification banner
  static void showWarning({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
    bool vibrate = true,
  }) {
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.warning,
      backgroundColor: const LinearGradient(
        colors: [Color(0xFFFF9800), Color(0xFFF57C00)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      iconColor: Colors.white,
      onTap: onTap,
      duration: duration,
      playSound: playSound,
      vibrate: vibrate,
    );
  }

  /// Show an error notification banner
  static void showError({
    required BuildContext context,
    required String title,
    required String message,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
    bool vibrate = true,
  }) {
    _show(
      context: context,
      title: title,
      message: message,
      icon: Icons.error,
      backgroundColor: const LinearGradient(
        colors: [Color(0xFFF44336), Color(0xFFD32F2F)],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      ),
      iconColor: Colors.white,
      onTap: onTap,
      duration: duration,
      playSound: playSound,
      vibrate: vibrate,
    );
  }

  static void _show({
    required BuildContext context,
    required String title,
    required String message,
    required IconData icon,
    required Gradient backgroundColor,
    required Color iconColor,
    VoidCallback? onTap,
    Duration duration = const Duration(seconds: 4),
    bool playSound = true,
    bool vibrate = true,
  }) {
    // Dismiss any existing notification
    dismiss();

    if (_isShowing) return;
    _isShowing = true;

    // Play notification sound and vibration
    _playNotificationFeedback(playSound: playSound, vibrate: vibrate);

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _NotificationBannerWidget(
        title: title,
        message: message,
        icon: icon,
        backgroundColor: backgroundColor,
        iconColor: iconColor,
        onTap: () {
          dismiss();
          onTap?.call();
        },
        onDismiss: dismiss,
      ),
    );

    _currentOverlay = overlayEntry;
    overlay.insert(overlayEntry);

    // Auto dismiss after duration
    Future.delayed(duration, () {
      dismiss();
    });
  }

  /// Play notification sound and vibration feedback
  static Future<void> _playNotificationFeedback({
    bool playSound = true,
    bool vibrate = true,
  }) async {
    try {
      // Play system notification sound
      if (playSound) {
        await FlutterRingtonePlayer().playNotification();
      }

      // Vibrate device
      if (vibrate) {
        // Check if device has vibration capability
        final hasVibrator = await Vibration.hasVibrator() ?? false;
        if (hasVibrator) {
          // Short vibration pattern: vibrate for 200ms
          await Vibration.vibrate(duration: 200);
        }
      }
    } catch (e) {
      if (kDebugMode) print('❌ [Notification] Error playing feedback: $e');
      // Silently fail - notification should still show even if sound/vibration fails
    }
  }

  /// Dismiss the current notification
  static void dismiss() {
    if (_currentOverlay != null) {
      _currentOverlay?.remove();
      _currentOverlay = null;
      _isShowing = false;
    }
  }
}

class _NotificationBannerWidget extends StatefulWidget {
  final String title;
  final String message;
  final IconData icon;
  final Gradient backgroundColor;
  final Color iconColor;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const _NotificationBannerWidget({
    required this.title,
    required this.message,
    required this.icon,
    required this.backgroundColor,
    required this.iconColor,
    this.onTap,
    this.onDismiss,
  });

  @override
  State<_NotificationBannerWidget> createState() =>
      _NotificationBannerWidgetState();
}

class _NotificationBannerWidgetState extends State<_NotificationBannerWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleDismiss() async {
    await _controller.reverse();
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.transparent,
                child: GestureDetector(
                  onTap: widget.onTap,
                  onVerticalDragEnd: (details) {
                    // Swipe up to dismiss
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity! < -200) {
                      _handleDismiss();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: widget.backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Stack(
                        children: [
                          // Content
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    widget.icon,
                                    color: widget.iconColor,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),

                                // Text content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        widget.title,
                                        style: GoogleFonts.mulish(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        widget.message,
                                        style: GoogleFonts.mulish(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white.withOpacity(0.95),
                                          height: 1.4,
                                        ),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),

                                // Close button
                                IconButton(
                                  onPressed: _handleDismiss,
                                  icon: Icon(
                                    Icons.close,
                                    color: Colors.white.withOpacity(0.8),
                                    size: 20,
                                  ),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ),

                          // Tap indicator hint (subtle arrow)
                          if (widget.onTap != null)
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Icon(
                                Icons.touch_app,
                                color: Colors.white.withOpacity(0.3),
                                size: 16,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
