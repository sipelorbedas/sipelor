import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';
import '../../constants/app_colors.dart';
import '../../models/field.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_cache_service.dart';
import '../../widgets/animated_gradient_button.dart';
import '../../widgets/offline_banner.dart';
import '../../services/supabase_service.dart';
import '../user/booking_confirmation_screen.dart';
import '../auth/auth_screen.dart';

class VenueDetailScreen extends StatefulWidget {
  final String imagePath;
  final String title;
  final String address;
  final double rating;
  final int reviewCount;
  final String price;
  final Field? field; // Optional field data from database
  final String? venueId; // Optional venue ID
  final double? latitude; // Latitude koordinat venue
  final double? longitude; // Longitude koordinat venue

  const VenueDetailScreen({
    super.key,
    required this.imagePath,
    required this.title,
    required this.address,
    required this.rating,
    required this.reviewCount,
    required this.price,
    this.field,
    this.venueId,
    this.latitude,
    this.longitude,
  });

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen> {
  int _selectedTab = 0; // 0 = Fasilitas, 1 = Review
  late PageController _carouselController;
  int _currentCarouselPage = 0;
  late List<String> _carouselImages;

  // ─── Offline support ───────────────────────────────────────────────────────
  bool _isOffline = false;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) print('🎬 [VenueDetail] ===== INIT STATE =====');
    if (kDebugMode) print('🎬 [VenueDetail] Widget created for venue: ${widget.title}');
    if (kDebugMode) print('🎬 [VenueDetail] Venue ID: ${widget.venueId}');
    if (kDebugMode) print('🎬 [VenueDetail] Venue ID type: ${widget.venueId.runtimeType}');
    
    _carouselController = PageController();
    _initializeCarouselImages();

    // Track offline state
    _isOffline = !ConnectivityService().isOnline;
    _connectivitySub = ConnectivityService().onConnectivityChanged.listen((online) {
      if (mounted) setState(() => _isOffline = !online);
    });

