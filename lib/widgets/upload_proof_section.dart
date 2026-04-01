import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

class UploadProofSection extends StatelessWidget {
  final String? selectedFileName;
  final VoidCallback onSelectFile;
  final VoidCallback? onUpload;
  final bool isUploading;

  const UploadProofSection({
    super.key,
    this.selectedFileName,
    required this.onSelectFile,
    this.onUpload,
    this.isUploading = false,
  });

  @override
  Widget build(BuildContext context) {
    final hasFile = selectedFileName != null && selectedFileName!.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Upload Bukti Pembayaran',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 12),
          
          // Upload area
          GestureDetector(
            onTap: onSelectFile,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.lightInputBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.borderGray,
                  width: 1.5,
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    hasFile ? Icons.insert_drive_file : Icons.upload_file,
                    size: 48,
                    color: hasFile ? AppColors.primaryYellow : AppColors.primaryDark.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasFile ? selectedFileName! : 'Belum ada file dipilih',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap untuk memilih file',
                    style: GoogleFonts.mulish(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.darkLabelText,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (hasFile) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isUploading ? null : onUpload,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryYellow,
                  foregroundColor: AppColors.primaryDark,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 0,
                ),
                child: isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryDark,
                          ),
                        ),
                      )
                    : Text(
                        'Upload',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
