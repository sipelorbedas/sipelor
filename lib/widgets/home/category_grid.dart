import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../screens/tournament/bupati_cup_screen.dart';

class CategoryItem {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const CategoryItem({
    required this.label,
    required this.icon,
    required this.color,
    this.onTap,
  });
}

class CategoryGrid extends StatelessWidget {
  const CategoryGrid({super.key});

  void _showComingSoonDialog(BuildContext context, CategoryItem category) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            width: 320,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  category.color.withOpacity(0.1),
                  Colors.white,
                ],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        category.color.withOpacity(0.8),
                        category.color,
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: category.color.withOpacity(0.3),
                        offset: const Offset(0, 4),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Icon(
                    category.icon,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                
                // Title
                Text(
                  category.label,
                  style: GoogleFonts.mulish(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Coming Soon Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: category.color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: category.color,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Coming Soon',
                        style: GoogleFonts.mulish(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: category.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  _getFeatureDescription(category.label),
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // Close Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: category.color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Mengerti',
                      style: GoogleFonts.mulish(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getFeatureDescription(String categoryLabel) {
    switch (categoryLabel) {
      case 'Bupati Cup':
        return 'Daftarkan tim Anda untuk turnamen resmi, lihat bracket pertandingan, dan jadwal lengkap.';
      case 'Multi Event':
        return 'Jelajahi kalender event olahraga, festival, workshop, dan acara menarik lainnya.';
      case 'Tiket':
        return 'Beli tiket untuk event, pertandingan, konser, dan berbagai acara dengan mudah.';
      case 'Moment':
        return 'Upload dan bagikan momen olahraga Anda, lihat galeri foto dari berbagai venue.';
      case 'Kegiatan':
        return 'Ikuti kegiatan terbaru, baca pengumuman penting, dan update berita terkini.';
      case 'Sidora':
        return 'Akses dokumen penting, peraturan, formulir, dan file yang Anda butuhkan.';
      case 'Sidopa':
        return 'Temukan lokasi venue terdekat, navigasi, dan informasi fasilitas sekitar.';
      default:
        return 'Fitur ini sedang dalam pengembangan dan akan segera hadir untuk Anda!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      // Row 1
      CategoryItem(
        label: 'Venue SJH',
        icon: Icons.stadium_outlined,
        color: const Color(0xFF4CAF50), // Green
        onTap: () {
          // Navigate to venue list (already functional)
          Navigator.pushNamed(context, '/venue-list');
        },
      ),
      CategoryItem(
        label: 'Bupati Cup',
        icon: Icons.emoji_events_outlined,
        color: const Color(0xFFFFB300), // Amber
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const BupatiCupScreen(),
          ),
        ),
      ),
      CategoryItem(
        label: 'Multi Event',
        icon: Icons.calendar_today_outlined,
        color: const Color(0xFF2196F3), // Blue
        onTap: () => _showComingSoonDialog(
          context,
          const CategoryItem(
            label: 'Multi Event',
            icon: Icons.calendar_today_outlined,
            color: Color(0xFF2196F3),
          ),
        ),
      ),
      CategoryItem(
        label: 'Tiket',
        icon: Icons.confirmation_number_outlined,
        color: const Color(0xFFE91E63), // Pink
        onTap: () => _showComingSoonDialog(
          context,
          const CategoryItem(
            label: 'Tiket',
            icon: Icons.confirmation_number_outlined,
            color: Color(0xFFE91E63),
          ),
        ),
      ),
      // Row 2
      CategoryItem(
        label: 'Moment',
        icon: Icons.camera_alt_outlined,
        color: const Color(0xFF9C27B0), // Purple
        onTap: () => _showComingSoonDialog(
          context,
          const CategoryItem(
            label: 'Moment',
            icon: Icons.camera_alt_outlined,
            color: Color(0xFF9C27B0),
          ),
        ),
      ),
      CategoryItem(
        label: 'Kegiatan',
        icon: Icons.assignment_outlined,
        color: const Color(0xFFFF5722), // Deep Orange
        onTap: () => _showComingSoonDialog(
          context,
          const CategoryItem(
            label: 'Kegiatan',
            icon: Icons.assignment_outlined,
            color: Color(0xFFFF5722),
          ),
        ),
      ),
      CategoryItem(
        label: 'Sidora',
        icon: Icons.folder_outlined,
        color: const Color(0xFF00BCD4), // Cyan
        onTap: () => _showComingSoonDialog(
          context,
          const CategoryItem(
            label: 'Sidora',
            icon: Icons.folder_outlined,
            color: Color(0xFF00BCD4),
          ),
        ),
      ),
      CategoryItem(
        label: 'Sidopa',
        icon: Icons.location_on_outlined,
        color: const Color(0xFFF44336), // Red
        onTap: () => _showComingSoonDialog(
          context,
          const CategoryItem(
            label: 'Sidopa',
            icon: Icons.location_on_outlined,
            color: Color(0xFFF44336),
          ),
        ),
      ),
    ];

    return Column(
      children: [
        // Row 1
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.sublist(0, 4).map((category) {
            return _CategoryBox(item: category);
          }).toList(),
        ),
        const SizedBox(height: 7),
        // Row 2
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: categories.sublist(4, 8).map((category) {
            return _CategoryBox(item: category);
          }).toList(),
        ),
      ],
    );
  }
}

class _CategoryBox extends StatelessWidget {
  final CategoryItem item;

  const _CategoryBox({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        children: [
          Container(
            width: 65,
            height: 65,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withOpacity(0.8),
                  item.color,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: item.color.withOpacity(0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            item.label,
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
