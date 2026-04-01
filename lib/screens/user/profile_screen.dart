import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../utils/optimized_image.dart';
import '../auth/sign_in_screen.dart';
import 'user_bookings_screen.dart';
import 'edit_profile_screen.dart';
import '../info/about_app_screen.dart';
import '../info/help_faq_screen.dart';
import '../settings/security_settings_screen.dart';
import '../settings/notification_settings_screen.dart';
import '../info/security_tips_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'User';
  String _userEmail = '';
  String _userFullName = '';
  String _userPhone = '';
  String? _avatarUrl;
  int _totalBookings = 0;
  bool _isLoading = true;
  Key _avatarKey = UniqueKey(); // For forcing image rebuild

  @override
  void initState() {
    super.initState();
    
    // Use addPostFrameCallback to ensure navigation happens after build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAuthentication();
    });
  }

  // Check if user is authenticated before loading any data
  Future<void> _checkAuthentication() async {
    if (!mounted) return;
    
    final isLoggedIn = SupabaseService.isLoggedIn;
    
    if (kDebugMode) {
      if (kDebugMode) print('🔐 [ProfileScreen] Checking authentication: $isLoggedIn');
    }

    if (!isLoggedIn) {
      // User is not logged in, redirect to sign-in screen
      if (kDebugMode) {
        if (kDebugMode) print('❌ [ProfileScreen] Not authenticated, redirecting to sign-in');
      }
      
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/',
          (route) => false,
        );
      }
      return;
    }

    // User is authenticated, proceed with loading data
    if (kDebugMode) {
      if (kDebugMode) print('✅ [ProfileScreen] Authenticated, loading data');
    }
    
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService.currentUser;

      if (user != null) {
        if (kDebugMode) print('[ProfileScreen] Loading user data for: ${user.id}');
        
        // Get user profile
        Map<String, dynamic>? profile;
        try {
          profile = await SupabaseService.getUserProfile(user.id);
          if (kDebugMode) print('[ProfileScreen] Profile loaded: $profile');
        } catch (profileError) {
          if (kDebugMode) print('[ProfileScreen] Error fetching profile: $profileError');
          
          // Check if it's a policy error
          if (profileError.toString().contains('infinite recursion') ||
              profileError.toString().contains('policy')) {
            if (kDebugMode) print('⚠️  [ProfileScreen] DATABASE RLS POLICY ERROR detected');
            
            // Show error to user
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'Kesalahan database. Sebagian informasi profil mungkin tidak tampil.',
                  ),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 4),
                  action: SnackBarAction(
                    label: 'Info',
                    textColor: Colors.white,
                    onPressed: () {
                      _showPolicyErrorDialog();
                    },
                  ),
                ),
              );
            }
            
            // Use fallback data from auth user
            profile = {
              'username': user.email?.split('@').first ?? 'User',
              'full_name': user.userMetadata?['full_name'] as String? ?? '',
              'email': user.email ?? '',
              'phone_number': user.phone ?? '',
              'avatar_url': null,
            };
          } else {
            rethrow;
          }
        }

        // Get user bookings count
        final bookings = await SupabaseService.fetchUserBookings(
          userId: user.id,
        );

        if (profile != null && mounted) {
          final newAvatarUrl = profile['avatar_url'] as String?;
          
          // Explicitly evict old avatar from cache if it exists
          if (_avatarUrl != null && _avatarUrl != newAvatarUrl) {
            if (kDebugMode) print('[ProfileScreen] Avatar changed, evicting old from cache: $_avatarUrl');
            final oldImageProvider = NetworkImage(_avatarUrl!);
            oldImageProvider.evict();
          }
          
          // Evict new avatar too to force fresh load
          if (newAvatarUrl != null && newAvatarUrl.isNotEmpty) {
            if (kDebugMode) print('[ProfileScreen] Evicting new avatar from cache: $newAvatarUrl');
            final newImageProvider = NetworkImage(newAvatarUrl);
            newImageProvider.evict();
          }
          
          setState(() {
            _userName = profile!['username'] as String? ?? 'User';
            _userFullName = profile['full_name'] as String? ?? '';
            _userEmail = profile['email'] as String? ?? user.email ?? '';
            _userPhone = profile['phone_number'] as String? ?? '';
            _avatarUrl = newAvatarUrl;
            _totalBookings = bookings.length;
            _isLoading = false;
            _avatarKey = UniqueKey(); // Force image widget to rebuild
          });
          if (kDebugMode) print('[ProfileScreen] State updated with new avatar: $_avatarUrl');
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user data: $e');
      setState(() => _isLoading = false);
      
      // Show generic error if not already shown
      if (mounted && !e.toString().contains('policy')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data profil: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showPolicyErrorDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.blue[700], size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Kesalahan Database',
                style: GoogleFonts.mulish(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil memerlukan perbaikan konfigurasi database oleh administrator.',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Untuk Admin:',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[900],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Jalankan SQL fix di docs/SUPABASE_SQL_SCRIPTS.sql untuk memperbaiki RLS policies.',
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        color: Colors.blue[900],
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Mengerti',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogout() async {
    // Show confirmation dialog
    final confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Keluar',
            style: GoogleFonts.mulish(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin keluar?',
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
                backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: Text(
                'Keluar',
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

    if (confirm == true && mounted) {
      try {
        // Show loading
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(
              color: Color.fromARGB(255, 0, 113, 72),
            ),
          ),
        );

        await SupabaseService.signOut();

        if (mounted) {
          // Pop loading dialog
          Navigator.of(context).pop();

          // Navigate to sign in screen and remove all previous routes
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const SignInScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (mounted) {
          // Pop loading dialog
          Navigator.of(context).pop();

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Gagal keluar: $e'),
              backgroundColor: Colors.red,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header Section
                  _buildHeader(),

                  const SizedBox(height: 20),

                  // Stats Cards
                  _buildStatsCards(),

                  const SizedBox(height: 20),

                  // Menu Sections
                  _buildMenuSection(),

                  const SizedBox(height: 20),

                  // Logout Button
                  _buildLogoutButton(),

                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 0, 113, 72),
              Color.fromARGB(255, 0, 117, 164),
            ],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(30),
            bottomRight: Radius.circular(30),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              children: [
                // Title
                Text(
                  'Profil Saya',
                  style: GoogleFonts.mulish(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 30),

                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? OptimizedAvatar(
                          key: _avatarKey,
                          imageUrl: _avatarUrl!,
                          radius: 50, // 100/2 for diameter of 100
                        )
                      : ClipOval(
                          child: Image.asset(
                            'assets/images/user_avatar.png',
                            width: 100,
                            height: 100,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // User Name
                Text(
                  _userFullName.isNotEmpty ? _userFullName : _userName,
                  style: GoogleFonts.mulish(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),

                // Email
                Text(
                  _userEmail,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                
                // Phone Number (if available)
                if (_userPhone.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _userPhone,
                        style: GoogleFonts.mulish(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.event_available,
              title: 'Total Booking',
              value: '$_totalBookings',
              color: const Color.fromARGB(255, 0, 113, 72),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: _buildStatCard(
              icon: Icons.workspace_premium,
              title: 'Status',
              value: 'Member',
              color: const Color.fromARGB(255, 0, 117, 164),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 28, color: color),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.mulish(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryDark,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          // Account Section
          _buildSectionTitle('Akun'),
          const SizedBox(height: 12),
          _buildMenuCard([
            _MenuItemData(
              icon: Icons.person_outline,
              title: 'Edit Profil',
              subtitle: 'Ubah informasi profil Anda',
              onTap: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EditProfileScreen(),
                  ),
                );

                // Reload user data if profile was updated
                if (result == true) {
                  if (kDebugMode) print('[ProfileScreen] Returned from edit, clearing cache and reloading...');
                  
                  // Aggressive cache clearing
                  PaintingBinding.instance.imageCache.clear();
                  PaintingBinding.instance.imageCache.clearLiveImages();
                  
                  // Also evict specific image if we know the URL
                  if (_avatarUrl != null && _avatarUrl!.isNotEmpty) {
                    if (kDebugMode) print('[ProfileScreen] Evicting current avatar from cache: $_avatarUrl');
                    final imageProvider = NetworkImage(_avatarUrl!);
                    await imageProvider.evict();
                  }
                  
                  // Small delay to ensure database has propagated
                  await Future.delayed(const Duration(milliseconds: 300));
                  
                  await _loadUserData();
                  
                  // Force another rebuild after load
                  if (mounted) {
                    setState(() {
                      _avatarKey = UniqueKey();
                    });
                  }
                  
                  if (kDebugMode) print('[ProfileScreen] Reload complete');
                }
              },
            ),
            _MenuItemData(
              icon: Icons.receipt_long_outlined,
              title: 'Riwayat Booking',
              subtitle: 'Lihat semua booking Anda',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const UserBookingsScreen(),
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),

          // Settings Section
          _buildSectionTitle('Pengaturan'),
          const SizedBox(height: 12),
          _buildMenuCard([
            _MenuItemData(
              icon: Icons.notifications_outlined,
              title: 'Notifikasi',
              subtitle: 'Kelola preferensi notifikasi',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const NotificationSettingsScreen(),
                  ),
                );
              },
            ),
            _MenuItemData(
              icon: Icons.security_outlined,
              title: 'Keamanan',
              subtitle: 'Ubah password dan keamanan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecuritySettingsScreen(),
                  ),
                );
              },
            ),
            _MenuItemData(
              icon: Icons.school_outlined,
              title: 'Tips Keamanan',
              subtitle: 'Pelajari cara melindungi akun Anda',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SecurityTipsScreen(),
                  ),
                );
              },
            ),
            _MenuItemData(
              icon: Icons.language_outlined,
              title: 'Bahasa',
              subtitle: 'Indonesia',
              onTap: () {
                // TODO: Navigate to language settings
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Fitur sedang dalam pengembangan'),
                  ),
                );
              },
            ),
          ]),

          const SizedBox(height: 20),

          // Support Section
          _buildSectionTitle('Dukungan'),
          const SizedBox(height: 12),
          _buildMenuCard([
            _MenuItemData(
              icon: Icons.help_outline,
              title: 'Bantuan & FAQ',
              subtitle: 'Pertanyaan yang sering ditanyakan',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpFaqScreen(),
                  ),
                );
              },
            ),
            _MenuItemData(
              icon: Icons.info_outline,
              title: 'Tentang Aplikasi',
              subtitle: 'Informasi lengkap tentang SIPELOR',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutAppScreen(),
                  ),
                );
              },
            ),
          ]),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.mulish(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItemData> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          for (int i = 0; i < items.length; i++) ...[
            _buildMenuItem(items[i]),
            if (i < items.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Divider(
                  color: AppColors.borderGray.withOpacity(0.5),
                  height: 1,
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(_MenuItemData item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
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
                item.icon,
                size: 24,
                color: const Color.fromARGB(255, 0, 113, 72),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.mulish(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  if (item.subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle!,
                      style: GoogleFonts.mulish(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppColors.secondaryDark.withOpacity(0.5),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _handleLogout,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red.shade50,
            foregroundColor: Colors.red.shade700,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: Colors.red.shade200, width: 1),
            ),
            elevation: 0,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, size: 20, color: Colors.red.shade700),
              const SizedBox(width: 8),
              Text(
                'Keluar',
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.red.shade700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/sipelor.png',
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'SIPELOR BEDAS',
                style: GoogleFonts.mulish(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sistem Informasi Penyewaan Lapangan Olahraga Kabupaten Bandung',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  color: AppColors.secondaryDark,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                'Versi 1.0.0',
                style: GoogleFonts.mulish(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '© 2026 SIPELOR BEDAS KABUPATEN BANDUNG',
                style: GoogleFonts.mulish(
                  fontSize: 11,
                  color: AppColors.secondaryDark.withOpacity(0.7),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Tutup',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 0, 113, 72),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MenuItemData {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  _MenuItemData({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
  });
}
