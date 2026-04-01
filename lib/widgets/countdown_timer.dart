import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class CountdownTimer extends StatefulWidget {
  final DateTime deadline;
  final VoidCallback? onExpired;

  const CountdownTimer({
    super.key,
    required this.deadline,
    this.onExpired,
  });

  @override
  State<CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<CountdownTimer> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final remaining = widget.deadline.difference(now);

    if (remaining.isNegative) {
      setState(() {
        _remaining = Duration.zero;
      });
      _timer?.cancel();
      widget.onExpired?.call();
    } else {
      setState(() {
        _remaining = remaining;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatTimeUnit(int value) {
    return value.toString().padLeft(2, '0');
  }

  Widget _buildTimeBox(String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        value,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.timerBg,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primaryDark, width: 2),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    size: 12,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  'Lakukan pembayaran dalam',
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.primaryDark,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                _buildTimeBox(_formatTimeUnit(hours)),
                const SizedBox(width: 1),
                _buildTimeBox(_formatTimeUnit(minutes)),
                const SizedBox(width: 1),
                _buildTimeBox(_formatTimeUnit(seconds)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
