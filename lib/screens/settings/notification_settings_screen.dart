import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/notification_service.dart';
import '../../services/push_notification_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  // Notification type preferences
  bool _bookingNotificationsEnabled = true;
  bool _paymentRemindersEnabled = true;
  bool _promoNotificationsEnabled = true;
  bool _reviewRemindersEnabled = true;
  bool _maintenanceNotificationsEnabled = true;
  
  // Notification behavior preferences
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      _bookingNotificationsEnabled = await PushNotificationService.getNotificationPreference(
        PushNotificationService.keyBookingNotifications,
      );
      _paymentRemindersEnabled = await PushNotificationService.getNotificationPreference(
        PushNotificationService.keyPaymentReminders,
      );
      _promoNotificationsEnabled = await PushNotificationService.getNotificationPreference(
        PushNotificationService.keyPromoNotifications,
      );
      _reviewRemindersEnabled = await PushNotificationService.getNotificationPreference(
        PushNotificationService.keyReviewReminders,
      );
      _maintenanceNotificationsEnabled = await PushNotificationService.getNotificationPreference(
        PushNotificationService.keyMaintenanceNotifications,
      );
      _soundEnabled = await PushNotificationService.getNotificationPreference(
        PushNotificationService.keySound,
      );
      _vibrationEnabled = await PushNotificationService.getNotificationPreference(
        PushNotificationService.keyVibration,
      );
      
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      if (kDebugMode) print('Error loading notification preferences: $e');
    }
  }

  Future<void> _savePreference(String key, bool value) async {
    try {
      await PushNotificationService.setNotificationPreference(key, value);
    } catch (e) {
      if (kDebugMode) print('Error saving preference: $e');
    }
  }

  Future<void> _clearAllNotifications() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Hapus Semua Notifikasi',
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Apakah Anda yakin ingin menghapus semua riwayat notifikasi? '
            'Tindakan ini tidak dapat dibatalkan.',
            style: GoogleFonts.mulish(
              fontSize: 14,
              color: AppColors.secondaryDark,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Batal',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                elevation: 0,
              ),
              child: Text(
                'Hapus',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      try {
        await PushNotificationService.clearAllNotifications();
        await NotificationService.clearSeenBookings();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Semua riwayat notifikasi berhasil dihapus',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color.fromARGB(255, 0, 113, 72),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal menghapus notifikasi: $e'),
              backgroundColor: Colors.red.shade600,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 0, 113, 72),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pengaturan Notifikasi',
          style: GoogleFonts.mulish(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: const Color.fromARGB(255, 0, 113, 72),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Kelola notifikasi untuk update booking dan informasi penting lainnya',
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color.fromARGB(255, 0, 113, 72),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Notification Types Section
          _buildSectionTitle('Jenis Notifikasi'),
          const SizedBox(height: 12),
          _buildNotificationTypeCard(),

          const SizedBox(height: 24),

          // Notification Behavior Section
          _buildSectionTitle('Perilaku Notifikasi'),
          const SizedBox(height: 12),
          _buildNotificationBehaviorCard(),

          const SizedBox(height: 24),

          // Clear All Section
          _buildSectionTitle('Riwayat Notifikasi'),
          const SizedBox(height: 12),
          _buildClearAllCard(),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.mulish(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.primaryDark,
      ),
    );
  }

  Widget _buildNotificationTypeCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.event_available,
            title: 'Update Booking',
            subtitle: 'Notifikasi approval/rejection booking',
            value: _bookingNotificationsEnabled,
            onChanged: (value) {
              setState(() => _bookingNotificationsEnabled = value);
              _savePreference(PushNotificationService.keyBookingNotifications, value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.payment,
            title: 'Pengingat Pembayaran',
            subtitle: 'Reminder sebelum booking expired',
            value: _paymentRemindersEnabled,
            onChanged: (value) {
              setState(() => _paymentRemindersEnabled = value);
              _savePreference(PushNotificationService.keyPaymentReminders, value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.local_offer,
            title: 'Promo & Diskon',
            subtitle: 'Informasi promo terbaru',
            value: _promoNotificationsEnabled,
            onChanged: (value) {
              setState(() => _promoNotificationsEnabled = value);
              _savePreference(PushNotificationService.keyPromoNotifications, value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.star_rate,
            title: 'Pengingat Review',
            subtitle: 'Reminder untuk memberikan review',
            value: _reviewRemindersEnabled,
            onChanged: (value) {
              setState(() => _reviewRemindersEnabled = value);
              _savePreference(PushNotificationService.keyReviewReminders, value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.build,
            title: 'Jadwal Maintenance',
            subtitle: 'Info maintenance venue',
            value: _maintenanceNotificationsEnabled,
            onChanged: (value) {
              setState(() => _maintenanceNotificationsEnabled = value);
              _savePreference(PushNotificationService.keyMaintenanceNotifications, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Divider(
        color: AppColors.borderGray.withOpacity(0.5),
        height: 1,
      ),
    );
  }

  Widget _buildNotificationBehaviorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            icon: Icons.volume_up_outlined,
            title: 'Suara',
            subtitle: 'Mainkan suara saat notifikasi masuk',
            value: _soundEnabled,
            onChanged: (value) {
              setState(() => _soundEnabled = value);
              _savePreference(PushNotificationService.keySound, value);
            },
          ),
          _buildDivider(),
          _buildSwitchTile(
            icon: Icons.vibration,
            title: 'Getar',
            subtitle: 'Getarkan perangkat saat notifikasi masuk',
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() => _vibrationEnabled = value);
              _savePreference(PushNotificationService.keyVibration, value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClearAllCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: InkWell(
        onTap: _clearAllNotifications,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.delete_outline,
                  size: 24,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hapus Semua Riwayat',
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Reset semua notifikasi yang sudah dibaca',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppColors.secondaryDark,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 22,
              color: const Color.fromARGB(255, 0, 113, 72),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.mulish(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color.fromARGB(255, 0, 113, 72),
          ),
        ],
      ),
    );
  }
}
