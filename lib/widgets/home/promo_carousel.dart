import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/carousel_banner.dart';
import '../../services/carousel_service.dart';

// ──────────────────────────────────────────────────────────────────────────────
// PromoData tetap ada untuk kompatibilitas mundur jika digunakan di tempat lain
// ──────────────────────────────────────────────────────────────────────────────
class PromoData {
  final String imagePath;
  final String title;
  final String subtitle;
  final String discount;
  final Color gradientStart;
  final Color gradientEnd;

  const PromoData({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.discount,
    required this.gradientStart,
    required this.gradientEnd,
  });
}

// ──────────────────────────────────────────────────────────────────────────────
// PromoCarousel — sekarang data-driven dari Supabase
// ──────────────────────────────────────────────────────────────────────────────
class PromoCarousel extends StatefulWidget {
  const PromoCarousel({super.key});

  @override
  State<PromoCarousel> createState() => _PromoCarouselState();
}

class _PromoCarouselState extends State<PromoCarousel>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  Timer? _timer;
  int _currentPage = 0;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<CarouselBanner> _banners = CarouselBanner.defaults;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // Langsung mulai auto-play dengan data statis, lalu ganti setelah fetch
    _startAutoPlay();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    final banners = await CarouselService.fetchActiveBanners();
    if (!mounted) return;
    setState(() {
      _banners = banners;
      _isLoading = false;
      // Reset ke halaman 0 jika jumlah banner berubah
      if (_currentPage >= banners.length) _currentPage = 0;
    });
    // Restart auto-play dengan data baru
    _restartAutoPlay();
  }

  void _startAutoPlay() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || _banners.isEmpty) return;
      _currentPage = (_currentPage + 1) % _banners.length;
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _restartAutoPlay() {
    _timer?.cancel();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (page) {
              setState(() => _currentPage = page);
            },
            itemCount: _banners.length,
            itemBuilder: (context, index) {
              return _buildBannerCard(_banners[index]);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => _buildIndicator(index == _currentPage, _banners[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(bool isActive, CarouselBanner banner) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? banner.gradientStart : Colors.grey.withOpacity(0.3),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildBannerCard(CarouselBanner banner) {
    final hasImage = banner.imageUrl != null && banner.imageUrl!.isNotEmpty;

    return GestureDetector(
      onTap: () async {
        final url = banner.linkUrl;
        if (url != null && url.isNotEmpty) {
          final uri = Uri.tryParse(url);
          if (uri != null && await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [banner.gradientStart, banner.gradientEnd],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: banner.gradientStart.withOpacity(0.4),
              offset: const Offset(0, 8),
              blurRadius: 20,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: hasImage
              ? _buildImageCard(banner)
              : _buildGradientCard(banner),
        ),
      ),
    );
  }

  /// Card dengan gambar penuh sebagai background (dari URL Supabase Storage)
  Widget _buildImageCard(CarouselBanner banner) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Gambar cover — memenuhi seluruh area carousel
        CachedNetworkImage(
          imageUrl: banner.imageUrl!,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: banner.gradientStart.withOpacity(0.3),
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white54,
                ),
              ),
            ),
          ),
          errorWidget: (context, url, error) => _buildGradientCard(banner),
        ),
        // Overlay gelap tipis untuk readability teks
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.black.withOpacity(0.45),
                Colors.black.withOpacity(0.10),
              ],
            ),
          ),
        ),
        _buildCardContent(banner, textOnDark: true),
      ],
    );
  }

  /// Card gradient (tanpa gambar — desain lama tetap dipertahankan)
  Widget _buildGradientCard(CarouselBanner banner) {
    return Stack(
      children: [
        // Decorative circles
        Positioned(
          right: -20,
          top: -20,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.1),
            ),
          ),
        ),
        Positioned(
          right: 40,
          bottom: -30,
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
            ),
          ),
        ),
        // Content row (text + icon)
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Expanded(flex: 3, child: _buildTextContent(banner)),
              Expanded(
                flex: 2,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Icon(
                    _iconForBanner(banner),
                    size: 80,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCardContent(CarouselBanner banner, {bool textOnDark = false}) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: _buildTextContent(banner),
      ),
    );
  }

  Widget _buildTextContent(CarouselBanner banner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (banner.badgeText.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              banner.badgeText,
              style: GoogleFonts.mulish(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: banner.gradientStart,
              ),
            ),
          ),
        if (banner.badgeText.isNotEmpty) const SizedBox(height: 10),
        if (banner.title.isNotEmpty)
          Text(
            banner.title,
            style: GoogleFonts.mulish(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        if (banner.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            banner.subtitle,
            style: GoogleFonts.mulish(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  IconData _iconForBanner(CarouselBanner banner) {
    final title = banner.title.toLowerCase();
    if (title.contains('stadion') ||
        title.contains('venue') ||
        title.contains('lapangan')) {
      return Icons.stadium_rounded;
    } else if (title.contains('cup') ||
        title.contains('event') ||
        title.contains('kejuaraan')) {
      return Icons.emoji_events_rounded;
    } else if (title.contains('tiket') || title.contains('ticket')) {
      return Icons.confirmation_number_rounded;
    } else if (title.contains('latihan') || title.contains('training')) {
      return Icons.sports_soccer_rounded;
    }
    return Icons.local_offer_rounded;
  }
}
