import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../constants/app_colors.dart';

class SocialButton extends StatelessWidget {
  final String iconPath;
  final VoidCallback onPressed;
  final bool isLightTheme;

  const SocialButton({
    super.key,
    required this.iconPath,
    required this.onPressed,
    this.isLightTheme = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isLightTheme
        ? Color(0xFFF5F5F5)
        : AppColors.googleBg;
    final borderColor = isLightTheme
        ? AppColors.darkLabelText.withOpacity(0.2)
        : AppColors.inputBg;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 58,
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Center(
          child: iconPath.endsWith('.svg')
              ? SvgPicture.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                )
              : Image.asset(
                  iconPath,
                  width: 24,
                  height: 24,
                ),
        ),
      ),
    );
  }
}
