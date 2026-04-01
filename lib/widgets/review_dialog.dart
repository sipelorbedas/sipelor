import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../services/supabase_service.dart';

class ReviewDialog extends StatefulWidget {
  final String bookingId; // UUID of booking
  final String bookingCode; // Display code like BOOK001
  final String venueName;
  final Function() onReviewSubmitted;

  const ReviewDialog({
    super.key,
    required this.bookingId,
    required this.bookingCode,
    required this.venueName,
    required this.onReviewSubmitted,
  });

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Silakan pilih rating terlebih dahulu',
            style: GoogleFonts.mulish(),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await SupabaseService.createReview(
        bookingId: widget.bookingId,
        rating: _rating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onReviewSubmitted();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Terima kasih atas review Anda!',
              style: GoogleFonts.mulish(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      
      if (mounted) {
        // Show user-friendly error message
        String errorMessage = 'Gagal mengirim review';
        
        final errorString = e.toString();
        if (errorString.contains('RLS policy') || 
            errorString.contains('permission') ||
            errorString.contains('contact administrator')) {
          errorMessage = 'Sistem review belum dikonfigurasi. Silakan hubungi administrator.';
        } else if (errorString.contains('already reviewed')) {
          errorMessage = 'Anda sudah memberikan review untuk booking ini.';
        } else if (errorString.contains('completed bookings')) {
          errorMessage = 'Hanya booking yang selesai yang bisa di-review.';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMessage,
              style: GoogleFonts.mulish(),
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.rate_review,
                    color: Color.fromARGB(255, 0, 113, 72),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Berikan Review',
                        style: GoogleFonts.mulish(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.bookingCode,
                        style: GoogleFonts.mulish(
                          fontSize: 12,
                          color: AppColors.secondaryDark,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Venue Name
            Text(
              widget.venueName,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 20),

            // Rating Section
            Text(
              'Rating',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starIndex = index + 1;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _rating = starIndex;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      starIndex <= _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: starIndex <= _rating
                          ? Colors.amber
                          : Colors.grey.shade300,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 20),

            // Comment Section
            Text(
              'Komentar (Opsional)',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentController,
              maxLines: 4,
              maxLength: 500,
              decoration: InputDecoration(
                hintText: 'Bagikan pengalaman Anda...',
                hintStyle: GoogleFonts.mulish(
                  fontSize: 14,
                  color: Colors.grey.shade400,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color.fromARGB(255, 0, 113, 72),
                    width: 2,
                  ),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
              style: GoogleFonts.mulish(fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Text(
                        'Kirim Review',
                        style: GoogleFonts.mulish(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
