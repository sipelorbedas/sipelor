import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sipelor/constants/admin_colors.dart';

void main() {
  group('AdminColors', () {
    test('primary colors should be defined', () {
      expect(AdminColors.primary, const Color(0xFF4880FF));
      expect(AdminColors.primaryBlue, const Color(0xFF4880FF));
      expect(AdminColors.successGreen, const Color(0xFF00B69B));
      expect(AdminColors.errorRed, const Color(0xFFF93C65));
      expect(AdminColors.warningOrange, const Color(0xFFFFA500));
    });

    test('text colors should be defined', () {
      expect(AdminColors.darkText, const Color(0xFF202224));
      expect(AdminColors.mediumText, const Color(0xFF646464));
      expect(AdminColors.lightText, const Color(0xFF565656));
      expect(AdminColors.placeholderText, const Color(0xFF2B3034));
    });

    test('background colors should be defined', () {
      expect(AdminColors.white, const Color(0xFFFFFFFF));
      expect(AdminColors.lightGrayBg, const Color(0xFFF5F6FA));
      expect(AdminColors.tableHeaderBg, const Color(0xFFF1F4F9));
      expect(AdminColors.screenBg, const Color(0xFFFCFDFD));
    });

    test('border colors should be defined', () {
      expect(AdminColors.borderGray, const Color(0xFFE0E0E0));
      expect(AdminColors.borderLight, const Color(0xFFD5D5D5));
    });

    test('icon background colors should be defined with opacity', () {
      expect(AdminColors.userIconBg, isA<Color>());
      expect(AdminColors.orderIconBg, isA<Color>());
      expect(AdminColors.salesIconBg, isA<Color>());
      expect(AdminColors.pendingIconBg, isA<Color>());
      
      // Verify they have opacity applied
      expect(AdminColors.userIconBg.opacity, lessThan(1.0));
      expect(AdminColors.orderIconBg.opacity, lessThan(1.0));
      expect(AdminColors.salesIconBg.opacity, lessThan(1.0));
      expect(AdminColors.pendingIconBg.opacity, lessThan(1.0));
    });

    test('stat icon colors should be defined', () {
      expect(AdminColors.userIcon, const Color(0xFF4880FF));
      expect(AdminColors.orderIcon, const Color(0xFFFFA500));
      expect(AdminColors.salesIcon, const Color(0xFF00C4A1));
      expect(AdminColors.pendingIcon, const Color(0xFFFF6B6B));
    });

    test('status colors should be defined', () {
      expect(AdminColors.deliveredStatus, const Color(0xFF00B69B));
      expect(AdminColors.deliveredBg, const Color(0xFFE6F9F5));
    });

    test('compatibility getters should work', () {
      expect(AdminColors.background, AdminColors.screenBg);
      expect(AdminColors.textPrimary, AdminColors.darkText);
      expect(AdminColors.textSecondary, AdminColors.mediumText);
      expect(AdminColors.border, AdminColors.borderGray);
      expect(AdminColors.cardBackground, AdminColors.tableHeaderBg);
    });

    test('all solid colors should be valid Color objects', () {
      final colors = [
        AdminColors.primary,
        AdminColors.successGreen,
        AdminColors.errorRed,
        AdminColors.darkText,
        AdminColors.white,
        AdminColors.borderGray,
      ];

      for (final color in colors) {
        expect(color, isA<Color>());
        expect(color.alpha, greaterThanOrEqualTo(0));
        expect(color.alpha, lessThanOrEqualTo(255));
      }
    });

    test('icon background colors should have same base as icon colors', () {
      expect(AdminColors.userIconBg.value & 0x00FFFFFF, 
             AdminColors.userIcon.value & 0x00FFFFFF);
      expect(AdminColors.orderIconBg.value & 0x00FFFFFF, 
             AdminColors.orderIcon.value & 0x00FFFFFF);
    });
  });
}
