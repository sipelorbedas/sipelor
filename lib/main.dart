import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/splash_screen.dart';
import 'screens/user/home_screen.dart';
import 'screens/auth/auth_screen.dart';
import 'screens/auth/reset_password_screen.dart';
import 'screens/debug/debug_menu_screen.dart';
import 'services/booking_expiration_service.dart';
import 'services/push_notification_service.dart';
import 'services/chat_service.dart';
import 'services/notification_cleanup_service.dart';
import 'services/pinned_http_client.dart';
import 'services/error_tracking_service.dart';
import 'services/encrypted_preferences_service.dart';
import 'services/file_encryption_service.dart';
import 'services/security_event_notification_service.dart';
import 'services/deep_link_handler.dart';
import 'widgets/auto_logout_wrapper.dart';
import 'config/build_config.dart';
import 'config/ssl_config.dart';
import 'core/service_locator.dart';
import 'core/app_router.dart';
import 'utils/performance_monitor.dart';
import 'utils/app_bundle_optimizer.dart';
import 'services/http_cache_service.dart';
import 'services/image_cache_optimizer.dart';
import 'services/dependency_monitor_service.dart';
import 'services/connectivity_service.dart';
import 'services/offline_cache_service.dart';
import 'security/rasp_security.dart';
import 'security/app_security_manager.dart';
import 'security/anti_tamper_guard.dart';
import 'security/network_security_manager.dart';

// Global flag to track Supabase initialization status
bool isSupabaseInitialized = false;

