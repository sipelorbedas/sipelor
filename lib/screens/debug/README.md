# Debug Screens Documentation

This directory contains debug and monitoring screens for the SIPELOR application.

## Available Screens

### 1. Debug Menu Screen (`debug_menu_screen.dart`)
The main hub for accessing all debugging tools.

**Access:** Navigate to `/debug` route or use:
```dart
Navigator.pushNamed(context, '/debug');
```

**Features:**
- Overview of all monitoring tools
- Quick access to detailed screens
- Quick actions (Clear cache, Print reports)

---

### 2. Database Optimizer Screen (`database_optimizer_screen.dart`)
Monitors database query caching and performance.

**Features:**
- View cache statistics (total entries, memory estimate)
- List all cached queries
- Invalidate specific cache entries
- Clear all cache
- Auto-refresh every 2 seconds

**Integration Example:**
```dart
// Use cached query in your code
final venues = await DatabaseOptimizer.cachedQuery(
  key: 'all_venues',
  query: () => supabase.from('venues').select(),
  duration: Duration(minutes: 5),
);
```

---

### 3. Memory Leak Detector Screen (`memory_leak_detector_screen.dart`)
Tracks disposable resources and detects potential memory leaks.

**Features:**
- View all tracked resources
- Monitor resource lifetime
- Color-coded status indicators:
  - 🟢 Green (< 1 min): Normal
  - 🟠 Orange (1-5 min): Monitor
  - 🟠 Deep Orange (5-10 min): Warning
  - 🔴 Red (> 10 min): Potential leak
- Warnings for long-lived resources
- Auto-refresh every 2 seconds

**Integration Example:**
```dart
// In initState
void initState() {
  super.initState();
  _controller = TextEditingController();
  MemoryLeakDetector.trackDisposable('my_controller', _controller);
}

// In dispose
@override
void dispose() {
  MemoryLeakDetector.markDisposed('my_controller');
  _controller.dispose();
  super.dispose();
}
```

**Using the Mixin:**
```dart
class MyWidget extends StatefulWidget {
  // ...
}

class _MyWidgetState extends State<MyWidget> with MemoryLeakDetectionMixin {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    trackResource('controller', _controller);
  }

  @override
  void dispose() {
    disposeResource('controller');
    _controller.dispose();
    super.dispose();
  }
}
```

---

### 4. Performance Monitor Screen (`performance_monitor_screen.dart`)
Displays detailed performance metrics and statistics.

**Features:**
- View all tracked operations
- Performance metrics:
  - Average, Min, Max execution time
  - P50, P95, P99 percentiles
- Color-coded performance levels:
  - 🟢 Green (< 50ms): Excellent
  - 🟠 Orange (50-100ms): Good
  - 🟠 Deep Orange (100-500ms): Slow
  - 🔴 Red (> 500ms): Very Slow
- Auto-refresh every 2 seconds

**Integration Example:**
```dart
// Track an operation
final stopwatch = PerformanceMonitor.startTimer('fetch_venues');
await fetchVenues();
PerformanceMonitor.stopTimer(stopwatch, 'fetch_venues');

// Track async operations
final result = await PerformanceMonitor.trackAsync(
  'fetch_bookings',
  () => fetchBookings(),
);

// Track widget builds
@override
Widget build(BuildContext context) {
  return PerformanceMonitor.trackBuild(
    'VenueCard',
    () => Card(...),
  );
}
```

---

## Initialization

Add to `main.dart` to initialize monitoring services:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize in debug mode only
  if (kDebugMode) {
    // Initialize memory leak detector
    MemoryLeakDetector.initialize(
      checkInterval: Duration(seconds: 60),
    );
    
    // Initialize performance monitor
    PerformanceMonitor.initialize(
      enableMemoryTracking: true,
      memoryCheckInterval: Duration(seconds: 30),
    );
  }
  
  runApp(const MyApp());
}
```

---

## Best Practices

1. **Database Optimizer:**
   - Use caching for frequently accessed, slowly changing data
   - Set appropriate cache durations based on data update frequency
   - Invalidate cache when data is modified
   - Use batch operations for multiple records

2. **Memory Leak Detector:**
   - Track all disposable resources (Controllers, Notifiers, Streams)
   - Always mark resources as disposed in the dispose() method
   - Use the mixin for automatic tracking
   - Monitor warnings for resources > 10 minutes old

3. **Performance Monitor:**
   - Track expensive operations (API calls, database queries, heavy computations)
   - Monitor widget build times for optimization opportunities
   - Use percentiles (P95, P99) to identify edge cases
   - Keep operations under 50ms for best user experience

---

## Accessing Debug Menu

### From Code:
```dart
// Navigate to debug menu
Navigator.pushNamed(context, '/debug');
```

### From Admin Dashboard:
Add a debug button in your admin panel:
```dart
IconButton(
  icon: Icon(Icons.bug_report),
  onPressed: () => Navigator.pushNamed(context, '/debug'),
  tooltip: 'Debug Tools',
)
```

### Using Deep Link:
```
sipelor://debug
```

---

## Notes

- ⚠️ These screens are for **development/debugging only**
- All monitoring features are disabled in release builds
- Data is stored in memory and cleared when app restarts
- Use DevTools for more advanced profiling

---

## Troubleshooting

**Cache not showing:**
- Ensure queries are using `DatabaseOptimizer.cachedQuery()`
- Check that cache duration hasn't expired

**Resources not tracked:**
- Verify `MemoryLeakDetector.trackDisposable()` is called
- Ensure detector is initialized in main()

**Metrics not appearing:**
- Check that `PerformanceMonitor.initialize()` is called
- Verify operations are wrapped with timing functions

---

For more information, see the individual utility files:
- `lib/utils/database_optimizer.dart`
- `lib/utils/memory_leak_detector.dart`
- `lib/utils/performance_monitor.dart`
