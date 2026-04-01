import 'package:flutter/material.dart';

/// Lazy Loading Manager for Lists and Grids
///
/// Features:
/// - Infinite scroll support
/// - Automatic pagination
/// - Loading indicators
/// - Error handling
/// - Pull to refresh
///
/// Usage:
/// ```dart
/// LazyLoadingManager<Venue>(
///   itemBuilder: (context, venue, index) => VenueCard(venue: venue),
///   loadMore: (page) async => await fetchVenues(page),
///   itemsPerPage: 20,
/// )
/// ```
class LazyLoadingManager<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) loadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int itemsPerPage;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final ScrollController? scrollController;
  final bool enablePullToRefresh;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;
  final bool shrinkWrap;
  final ScrollPhysics? physics;
  final Axis scrollDirection;
  final double loadMoreThreshold; // Percentage of scroll to trigger load

  const LazyLoadingManager({
    super.key,
    required this.loadMore,
    required this.itemBuilder,
    this.itemsPerPage = 20,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.scrollController,
    this.enablePullToRefresh = true,
    this.onRefresh,
    this.padding,
    this.shrinkWrap = false,
    this.physics,
    this.scrollDirection = Axis.vertical,
    this.loadMoreThreshold = 0.8, // Load when 80% scrolled
  });

  @override
  State<LazyLoadingManager<T>> createState() => _LazyLoadingManagerState<T>();
}

class _LazyLoadingManagerState<T> extends State<LazyLoadingManager<T>> {
  final List<T> _items = [];
  late ScrollController _scrollController;
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * widget.loadMoreThreshold) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.loadMore(0);
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _currentPage = 0;
          _hasMore = items.length >= widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await widget.loadMore(_currentPage + 1);
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _currentPage++;
          _hasMore = items.length >= widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
      _error = null;
    });

    try {
      // Call custom refresh callback if provided
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }

      // Reload first page
      final items = await widget.loadMore(0);
      if (mounted) {
        setState(() {
          _items.clear();
          _items.addAll(items);
          _currentPage = 0;
          _hasMore = items.length >= widget.itemsPerPage;
          _isRefreshing = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Error state
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: $_error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    // Loading state (initial)
    if (_isLoading && _items.isEmpty) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    // Empty state
    if (_items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Tidak ada data',
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
              ],
            ),
          );
    }

    // List with items
    Widget listView = ListView.builder(
      controller: _scrollController,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      physics: widget.physics,
      scrollDirection: widget.scrollDirection,
      itemCount: _items.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          // Loading indicator at bottom
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Center(
              child: _isLoading
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }

        return widget.itemBuilder(context, _items[index], index);
      },
    );

    // Wrap with RefreshIndicator if enabled
    if (widget.enablePullToRefresh) {
      listView = RefreshIndicator(
        onRefresh: _refresh,
        child: listView,
      );
    }

    return listView;
  }
}

/// Grid variant of LazyLoadingManager
class LazyLoadingGrid<T> extends StatefulWidget {
  final Future<List<T>> Function(int page) loadMore;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final int itemsPerPage;
  final Widget? loadingWidget;
  final Widget? errorWidget;
  final Widget? emptyWidget;
  final bool enablePullToRefresh;
  final Future<void> Function()? onRefresh;
  final EdgeInsetsGeometry? padding;

  const LazyLoadingGrid({
    super.key,
    required this.loadMore,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.itemsPerPage = 20,
    this.loadingWidget,
    this.errorWidget,
    this.emptyWidget,
    this.enablePullToRefresh = true,
    this.onRefresh,
    this.padding,
  });

  @override
  State<LazyLoadingGrid<T>> createState() => _LazyLoadingGridState<T>();
}

class _LazyLoadingGridState<T> extends State<LazyLoadingGrid<T>> {
  final List<T> _items = [];
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMore();
    }
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await widget.loadMore(0);
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _currentPage = 0;
          _hasMore = items.length >= widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final items = await widget.loadMore(_currentPage + 1);
      if (mounted) {
        setState(() {
          _items.addAll(items);
          _currentPage++;
          _hasMore = items.length >= widget.itemsPerPage;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    try {
      if (widget.onRefresh != null) {
        await widget.onRefresh!();
      }

      final items = await widget.loadMore(0);
      if (mounted) {
        setState(() {
          _items.clear();
          _items.addAll(items);
          _currentPage = 0;
          _hasMore = items.length >= widget.itemsPerPage;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null && _items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: $_error', textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadInitialData,
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
    }

    if (_isLoading && _items.isEmpty) {
      return widget.loadingWidget ??
          const Center(child: CircularProgressIndicator());
    }

    if (_items.isEmpty) {
      return widget.emptyWidget ??
          const Center(
            child: Text('Tidak ada data', style: TextStyle(color: Colors.grey)),
          );
    }

    Widget gridView = GridView.builder(
      controller: _scrollController,
      padding: widget.padding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: widget.crossAxisCount,
        mainAxisSpacing: widget.mainAxisSpacing,
        crossAxisSpacing: widget.crossAxisSpacing,
        childAspectRatio: widget.childAspectRatio,
      ),
      itemCount: _items.length + (_hasMore && _isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _items.length) {
          return const Center(child: CircularProgressIndicator());
        }
        return widget.itemBuilder(context, _items[index], index);
      },
    );

    if (widget.enablePullToRefresh) {
      gridView = RefreshIndicator(
        onRefresh: _refresh,
        child: gridView,
      );
    }

    return gridView;
  }
}
