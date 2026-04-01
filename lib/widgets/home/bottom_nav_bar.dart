import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final int bookingNotificationCount;
  final int chatNotificationCount;

  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.bookingNotificationCount = 0,
    this.chatNotificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.13),
            offset: const Offset(0, -5),
            blurRadius: 40,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                iconPath: 'assets/icons/home_icon.svg',
                label: 'Beranda',
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                iconPath: 'assets/icons/field_icon.svg',
                label: 'Lapangan',
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                iconPath: 'assets/icons/booking_icon.svg',
                label: 'Pemesanan',
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
                notificationCount: bookingNotificationCount,
              ),
              _NavItem(
                iconPath: 'assets/icons/chat_icon.svg',
                label: 'Chat',
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
                notificationCount: chatNotificationCount,
              ),
              _NavItem(
                iconPath: 'assets/icons/profile_icon.svg',
                label: 'Profil',
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String iconPath;
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final int notificationCount;

  const _NavItem({
    required this.iconPath,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.notificationCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? AppColors.primaryDark : AppColors.navInactive;
    
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with notification badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  iconPath,
                  width: 20,
                  height: 20,
                  colorFilter: ColorFilter.mode(
                    color,
                    BlendMode.srcIn,
                  ),
                ),
                // Notification badge (red dot)
                if (notificationCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: GoogleFonts.mulish(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
