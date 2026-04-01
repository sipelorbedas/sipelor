# 🚀 PERFORMANCE OPTIMIZATION IMPLEMENTATION - SIPELOR BEDAS

> **Panduan implementasi step-by-step untuk menerapkan performance optimization**
> 
> **Tanggal**: 2 Februari 2026  
> **Status**: Ready to Implement

---

## 📋 QUICK START

### 1. Initialize Performance System (main.dart)

Tambahkan di `main()` setelah existing initialization:

```dart
import 'package:sipelor/utils/performance_monitor.dart';
import 'package:sipelor/utils/memory_leak_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing initialization ...
  
  // PERFORMANCE: Initialize performance monitoring (Debug mode only)
  if (kDebugMode) {
    PerformanceMonitor.initialize(
      enableMemoryTracking: true,
      memoryCheckInterval: Duration(seconds: 30),
    );
    
    MemoryLeakDetector.initialize(
      checkInterval: Duration(minutes: 5),
    );
    
    print('✅ Performance optimization initialized');
  }
  
  runApp(const MyApp());
}
```

---

## 📸 IMPLEMENTASI IMAGE CACHING

### Step 1: Import OptimizedImage

Untuk screen/widget yang menggunakan network images, tambahkan import:

```dart
import 'package:sipelor/utils/optimized_image.dart';
```

### Step 2: Ganti Image.network dengan OptimizedImage

**Before:**
```dart
Image.network(
  venue.image_url,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
)
```

**After:**
```dart
OptimizedImage(
  imageUrl: venue.image_url,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
  borderRadius: BorderRadius.circular(8),
)
```

### Step 3: Untuk Avatar Images

**Before:**
```dart
CircleAvatar(
  backgroundImage: NetworkImage(user.avatar_url),
  radius: 20,
)
```

**After:**
```dart
OptimizedAvatar(
  imageUrl: user.avatar_url,
  radius: 20,
  fallbackText: user.name,
)
```

### Contoh Implementasi Lengkap

```dart
// File: lib/widgets/home/venue_card.dart
import 'package:sipelor/utils/optimized_image.dart';

class VenueCard extends StatelessWidget {
  final Venue venue;
  
  const VenueCard({Key? key, required this.venue}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Ganti CachedNetworkImage dengan OptimizedImage
          OptimizedImage(
            imageUrl: venue.image_url,
            height: 150,
            width: double.infinity,
            fit: BoxFit.cover,
            borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
          ),
          Padding(
            padding: EdgeInsets.all(8),
            child: Text(venue.name),
          ),
        ],
      ),
    );
  }
}
```

---

## 📜 IMPLEMENTASI LAZY LOADING

### Step 1: Buat Controller

Untuk screen dengan list yang panjang (venues, bookings, dll), ganti dengan LazyLoadingController:

```dart
import 'package:sipelor/utils/lazy_loading_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VenueListScreen extends StatefulWidget {
  const VenueListScreen({Key? key}) : super(key: key);

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  late LazyLoadingController<Venue> _controller;
  
  @override
  void initState() {
    super.initState();
    
    _controller = LazyLoadingController<Venue>(
      fetchItems: _fetchVenues,
      pageSize: 20,
    );
  }
  
  Future<List<Venue>> _fetchVenues(int page, int pageSize) async {
    final supabase = Supabase.instance.client;
    
    final response = await supabase
        .from('venues')
        .select()
        .eq('is_active', true)
        .order('created_at', ascending: false)
        .range(page * pageSize, (page + 1) * pageSize - 1);
    
    return (response as List).map((json) => Venue.fromJson(json)).toList();
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Venues')),
      body: LazyLoadingListView<Venue>(
        controller: _controller,
        itemBuilder: (context, venue) => VenueCard(venue: venue),
        padding: EdgeInsets.all(16),
        separator: SizedBox(height: 8),
        emptyWidget: Center(
          child: Text('Tidak ada venue tersedia'),
        ),
      ),
    );
  }
}
```

### Step 2: Untuk GridView

```dart
LazyLoadingGridView<Venue>(
  controller: _controller,
  itemBuilder: (context, venue) => VenueCard(venue: venue),
  crossAxisCount: 2,
  crossAxisSpacing: 8,
  mainAxisSpacing: 8,
  childAspectRatio: 0.8,
  padding: EdgeInsets.all(16),
)
```

---

## 🗄️ IMPLEMENTASI DATABASE OPTIMIZATION

### Step 1: Cached Queries

Untuk queries yang sering diakses, gunakan caching:

```dart
import 'package:sipelor/utils/database_optimizer.dart';

class VenueService {
  // Before: Direct query
  Future<List<Venue>> getActiveVenues() async {
    final supabase = Supabase.instance.client;
    final response = await supabase
        .from('venues')
        .select()
        .eq('is_active', true);
    return (response as List).map((json) => Venue.fromJson(json)).toList();
  }
  
  // After: Cached query
  Future<List<Map<String, dynamic>>> getActiveVenuesCached() async {
    return await DatabaseOptimizer.cachedQuery(
      key: 'active_venues',
      query: () async {
        final supabase = Supabase.instance.client;
        return await supabase
            .from('venues')
            .select()
            .eq('is_active', true);
      },
      duration: Duration(minutes: 5),
    );
  }
}
```

