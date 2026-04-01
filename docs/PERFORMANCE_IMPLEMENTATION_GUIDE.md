# 🚀 Performance Optimization Implementation Guide

**Project**: SIPELOR BEDAS  
**Date**: 5 Februari 2026  
**Status**: ✅ Ready for Implementation

---

## 📋 Quick Start

This guide shows you how to implement the performance optimizations in your existing screens.

---

## 1️⃣ Enable Performance Monitoring

### ✅ Already Implemented in `main.dart`

Performance monitoring is now automatically enabled when the app starts:

```dart
// lib/main.dart - Already added
PerformanceMonitor.initialize(
  enableMemoryTracking: kDebugMode,
  memoryCheckInterval: const Duration(seconds: 30),
);
```

**What it does:**
- ✅ Tracks execution time of operations
- ✅ Monitors memory usage
- ✅ Detects slow operations
- ✅ Prints optimization recommendations

**View reports:**
```dart
// Anywhere in your app (debug mode only)
PerformanceMonitor.printReport();
```

---

## 2️⃣ Replace Image.network with OptimizedImage

### ✅ Already Migrated Files:
- ✅ `lib/widgets/home/home_header.dart` - Using `OptimizedAvatar`
- ✅ `lib/screens/user/profile_screen.dart` - Using `OptimizedAvatar`

### 🔄 Files to Migrate:

1. **lib/screens/venue/venue_detail_screen.dart** (Line 183)
2. **lib/screens/admin/admin_time_slots_screen.dart** (Line 937)
3. **lib/widgets/admin/recent_booking_table.dart** (Line 776)
4. **lib/screens/user/edit_profile_screen.dart** (Line 573)
5. **lib/screens/admin/admin_field_management_screen.dart** (Line 1651)

### Migration Pattern:

**Before:**
```dart
Image.network(
  imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  errorBuilder: (context, error, stackTrace) {
    return Icon(Icons.broken_image);
  },
)
```

**After:**
```dart
// Add import
import '../../utils/optimized_image.dart';

// Replace with OptimizedImage
OptimizedImage(
  imageUrl: imageUrl,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  // Automatically has caching, loading, and error handling
)
```

**For Avatar Images:**
```dart
// Before
ClipOval(
  child: Image.network(
    avatarUrl,
    width: 50,
    height: 50,
  ),
)

// After
OptimizedAvatar(
  imageUrl: avatarUrl,
  radius: 25, // width/2
)
```

---

## 3️⃣ Implement Lazy Loading in List Screens

### Example Files Created:
- ✅ `lib/screens/user/user_bookings_optimized_example.dart`
- ✅ `lib/widgets/home/venue_list_optimized_example.dart`

### Screens to Migrate:

1. **User Bookings Screen** (`lib/screens/user/user_bookings_screen.dart`)
2. **Venue List/Grid** (`lib/widgets/home/venue_grid.dart`)
3. **Admin Booking Management** (`lib/screens/admin/admin_booking_management_screen.dart`)
4. **Chat Messages** (if using ListView)

### Migration Pattern for Lists:

**Before:**
```dart
class UserBookingsScreen extends StatefulWidget {
  // ... state with List<Booking> _bookings
  
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        return BookingCard(booking: _bookings[index]);
      },
    );
  }
}
```

**After:**
```dart
// Add import
import '../../utils/lazy_loading_manager.dart';
import '../../utils/database_optimizer.dart';

class UserBookingsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return LazyLoadingManager<Booking>(
      itemBuilder: (context, booking, index) {
        return BookingCard(booking: booking);
      },
      loadMore: (page) async {
        // Load bookings for this page
        return await DatabaseOptimizer.paginatedQuery<Booking>(
          table: 'bookings',
          fromJson: Booking.fromJson,
          page: page,
          pageSize: 20,
          orderBy: 'created_at',
          ascending: false,
        );
      },
      itemsPerPage: 20,
      enablePullToRefresh: true,
    );
  }
}
```

