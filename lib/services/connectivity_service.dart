import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Connectivity Service — deteksi status jaringan secara real-time.
///
/// Cara pakai:
/// ```dart
/// // Inisialisasi di main.dart
/// await ConnectivityService().initialize();
///
/// // Cek status saat ini
/// if (ConnectivityService().isOnline) { ... }
///
/// // Listen perubahan
/// ConnectivityService().onConnectivityChanged.listen((isOnline) { ... });
/// ```
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final _connectivity = Connectivity();
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  // FIX: Debounce timer agar tidak rapid-fire saat sinyal tidak stabil
  Timer? _debounce;

  bool _isOnline = true;
  bool _initialized = false;

  /// Status koneksi saat ini
  bool get isOnline => _isOnline;

  /// Stream perubahan status koneksi (true = online, false = offline)
  Stream<bool> get onConnectivityChanged => _controller.stream;

  /// Inisialisasi service — panggil sekali di main()
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Cek status awal
    _isOnline = await checkConnectivity();

    // Pantau perubahan koneksi dengan debounce 500ms
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        final newStatus = results.any((r) => r != ConnectivityResult.none);
        if (_isOnline != newStatus) {
          _isOnline = newStatus;
          _controller.add(_isOnline);
          if (kDebugMode) {
            print(_isOnline
                ? '🌐 [Connectivity] Kembali online'
                : '📴 [Connectivity] Koneksi terputus');
          }
        }
      });
    });

    if (kDebugMode) {
      print('✅ [Connectivity] Service initialized — isOnline: $_isOnline');
    }
  }

  /// Periksa koneksi secara langsung (one-shot)
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final online = results.any((r) => r != ConnectivityResult.none);
      _isOnline = online;
      return online;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️  [Connectivity] Error saat memeriksa koneksi: $e');
      }
      return true; // Asumsikan online jika terjadi error
    }
  }

  void dispose() {
    _debounce?.cancel();
    _subscription?.cancel();
    _controller.close();
  }
}
