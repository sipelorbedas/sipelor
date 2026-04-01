import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/booking_expiration_service.dart';

/// Widget to display countdown timer for booking payment
class BookingExpirationTimer extends StatefulWidget {
  final DateTime bookingCreatedAt;
  final VoidCallback? onExpired;

  const BookingExpirationTimer({
    super.key,
    required this.bookingCreatedAt,
    this.onExpired,
  });

  @override
  State<BookingExpirationTimer> createState() => _BookingExpirationTimerState();
}

class _BookingExpirationTimerState extends State<BookingExpirationTimer> {
  Timer? _timer;
  Duration _remainingTime = Duration.zero;
  bool _hasExpired = false;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateRemainingTime() {
    setState(() {
      _remainingTime = BookingExpirationService.getRemainingTime(widget.bookingCreatedAt);
      
      // Check if expired
      if (_remainingTime == Duration.zero && !_hasExpired) {
        _hasExpired = true;
        widget.onExpired?.call();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        _updateRemainingTime();
        
        // Stop timer when expired
        if (_hasExpired) {
          timer.cancel();
        }
      }
    });
  }

  Color _getTimerColor() {
    final totalSeconds = _remainingTime.inSeconds;
    
    if (totalSeconds <= 0) {
      return Colors.red;
    } else if (totalSeconds <= 300) { // 5 minutes or less
      return Colors.orange;
    } else {
      return const Color.fromARGB(255, 0, 113, 72);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedTime = BookingExpirationService.formatRemainingTime(_remainingTime);
    final timerColor = _getTimerColor();
    final isExpired = _hasExpired || _remainingTime == Duration.zero;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: timerColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: timerColor,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isExpired ? Icons.timer_off : Icons.timer,
            size: 20,
            color: timerColor,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isExpired ? 'Waktu Habis' : 'Sisa Waktu Pembayaran',
                style: GoogleFonts.mulish(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isExpired ? '00:00' : formattedTime,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: timerColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
