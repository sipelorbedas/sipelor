import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Heading styles
  static TextStyle headingLarge = GoogleFonts.poppins(
    fontSize: 40.33,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static TextStyle headingMedium = GoogleFonts.poppins(
    fontSize: 17.92,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryText,
  );

  // Label styles
  static TextStyle labelText = GoogleFonts.poppins(
    fontSize: 14.33,
    fontWeight: FontWeight.w500,
    color: AppColors.labelText,
  );

  static TextStyle subLabelText = GoogleFonts.poppins(
    fontSize: 11.33,
    fontWeight: FontWeight.w500,
    color: AppColors.labelText,
  );

  // Input text style
  static TextStyle inputText = GoogleFonts.poppins(
    fontSize: 14.33,
    fontWeight: FontWeight.w500,
    color: AppColors.labelText,
  );

  // Secondary text style
  static TextStyle secondaryHeading = GoogleFonts.poppins(
    fontSize: 14.33,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  // Password strength indicator
  static TextStyle strengthText = GoogleFonts.poppins(
    fontSize: 10.45,
    fontWeight: FontWeight.w500,
    color: AppColors.successText,
  );

  // Button text style
  static TextStyle buttonText = GoogleFonts.poppins(
    fontSize: 17.92,
    fontWeight: FontWeight.w500,
    color: Colors.white,
  );

  // Divider text style
  static TextStyle dividerText = GoogleFonts.poppins(
    fontSize: 11.25,
    fontWeight: FontWeight.w500,
    color: AppColors.secondaryText,
  );

  // Forgot password text style
  static TextStyle forgotPasswordText = GoogleFonts.poppins(
    fontSize: 11.33,
    fontWeight: FontWeight.w500,
    color: AppColors.labelText,
  );

  // Subtitle text style
  static TextStyle subtitleText = GoogleFonts.poppins(
    fontSize: 14.33,
    fontWeight: FontWeight.w500,
    color: AppColors.labelText,
  );

  // Light theme heading styles
  static TextStyle lightHeadingLarge = GoogleFonts.poppins(
    fontSize: 40.33,
    fontWeight: FontWeight.w600,
    color: AppColors.darkPrimaryText,
  );

  static TextStyle lightHeadingMedium = GoogleFonts.poppins(
    fontSize: 17.92,
    fontWeight: FontWeight.w500,
    color: AppColors.darkPrimaryText,
  );

  // Light theme label styles
  static TextStyle lightLabelText = GoogleFonts.poppins(
    fontSize: 14.33,
    fontWeight: FontWeight.w500,
    color: AppColors.darkLabelText,
  );

  static TextStyle lightSubLabelText = GoogleFonts.poppins(
    fontSize: 11.33,
    fontWeight: FontWeight.w500,
    color: AppColors.darkLabelText,
  );

  // Light theme input text style
  static TextStyle lightInputText = GoogleFonts.poppins(
    fontSize: 14.33,
    fontWeight: FontWeight.w500,
    color: AppColors.darkLabelText,
  );

  // Light theme secondary text style
  static TextStyle lightSecondaryHeading = GoogleFonts.poppins(
    fontSize: 14.33,
    fontWeight: FontWeight.w500,
    color: AppColors.darkSecondaryText,
  );

  // Light theme divider text style
  static TextStyle lightDividerText = GoogleFonts.poppins(
    fontSize: 11.25,
    fontWeight: FontWeight.w500,
    color: AppColors.darkSecondaryText,
  );

  // Light theme forgot password text style
  static TextStyle lightForgotPasswordText = GoogleFonts.poppins(
    fontSize: 11.33,
    fontWeight: FontWeight.w500,
    color: AppColors.darkLabelText,
  );
}
