import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for content moderation and filtering inappropriate content
/// Includes SARA (Suku, Agama, Ras, Antar-golongan) filtering
class ContentModerationService {
  // Daftar kata-kata SARA yang diblokir
  static final List<String> _blockedWords = [
    // Suku & Ras (offensive terms)
    'kafir', 'pribumi', 'cina', 'cino', 'cino', 'aseng', 'asing',
    'indon', 'indo', 'jawa', 'sunda', 'batak', 'padang',
    
    // Agama (offensive/divisive terms)
    'sesat', 'murtad', 'laknatullah', 'tuhan palsu', 'agama palsu',
    'teroris agama', 'radikal', 'fundamentalis', 'ekstremis',
    
    // Antar-golongan (hate speech)
    'bodoh', 'tolol', 'goblok', 'idiot', 'bego', 'dungu',
    'kampungan', 'ndeso', 'miskin', 'kumuh', 'jorok',
    
    // Kata-kata kasar umum
    'anjing', 'babi', 'bangsat', 'bajingan', 'kontol', 'memek',
    'tai', 'jancok', 'cok', 'njing', 'jing', 'asu',
    'kampret', 'monyet', 'setan', 'iblis',
    
    // Hate speech & diskriminasi
    'rasis', 'diskriminasi', 'penindasan', 'genocida',
    'pembunuhan massal', 'pemerkosaan', 'perkosa',
    
    // Politik sensitif (optional - bisa di-uncomment jika perlu)
    // 'komunis', 'pki', 'separatis', 'makar',
  ];

  // Variation dengan angka & simbol (leetspeak)
  static final List<String> _blockedVariations = [
    'k4f1r', 'b4b1', '4nj1ng', 'b0d0h', 't0l0l',
    'g0bl0k', '1d10t', 'b3g0', 'b4ng54t', 't41',
  ];

  /// Check if message contains blocked words
  static bool containsBlockedContent(String message) {
    final lowerMessage = message.toLowerCase();
    
    // Check exact words
    for (final word in _blockedWords) {
      // Word boundary check to avoid false positives
      final regex = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      if (regex.hasMatch(lowerMessage)) {
        if (kDebugMode) {
          if (kDebugMode) print('🚫 Blocked word detected: $word');
        }
        return true;
      }
    }
    
    // Check variations
    for (final word in _blockedVariations) {
      if (lowerMessage.contains(word)) {
        if (kDebugMode) {
          if (kDebugMode) print('🚫 Blocked variation detected: $word');
        }
        return true;
      }
    }
    
    return false;
  }

  /// Filter message and return cleaned version with asterisks
  static String filterMessage(String message) {
    String filtered = message;
    
    // Replace blocked words with asterisks
    for (final word in _blockedWords) {
      final regex = RegExp(r'\b' + RegExp.escape(word) + r'\b', caseSensitive: false);
      filtered = filtered.replaceAllMapped(regex, (match) {
        return '*' * match.group(0)!.length;
      });
    }
    
    // Replace variations
    for (final word in _blockedVariations) {
      filtered = filtered.replaceAll(
        RegExp(word, caseSensitive: false),
        '*' * word.length,
      );
    }
    
    return filtered;
  }

  /// Validate message before sending
  /// Returns error message if blocked, null if OK
  static String? validateMessage(String message) {
    if (message.trim().isEmpty) {
      return 'Pesan tidak boleh kosong';
    }
    
    if (message.length > 1000) {
      return 'Pesan terlalu panjang (maksimal 1000 karakter)';
    }
    
    if (containsBlockedContent(message)) {
      return 'Pesan mengandung kata-kata yang tidak pantas atau SARA. Mohon gunakan bahasa yang sopan.';
    }
    
    return null; // Message is valid
  }

  /// Get warning message for user
  static String getWarningMessage() {
    return '⚠️ Pesan Anda mengandung kata-kata yang tidak pantas atau SARA.\n\n'
        'Harap gunakan bahasa yang sopan dan menghormati semua pihak.\n\n'
        'Kata-kata yang mengandung:\n'
        '• Ujaran kebencian SARA\n'
        '• Kata-kata kasar\n'
        '• Diskriminasi\n\n'
        'akan diblokir secara otomatis.';
  }

  /// Log inappropriate content attempt to database for monitoring.
  static Future<void> logBlockedAttempt({
    required String userId,
    required String message,
    String? context,
  }) async {
    if (kDebugMode) {
      if (kDebugMode) print('🚨 Content moderation blocked:');
      if (kDebugMode) print('   User: $userId');
      if (kDebugMode) print('   Context: ${context ?? "chat"}');
      if (kDebugMode) print('   Message: ${message.substring(0, message.length > 50 ? 50 : message.length)}...');
    }

    try {
      await Supabase.instance.client.from('moderation_logs').insert({
        'user_id': userId,
        'blocked_content': message.length > 500 ? message.substring(0, 500) : message,
        'context': context ?? 'chat',
        'attempted_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      // Non-fatal — moderation log failure must never break user flow
      if (kDebugMode) {
        if (kDebugMode) print('⚠️ [ContentModeration] Failed to write moderation log: $e');
      }
    }
  }
}