### Migration Pattern for Grids:

**Before:**
```dart
GridView.builder(
  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
  ),
  itemCount: venues.length,
  itemBuilder: (context, index) {
    return VenueCard(venue: venues[index]);
  },
)
```

**After:**
```dart
LazyLoadingGrid<Venue>(
  loadMore: (page) => _loadVenues(page),
  itemBuilder: (context, venue, index) {
    return VenueCard(venue: venue);
  },
  crossAxisCount: 2,
  itemsPerPage: 20,
)
```

---

## 4️⃣ Add Database Query Caching

### Pattern 1: Simple Cached Query

**Before:**
```dart
Future<List<Venue>> fetchVenues() async {
  final response = await supabase.from('venues').select();
  return response.map((v) => Venue.fromJson(v)).toList();
}
```

**After:**
```dart
// Add import
import '../../utils/database_optimizer.dart';

Future<List<Venue>> fetchVenues() async {
  return await DatabaseOptimizer.cachedQuery(
    key: 'all_venues',
    duration: Duration(minutes: 5), // Cache for 5 minutes
    query: () async {
      final response = await supabase.from('venues').select();
      return response.map((v) => Venue.fromJson(v)).toList();
    },
  );
}
```

### Pattern 2: Cached Query with Filters

```dart
Future<List<Booking>> fetchUserBookings(String userId) async {
  final cacheKey = 'user_bookings_$userId';
  
  return await DatabaseOptimizer.cachedQuery(
    key: cacheKey,
    duration: Duration(minutes: 3),
    query: () async {
      final response = await supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return response.map((b) => Booking.fromJson(b)).toList();
    },
  );
}
```

### Pattern 3: Invalidate Cache After Update

```dart
Future<void> updateBooking(Booking booking) async {
  await supabase.from('bookings').update(booking.toJson()).eq('id', booking.id);
  
  // Invalidate related caches
  DatabaseOptimizer.invalidateCache('user_bookings_${booking.userId}');
  DatabaseOptimizer.invalidateCachePattern('bookings'); // All booking caches
}
```

### Pattern 4: Optimized Pagination

```dart
Future<List<Venue>> loadVenues(int page) async {
  return await DatabaseOptimizer.paginatedQuery<Venue>(
    table: 'venues',
    fromJson: Venue.fromJson,
    columns: 'id, name, type, location, price, image_url', // Only needed columns
    page: page,
    pageSize: 20,
    orderBy: 'created_at',
    ascending: false,
    filters: {'status': 'active'}, // Optional filters
  );
}
```

### Pattern 5: Batch Operations

```dart
// Instead of:
for (final booking in bookings) {
  await supabase.from('bookings').insert(booking.toJson());
}

// Use batch insert:
await DatabaseOptimizer.batchInsert(
  'bookings',
  bookings.map((b) => b.toJson()).toList(),
  batchSize: 100,
);
```

---

## 5️⃣ Migration Checklist

### Phase 1: Critical Screens (Week 1)
- [ ] Home Screen - Replace Image.network with OptimizedImage
- [ ] Profile Screen - ✅ Already done
- [ ] User Bookings - Implement LazyLoadingManager
- [ ] Venue List - Implement LazyLoadingGrid + OptimizedImage

### Phase 2: Admin Screens (Week 2)
- [ ] Admin Dashboard - Replace Image.network
- [ ] Booking Management - Implement LazyLoadingManager
- [ ] Field Management - Replace Image.network + add caching
- [ ] Admin Time Slots - Replace Image.network

### Phase 3: Data Layer (Week 3)
- [ ] Add caching to venue queries
- [ ] Add caching to booking queries
- [ ] Add caching to user profile queries
- [ ] Implement batch operations where applicable

### Phase 4: Testing & Validation (Week 4)
- [ ] Run performance tests
- [ ] Measure load times
- [ ] Check memory usage
- [ ] Validate cache hit rates
- [ ] Test on real devices

