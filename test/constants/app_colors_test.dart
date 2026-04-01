import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/constants/app_colors.dart';

void main() {
  group('AppColors', () {
    test('background colors should be defined', () {
      expect(AppColors.darkBg, const Color(0xFF151316));
      expect(AppColors.whiteBg, const Color(0xFFFFFFFF));
      expect(AppColors.inputBg, const Color(0xFF2A2A2E));
      expect(AppColors.lightInputBg, const Color(0xFFF5F5F5));
    });

    test('home screen colors should be defined', () {
      expect(AppColors.screenBg, const Color(0xFFF5F5F5));
      expect(AppColors.headerBg, const Color(0xFF000000));
      expect(AppColors.primaryDark, const Color(0xFF211A2C));
      expect(AppColors.secondaryDark, const Color(0xFF28293F));
      expect(AppColors.categoryBg, const Color(0xFFD9D9D9));
      expect(AppColors.placeholderText, const Color(0x61000000));
      expect(AppColors.navInactive, const Color(0x80211A2C));
      expect(AppColors.searchBarBg, const Color(0xFFF0F0F0));
    });

    test('text colors should be defined', () {
      expect(AppColors.labelText, const Color(0xFFA4A4A4));
      expect(AppColors.primaryText, const Color(0xFFEFEFEF));
      expect(AppColors.secondaryText, const Color(0xFFB6B6B6));
      expect(AppColors.successText, const Color(0xFF9FDBA1));
    });

    test('light theme text colors should be defined', () {
      expect(AppColors.darkLabelText, const Color(0xFF666666));
      expect(AppColors.darkPrimaryText, const Color(0xFF1A1A1A));
      expect(AppColors.darkSecondaryText, const Color(0xFF555555));
    });

    test('password strength colors should be defined', () {
      expect(AppColors.strongPassword, const Color(0xFF4CAF50));
      expect(AppColors.mediumPassword, const Color(0xFF009606));
      expect(AppColors.weakPassword, const Color(0xFF8F8F8F));
    });

    test('gradient colors should be defined', () {
      expect(AppColors.gradientStart, const Color(0xFFD946EF));
      expect(AppColors.gradientEnd, const Color(0xFFF97316));
    });

    test('divider color should be defined', () {
      expect(AppColors.dividerColor, const Color(0xFFC4C4C4));
    });

    test('payment confirmation colors should be defined', () {
      expect(AppColors.primaryYellow, const Color(0xFFFDC300));
      expect(AppColors.linkBlue, const Color(0xFF0068E1));
      expect(AppColors.borderGray, const Color(0xFFDFDFDF));
      expect(AppColors.timerBg, const Color(0xFFF5E6B8));
    });

    test('social button colors should be defined', () {
      expect(AppColors.googleBg, const Color(0xFF1F1F1F));
      expect(AppColors.appleBg, const Color(0xFF1F1F1F));
      expect(AppColors.facebookBg, const Color(0xFF1F1F1F));
    });

    test('field status colors should be defined', () {
      expect(AppColors.statusAvailable, const Color(0xFF4CAF50));
      expect(AppColors.statusBooked, const Color(0xFFFF9800));
      expect(AppColors.statusMaintenance, const Color(0xFFF44336));
    });

    test('all colors should be valid Color objects', () {
      final colors = [
        AppColors.darkBg,
        AppColors.whiteBg,
        AppColors.inputBg,
        AppColors.screenBg,
        AppColors.headerBg,
        AppColors.primaryDark,
        AppColors.labelText,
        AppColors.strongPassword,
        AppColors.gradientStart,
        AppColors.statusAvailable,
      ];

      for (final color in colors) {
        expect(color, isA<Color>());
        expect(color.alpha, greaterThanOrEqualTo(0));
        expect(color.alpha, lessThanOrEqualTo(255));
      }
    });
  });
}
