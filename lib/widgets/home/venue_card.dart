import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../constants/app_colors.dart';
import '../../models/field.dart';
import '../../models/venue.dart' as venue_model;
import '../../screens/venue/venue_detail_screen.dart';

class VenueCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final String address;
  final double rating;
  final int reviewCount;
  final String? price;
  final String? venueType; // NEW: Jenis venue (Futsal, Badminton, dll)
  final String? satuan; // NEW: Satuan (per jam, per hari, dll)
  final venue_model.Venue? venue;
  final List<Field>? fields;
  final String? venueId; // Direct venue ID (can be passed separately from venue object)
  final double? latitude; // Koordinat latitude venue
  final double? longitude; // Koordinat longitude venue
  final bool isFullWidth; // NEW: Make card responsive and full-width
  final double? customImageHeight; // Override image height (e.g. for grid layout)

  const VenueCard({
    super.key,
    required this.imagePath,
    required this.title,
    required this.address,
    required this.rating,
    required this.reviewCount,
    this.price,
    this.venueType,
    this.satuan,
    this.venue,
    this.fields,
    this.venueId,
    this.latitude,
    this.longitude,
    this.isFullWidth = false,
    this.customImageHeight,
  });

  @override
  Widget build(BuildContext context) {
    // Get field status
    final fieldStatus = fields != null && fields!.isNotEmpty 
        ? fields!.first.status 
        : FieldStatus.available;

    return GestureDetector(
      onTap: () {
        // Show popup if status is booked or maintenance
        if (fieldStatus == FieldStatus.booked || fieldStatus == FieldStatus.maintenance) {
          _showStatusDialog(context, fieldStatus);
          return;
        }
        
        // Navigate to detail screen if available
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VenueDetailScreen(
              imagePath: imagePath,
              title: title,
              address: address,
              rating: rating,
              reviewCount: reviewCount,
              price: price ?? 'Rp. 0',
              field: fields != null && fields!.isNotEmpty ? fields!.first : null,
              venueId: venueId ?? venue?.id, // Use direct venueId or fall back to venue?.id
              latitude: latitude,
              longitude: longitude,
            ),
          ),
        );
      },
      child: isFullWidth
          ? _buildFullWidthCard(context)
          : SizedBox(
              width: 200.0,
              child: _buildCardContent(context, 200.0),
            ),
    );
  }

  Widget _buildFullWidthCard(BuildContext context) {
    return _buildCardContent(context, null);
  }

  Widget _buildCardContent(BuildContext context, double? fixedWidth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image with status badge
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _buildImage(imagePath, fixedWidth),
            ),
            // Status badge overlay
            if (fields != null && fields!.isNotEmpty)
              Positioned(
                top: 8,
                right: 8,
                child: _buildStatusBadge(fields!.first.status),
              ),
          ],
        ),
        const SizedBox(height: 6),
        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  // Title
                  Text(
                    title,
                    style: GoogleFonts.mulish(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  
                  // Jenis Venue (NEW)
                  if (venueType != null)
                    Row(
                      children: [
                        Icon(
                          Icons.sports_soccer_outlined,
                          size: 13,
                          color: AppColors.secondaryDark,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            venueType!,
                            style: GoogleFonts.mulish(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (venueType != null) const SizedBox(height: 2),
                  
                  // Satuan - positioned above location
                  if (satuan != null)
                    Row(
                      children: [
                        Icon(
                          Icons.schedule_outlined,
                          size: 13,
                          color: AppColors.secondaryDark,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            satuan!,
                            style: GoogleFonts.mulish(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: AppColors.secondaryDark,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (satuan != null) const SizedBox(height: 2),
                  
                  // Address/Lokasi
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: AppColors.secondaryDark,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          address,
                          style: GoogleFonts.mulish(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  
                  // Rating
                  Row(
                    children: [
                      SvgPicture.asset(
                        'assets/icons/star_filled.svg',
                        width: 10,
                        height: 10,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFFDC300),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          reviewCount > 0 
                              ? '${rating.toStringAsFixed(1)} ($reviewCount)'
                              : 'Belum ada review',
                          style: GoogleFonts.mulish(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: AppColors.secondaryDark,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  
              // Price only (Satuan moved above location)
              if (price != null)
                Text(
                  price!,
                  style: GoogleFonts.mulish(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImage(String path, double? width) {
    // Responsive height calculation
    final height = customImageHeight ?? (isFullWidth ? 180.0 : 120.0);
    
    // Check if it's a network URL
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return CachedNetworkImage(
        imageUrl: path,
        width: width ?? double.infinity,
        height: height,
        fit: BoxFit.cover,
        // PERFORMANCE: Optimized cache settings for faster loading
        memCacheWidth: 300, // Reduced from 400 for better memory usage
        maxHeightDiskCache: 300,
        fadeInDuration: const Duration(milliseconds: 300), // Smooth fade-in
        placeholder: (context, url) => Container(
          width: width ?? double.infinity,
          height: height,
          color: AppColors.screenBg,
          child: const Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryDark),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          return _buildPlaceholder(width, height);
        },
      );
    } else {
      // Asset image dengan caching
      return Image.asset(
        path,
        width: width ?? double.infinity,
        height: height,
        fit: BoxFit.cover,
        // PERFORMANCE: Optimized decode size for faster loading
        cacheWidth: 300, // Reduced from 400 for better performance
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(width, height);
        },
      );
    }
  }

  Widget _buildPlaceholder(double? width, double height) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      color: AppColors.screenBg,
      child: const Center(
        child: Icon(
          Icons.sports_soccer,
          size: 48,
          color: AppColors.secondaryDark,
        ),
      ),
    );
  }
  
  Widget _buildStatusBadge(FieldStatus status) {
    Color backgroundColor;
    String statusText;
    
    switch (status) {
      case FieldStatus.available:
        backgroundColor = AppColors.statusAvailable;
        statusText = 'Available';
        break;
      case FieldStatus.booked:
        backgroundColor = AppColors.statusBooked;
        statusText = 'Booked';
        break;
      case FieldStatus.maintenance:
        backgroundColor = AppColors.statusMaintenance;
        statusText = 'Maintenance';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        statusText,
        style: GoogleFonts.mulish(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
  
  void _showStatusDialog(BuildContext context, FieldStatus status) {
    String dialogTitle;
    String dialogMessage;
    IconData dialogIcon;
    Color dialogColor;
    
    if (status == FieldStatus.booked) {
      dialogTitle = 'Booked';
      dialogMessage = 'Maaf, Lapangan "$title" Sedang Di Booked Oleh Pihak Ketiga, Silahkan Pilih Lapangan Lain atau Waktu Yang Berbeda.';
      dialogIcon = Icons.event_busy;
      dialogColor = AppColors.statusBooked;
    } else {
      dialogTitle = 'Under Maintance';
      dialogMessage = 'Maaf, Lapangan "$title" Sedang dalam Maintance / Pemeliharaan. Silahkan Pilih Lapangan Lain.';
      dialogIcon = Icons.build_circle;
      dialogColor = AppColors.statusMaintenance;
    }
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: dialogColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    dialogIcon,
                    size: 32,
                    color: dialogColor,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Title
                Text(
                  dialogTitle,
                  style: GoogleFonts.mulish(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                
                // Message
                Text(
                  dialogMessage,
                  style: GoogleFonts.mulish(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryDark,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                
                // OK Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dialogColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Mengerti',
                      style: GoogleFonts.mulish(
                        fontSize: 14,
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
}