### Step 2: Cache Invalidation

Saat data berubah, invalidate cache:

```dart
class VenueService {
  Future<void> updateVenue(int id, Map<String, dynamic> data) async {
    final supabase = Supabase.instance.client;
    
    await supabase
        .from('venues')
        .update(data)
        .eq('id', id);
    
    // Invalidate related caches
    DatabaseOptimizer.invalidateCachePattern('venue');
  }
  
  Future<void> deleteVenue(int id) async {
    final supabase = Supabase.instance.client;
    
    await supabase
        .from('venues')
        .delete()
        .eq('id', id);
    
    // Invalidate cache
    DatabaseOptimizer.invalidateCache('active_venues');
  }
}
```

### Step 3: Batch Operations

Untuk operasi massal, gunakan batch:

```dart
class BookingService {
  Future<void> createMultipleBookings(List<Booking> bookings) async {
    // Convert to JSON
    final jsonList = bookings.map((b) => b.toJson()).toList();
    
    // Batch insert (lebih cepat dari loop)
    await DatabaseOptimizer.batchInsert(
      'bookings',
      jsonList,
      batchSize: 100,
    );
    
    // Invalidate cache
    DatabaseOptimizer.invalidateCache('user_bookings');
  }
}
```

---

## 📊 IMPLEMENTASI PERFORMANCE MONITORING

### Step 1: Track Critical Operations

```dart
import 'package:sipelor/utils/performance_monitor.dart';

class VenueService {
  Future<List<Venue>> fetchVenues() async {
    // Track operation performance
    return await PerformanceMonitor.trackAsync(
      'fetch_venues',
      () async {
        final supabase = Supabase.instance.client;
        final response = await supabase.from('venues').select();
        return (response as List).map((json) => Venue.fromJson(json)).toList();
      },
    );
  }
}
```

### Step 2: Track Widget Builds (Debug)

```dart
class VenueCard extends StatelessWidget {
  final Venue venue;
  
  const VenueCard({Key? key, required this.venue}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      RenderOptimizer.trackRebuild('VenueCard');
    }
    
    return Card(
      // widget content
    );
  }
}
```

### Step 3: Performance Reports

Tambahkan di admin dashboard atau settings:

```dart
ElevatedButton(
  onPressed: () {
    PerformanceMonitor.printReport();
    MemoryLeakDetector.printReport();
    RenderOptimizer.printBuildStats();
  },
  child: Text('Show Performance Report'),
)
```

---

## 🔍 IMPLEMENTASI MEMORY LEAK DETECTION

### Step 1: Using Mixin (Recommended)

```dart
import 'package:sipelor/utils/memory_leak_detector.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> 
    with MemoryLeakDetectionMixin<ChatScreen> {
  
  late StreamController<Message> _messageController;
  late ScrollController _scrollController;
  
  @override
  void initState() {
    super.initState();
    
    _messageController = StreamController<Message>();
    _scrollController = ScrollController();
    
    // Track resources
    trackResource('message_controller', _messageController);
    trackResource('scroll_controller', _scrollController);
  }
  
  @override
  void dispose() {
    // Dispose and mark
    disposeResource('message_controller');
    disposeResource('scroll_controller');
    
    _messageController.close();
    _scrollController.dispose();
    
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(controller: _scrollController),
    );
  }
}
```

### Step 2: Using Resource Manager

```dart
import 'package:sipelor/utils/memory_leak_detector.dart';

class ComplexScreen extends StatefulWidget {
  @override
  State<ComplexScreen> createState() => _ComplexScreenState();
}

class _ComplexScreenState extends State<ComplexScreen> {
  final _resources = DisposableResourceManager();
  final _subscriptions = StreamSubscriptionManager();
  
  @override
  void initState() {
    super.initState();
    
    // Add controllers
    _resources.add('scroll', ScrollController());
    _resources.add('text', TextEditingController());
    
    // Add subscriptions
    _subscriptions.add(
      Stream.periodic(Duration(seconds: 1)).listen((_) {
        // Handle periodic event
      }),
    );
  }
  
  @override
  void dispose() {
    _resources.dispose();
    _subscriptions.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final scrollController = _resources.get<ScrollController>('scroll')!;
    return ListView(controller: scrollController);
  }
}
```

---

## 🎨 IMPLEMENTASI RENDER OPTIMIZATION

### Step 1: Use Const Constructors

```dart
// Before
class VenueCard extends StatelessWidget {
  final Venue venue;
  
  VenueCard({Key? key, required this.venue}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(child: Text(venue.name));
  }
}

// After
class VenueCard extends StatelessWidget {
  final Venue venue;
  
  const VenueCard({Key? key, required this.venue}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Card(child: Text(venue.name));
  }
}
```

### Step 2: RepaintBoundary for Expensive Widgets