---

## 6️⃣ Quick Migration Commands

### Find all Image.network usages:
```powershell
# Windows PowerShell
rg "Image.network" --type-add "dart:*.dart" -t dart lib/
```

### Find all ListView.builder usages:
```powershell
rg "ListView.builder" --type-add "dart:*.dart" -t dart lib/
```

### Find all GridView.builder usages:
```powershell
rg "GridView.builder" --type-add "dart:*.dart" -t dart lib/
```

### Find all Supabase queries:
```powershell
rg "supabase.from" --type-add "dart:*.dart" -t dart lib/
```

---

## 7️⃣ Testing Your Optimizations

### Test Image Optimization:
```dart
// Check if images are cached
debugPrint('Cache stats: ${ImageCacheManager.getCacheSize()}');

// Preload images before navigation
await ImageCacheManager.preloadImages(context, [
  'image1.jpg',
  'image2.jpg',
]);
```

### Test Database Caching:
```dart
// Check cache statistics
final stats = DatabaseOptimizer.getCacheStats();
debugPrint('Cache entries: ${stats['total_entries']}');
debugPrint('Cache memory: ${stats['memory_estimate']}');

// Force refresh cache
final data = await DatabaseOptimizer.cachedQuery(
  key: 'venues',
  query: () => fetchVenues(),
  forceRefresh: true, // Bypass cache
);
```

### Test Performance:
```dart
// Measure operation time
await PerformanceMonitor.measure('load_bookings', () async {
  return await fetchBookings();
});

// Print performance report
PerformanceMonitor.printReport();
```

---

## 8️⃣ Common Issues & Solutions

### Issue: Images not caching
**Solution:** Ensure you're using `OptimizedImage` instead of `Image.network`

### Issue: List scrolling still slow
**Solution:** 
1. Implement `LazyLoadingManager`
2. Reduce `itemsPerPage` if items are heavy
3. Use `OptimizedImage` for images in list items

### Issue: Database queries still slow
**Solution:**
1. Add caching with `DatabaseOptimizer.cachedQuery`
2. Select only needed columns
3. Add indexes in Supabase database
4. Use pagination for large datasets

### Issue: Cache not invalidating
**Solution:**
```dart
// Invalidate specific cache
DatabaseOptimizer.invalidateCache('venues_list');

// Invalidate all matching caches
DatabaseOptimizer.invalidateCachePattern('venues');

// Clear all cache
DatabaseOptimizer.clearCache();
```

---

## 9️⃣ Performance Targets

After implementing all optimizations, you should see:

| Metric | Before | Target | How to Measure |
|--------|--------|--------|----------------|
| App Startup | 3-5s | < 2s | Time to first frame |
| Image Load | 800ms | < 300ms | PerformanceMonitor |
| List Scroll | 45fps | 60fps | Flutter DevTools |
| DB Query | 500ms | < 50ms | PerformanceMonitor |
| Memory | 200MB | < 120MB | Flutter DevTools |

---

## 🔟 Next Steps

1. **Review example files:**
   - `lib/screens/user/user_bookings_optimized_example.dart`
   - `lib/widgets/home/venue_list_optimized_example.dart`

2. **Start with one screen:**
   - Pick the slowest screen
   - Apply optimizations
   - Test and measure improvements

3. **Gradually migrate:**
   - One screen per day
   - Test after each migration
   - Monitor performance metrics

4. **Validate results:**
   - Run performance tests
   - Compare before/after metrics
   - Adjust cache durations as needed

---

**Need Help?**
- See [PERFORMANCE_OPTIMIZATION_GUIDE.md](./PERFORMANCE_OPTIMIZATION_GUIDE.md) for detailed documentation
- Check example files for implementation patterns
- Use `PerformanceMonitor.printReport()` to identify bottlenecks

---

**Last Updated**: 5 Februari 2026  
**Status**: ✅ Ready for Team Implementation
