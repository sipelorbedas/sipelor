import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/security_event_notification_service.dart';

/// Screen for managing security event notification preferences
class SecurityNotificationSettingsScreen extends StatefulWidget {
  const SecurityNotificationSettingsScreen({super.key});

  @override
  State<SecurityNotificationSettingsScreen> createState() =>
      _SecurityNotificationSettingsScreenState();
}

class _SecurityNotificationSettingsScreenState
    extends State<SecurityNotificationSettingsScreen> {
  Map<SecurityEventType, bool> _preferences = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);
    
    final prefs =
        await SecurityEventNotificationService.getAllPreferences();
    
    setState(() {
      _preferences = prefs;
      _isLoading = false;
    });
  }

  Future<void> _updatePreference(SecurityEventType type, bool value) async {
    await SecurityEventNotificationService.setNotificationPreference(
      type,
      value,
    );
    
    setState(() {
      _preferences[type] = value;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Preferensi notifikasi disimpan',
          style: GoogleFonts.mulish(),
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteBg,
      appBar: AppBar(
        title: Text(
          'Notifikasi Keamanan',
          style: GoogleFonts.mulish(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header explanation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.blue.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.blue.shade700,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Kelola notifikasi untuk aktivitas keamanan akun Anda',
                          style: GoogleFonts.mulish(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Security event notification toggles
                ...SecurityEventType.values.map((type) {
                  final isEnabled = _preferences[type] ?? true;
                  final displayName =
                      SecurityEventNotificationService.getEventTypeDisplayName(
                          type);
                  final description =
                      SecurityEventNotificationService.getEventTypeDescription(
                          type);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade200,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: _getEventTypeColor(type).withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getEventTypeIcon(type),
                            color: _getEventTypeColor(type),
                            size: 24,
                          ),
                        ),
                        
                        const SizedBox(width: 16),
                        
                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                displayName,
                                style: GoogleFonts.mulish(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: GoogleFonts.mulish(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w400,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(width: 12),
                        
                        // Switch
                        Switch(
                          value: isEnabled,
                          onChanged: (value) => _updatePreference(type, value),
                          activeThumbColor: const Color.fromARGB(255, 0, 113, 72),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Additional info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.orange.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.security,
                            color: Colors.orange.shade700,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Tips Keamanan',
                            style: GoogleFonts.mulish(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.orange.shade900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Kami sangat menyarankan untuk mengaktifkan semua notifikasi keamanan agar Anda selalu waspada terhadap aktivitas mencurigakan.',
                        style: GoogleFonts.mulish(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  IconData _getEventTypeIcon(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.loginNewDevice:
        return Icons.devices;
      case SecurityEventType.passwordChange:
        return Icons.vpn_key;
      case SecurityEventType.emailChange:
        return Icons.email;
      case SecurityEventType.failedLogins:
        return Icons.warning_amber_rounded;
      case SecurityEventType.payment:
        return Icons.payment;
      case SecurityEventType.bookingStatus:
        return Icons.event_available;
    }
  }

  Color _getEventTypeColor(SecurityEventType type) {
    switch (type) {
      case SecurityEventType.loginNewDevice:
        return Colors.blue;
      case SecurityEventType.passwordChange:
        return Colors.purple;
      case SecurityEventType.emailChange:
        return Colors.teal;
      case SecurityEventType.failedLogins:
        return Colors.orange;
      case SecurityEventType.payment:
        return Colors.green;
      case SecurityEventType.bookingStatus:
        return Colors.indigo;
    }
  }
}
