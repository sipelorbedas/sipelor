# 🚀 Performance Optimization Utils - SIPELOR BEDAS

Kumpulan utilities untuk meningkatkan performa aplikasi tanpa mengubah source code yang sudah ada.

---

## 📦 Daftar Utilities

### 1. **optimized_image.dart**
Optimasi image loading dan caching dengan `cached_network_image`

**Features:**
- ✅ Automatic caching
- ✅ Memory & disk optimization
- ✅ Shimmer loading
- ✅ Error handling
- ✅ Avatar support

**Usage:**
```dart
import 'package:sipelor/utils/optimized_image.dart';

OptimizedImage(
  imageUrl: venue.image_url,
  width: 200,
  height: 200,
  fit: BoxFit.cover,
)
```

---

### 2. **lazy_loading_controller.dart**
Lazy loading dan pagination untuk lists

**Features:**
- ✅ Automatic pagination
- ✅ Pull to refresh
- ✅ Error handling
- ✅ ListView & GridView support

**Usage:**
```dart
import 'package:sipelor/utils/lazy_loading_controller.dart';

final controller = LazyLoadingController<Venue>(
  fetchItems: (page, pageSize) async {
    return await fetchVenues(page, pageSize);
  },
  pageSize: 20,
);

LazyLoadingListView(
  controller: controller,
  itemBuilder: (context, venue) => VenueCard(venue),
)
```

---

### 3. **database_optimizer.dart**
Database query optimization dan caching

**Features:**
- ✅ Query caching dengan TTL
- ✅ Batch operations
- ✅ Pagination helper
- ✅ Cache invalidation

**Usage:**
```dart
import 'package:sipelor/utils/database_optimizer.dart';

// Cached query
final venues = await DatabaseOptimizer.cachedQuery(
  key: 'active_venues',
  query: () => supabase.from('venues').select(),
  duration: Duration(minutes: 5),
);

// Batch insert
await DatabaseOptimizer.batchInsert('bookings', records);

// Invalidate cache
DatabaseOptimizer.invalidateCache('active_venues');
```

---

### 4. **performance_monitor.dart**
Monitor dan track performa aplikasi

**Features:**
- ✅ Operation timing
- ✅ Widget build tracking
- ✅ Memory monitoring
- ✅ Performance reports

**Usage:**
```dart
import 'package:sipelor/utils/performance_monitor.dart';

// Initialize di main()
PerformanceMonitor.initialize();

// Track operation
final stopwatch = PerformanceMonitor.startTimer('fetch_data');
await fetchData();
PerformanceMonitor.stopTimer(stopwatch, 'fetch_data');

// Track async
final result = await PerformanceMonitor.trackAsync(
  'fetch_venues',
  () => fetchVenues(),
);

// Print report
PerformanceMonitor.printReport();
```

---

### 5. **memory_leak_detector.dart**
Detect dan prevent memory leaks

**Features:**
- ✅ Track disposable resources
- ✅ Automatic leak detection
- ✅ Resource manager
- ✅ Subscription manager

**Usage:**
```dart
import 'package:sipelor/utils/memory_leak_detector.dart';

// Initialize di main()
MemoryLeakDetector.initialize();

// Using mixin
class MyScreen extends StatefulWidget {
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> 
    with MemoryLeakDetectionMixin<MyScreen> {
  
  late ScrollController _controller;
  
  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    trackResource('scroll', _controller);
  }
  
  @override
  void dispose() {
    disposeResource('scroll');
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return ListView(controller: _controller);
  }
}

// Print report
MemoryLeakDetector.printReport();
```

---

### 6. **render_optimizer.dart**
Optimize widget rendering dan rebuilds

**Features:**
- ✅ Rebuild detection
- ✅ RepaintBoundary helper
- ✅ Build counter
- ✅ Performance tips

**Usage:**
```dart
import 'package:sipelor/utils/render_optimizer.dart';

// Track rebuilds
@override
Widget build(BuildContext context) {
  RenderOptimizer.trackRebuild('VenueCard');
  return Card(...);
}

// RepaintBoundary
RenderOptimizer.withRepaintBoundary(
  child: ExpensiveWidget(),
)

// Rebuild counter (debug)
RebuildCounter(
  label: 'VenueList',
  child: VenueList(),
)

// Print stats
RenderOptimizer.printBuildStats();
```

---

## 🎯 Quick Start

### 1. Initialize di main.dart

```dart
import 'package:sipelor/utils/performance_monitor.dart';
import 'package:sipelor/utils/memory_leak_detector.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ... existing code ...
  
  if (kDebugMode) {
    PerformanceMonitor.initialize();
    MemoryLeakDetector.initialize();
  }
  
  runApp(MyApp());
}
```

### 2. Gunakan OptimizedImage

```dart
// Ganti Image.network dengan:
OptimizedImage(imageUrl: url)
```

### 3. Gunakan LazyLoadingController

```dart
// Untuk lists dengan data banyak:
LazyLoadingListView(
  controller: LazyLoadingController(...),
  itemBuilder: (context, item) => ItemWidget(item),
)
```

### 4. Cache Database Queries

```dart
// Cache frequently accessed queries:
DatabaseOptimizer.cachedQuery(
  key: 'key',
  query: () => fetchData(),
)
```

---

## 📚 Documentation

Untuk panduan lengkap, lihat:
- **docs/PERFORMANCE_OPTIMIZATION_GUIDE.md** - Panduan lengkap semua fitur
- **docs/PERFORMANCE_OPTIMIZATION_IMPLEMENTATION.md** - Step-by-step implementation

---

## ✅ Checklist Optimasi

- [ ] Initialize performance system di main()
- [ ] Ganti Image.network dengan OptimizedImage
- [ ] Implement LazyLoadingController untuk long lists
- [ ] Cache frequently accessed queries
- [ ] Track critical operations
- [ ] Dispose resources dengan benar
- [ ] Review performance reports

---

## 🔍 Debug Commands

```dart
// Print semua reports
PerformanceMonitor.printReport();
MemoryLeakDetector.printReport();
RenderOptimizer.printBuildStats();
print(DatabaseOptimizer.getCacheStats());
PerformanceTips.printAllTips();
```

---

## 📊 Performance Targets

| Metric | Target | Critical |
|--------|--------|----------|
| Initial Load | < 2s | < 3s |
| Screen Transition | < 300ms | < 500ms |
| List Scroll FPS | 60fps | 50fps |
| Image Load | < 1s | < 2s |
| API Response | < 500ms | < 1s |
| Memory Usage | < 200MB | < 300MB |

---

## 🐛 Troubleshooting

**Issue: Images tidak di-cache**
- Solution: Gunakan OptimizedImage bukan Image.network

**Issue: List lag saat scroll**
- Solution: Gunakan LazyLoadingController

**Issue: Memory usage tinggi**
- Solution: Check memory leaks, clear caches

**Issue: Excessive rebuilds**
- Solution: Use const constructors, RepaintBoundary

**Issue: Slow queries**
- Solution: Implement query caching

---

## 💡 Best Practices

1. ✅ **Use const constructors** whenever possible
2. ✅ **Cache images** dengan OptimizedImage
3. ✅ **Lazy load lists** dengan LazyLoadingController
4. ✅ **Cache database queries** yang sering diakses
5. ✅ **Dispose resources** dengan benar
6. ✅ **Track performance** di debug mode
7. ✅ **Review reports** secara berkala

---

**All utilities are production-ready and can be used without modifying existing code! 🚀**

*Last updated: 2 Februari 2026*