// Configuration Strategy:
// For Development: Use .env file (easier for local development)
// For Production: Use --dart-define (more secure, no file bundling)//
//
// Build commands:
// Development: flutter run
// Production:  flutter build apk --release \
//                --dart-define=SUPABASE_URL=your_url \
//                --dart-define=SUPABASE_ANON_KEY=your_key

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── LAYER 1+: Comprehensive Security Startup Checks ──────────────────────
  // Perform startup security check (RASP + Anti-Tamper + Network) - skip on web
  if (!kIsWeb) {
    try {
      // Initialize the central security manager (orchestrates all layers)
      await AppSecurityManager.initialize();

      // Run anti-tamper check independently for early detection
      final tamperCheck = await AntiTamperGuard.runAllChecks();
      if (tamperCheck.isTampered && kReleaseMode) {
        if (kDebugMode) {
          print(
            '🔴 [Security] Anti-tamper violations: ${tamperCheck.violations}',
          );
        }
        // In production, block if critical tampering is detected
        if (tamperCheck.severity == TamperSeverity.critical) {
          runApp(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.security, size: 64, color: Colors.red),
                        const SizedBox(height: 24),
                        Text(
                          AntiTamperGuard.getSeverityMessage(
                            tamperCheck.severity,
                          ),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          return;
        }
      }

      // Network security assessment
      final networkCheck = await NetworkSecurityManager.assess();
      if (!networkCheck.isSecure && kDebugMode) {
        print('⚠️  [Security] Network warnings: ${networkCheck.warnings}');
      }
    } catch (e) {
      if (kDebugMode) print('⚠️  [Security] Security init error: $e');
    }
  }

  if (!kIsWeb) {
    try {
      final securityCheck = await RASPSecurity.performSecurityCheck();

      if (!securityCheck.isSafe) {
        if (kDebugMode) {
          if (kDebugMode) print('🔒 Security Check Result:');
          if (kDebugMode) print('  Level: ${securityCheck.securityLevel}');
          for (final threat in securityCheck.threats) {
            if (kDebugMode) print('  ⚠️  $threat');
          }
        }

        // If critical security threat in production, block app
        if (securityCheck.securityLevel == SecurityLevel.critical &&
            kReleaseMode) {
          runApp(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.security, size: 64, color: Colors.red),
                        const SizedBox(height: 24),
                        Text(
                          RASPSecurity.getSecurityMessage(securityCheck),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
          return;
        }
      }

      // Start security monitoring in background
      RASPSecurity.startRuntimeMonitoring();
    } catch (e) {
      if (kDebugMode) {
        if (kDebugMode) print('⚠️  RASP security check failed: $e');
      }
    }
  }

  if (kDebugMode) {
    if (kDebugMode) print('✅ RASP security check completed');
  }

  // ── PHASE 2: Initialize independent services in PARALLEL ─────────────────
  // Semua service ini tidak saling bergantung, jalankan bersamaan untuk
  // mempercepat cold start (sebelumnya sequential ~400-600ms, sekarang ~100-200ms).
  await Future.wait([
    initializeDateFormatting('id_ID', null),
    ErrorTrackingService.initialize(),
    HttpCacheService().initialize(),
    ConnectivityService().initialize(),
    OfflineCacheService().initialize(),
  ]);
  if (kDebugMode) {
    print(
      '✅ [Phase 2] Parallel services initialized (locale, error tracking, cache, connectivity, offline)',
    );
  }

  // Sync operations — tidak perlu await
  PerformanceMonitor.initialize(
    enableMemoryTracking: kDebugMode,
    memoryCheckInterval: const Duration(seconds: 30),
  );
  ImageCacheOptimizer.configure();
  if (kDebugMode) {
    print('✅ Performance monitoring & image cache configured');
    AppBundleOptimizer.printOptimizationReport();
  }

  // Run dependency health check (debug only)
  if (kDebugMode) {
    await DependencyMonitorService().checkOutdatedDependencies();
  }

  // Initialize Supabase with credentials
  // Priority: --dart-define > .env file > error
  try {
    String? supabaseUrl;
    String? supabaseAnonKey;

    // Try to get from --dart-define (production builds)
    const dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
    const dartDefineKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    // ── Tier 1: --dart-define (production build) ─────────────────────────────
    if (dartDefineUrl.isNotEmpty && dartDefineKey.isNotEmpty) {
      supabaseUrl = dartDefineUrl;
      supabaseAnonKey = dartDefineKey;
      if (kDebugMode) print('✅ Using Supabase credentials from --dart-define');
    } else {
      // ── Tier 2: .env file (development) ──────────────────────────────────
      try {
        await dotenv.load(fileName: '.env');
        supabaseUrl = dotenv.env['SUPABASE_URL'];
        supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];
        if (kDebugMode) print('✅ Using Supabase credentials from .env file');
      } catch (e) {
        if (kDebugMode) print('⚠️  Error loading .env file: $e');
      }
    }

    // ── Tier 3: No fallback in production — credentials WAJIB di-pass via --dart-define ─
    // Untuk development tanpa .env, jalankan:
    //   flutter run --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx
    if ((supabaseUrl == null || supabaseUrl.isEmpty) ||
        (supabaseAnonKey == null || supabaseAnonKey.isEmpty)) {
      if (kDebugMode) {
        print('❌ [Supabase] Credentials tidak ditemukan!');
        print(
          '   Gunakan --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx',
        );
        print('   Atau buat file .env di root project.');
      }
      // Biarkan null — Supabase.initialize() akan throw dan ditangkap di catch block
    }

    // Guard: throw jika credentials masih kosong setelah semua Tier
    if (supabaseUrl == null ||
        supabaseUrl.isEmpty ||
        supabaseAnonKey == null ||
        supabaseAnonKey.isEmpty) {
      throw Exception(
        'Supabase credentials tidak ditemukan.\n'
        'Gunakan --dart-define=SUPABASE_URL=xxx --dart-define=SUPABASE_ANON_KEY=xxx\n'
        'atau buat file .env di root project.',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      // PKCE flow is required for email verification deep links in supabase_flutter v2
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
    isSupabaseInitialized = true;

    if (kDebugMode) {
      if (kDebugMode) print('✅ Supabase initialized successfully');
    }

    // Initialize Dependency Injection (GetIt) — AFTER Supabase is ready
    await setupServiceLocator();
    if (kDebugMode) {
      if (kDebugMode) print('✅ Service locator initialized (GetIt DI)');
    }

    // Initialize SSL pinned HTTP client
    final _ = PinnedHttpClient.instance;

    // Print build configuration
    BuildConfig.printConfig();

    // Validate SSL configuration
    if (SSLConfig.sslPinningEnabled) {
      final isValid = SSLConfig.validate();
      if (kDebugMode) {
        if (kDebugMode) {
          print(
            isValid
                ? '✅ SSL pinning configured and validated'
                : '⚠️  SSL pinning validation failed',
          );
        }
      }

      // Check certificate expiry warning
      final warning = SSLConfig.getCertificateExpiryWarning();
      if (warning != null && kDebugMode) {
        if (kDebugMode) print(warning);
      }
    }

    // PERFORMANCE: Initialize post-Supabase services in PARALLEL
    // BookingExpiration dan PushNotification tidak saling bergantung
    await Future.wait([
      BookingExpirationService.initialize()
          .then((_) {
            if (kDebugMode) print('✅ Booking expiration service initialized');
          })
          .catchError((e) {
            if (kDebugMode) print('⚠️  BookingExpiration init error: $e');
          }),
      if (!kIsWeb)
        PushNotificationService()
            .initialize()
            .then((_) {
              if (kDebugMode) {
                print('✅ Push notification service initialized');
                PushNotificationService.printStatus();
              }
            })
            .catchError((e) {
              if (kDebugMode) print('❌ Push notification service failed: $e');
            }),
    ]);
    if (kIsWeb && kDebugMode) {
      print('ℹ️  Push notification service skipped (web platform)');
    }

    // PERFORMANCE: Initialize other non-critical services in background
    Future.wait([
      EncryptedPreferencesService()
          .initialize()
          .then((_) {
            if (kDebugMode) {
              debugPrint('✅ Encrypted preferences service initialized');
            }
          })
          .catchError((e) {
            if (kDebugMode) {
              debugPrint('⚠️  EncryptedPreferences init error: $e');
            }
          }),
      FileEncryptionService()
          .initialize()
          .then((_) {
            if (kDebugMode) debugPrint('✅ File encryption service initialized');
          })
          .catchError((e) {
            if (kDebugMode) debugPrint('⚠️  FileEncryption init error: $e');
          }),
      SecurityEventNotificationService.initialize()
          .then((_) {
            if (kDebugMode) {
              debugPrint('✅ Security event notification service initialized');
            }
          })
          .catchError((e) {
            if (kDebugMode) {
              debugPrint('⚠️  SecurityEventNotification init error: $e');
            }
          }),
    ]); // fire-and-forget — individual errors handled above

    // Initialize chat auto-cleanup (delete messages older than 24 hours)
    // Check every 6 hours
    ChatService.initializeAutoCleanup(hoursOld: 24, checkIntervalHours: 6);
    if (kDebugMode) {
      if (kDebugMode) print('✅ Chat auto-cleanup service initialized');
    }

    // Initialize notification auto-cleanup (delete notifications older than 24 hours)
    // Check every 6 hours to keep database storage efficient
    NotificationCleanupService.initialize(hoursOld: 24, checkIntervalHours: 6);
    if (kDebugMode) {
      if (kDebugMode) print('✅ Notification auto-cleanup service initialized');
    }
  } catch (e) {
    // Mark Supabase as not initialized
    isSupabaseInitialized = false;

    // Only log errors in debug mode
    if (kDebugMode) {
      if (kDebugMode) print('⚠️  Error initializing Supabase: $e');

      // Provide helpful message for web platform
      if (kIsWeb) {
        if (kDebugMode) print('');
        if (kDebugMode) {
          print(
            '╔════════════════════════════════════════════════════════════╗',
          );
        }
        if (kDebugMode) {
          print('║           ⚠️  FLUTTER WEB CONFIGURATION ISSUE            ║');
        }
        if (kDebugMode) {
          print(
            '╠════════════════════════════════════════════════════════════╣',
          );
        }
        if (kDebugMode) {
          print('║ .env files do not work reliably on Flutter Web           ║');
        }
        if (kDebugMode) {
          print(
            '║                                                            ║',
          );
        }
        if (kDebugMode) {
          print(
            '║ Solutions:                                                 ║',
          );
        }
        if (kDebugMode) {
          print(
            '║ 1. Use --dart-define flags:                               ║',
          );
        }
        if (kDebugMode) {
          print(
            '║    flutter run -d chrome \\                                ║',
          );
        }
        if (kDebugMode) {
          print(
            '║      --dart-define=SUPABASE_URL=your_url \\                ║',
          );
        }
        if (kDebugMode) {
          print(
            '║      --dart-define=SUPABASE_ANON_KEY=your_key             ║',
          );
        }
        if (kDebugMode) {
          print(
            '║                                                            ║',
          );
        }
        if (kDebugMode) {
          print(
            '║ 2. Or build for release with credentials:                 ║',
          );
        }
        if (kDebugMode) {
          print(
            '║    flutter build web \\                                    ║',
          );
        }
        if (kDebugMode) {
          print(
            '║      --dart-define=SUPABASE_URL=your_url \\                ║',
          );
        }
        if (kDebugMode) {
          print(
            '║      --dart-define=SUPABASE_ANON_KEY=your_key             ║',
          );
        }
        if (kDebugMode) {
          print(
            '╚════════════════════════════════════════════════════════════╝',
          );
        }
        if (kDebugMode) print('');
      }
    }
    // In production, handle silently or show user-friendly error
    // Continue running app - splash screen will show error
  }

  // Wrap app with ProviderScope for Riverpod
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final _deepLinkHandler = DeepLinkHandler();
  // Gunakan AppRouter.navigatorKey agar bisa diakses dari PushNotificationService
  final _navigatorKey = AppRouter.navigatorKey;
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to Supabase auth state changes.
    // This is the KEY fix for email verification deep links:
    // When app opens from a verification link, HomeScreen renders first (blank),
    // then the deep link handler exchanges the code for a session.
    // The onAuthStateChange event fires → we navigate to /home.
    if (isSupabaseInitialized) {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
        (data) {
          if (kDebugMode) {
            if (kDebugMode) {
              print(
                '🔑 [AuthState] Event: ${data.event}, Session: ${data.session?.user.email}',
              );
            }
          }
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted || _navigatorKey.currentState == null) return;
            if (data.event == AuthChangeEvent.signedIn) {
              // Determine destination based on user role
              try {
                final supabase = Supabase.instance.client;
                final userId = data.session?.user.id;
                if (userId == null) {
                  _navigatorKey.currentState!.pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                  return;
                }

                final profile = await supabase
                    .from('profiles')
                    .select('role')
                    .eq('id', userId)
                    .maybeSingle();

                final roleStr = profile?['role'] as String? ?? 'user';

                if (kDebugMode) {
                  if (kDebugMode) print('🔑 [AuthState] Role: $roleStr');
                }

                if (!mounted || _navigatorKey.currentState == null) return;

                // Admin panel tersedia via web browser (website/admin/)
                _navigatorKey.currentState!.pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                );
              } catch (e) {
                if (kDebugMode) {
                  if (kDebugMode) {
                    print(
                      '⚠️  [AuthState] Role check failed, defaulting to /home: $e',
                    );
                  }
                }
                if (mounted && _navigatorKey.currentState != null) {
                  _navigatorKey.currentState!.pushNamedAndRemoveUntil(
                    '/home',
                    (route) => false,
                  );
                }
              }
            } else if (data.event == AuthChangeEvent.passwordRecovery) {
              // Navigate to reset password screen
              _navigatorKey.currentState!.pushNamedAndRemoveUntil(
                '/reset-password',
                (route) => false,
              );
            }
          });
        },
        onError: (error) {
          if (kDebugMode) {
            if (kDebugMode) print('❌ [AuthState] Stream error: $error');
          }
        },
      );
    }

    // Deep link handler will be initialized after first frame
    // to ensure navigator is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _navigatorKey.currentContext != null) {
        _deepLinkHandler.initialize(_navigatorKey.currentContext!);
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    _deepLinkHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AutoLogoutWrapper(
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'SIPELOR BEDAS',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
          fontFamily: 'Mulish',
          textTheme: GoogleFonts.mulishTextTheme(),
        ),
        // SplashScreen menampilkan animasi branded lalu navigate ke
        // HomeScreen atau AuthScreen berdasarkan status auth Supabase.
        // Warna background SplashScreen sama dengan native launch_background.xml (#1A1A2E)
        // sehingga transisi native → Flutter tampak mulus tanpa white flash.
        home: isSupabaseInitialized
            ? const SplashScreen()
            : const _SupabaseErrorScreen(),
        routes: {
          '/home': (context) => const HomeScreen(),
          '/login': (context) => const AuthScreen(),
          '/reset-password': (context) => const ResetPasswordScreen(),
          // SECURITY: Debug route hanya tersedia di debug/staging build
          if (BuildConfig.debugToolsEnabled)
            '/debug': (context) {
              if (!isSupabaseInitialized) return const HomeScreen();
              final user = Supabase.instance.client.auth.currentUser;
              final role = user?.userMetadata?['role'] as String?;
              final isAdmin = role == 'admin' || role == 'super_admin';
              if (!isAdmin) return const HomeScreen();
              return const DebugMenuScreen();
            },
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

/// Shown only if Supabase.initialize() completely fails (e.g. network error).
/// FIX: Dikonversi ke StatefulWidget agar tombol "Coba Lagi" bisa menampilkan
/// loading indicator selama proses retry berlangsung.
class _SupabaseErrorScreen extends StatefulWidget {
  const _SupabaseErrorScreen();

  @override
  State<_SupabaseErrorScreen> createState() => _SupabaseErrorScreenState();
}

class _SupabaseErrorScreenState extends State<_SupabaseErrorScreen> {
  bool _isRetrying = false;

  Future<void> _retry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await main();
    } catch (e) {
      if (kDebugMode) print('⚠️  Retry failed: $e');
    } finally {
      // Jika widget masih terpasang (retry gagal), kembalikan ke idle state
      if (mounted) setState(() => _isRetrying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.cloud_off_rounded,
                  size: 72,
                  color: Color(0xFFE94560),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Koneksi Gagal',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tidak dapat terhubung ke server.\nPastikan koneksi internet aktif, lalu restart aplikasi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _isRetrying ? null : _retry,
                  icon: _isRetrying
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded),
                  label: Text(_isRetrying ? 'Menghubungkan...' : 'Coba Lagi'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE94560),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(
                      0xFFE94560,
                    ).withOpacity(0.6),
                    disabledForegroundColor: Colors.white70,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
