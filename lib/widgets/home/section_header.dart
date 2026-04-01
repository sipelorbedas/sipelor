import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  const SectionHeader({
    super.key,
    required this.title,
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        GestureDetector(
          onTap: onSeeAll,
          child: Row(
            children: [
              Text(
                'Lihat Semua',
                style: GoogleFonts.mulish(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 5),
              SvgPicture.asset(
                'assets/icons/arrow_right_circle.svg',
                width: 15,
                height: 15,
                colorFilter: const ColorFilter.mode(
                  AppColors.primaryDark,
                  BlendMode.srcIn,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
