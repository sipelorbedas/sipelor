/// Riverpod providers for authentication
/// 
/// This file contains all providers for authentication state and operations
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ==================== Auth Providers ====================

/// Current user provider
/// Returns the currently authenticated user or null
final currentUserProvider = StreamProvider<User?>((ref) {
  final client = Supabase.instance.client;
  return client.auth.onAuthStateChange.map((data) => data.session?.user);
});

/// Current user ID provider
/// Returns the current user's ID or throws if not authenticated
final currentUserIdProvider = Provider<String>((ref) {
  final user = ref.watch(currentUserProvider).valueOrNull;
  if (user == null) {
    throw Exception('User not authenticated');
  }
  return user.id;
});

/// Auth state provider
/// Returns true if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider).valueOrNull != null;
});

/// User email provider
final userEmailProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.email;
});

/// User metadata provider
final userMetadataProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(currentUserProvider).valueOrNull?.userMetadata;
});

// ==================== Auth Actions ====================

/// Sign out action provider
final signOutProvider = Provider<Future<void> Function()>((ref) {
  return () async {
    await Supabase.instance.client.auth.signOut();
  };
});