```dart
// For charts, animations, complex graphics
RepaintBoundary(
  child: ComplexChart(data: chartData),
)

// Or use helper
RenderOptimizer.withRepaintBoundary(
  child: ExpensiveWidget(),
)
```

### Step 3: Detect Rebuilds (Debug)

```dart
// Wrap widget to see rebuild count
if (kDebugMode) {
  return RebuildCounter(
    label: 'VenueList',
    child: VenueList(),
  );
} else {
  return VenueList();
}
```

---

## 🎯 PRIORITAS IMPLEMENTASI

### High Priority (Implement First)

1. ✅ **Initialize Performance System** (main.dart)
2. ✅ **Image Caching** (venue_card.dart, venue_grid.dart, profile screens)
3. ✅ **Lazy Loading** (venue list, booking list, notification list)
4. ✅ **Database Caching** (frequently accessed queries)

### Medium Priority

5. ⚠️ **Performance Monitoring** (critical operations)
6. ⚠️ **Cache Invalidation** (saat data berubah)
7. ⚠️ **Batch Operations** (bulk inserts/updates)

### Low Priority

8. ℹ️ **Memory Leak Detection** (complex screens)
9. ℹ️ **Render Optimization** (performance bottlenecks)
10. ℹ️ **Performance Reports** (admin dashboard)

---

## 📝 IMPLEMENTATION CHECKLIST

### Phase 1: Core Setup (30 minutes)

- [ ] Initialize PerformanceMonitor di main.dart
- [ ] Initialize MemoryLeakDetector di main.dart
- [ ] Test initialization logs

### Phase 2: Image Optimization (1-2 hours)

- [ ] Import OptimizedImage di venue_card.dart
- [ ] Import OptimizedImage di venue_grid.dart
- [ ] Replace all Image.network dengan OptimizedImage
- [ ] Replace CircleAvatar NetworkImage dengan OptimizedAvatar
- [ ] Test image loading dan caching

### Phase 3: List Optimization (2-3 hours)

- [ ] Implement LazyLoadingController untuk venue list
- [ ] Implement LazyLoadingController untuk booking list
- [ ] Implement LazyLoadingController untuk notification list
- [ ] Test pagination dan pull-to-refresh

### Phase 4: Database Optimization (2-3 hours)

- [ ] Add caching untuk active venues query
- [ ] Add caching untuk user bookings query
- [ ] Implement cache invalidation saat update/delete
- [ ] Test cache hit/miss logs

### Phase 5: Monitoring (1-2 hours)

- [ ] Track fetch venues operation
- [ ] Track fetch bookings operation
- [ ] Add performance report button di settings
- [ ] Test performance reports

### Phase 6: Memory Management (1-2 hours)

- [ ] Add MemoryLeakDetectionMixin ke chat screen
- [ ] Add ResourceManager ke complex screens
- [ ] Test memory leak detection
- [ ] Review memory reports

### Phase 7: Render Optimization (1-2 hours)

- [ ] Add const constructors where possible
- [ ] Add RepaintBoundary untuk charts
- [ ] Add RebuildCounter untuk debug
- [ ] Review rebuild statistics

---

## 🧪 TESTING

### Manual Testing

1. **Image Caching**
   - Load screen dengan images
   - Check logs untuk cache hits
   - Kill app dan reload - images harus load dari cache

2. **Lazy Loading**
   - Scroll list sampai bottom
   - Check pagination logs
   - Pull to refresh
   - Check error handling

3. **Database Caching**
   - Load data pertama kali (cache miss)
   - Load data kedua kali (cache hit)
   - Update data dan check cache invalidation

4. **Performance**
   - Run PerformanceMonitor.printReport()
   - Check operation durations
   - Identify slow operations

5. **Memory**
   - Run MemoryLeakDetector.printReport()
   - Check for undisposed resources
   - Test disposal flow

### Debug Commands

```dart
// Print all reports
if (kDebugMode) {
  PerformanceMonitor.printReport();
  MemoryLeakDetector.printReport();
  RenderOptimizer.printBuildStats();
  
  final cacheStats = DatabaseOptimizer.getCacheStats();
  print('Cache Stats: $cacheStats');
}
```

---

## 🎓 TRAINING NOTES

### Untuk Team Developer

1. **Always use OptimizedImage** untuk network images
2. **Always dispose controllers** dan mark di MemoryLeakDetector
3. **Use LazyLoadingController** untuk lists dengan data banyak
4. **Cache frequently accessed queries** dengan duration yang sesuai
5. **Invalidate cache** saat data berubah
6. **Track critical operations** dengan PerformanceMonitor
7. **Use const constructors** whenever possible
8. **Review performance reports** secara berkala

---

## 📞 SUPPORT

Jika ada pertanyaan atau issue saat implementasi:

1. Check documentation di `PERFORMANCE_OPTIMIZATION_GUIDE.md`
2. Review code examples di file utilities
3. Check debug logs untuk hints
4. Contact technical lead

---

**Good luck dengan implementation! 🚀**

*Last updated: 2 Februari 2026*
