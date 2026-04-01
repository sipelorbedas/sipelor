import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:file_picker/file_picker.dart';
import '../../constants/app_colors.dart';
import '../../services/supabase_service.dart';
import '../../utils/input_sanitizer.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  String _userName = '';
  String _userEmail = '';
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasChanges = false;
  File? _selectedImage;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    
    // Listen for changes
    _fullNameController.addListener(_onFieldChanged);
    _phoneController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    if (!_hasChanges) {
      setState(() => _hasChanges = true);
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = SupabaseService.currentUser;
      
      if (user != null) {
        final profile = await SupabaseService.getUserProfile(user.id);
        
        if (profile != null && mounted) {
          setState(() {
            _userName = profile['username'] as String? ?? '';
            _userEmail = profile['email'] as String? ?? user.email ?? '';
            _fullNameController.text = profile['full_name'] as String? ?? '';
            _phoneController.text = profile['phone_number'] as String? ?? '';
            _currentAvatarUrl = profile['avatar_url'] as String?;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error loading user data: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        _showErrorSnackBar('Gagal memuat data profil');
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _selectedImage = File(result.files.single.path!);
          _hasChanges = true;
        });
      }
    } catch (e) {
      if (kDebugMode) print('Error picking image: $e');
      _showErrorSnackBar('Gagal memilih gambar');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Show confirmation dialog
    final confirm = await _showConfirmDialog();
    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Prepare updates with sanitized inputs
      final updates = <String, dynamic>{};

      // Sanitize inputs before saving
      final sanitizedFullName = InputSanitizer.sanitizeText(
        _fullNameController.text.trim(),
      );
      final sanitizedPhone = InputSanitizer.sanitizePhoneNumber(
        _phoneController.text.trim(),
      );

      // Check for malicious patterns
      if (InputSanitizer.containsMaliciousPattern(sanitizedFullName) ||
          InputSanitizer.containsMaliciousPattern(sanitizedPhone)) {
        if (mounted) {
          setState(() => _isSaving = false);
          _showErrorSnackBar('Input mengandung karakter tidak valid');
        }
        return;
      }
      
      final currentProfile = await SupabaseService.getUserProfile(user.id);
      if (currentProfile != null) {
        // Only add changed fields
        if (sanitizedFullName != (currentProfile['full_name'] ?? '')) {
          updates['full_name'] = sanitizedFullName;
        }
        if (sanitizedPhone != (currentProfile['phone_number'] ?? '')) {
          updates['phone_number'] = sanitizedPhone;
        }
      }

      // Upload image if selected
      if (_selectedImage != null) {
        try {
          if (kDebugMode) print('[EditProfile] Starting image upload...');
          final imageUrl = await SupabaseService.uploadProfileImage(
            userId: user.id,
            file: _selectedImage!,
          );
          if (kDebugMode) print('[EditProfile] Image uploaded, URL: $imageUrl');
          updates['avatar_url'] = imageUrl;
          
          // Delete old avatar if exists
          if (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty) {
            try {
              if (kDebugMode) print('[EditProfile] Deleting old avatar: $_currentAvatarUrl');
              await SupabaseService.deleteProfileImage(_currentAvatarUrl!);
              if (kDebugMode) print('[EditProfile] Old avatar deleted');
            } catch (e) {
              if (kDebugMode) print('Warning: Could not delete old avatar: $e');
              // Continue even if deletion fails
            }
          }
        } catch (e) {
          if (kDebugMode) print('Error uploading profile image: $e');
          if (mounted) {
            setState(() => _isSaving = false);
            _showErrorSnackBar('Gagal mengupload foto profil');
            return;
          }
        }
      }

      // Update profile if there are changes
      if (updates.isNotEmpty) {
        if (kDebugMode) print('[EditProfile] Updating profile with: $updates');
        await SupabaseService.updateUserProfile(
          userId: user.id,
          updates: updates,
        );
        if (kDebugMode) print('[EditProfile] Profile updated successfully');
        
        // Wait a bit for database to propagate
        await Future.delayed(const Duration(milliseconds: 300));
        
        // Verify the update
        final updatedProfile = await SupabaseService.getUserProfile(user.id);
        if (kDebugMode) print('[EditProfile] Verified avatar_url in DB: ${updatedProfile?['avatar_url']}');
        
        // Update local state with new avatar URL if it was changed
        if (updates.containsKey('avatar_url')) {
          _currentAvatarUrl = updates['avatar_url'] as String?;
          _selectedImage = null; // Clear selected image since it's now uploaded
        }
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
          _hasChanges = false;
        });
        
        _showSuccessSnackBar('Profil berhasil diperbarui');
        
        // Wait a bit then go back
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          Navigator.pop(context, true); // Return true to indicate profile was updated
        }
      }
    } catch (e) {
      if (kDebugMode) print('Error saving profile: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        _showErrorSnackBar('Gagal menyimpan profil: ${e.toString()}');
      }
    }
  }

  Future<bool?> _showConfirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Simpan Perubahan?',
            style: GoogleFonts.mulish(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          content: Text(
            'Apakah Anda yakin ingin menyimpan perubahan profil?',
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
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
              child: Text(
                'Simpan',
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
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Batalkan Perubahan?',
            style: GoogleFonts.mulish(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
            ),
          ),
          content: Text(
            'Anda memiliki perubahan yang belum disimpan. Yakin ingin keluar?',
            style: GoogleFonts.mulish(
              fontSize: 14,
              color: AppColors.secondaryDark,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Tetap di Sini',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color.fromARGB(255, 0, 113, 72),
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                'Keluar',
                style: GoogleFonts.mulish(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red.shade700,
                ),
              ),
            ),
          ],
        );
      },
    );

    return shouldPop ?? false;
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
      ),
    );
  }

  String? _validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Nama lengkap tidak boleh kosong';
    }
    if (value.trim().length < 3) {
      return 'Nama lengkap minimal 3 karakter';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone is optional
    }
    
    // Remove all non-digit characters for validation
    final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check if it's a valid Indonesian phone number
    if (digitsOnly.length < 10 || digitsOnly.length > 13) {
      return 'Nomor telepon tidak valid (10-13 digit)';
    }
    
    // Check if starts with valid Indonesian prefix
    if (!digitsOnly.startsWith('08') && 
        !digitsOnly.startsWith('628') &&
        !digitsOnly.startsWith('62')) {
      return 'Nomor harus dimulai dengan 08 atau 62';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvoked: (didPop) async {
        if (!didPop && _hasChanges) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.screenBg,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // App Bar with Gradient
                  _buildAppBar(),
                  
                  // Form Content
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Picture Section
                            _buildProfilePictureSection(),
                            
                            const SizedBox(height: 32),
                            
                            // Read-only Info Section
                            _buildSectionTitle('Informasi Akun'),
                            const SizedBox(height: 12),
                            _buildReadOnlyField('Username', _userName, Icons.person_outline),
                            const SizedBox(height: 12),
                            _buildReadOnlyField('Email', _userEmail, Icons.email_outlined),
                            
                            const SizedBox(height: 32),
                            
                            // Editable Fields Section
                            _buildSectionTitle('Informasi Pribadi'),
                            const SizedBox(height: 12),
                            _buildEditableField(
                              label: 'Nama Lengkap',
                              controller: _fullNameController,
                              icon: Icons.badge_outlined,
                              validator: _validateFullName,
                              hint: 'Masukkan nama lengkap Anda',
                            ),
                            const SizedBox(height: 16),
                            _buildEditableField(
                              label: 'Nomor Telepon',
                              controller: _phoneController,
                              icon: Icons.phone_outlined,
                              validator: _validatePhone,
                              hint: 'Contoh: 08123456789',
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[\d+]')),
                              ],
                            ),
                            
                            const SizedBox(height: 40),
                            
                            // Save Button
                            _buildSaveButton(),
                            
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: const Color.fromARGB(255, 0, 113, 72),
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.fromARGB(255, 0, 113, 72),
              Color.fromARGB(255, 0, 117, 164),
            ],
          ),
        ),
        child: FlexibleSpaceBar(
          centerTitle: true,
          title: Text(
            'Edit Profil',
            style: GoogleFonts.mulish(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: Colors.white),
        onPressed: () async {
          if (_hasChanges) {
            final shouldPop = await _onWillPop();
            if (shouldPop && mounted) {
              Navigator.of(context).pop();
            }
          } else {
            Navigator.of(context).pop();
          }
        },
      ),
    );
  }

  Widget _buildProfilePictureSection() {
    return Center(
      child: Column(
        children: [
          Stack(
            children: [
              // Avatar
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color.fromARGB(255, 0, 113, 72),
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: _selectedImage != null
                      ? Image.file(
                          _selectedImage!,
                          width: 120,
                          height: 120,
                          fit: BoxFit.cover,
                        )
                      : (_currentAvatarUrl != null && _currentAvatarUrl!.isNotEmpty)
                          ? Image.network(
                              _currentAvatarUrl!,
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/images/user_avatar.png',
                                  width: 120,
                                  height: 120,
                                  fit: BoxFit.cover,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  width: 120,
                                  height: 120,
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                      valueColor: const AlwaysStoppedAnimation<Color>(
                                        Color.fromARGB(255, 0, 113, 72),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            )
                          : Image.asset(
                              'assets/images/user_avatar.png',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                            ),
                ),
              ),
              
              // Edit Button Overlay
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 0, 113, 72),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ubah Foto Profil',
            style: GoogleFonts.mulish(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color.fromARGB(255, 0, 113, 72),
            ),
          ),
          Text(
            'Tap ikon kamera untuk mengganti',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryDark.withOpacity(0.7),
            ),
          ),
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

  Widget _buildReadOnlyField(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '-' : value,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.lock_outline,
            size: 18,
            color: Colors.grey.shade500,
          ),
        ],
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String? Function(String?) validator,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.mulish(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          style: GoogleFonts.mulish(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.mulish(
              fontSize: 14,
              color: AppColors.secondaryDark.withOpacity(0.5),
            ),
            prefixIcon: Icon(
              icon,
              size: 22,
              color: const Color.fromARGB(255, 0, 113, 72),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.borderGray,
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: AppColors.borderGray,
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color.fromARGB(255, 0, 113, 72),
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.red.shade400,
                width: 1,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: Colors.red.shade600,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSaving ? null : _saveProfile,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          disabledBackgroundColor: Colors.grey.shade300,
        ),
        child: Container(
          decoration: _isSaving
              ? null
              : const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color.fromARGB(255, 0, 113, 72),
                      Color.fromARGB(255, 0, 117, 164),
                    ],
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: _isSaving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.save_outlined,
                      size: 20,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Simpan Perubahan',
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
