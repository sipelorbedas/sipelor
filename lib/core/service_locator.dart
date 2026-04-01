/// Service Locator for Dependency Injection
/// 
/// This file sets up the dependency injection container using get_it.
/// All services, repositories, and dependencies are registered here.
/// 
/// Usage:
/// ```dart
/// // In main.dart
/// await setupServiceLocator();
/// 
/// // In code
/// final repository = getIt<IBookingRepository>();
/// ```
library;

import 'package:get_it/get_it.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/interfaces/i_booking_repository.dart';
import '../repositories/supabase_booking_repository.dart';
import '../services/chat_service.dart';
import '../services/rate_limiter_service.dart';
import '../services/encrypted_preferences_service.dart';
import '../services/file_encryption_service.dart';
import '../services/http_cache_service.dart';
import '../services/query_cache_service.dart';
import '../services/dependency_monitor_service.dart';

// Global service locator instance
final GetIt getIt = GetIt.instance;

/// Setup all dependencies for the application
/// 
/// Call this function in main.dart before runApp()
Future<void> setupServiceLocator() async {
  // ========================================
  // External Dependencies
  // ========================================
  
  /// Register Supabase client as singleton
  getIt.registerLazySingleton<SupabaseClient>(
    () => Supabase.instance.client,
  );
  
  // ========================================
  // Repositories (Data Layer)
  // ========================================
  
  /// Register Booking Repository
  getIt.registerLazySingleton<IBookingRepository>(
    () => SupabaseBookingRepository(getIt<SupabaseClient>()),
  );
  
  // ========================================
  // Services (Business Logic Layer)
  // ========================================
  
  /// Register core services as singletons
  getIt.registerLazySingleton<ChatService>(
    () => ChatService(),
  );

  /// Register rate limiter dan mulai cleanup timer (mencegah memory leak)
  getIt.registerLazySingleton<RateLimiterService>(() {
    final svc = RateLimiterService();
    svc.startCleanupTimer();
    return svc;
  });
  
  // ========================================
  // Security Services
  // ========================================
  
  /// Register security services
  getIt.registerLazySingleton<EncryptedPreferencesService>(
    () => EncryptedPreferencesService(),
  );
  
  getIt.registerLazySingleton<FileEncryptionService>(
    () => FileEncryptionService(),
  );
  
  // ========================================
  // Performance & Caching Services
  // ========================================
  
  /// Register caching services for better performance
  getIt.registerLazySingleton<HttpCacheService>(
    () => HttpCacheService(),
  );
  
  getIt.registerLazySingleton<QueryCacheService>(
    () => QueryCacheService(),
  );
  
  getIt.registerLazySingleton<DependencyMonitorService>(
    () => DependencyMonitorService(),
  );
  
  // Note: These services are initialized in main.dart
  // and don't need to be registered here:
  // - BookingExpirationService (static initialization)
  // - PushNotificationService (instance-based)
  // - NotificationCleanupService (static initialization)
  // - SecurityEventNotificationService (static initialization)
  // - ErrorTrackingService (static initialization)
  // - ImageCacheOptimizer (static configuration)
  
  // ========================================
  // Utilities
  // ========================================
  
  // Utilities can be accessed directly without DI
}

/// Reset the service locator (useful for testing)
/// 
/// Call this in setUp() of test files
void resetServiceLocator() {
  getIt.reset();
}
