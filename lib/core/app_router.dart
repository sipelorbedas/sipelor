/// App Router — SIPELOR BEDAS
///
/// Menyimpan GlobalKey<NavigatorState> yang dapat diakses dari manapun
/// termasuk dari static methods seperti _onNotificationTapped.
library;

import 'package:flutter/material.dart';

class AppRouter {
  AppRouter._();

  /// Global navigator key — digunakan di MaterialApp dan oleh PushNotificationService.
  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  /// Convenience getter ke state navigator aktif.
  static NavigatorState? get navigator => navigatorKey.currentState;

  // ─── Navigation helpers ───────────────────────────────────────────────────

  /// Navigate ke named route, hapus semua route sebelumnya.
  static void pushAndRemoveUntil(String routeName, {Object? arguments}) {
    navigator?.pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  /// Navigate ke named route di atas stack saat ini.
  static Future<T?> pushNamed<T>(String routeName, {Object? arguments}) {
    return navigator!.pushNamed<T>(routeName, arguments: arguments);
  }

  /// Navigate dengan MaterialPageRoute (untuk screen yang butuh object).
  static Future<T?> push<T>(Widget screen) {
    return navigator!.push<T>(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  /// Pop screen saat ini.
  static void pop<T>([T? result]) {
    navigator?.pop(result);
  }
}
