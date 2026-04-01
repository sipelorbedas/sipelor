import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../services/supabase_service.dart';
import '../../models/user_role.dart';

/// Screen untuk testing dan debugging role-based access
class RoleCheckScreen extends StatefulWidget {
  const RoleCheckScreen({super.key});

  @override
  State<RoleCheckScreen> createState() => _RoleCheckScreenState();
}

class _RoleCheckScreenState extends State<RoleCheckScreen> {
  UserRole? _currentRole;
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final role = await SupabaseService.getCurrentUserRole();
      final user = SupabaseService.currentUser;
      
      Map<String, dynamic>? profile;
      if (user != null) {
        profile = await SupabaseService.getUserProfile(user.id);
      }

      setState(() {
        _currentRole = role;
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) print('Error loading user role: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Role Check & Debug',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 0, 113, 72),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildRoleCard(),
                  const SizedBox(height: 20),
                  _buildUserInfoCard(),
                  const SizedBox(height: 20),
                  _buildActionsCard(),
                  const SizedBox(height: 20),
                  _buildPermissionsCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildRoleCard() {
    final isAdmin = _currentRole?.isAdmin ?? false;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: isAdmin
                ? [
                    const Color.fromARGB(255, 0, 113, 72),
                    const Color.fromARGB(255, 0, 117, 164),
                  ]
                : [
                    Colors.blue.shade400,
                    Colors.blue.shade600,
                  ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              isAdmin ? Icons.admin_panel_settings : Icons.person,
              size: 64,
              color: Colors.white,
            ),
            const SizedBox(height: 12),
            Text(
              _currentRole?.displayName ?? 'Unknown',
              style: GoogleFonts.poppins(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Current Role',
              style: GoogleFonts.mulish(
                fontSize: 14,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final user = SupabaseService.currentUser;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Information',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 24),
            _buildInfoRow('User ID', user?.id ?? 'Not logged in'),
            _buildInfoRow('Email', user?.email ?? '-'),
            _buildInfoRow('Username', _userProfile?['username'] ?? '-'),
            _buildInfoRow('Full Name', _userProfile?['full_name'] ?? '-'),
            _buildInfoRow('Role', _userProfile?['role'] ?? '-'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.mulish(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Actions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loadUserRole,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Role'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_currentRole?.isAdmin ?? false) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacementNamed('/home');
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Gunakan Web Admin Panel'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 0, 117, 164),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionsCard() {
    final isAdmin = _currentRole?.isAdmin ?? false;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Permissions',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Divider(height: 24),
            _buildPermissionItem('View own profile', true),
            _buildPermissionItem('Create bookings', true),
            _buildPermissionItem('Upload payment proof', true),
            _buildPermissionItem('View all users', isAdmin),
            _buildPermissionItem('Verify payments', isAdmin),
            _buildPermissionItem('Manage venues', isAdmin),
            _buildPermissionItem('Manage fields', isAdmin),
            _buildPermissionItem('Update user roles', isAdmin),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionItem(String permission, bool granted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            granted ? Icons.check_circle : Icons.cancel,
            color: granted ? Colors.green : Colors.red.shade300,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              permission,
              style: GoogleFonts.mulish(
                fontSize: 14,
                color: granted ? Colors.black87 : Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
