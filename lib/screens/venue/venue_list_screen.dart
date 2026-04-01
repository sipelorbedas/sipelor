import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/app_colors.dart';
import '../../models/field.dart';
import '../../services/supabase_service.dart';
import '../../services/connectivity_service.dart';
import '../../services/offline_cache_service.dart';
import '../../widgets/home/venue_card.dart';
import '../../widgets/offline_banner.dart';
import '../../widgets/skeleton_loading.dart';

class VenueListScreen extends StatefulWidget {
  final String initialQuery;
  final bool autoFocus;

  const VenueListScreen({
    super.key,
    this.initialQuery = '',
    this.autoFocus = false,
  });

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  List<Field> _allFields = [];
  List<Field> _filteredFields = [];
  List<String> _areas = [];
  String? _selectedArea;
  late final TextEditingController _searchController;
  final FocusNode _searchFocus = FocusNode();
  bool _isLoading = true;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery);
    _loadFields();
    // Auto-focus or pre-fill from voice/search tap
    if (widget.autoFocus || widget.initialQuery.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  Future<void> _loadFields() async {
    setState(() => _isLoading = true);

    final isOnline = await ConnectivityService().checkConnectivity();

    if (isOnline) {
      try {
        final fields = await SupabaseService.fetchFields();
        // Cache untuk akses offline berikutnya
        await OfflineCacheService().cacheFields(fields);

        final areas = fields.map((f) => f.area).toSet().toList();
        areas.sort();

        if (mounted) {
          setState(() {
            _allFields = fields;
            _isLoading = false;
            _isOffline = false;
            _areas = areas;
          });
          // Apply initial query filter if provided
          _filterFields();
        }
      } catch (e) {
        if (kDebugMode) print('⚠️  [VenueList] Error online, fallback cache: $e');
        await _loadFieldsFromCache();
      }
    } else {
      await _loadFieldsFromCache();
    }
  }

  Future<void> _loadFieldsFromCache() async {
    final cached = await OfflineCacheService().getCachedFields();
    final fields = cached ?? [];
    final areas = fields.map((f) => f.area).toSet().toList();
    areas.sort();

    if (mounted) {
      setState(() {
        _allFields = fields;
        _filteredFields = fields;
        _areas = areas;
        _isLoading = false;
        _isOffline = true;
      });
    }
    if (kDebugMode) {
      if (kDebugMode) print('📴 [VenueList] Offline mode — loaded ${fields.length} cached fields');
    }
  }

  void _filterFields() {
    setState(() {
      _filteredFields = _allFields.where((field) {
        // Filter by area
        if (_selectedArea != null && field.area != _selectedArea) {
          return false;
        }
        
        // Filter by search query
        final query = _searchController.text.toLowerCase();
        if (query.isNotEmpty) {
          final nameMatch = field.venueName.toLowerCase().contains(query);
          final typeMatch = field.venueType.toLowerCase().contains(query);
          final areaMatch = field.area.toLowerCase().contains(query);
          
          return nameMatch || typeMatch || areaMatch;
        }
        
        return true;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedArea = null;
      _searchController.clear();
      _filteredFields = _allFields;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.screenBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primaryDark),
        ),
        title: Text(
          'Semua Venue',
          style: GoogleFonts.mulish(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Offline Banner
          const OfflineBanner(cacheKey: 'fields'),

          // Search and Filter Section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  focusNode: _searchFocus,
                  onChanged: (value) => _filterFields(),
                  decoration: InputDecoration(
                    hintText: 'Cari venue, jenis, atau tempat...',
                    hintStyle: GoogleFonts.mulish(
                      fontSize: 14,
                      color: AppColors.secondaryDark,
                    ),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.secondaryDark,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.secondaryDark,
                            ),
                            onPressed: () {
                              _searchController.clear();
                              _filterFields();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.screenBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: GoogleFonts.mulish(fontSize: 14),
                ),
                const SizedBox(height: 12),
                
                // Filter Row
                Row(
                  children: [
                    // Area Filter
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.screenBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedArea != null
                                ? const Color.fromARGB(255, 0, 113, 72)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        child: DropdownButton<String?>(
                          value: _selectedArea,
                          hint: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: AppColors.secondaryDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Filter Tempat',
                                style: GoogleFonts.mulish(
                                  fontSize: 14,
                                  color: AppColors.secondaryDark,
                                ),
                              ),
                            ],
                          ),
                          isExpanded: true,
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'Semua Tempat',
                                style: GoogleFonts.mulish(fontSize: 14),
                              ),
                            ),
                            ..._areas.map((area) {
                              return DropdownMenuItem(
                                value: area,
                                child: Text(
                                  area,
                                  style: GoogleFonts.mulish(fontSize: 14),
                                ),
                              );
                            }),
                          ],
                          onChanged: (value) {
                            setState(() => _selectedArea = value);
                            _filterFields();
                          },
                        ),
                      ),
                    ),
                    
                    // Clear Filter Button
                    if (_selectedArea != null || _searchController.text.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: Text(
                          'Reset',
                          style: GoogleFonts.mulish(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color.fromARGB(255, 0, 113, 72),
                          backgroundColor: AppColors.screenBg,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          
          // Results Count
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: AppColors.screenBg,
            child: Text(
              '${_filteredFields.length} venue ditemukan',
              style: GoogleFonts.mulish(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          
          // Venue Grid — 2 Kolom
          Expanded(
            child: _isLoading
                ? GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.73,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const SkeletonVenueCard(isFullWidth: true),
                  )
                : _filteredFields.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _isOffline && _allFields.isEmpty
                                  ? Icons.wifi_off_rounded
                                  : Icons.search_off,
                              size: 64,
                              color: AppColors.secondaryDark.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isOffline && _allFields.isEmpty
                                  ? 'Data belum tersedia'
                                  : 'Tidak ada venue ditemukan',
                              style: GoogleFonts.mulish(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondaryDark,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _isOffline && _allFields.isEmpty
                                  ? 'Sambungkan ke internet untuk memuat venue'
                                  : 'Coba ubah kata kunci atau filter',
                              style: GoogleFonts.mulish(
                                fontSize: 14,
                                color: AppColors.secondaryDark.withOpacity(0.7),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                        padding: const EdgeInsets.all(12),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.73,
                        ),
                        itemCount: _filteredFields.length,
                        itemBuilder: (context, index) {
                          final field = _filteredFields[index];
                          final imageUrl = field.imageUrls != null && field.imageUrls!.isNotEmpty
                              ? field.imageUrls!.first
                              : null;

                          return StreamBuilder<List<Map<String, dynamic>>>(
                            stream: SupabaseService.streamReviewsByVenueId(venueId: field.id),
                            builder: (context, reviewSnapshot) {
                              final reviews = reviewSnapshot.data ?? [];
                              final rating = reviews.isEmpty
                                  ? 0.0
                                  : reviews.fold<double>(0, (sum, review) => sum + (review['rating'] as int)) / reviews.length;
                              final reviewCount = reviews.length;

                              return VenueCard(
                                key: ValueKey(field.id),
                                imagePath: imageUrl ?? 'assets/images/stadium_jalak_harupat.jpg',
                                title: field.venueName,
                                address: field.area,
                                rating: rating,
                                reviewCount: reviewCount,
                                price: 'Rp. ${_formatPriceNumber(field.pricePerHour)}',
                                venueType: field.venueType,
                                satuan: field.satuan ?? 'per jam',
                                venue: null,
                                fields: [field],
                                venueId: field.id,
                                latitude: field.latitude ?? -6.996321,
                                longitude: field.longitude ?? 107.529595,
                                isFullWidth: true,
                                customImageHeight: 120.0, // Lebih compact untuk grid 2 kolom
                              );
                            },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  String _formatPriceNumber(int price) {
    final priceStr = price.toString();
    final buffer = StringBuffer();
    var count = 0;
    
    for (var i = priceStr.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(priceStr[i]);
      count++;
    }
    
    return buffer.toString().split('').reversed.join('');
  }
}