    if (kDebugMode) print('🎬 [VenueDetail] Init complete');
  }

  void _initializeCarouselImages() {
    // Use admin-uploaded photos if available, otherwise use default assets
    if (widget.field?.imageUrls != null && widget.field!.imageUrls!.isNotEmpty) {
      // Use field's uploaded images
      _carouselImages = widget.field!.imageUrls!;
      if (kDebugMode) print('📸 [VenueDetail] Using ${_carouselImages.length} uploaded images from field');
    } else {
      // Fallback to default asset images
      _carouselImages = [
        'assets/images/stadium_jalak_harupat.jpg',
        'assets/images/training_soccer.png',
        'assets/images/venue_gallery_1.png',
        'assets/images/venue_gallery_2.png',
      ];
      if (kDebugMode) print('📸 [VenueDetail] Using default asset images (no uploaded images found)');
    }
  }

  // Stream reviews with real-time updates using SupabaseService
  Stream<List<Map<String, dynamic>>> _getReviewsStream() {
    // Validate venueId exists and is not empty
    if (widget.venueId == null || widget.venueId!.trim().isEmpty) {
      if (kDebugMode) print('⚠️ [VenueDetail] Invalid venueId, returning empty stream');
      return Stream.value([]);
    }

    // Offline: kembalikan data dari cache
    if (_isOffline) {
      return Stream.fromFuture(
        OfflineCacheService()
            .getCachedReviews(widget.venueId!)
            .then((cached) => cached ?? []),
      );
    }
    
    if (kDebugMode) print('📡 [VenueDetail] ===== INITIALIZING STREAM =====');
    if (kDebugMode) print('📡 [VenueDetail] Venue ID: ${widget.venueId}');
    if (kDebugMode) print('📡 [VenueDetail] Venue ID type: ${widget.venueId.runtimeType}');
    if (kDebugMode) print('📡 [VenueDetail] Venue Name: ${widget.title}');
    
    // Ensure venueId is passed as String (should already be String but explicit for safety)
    final venueIdString = widget.venueId!.toString();
    
    // TOGGLE THIS FOR DEBUGGING:
    // Set debugMode = true to see ALL reviews without filtering
    // Set debugMode = false for normal operation (filtered by venue)
    const bool debugMode = false; // Change to true for testing
    
    if (debugMode) {
      if (kDebugMode) print('🧪 [VenueDetail] DEBUG MODE ENABLED: Will show ALL reviews');
    }
    
    return SupabaseService.streamReviewsByVenueId(
      venueId: venueIdString,
      debugMode: debugMode,
    );
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    _carouselController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) print('🎨 [VenueDetail] ===== BUILD METHOD CALLED =====');
    if (kDebugMode) print('🎨 [VenueDetail] Current tab: ${_selectedTab == 0 ? "Fasilitas" : "Review"}');
    
    // Set status bar to transparent
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      backgroundColor: AppColors.screenBg,
      body: SafeArea(
        child: Column(
          children: [
            // Offline Banner
            const OfflineBanner(),

            // Main scrollable content
            Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Header with carousel
                  _buildHeader(),

                  // Content card
                  _buildContentCard(),

                  // Bottom spacing for fixed button
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

            // Fixed bottom button
            _buildFixedBottomButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 304,
      child: Stack(
        children: [
          // Carousel
          PageView.builder(
            controller: _carouselController,
            onPageChanged: (index) {
              setState(() {
                _currentCarouselPage = index;
              });
            },
            itemCount: _carouselImages.length,
            itemBuilder: (context, index) {
              final imagePath = _carouselImages[index];
              // Check if it's a URL or asset path
              if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
                // Network image from admin upload
                return Image.network(
                  imagePath,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to default image on error
                    return Image.asset(
                      'assets/images/stadium_jalak_harupat.jpg',
                      fit: BoxFit.cover,
                    );
                  },
                );
              } else {
                // Asset image
                return Image.asset(imagePath, fit: BoxFit.cover);
              }
            },
          ),

          // Back button
          Positioned(
            top: 50,
            left: 20,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SvgPicture.asset(
                  'assets/icons/arrow_left.svg',
                  width: 18,
                  height: 11,
                  colorFilter: const ColorFilter.mode(
                    Colors.white,
                    BlendMode.srcIn,
                  ),
                ),
              ),
            ),
          ),

          // Image counter
          Positioned(
            bottom: 15,
            right: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${_currentCarouselPage + 1}/${_carouselImages.length}',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 7),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 19, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title and Rating
            _buildTitleSection(),

            const SizedBox(height: 15),

            // Address
            _buildAddressSection(),

            const SizedBox(height: 10),

            // Tabs
            _buildTabSection(),

            const SizedBox(height: 20),

            // Content based on selected tab
            if (_selectedTab == 0) ...[
              _buildFacilitiesSection(),
            ] else ...[
              Builder(
                builder: (context) {
                  if (kDebugMode) print('🏗️ [VenueDetail] Building Review Section...');
                  return _buildReviewsSection();
                },
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.title,
          style: GoogleFonts.mulish(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 5),
        // Use StreamBuilder for real-time rating display
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: _getReviewsStream(),
          builder: (context, snapshot) {
            final reviews = snapshot.data ?? [];
            final rating = reviews.isEmpty
                ? 0.0
                : reviews.fold<double>(0, (sum, review) => sum + (review['rating'] as int)) / reviews.length;
            
            return Row(
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
                const SizedBox(width: 3.12),
                Text(
                  reviews.isEmpty
                      ? 'Belum ada review'
                      : '${rating.toStringAsFixed(1)} (${reviews.length})',
                  style: GoogleFonts.mulish(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryDark,
                  ),
                ),
              ],
            );
          },
        ),
        // NEW: Satuan - positioned below rating
        if (widget.field?.satuan != null) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              Icon(
                Icons.schedule_outlined,
                size: 14,
                color: AppColors.secondaryDark,
              ),
              const SizedBox(width: 4),
              Text(
                widget.field!.satuan!,
                style: GoogleFonts.mulish(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
        ],
        // NEW: Jenis Venue
        if (widget.field != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.sports_soccer_outlined,
                size: 14,
                color: AppColors.secondaryDark,
              ),
              const SizedBox(width: 4),
              Text(
                widget.field!.venueType,
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAddressSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SvgPicture.asset(
          'assets/icons/location_pin.svg',
          width: 45,
          height: 46,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.address,
                style: GoogleFonts.mulish(
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(height: 5),
              GestureDetector(
                onTap: _openGoogleMaps,
                child: Text(
                  'Buka di Google Maps',
                  style: GoogleFonts.mulish(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0C3EEE),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Function to open Google Maps with venue location
  Future<void> _openGoogleMaps() async {
    // Gunakan koordinat dari parameter widget, atau default ke Stadion SOR Jalak Harupat
    final double latitude = widget.latitude ?? -6.996321;
    final double longitude = widget.longitude ?? 107.529595;
    final String locationName = widget.title;
    
    // Try different URL schemes for better compatibility
    final List<String> urlSchemes = [
      // Google Maps app (preferred)
      'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude',
      // Universal fallback
      'https://maps.google.com/?q=$latitude,$longitude',
    ];

    for (final urlString in urlSchemes) {
      final Uri url = Uri.parse(urlString);
      
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(
            url,
            mode: LaunchMode.externalApplication, // Open in external app
          );
          return; // Success, exit
        }
      } catch (e) {
        if (kDebugMode) print('❌ Error launching URL $urlString: $e');
        continue; // Try next URL
      }
    }
    
    // If all attempts fail, show error message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Tidak dapat membuka Google Maps'),
          backgroundColor: Colors.red,
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {},
          ),
        ),
      );
    }
  }

  Widget _buildTabSection() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: const Color(0xFFDFDFDF), width: 1),
          bottom: BorderSide(color: const Color(0xFFDFDFDF), width: 1),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Row(
              children: [
                const SizedBox(width: 48),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = 0;
                    });
                  },
                  child: Text(
                    'Fasilitas',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: _selectedTab == 0
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: _selectedTab == 0
                          ? AppColors.primaryDark
                          : AppColors.primaryDark.withOpacity(0.5),
                    ),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (kDebugMode) print('👆 [VenueDetail] Review tab tapped');
                    setState(() {
                      _selectedTab = 1;
                      if (kDebugMode) print('✅ [VenueDetail] Tab switched to Review (index: 1)');
                    });
                  },
                  child: Text(
                    'Review',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: _selectedTab == 1
                          ? FontWeight.w700
                          : FontWeight.w400,
                      color: _selectedTab == 1
                          ? AppColors.primaryDark
                          : AppColors.primaryDark.withOpacity(0.5),
                    ),
                  ),
                ),
                const SizedBox(width: 49),
              ],
            ),
          ),
          // Indicator line with animation
          Stack(
            children: [
              // Animated indicator
              AnimatedAlign(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: _selectedTab == 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                child: Container(
                  margin: _selectedTab == 0
                      ? const EdgeInsets.only(left: 36)
                      : const EdgeInsets.only(right: 36),
                  width: 68,
                  height: 2,
                  decoration: const BoxDecoration(color: Color(0xFFFDC300)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFacilitiesSection() {
    // Get facility data from field if available
    final ukuran = widget.field?.ukuranLapangan ?? '16.8m x 24.95m';
    final kapasitas = widget.field?.kapasitas ?? '14 orang';
    final hasTempatParkir = widget.field?.tempatParkir ?? true;
    final hasMushola = widget.field?.mushola ?? true;
    final hasCctv = widget.field?.cctv ?? true;
    final hasRuangTunggu = widget.field?.ruangTunggu ?? true;
    final hasRuangGanti = widget.field?.ruangGanti ?? true;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column
        Expanded(
          child: Column(
            children: [
              _buildFacilityItem(
                'assets/icons/size_icon.svg',
                'Ukuran : $ukuran',
              ),
              const SizedBox(height: 8),
              _buildFacilityItem(
                'assets/icons/capacity_icon.svg',
                'Kapasitas : $kapasitas',
              ),
              if (hasTempatParkir) ...[
                const SizedBox(height: 8),
                _buildFacilityItem(
                  'assets/icons/parking_icon.svg',
                  'Tempat Parkir',
                ),
              ],
              if (hasMushola) ...[
                const SizedBox(height: 8),
                _buildFacilityItem('assets/icons/mushola_icon.svg', 'Mushola'),
              ],
            ],
          ),
        ),
        const SizedBox(width: 20),
        // Right column
        Expanded(
          child: Column(
            children: [
              if (hasCctv) ...[
                _buildFacilityItem('assets/icons/cctv_icon.svg', 'Full CCTV'),
                const SizedBox(height: 8),
              ],
              if (hasRuangTunggu) ...[
                _buildFacilityItem(
                  'assets/icons/waiting_room_icon.svg',
                  'Ruang Tunggu',
                ),
                const SizedBox(height: 8),
              ],
              if (hasRuangGanti) ...[
                _buildFacilityItem(
                  'assets/icons/changing_room_icon.svg',
                  'Ruang Ganti',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFacilityItem(String iconPath, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: SvgPicture.asset(
            iconPath,
            width: 20,
            height: 20,
            colorFilter: const ColorFilter.mode(
              AppColors.primaryDark,
              BlendMode.srcIn,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection() {
    if (kDebugMode) print('📺 [VenueDetail] _buildReviewsSection() called');
    
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _getReviewsStream(),
      builder: (context, snapshot) {
        // DEBUGGING: Print connection state on every rebuild
        final timestamp = DateTime.now().toString().split('.')[0];
        if (kDebugMode) print('🎨 [VenueDetail] [$timestamp] StreamBuilder rebuild');
        if (kDebugMode) print('🎨 [VenueDetail] ├─ State: ${snapshot.connectionState}');
        if (kDebugMode) print('🎨 [VenueDetail] ├─ Has data: ${snapshot.hasData}');
        if (kDebugMode) print('🎨 [VenueDetail] ├─ Has error: ${snapshot.hasError}');
        
        if (snapshot.hasData) {
          if (kDebugMode) print('🎨 [VenueDetail] └─ Data count: ${snapshot.data!.length} reviews');
          // Cache reviews saat online agar bisa diakses offline
          if (!_isOffline &&
              snapshot.data!.isNotEmpty &&
              widget.venueId != null &&
              widget.venueId!.isNotEmpty) {
            OfflineCacheService().cacheReviews(widget.venueId!, snapshot.data!);
          }
        } else if (snapshot.hasError) {
          if (kDebugMode) print('🎨 [VenueDetail] └─ Error: ${snapshot.error}');
        } else {
          if (kDebugMode) print('🎨 [VenueDetail] └─ Waiting for data...');
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (kDebugMode) print('⏳ [VenueDetail] Stream is waiting...');
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          if (kDebugMode) print('❌ [VenueDetail] Stream error: ${snapshot.error}');
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Terjadi kesalahan',
                    style: GoogleFonts.mulish(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: GoogleFonts.mulish(
                      fontSize: 13,
                      color: Colors.grey.shade400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final reviews = snapshot.data ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overall Rating Summary
            _buildRatingSummary(reviews),

            const SizedBox(height: 20),

            // Reviews List
            _buildReviewsList(reviews),
          ],
        );
      },
    );
  }

  Widget _buildRatingSummary(List<Map<String, dynamic>> reviews) {
    // Calculate actual rating from reviews
    final actualRating = reviews.isEmpty
        ? 0.0 // No reviews yet
        : reviews.fold<double>(0, (sum, review) => sum + (review['rating'] as int)) / reviews.length;
    final actualReviewCount = reviews.length; // Always use actual count from database
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.screenBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Large rating number
              Text(
                actualRating.toStringAsFixed(1),
                style: GoogleFonts.mulish(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 12),
              // Stars and review count
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        index < actualRating.floor()
                            ? Icons.star
                            : (index < actualRating
                                  ? Icons.star_half
                                  : Icons.star_border),
                        color: const Color(0xFFFDC300),
                        size: 16,
                      );
                    }),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$actualReviewCount reviews',
                    style: GoogleFonts.mulish(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Rating bars - calculate from actual reviews
          ..._buildRatingBars(reviews),
        ],
      ),
    );
  }

  List<Widget> _buildRatingBars(List<Map<String, dynamic>> reviews) {
    // Calculate rating distribution from actual reviews
    final distribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final review in reviews) {
      final rating = review['rating'] as int;
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }

    final widgets = <Widget>[];
    final total = reviews.length;
    for (int stars = 5; stars >= 1; stars--) {
      widgets.add(_buildRatingBar(stars, distribution[stars] ?? 0, total));
      if (stars > 1) {
        widgets.add(const SizedBox(height: 6));
      }
    }
    return widgets;
  }

  Widget _buildRatingBar(int stars, int count, int total) {
    final percentage = total > 0 ? count / total : 0.0;

    return Row(
      children: [
        Text(
          '$stars',
          style: GoogleFonts.mulish(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(width: 4),
        const Icon(Icons.star, size: 12, color: Color(0xFFFDC300)),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFDC300),
              ),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 30,
          child: Text(
            '$count',
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: AppColors.secondaryDark,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsList(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            children: [
              Icon(
                Icons.rate_review_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'Belum ada review',
                style: GoogleFonts.mulish(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryDark,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Jadilah yang pertama memberikan review!',
                style: GoogleFonts.mulish(
                  fontSize: 13,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: reviews.map((review) => _buildReviewItem(review)).toList(),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final userName = review['user_name'] as String? ?? 'User';
    final rating = (review['rating'] as int).toDouble();
    final comment = review['comment'] as String?;
    final createdAt = DateTime.parse(review['created_at'] as String);
    final dateStr = _formatReviewDate(createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color.fromARGB(255, 0, 113, 72),
                child: Text(
                  userName[0].toUpperCase(),
                  style: GoogleFonts.mulish(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: GoogleFonts.mulish(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: GoogleFonts.mulish(
                        fontSize: 11,
                        fontWeight: FontWeight.w400,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating - 5 stars
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.floor()
                        ? Icons.star
                        : (index < rating
                              ? Icons.star_half
                              : Icons.star_border),
                    color: const Color(0xFFFDC300),
                    size: 14,
                  );
                }),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            // Comment
            Text(
              comment,
              style: GoogleFonts.mulish(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryDark,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatReviewDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} menit yang lalu';
      }
      return '${difference.inHours} jam yang lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari yang lalu';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks minggu yang lalu';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months bulan yang lalu';
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.lock_outline,
              color: AppColors.primaryDark,
              size: 28,
            ),
            const SizedBox(width: 12),
            Text(
              'Login Diperlukan',
              style: GoogleFonts.mulish(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Anda perlu login untuk melakukan booking. Silakan login atau daftar akun baru.',
          style: GoogleFonts.mulish(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: GoogleFonts.mulish(color: Colors.grey[600]),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to Sign In screen (AuthScreen)
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(
                  builder: (context) => const AuthScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Login',
              style: GoogleFonts.mulish(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFixedBottomButton() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            offset: const Offset(0, -4),
            blurRadius: 12,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Harga lapangan perjam',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  Text(
                    widget.price,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Button with same color as login button
              AnimatedGradientButton(
                text: 'Sewa Sekarang',
                onPressed: () {
                  // Check if user is authenticated before booking
                  if (!SupabaseService.isLoggedIn) {
                    _showLoginRequiredDialog();
                    return;
                  }
                  
                  // If field data available, navigate to booking confirmation
                  if (widget.field != null) {
                    // Determine the correct venueId to use
                    // Priority: widget.venueId > field.venueId > field.id (fallback)
                    // Note: Since there's no separate venues table, field ID can be used as venueId
                    final venueIdToUse = widget.venueId ?? widget.field!.venueId ?? widget.field!.id;
                    
                    if (kDebugMode) print('✅ [VenueDetail] Booking with venueId: $venueIdToUse');
                    if (kDebugMode) print('   widget.venueId: ${widget.venueId}');
                    if (kDebugMode) print('   field.venueId: ${widget.field!.venueId}');
                    if (kDebugMode) print('   field.id (fallback): ${widget.field!.id}');
                    
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BookingConfirmationScreen(
                          field: widget.field!,
                          venueId: venueIdToUse,
                          venueName: widget.title,
                        ),
                      ),
                    );
                  } else {
                    // Fallback: show message that booking is not available
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Booking tidak tersedia untuk venue ini'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                gradientColors: const [
                  Color.fromARGB(255, 0, 113, 72),
                  Color.fromARGB(255, 0, 117, 164),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
