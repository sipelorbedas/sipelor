import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../services/auto_logout_service.dart';
import '../../services/biometric_auth_service.dart';
import '../../services/password_service.dart';
import '../../utils/password_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../info/security_tips_screen.dart';
import 'security_notification_settings_screen.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({super.key});

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  bool _biometricEnabled = false;
  bool _biometricAvailable = true; // Default true, akan di-update saat check
  bool _isCheckingBiometric = true;
  String _biometricTypeName = 'Biometrik';
  String _autoLogoutDuration = '10 menit';
  final AutoLogoutService _autoLogoutService = AutoLogoutService();

  @override
  void initState() {
    super.initState();
    _checkBiometricStatus();
  }

  Future<void> _checkBiometricStatus() async {
    try {
      final available = await BiometricAuthService.isBiometricAvailable();
      final enabled = await BiometricAuthService.isBiometricEnabled();
      final typeName = await BiometricAuthService.getBiometricTypeName();
      
      if (mounted) {
        setState(() {
          _biometricAvailable = available;
          _biometricEnabled = enabled;
          _biometricTypeName = typeName;
          _isCheckingBiometric = false;
        });
      }
    } catch (e) {
      // Jika error, set available = true agar user bisa coba toggle
      // Error akan muncul saat toggle di-klik
      if (mounted) {
        setState(() {
          _biometricAvailable = true;
          _isCheckingBiometric = false;
        });
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
          'Pengaturan Keamanan',
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
          // Password Section
          _buildSectionTitle('Password & Login'),
          const SizedBox(height: 12),
          _buildPasswordCard(),
          
          const SizedBox(height: 24),
          
          // Biometric Section
          _buildSectionTitle('Autentikasi Biometrik'),
          const SizedBox(height: 12),
          _buildBiometricCard(),
          
          const SizedBox(height: 24),
          
          // Auto Logout Section
          _buildSectionTitle('Auto Logout'),
          const SizedBox(height: 12),
          _buildAutoLogoutCard(),
          
          const SizedBox(height: 24),
          
          // Security Notifications Section
          _buildSectionTitle('Notifikasi Keamanan'),
          const SizedBox(height: 12),
          _buildSecurityNotificationsCard(),
          
          const SizedBox(height: 24),
          
          // Security Education Section
          _buildSectionTitle('Edukasi Keamanan'),
          const SizedBox(height: 12),
          _buildSecurityEducationCard(),
          
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

  Widget _buildPasswordCard() {
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
          _buildMenuItem(
            icon: Icons.lock_outline,
            title: 'Ubah Password',
            subtitle: 'Ganti password akun Anda',
            onTap: _showChangePasswordDialog,
          ),
          const Divider(height: 1, indent: 68),
          _buildMenuItem(
            icon: Icons.vpn_key_outlined,
            title: 'Forgot Password',
            subtitle: 'Reset password melalui email',
            onTap: _showForgotPasswordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricCard() {
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
              child: const Icon(
                Icons.fingerprint,
                size: 22,
                color: Color.fromARGB(255, 0, 113, 72),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Login Biometrik',
                    style: GoogleFonts.mulish(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _isCheckingBiometric
                        ? 'Memeriksa ketersediaan...'
                        : (_biometricAvailable
                            ? 'Gunakan $_biometricTypeName untuk login'
                            : 'Tidak tersedia di perangkat ini'),
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
              value: _biometricEnabled,
              onChanged: _isCheckingBiometric
                  ? null
                  : (value) async {
                      if (value) {
                        await _enableBiometric();
                      } else {
                        await _disableBiometric();
                      }
                    },
              activeThumbColor: const Color.fromARGB(255, 0, 113, 72),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoLogoutCard() {
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
        onTap: _showAutoLogoutOptions,
        borderRadius: BorderRadius.circular(16),
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
                child: const Icon(
                  Icons.timer_outlined,
                  size: 22,
                  color: Color.fromARGB(255, 0, 113, 72),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Waktu Auto Logout',
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Logout otomatis setelah $_autoLogoutDuration tidak aktif',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
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

  Widget _buildSecurityNotificationsCard() {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecurityNotificationSettingsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  size: 22,
                  color: Colors.orange,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Notifikasi Keamanan',
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Kelola notifikasi untuk aktivitas mencurigakan',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
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

  Widget _buildSecurityEducationCard() {
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
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SecurityTipsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school_outlined,
                  size: 22,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tips Keamanan',
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pelajari cara melindungi akun dari ancaman',
                      style: GoogleFonts.mulish(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
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

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
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
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.secondaryDark,
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureOld = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    bool isLoading = false;
    String? passwordStrengthLabel;
    int passwordStrength = 0;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                    child: const Icon(
                      Icons.lock_outline,
                      size: 40,
                      color: Color.fromARGB(255, 0, 113, 72),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Ubah Password',
                    style: GoogleFonts.mulish(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Masukkan password lama dan password baru Anda',
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryDark,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.orange.shade200,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.orange.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'PENTING: Jangan bagikan password ke siapapun, termasuk yang mengaku dari tim SIPELOR',
                            style: GoogleFonts.mulish(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Password Lama',
                        labelStyle: GoogleFonts.mulish(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureOld ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() => obscureOld = !obscureOld);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 0, 113, 72),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      enabled: !isLoading,
                      onChanged: (value) {
                        setDialogState(() {
                          passwordStrength = PasswordValidator.getStrength(value);
                          passwordStrengthLabel = PasswordValidator.getStrengthLabel(value);
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        labelStyle: GoogleFonts.mulish(),
                        prefixIcon: const Icon(Icons.vpn_key),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNew ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() => obscureNew = !obscureNew);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 0, 113, 72),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                    if (newPasswordController.text.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: passwordStrength / 4,
                              backgroundColor: Colors.grey.shade300,
                              color: passwordStrength <= 1
                                  ? Colors.red
                                  : passwordStrength == 2
                                      ? Colors.orange
                                      : passwordStrength == 3
                                          ? Colors.blue
                                          : Colors.green,
                              minHeight: 4,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            passwordStrengthLabel ?? '',
                            style: GoogleFonts.mulish(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: passwordStrength <= 1
                                  ? Colors.red
                                  : passwordStrength == 2
                                      ? Colors.orange
                                      : passwordStrength == 3
                                          ? Colors.blue
                                          : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    TextField(
                      controller: confirmPasswordController,
                      obscureText: obscureConfirm,
                      enabled: !isLoading,
                      decoration: InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        labelStyle: GoogleFonts.mulish(),
                        prefixIcon: const Icon(Icons.check_circle_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() => obscureConfirm = !obscureConfirm);
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color.fromARGB(255, 0, 113, 72),
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isLoading ? null : () => Navigator.of(context).pop(),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.mulish(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isLoading ? Colors.grey : AppColors.secondaryDark,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading ? null : () async {
                    setDialogState(() => isLoading = true);
                    
                    final error = await PasswordService.changePassword(
                      oldPassword: oldPasswordController.text,
                      newPassword: newPasswordController.text,
                      confirmPassword: confirmPasswordController.text,
                    );
                    
                    if (mounted) {
                      Navigator.of(context).pop();
                      
                      if (error == null) {
                        _showSuccessSnackBar(
                          'Password berhasil diubah. Semua sesi lain telah diakhiri.'
                        );
                      } else {
                        _showErrorSnackBar(error);
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isLoading 
                        ? Colors.grey 
                        : const Color.fromARGB(255, 0, 113, 72),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    elevation: 0,
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Ubah Password',
                          style: GoogleFonts.mulish(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showForgotPasswordDialog() {
    final emailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                child: const Icon(
                  Icons.email_outlined,
                  size: 40,
                  color: Color.fromARGB(255, 0, 113, 72),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Reset Password',
                style: GoogleFonts.mulish(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Masukkan email Anda untuk menerima link reset password',
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryDark,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          content: TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Email',
              labelStyle: GoogleFonts.mulish(),
              prefixIcon: const Icon(Icons.email_outlined),
              hintText: 'contoh@email.com',
              hintStyle: GoogleFonts.mulish(
                color: Colors.grey.shade400,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: Color.fromARGB(255, 0, 113, 72),
                  width: 2,
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.of(context).pop(),
              child: Text(
                'Batal',
                style: GoogleFonts.mulish(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isLoading ? Colors.grey : AppColors.secondaryDark,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                setDialogState(() => isLoading = true);
                
                final error = await PasswordService.requestPasswordReset(
                  email: emailController.text,
                );
                
                if (mounted) {
                  Navigator.of(context).pop();
                  
                  if (error == null) {
                    _showSuccessSnackBar(
                      'Link reset password telah dikirim ke email Anda (jika terdaftar).'
                    );
                  } else {
                    _showErrorSnackBar(error);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: isLoading 
                    ? Colors.grey 
                    : const Color.fromARGB(255, 0, 113, 72),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
              ),
              child: isLoading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Kirim Link',
                      style: GoogleFonts.mulish(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
            ),
          ],
            );
          },
        );
      },
    );
  }

  Future<void> _enableBiometric() async {
    // Check if biometric is actually available
    final available = await BiometricAuthService.isBiometricAvailable();
    if (!available) {
      if (mounted) {
        _showErrorSnackBar('Biometrik tidak tersedia di perangkat ini');
      }
      return;
    }

    // First authenticate with biometric to make sure it works
    final authenticated = await BiometricAuthService.authenticate(
      reason: 'Verifikasi $_biometricTypeName untuk mengaktifkan login biometrik',
    );

    if (!authenticated) {
      if (mounted) {
        _showErrorSnackBar('Autentikasi $_biometricTypeName gagal');
      }
      return;
    }

    // Get current user credentials
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      if (mounted) {
        _showErrorSnackBar('Tidak ada sesi login aktif');
      }
      return;
    }

    // Show dialog to enter password for security
    final passwordController = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
              child: const Icon(
                Icons.fingerprint,
                size: 40,
                color: Color.fromARGB(255, 0, 113, 72),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Aktifkan Login $_biometricTypeName',
              style: GoogleFonts.mulish(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Masukkan password Anda untuk menyimpan kredensial dengan aman',
              style: GoogleFonts.mulish(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryDark,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: TextField(
          controller: passwordController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: GoogleFonts.mulish(),
            prefixIcon: const Icon(Icons.lock_outline),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 0, 113, 72),
                width: 2,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Batal',
              style: GoogleFonts.mulish(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryDark,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              if (passwordController.text.isEmpty) {
                return;
              }
              Navigator.of(context).pop(true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 0, 113, 72),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              elevation: 0,
            ),
            child: Text(
              'Aktifkan',
              style: GoogleFonts.mulish(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (result != true || passwordController.text.isEmpty) {
      return;
    }

    try {
      // Get username from user metadata or email
      final username = currentUser.userMetadata?['username'] as String? ?? 
                      currentUser.email?.split('@')[0] ?? 
                      '';

      // Save credentials
      await BiometricAuthService.enableBiometric(
        username: username,
        password: passwordController.text,
      );

      if (mounted) {
        setState(() => _biometricEnabled = true);
        _showSuccessSnackBar('Login $_biometricTypeName berhasil diaktifkan');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal mengaktifkan login $_biometricTypeName');
      }
    }
  }

  Future<void> _disableBiometric() async {
    try {
      await BiometricAuthService.disableBiometric();
      
      if (mounted) {
        setState(() => _biometricEnabled = false);
        _showSuccessSnackBar('Login $_biometricTypeName dinonaktifkan');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Gagal menonaktifkan login $_biometricTypeName');
      }
    }
  }

  void _showAutoLogoutOptions() {
    final logoutOptions = [
      {'label': '5 menit', 'value': '5 menit', 'icon': Icons.timer_outlined},
      {'label': '10 menit', 'value': '10 menit', 'icon': Icons.timer_outlined},
      {'label': '15 menit', 'value': '15 menit', 'icon': Icons.timer_outlined},
      {'label': '30 menit', 'value': '30 menit', 'icon': Icons.timer_outlined},
      {'label': '1 jam', 'value': '1 jam', 'icon': Icons.schedule_outlined},
      {'label': '2 jam', 'value': '2 jam', 'icon': Icons.schedule_outlined},
      {'label': 'Tidak Pernah', 'value': 'Tidak Pernah', 'icon': Icons.all_inclusive},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (BuildContext context) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.timer_outlined,
                        size: 24,
                        color: Color.fromARGB(255, 0, 113, 72),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pilih Waktu Auto Logout',
                          style: GoogleFonts.mulish(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Logout otomatis saat tidak aktif',
                          style: GoogleFonts.mulish(
                            fontSize: 13,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: logoutOptions.length,
                  itemBuilder: (context, index) {
                    final option = logoutOptions[index];
                    final isSelected = _autoLogoutDuration == option['value'];
                    
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _autoLogoutDuration = option['value'] as String;
                        });
                        
                        // Enable or disable auto logout based on selection
                        if (option['value'] == 'Tidak Pernah') {
                          _autoLogoutService.setEnabled(false);
                          _showSuccessSnackBar('Auto logout dinonaktifkan');
                        } else {
                          _autoLogoutService.setEnabled(true);
                          _showSuccessSnackBar(
                            'Auto logout diatur ke ${option['label']}',
                          );
                        }
                        
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color.fromARGB(255, 0, 113, 72).withOpacity(0.05)
                              : Colors.transparent,
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color.fromARGB(255, 0, 113, 72).withOpacity(0.1)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                option['icon'] as IconData,
                                size: 20,
                                color: isSelected
                                    ? const Color.fromARGB(255, 0, 113, 72)
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                option['label'] as String,
                                style: GoogleFonts.mulish(
                                  fontSize: 15,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected
                                      ? const Color.fromARGB(255, 0, 113, 72)
                                      : AppColors.primaryDark,
                                ),
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: Color.fromARGB(255, 0, 113, 72),
                                size: 22,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
