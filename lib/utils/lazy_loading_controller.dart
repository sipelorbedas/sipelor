import 'package:flutter/material.dart';

/// Lazy Loading Controller for efficient list pagination
/// 
/// Features:
/// - Automatic pagination when reaching bottom
/// - Loading state management
/// - Error handling
/// - Pull to refresh support
/// - Customizable threshold
/// 
/// Usage:
/// ```dart
/// final controller = LazyLoadingController<MyItem>(
///   fetchItems: (page, pageSize) async {
///     return await api.fetchItems(page, pageSize);
///   },
///   pageSize: 20,
/// );
/// 
/// LazyLoadingListView(
///   controller: controller,
///   itemBuilder: (context, item) => MyItemWidget(item),
/// )
/// ```
class LazyLoadingController<T> extends ChangeNotifier {
  final Future<List<T>> Function(int page, int pageSize) fetchItems;
  final int pageSize;
  final double loadMoreThreshold;

  List<T> _items = [];
  int _currentPage = 0;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  LazyLoadingController({
    required this.fetchItems,
    this.pageSize = 20,
    this.loadMoreThreshold = 0.8, // Load more when 80% scrolled
  });

  List<T> get items => _items;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get isEmpty => _items.isEmpty && !_isLoading;

  /// Load initial page
  Future<void> loadInitial() async {
    _currentPage = 0;
    _items = [];
    _hasMore = true;
    _error = null;
    await loadMore();
  }

  /// Load next page
  Future<void> loadMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newItems = await fetchItems(_currentPage, pageSize);

      _items.addAll(newItems);
      _currentPage++;
      _hasMore = newItems.length >= pageSize;
    } catch (e) {
      _error = e.toString();
      debugPrint('LazyLoadingController error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh (pull to refresh)
  Future<void> refresh() async {
    await loadInitial();
  }

  /// Clear all data
  void clear() {
    _items = [];
    _currentPage = 0;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _items.clear();
    super.dispose();
  }
}

/// Lazy Loading ListView Widget
class LazyLoadingListView<T> extends StatefulWidget {
  final LazyLoadingController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final Widget? separator;
  final EdgeInsetsGeometry? padding;
  final Widget? emptyWidget;
  final Widget? errorWidget;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LazyLoadingListView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.separator,
    this.padding,
    this.emptyWidget,
    this.errorWidget,
    this.shrinkWrap = false,
    this.physics,
  });

  @override
  State<LazyLoadingListView<T>> createState() =>
      _LazyLoadingListViewState<T>();
}

class _LazyLoadingListViewState<T> extends State<LazyLoadingListView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.controller.addListener(_onControllerUpdate);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.items.isEmpty) {
        widget.controller.loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent *
            widget.controller.loadMoreThreshold) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show empty state
    if (widget.controller.isEmpty && !widget.controller.isLoading) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada data',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
    }

    // Show error state
    if (widget.controller.error != null && widget.controller.items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => widget.controller.loadInitial(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
    }

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: ListView.separated(
        controller: _scrollController,
        padding: widget.padding,
        shrinkWrap: widget.shrinkWrap,
        physics: widget.physics,
        itemCount: widget.controller.items.length +
            (widget.controller.hasMore ? 1 : 0),
        separatorBuilder: (context, index) =>
            widget.separator ?? const SizedBox.shrink(),
        itemBuilder: (context, index) {
          // Show loading indicator at bottom
          if (index >= widget.controller.items.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: CircularProgressIndicator(),
              ),
            );
          }

          return widget.itemBuilder(
            context,
            widget.controller.items[index],
          );
        },
      ),
    );
  }
}

/// Lazy Loading GridView Widget
class LazyLoadingGridView<T> extends StatefulWidget {
  final LazyLoadingController<T> controller;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsetsGeometry? padding;
  final Widget? emptyWidget;
  final Widget? errorWidget;

  const LazyLoadingGridView({
    super.key,
    required this.controller,
    required this.itemBuilder,
    this.crossAxisCount = 2,
    this.crossAxisSpacing = 8.0,
    this.mainAxisSpacing = 8.0,
    this.childAspectRatio = 1.0,
    this.padding,
    this.emptyWidget,
    this.errorWidget,
  });

  @override
  State<LazyLoadingGridView<T>> createState() =>
      _LazyLoadingGridViewState<T>();
}

class _LazyLoadingGridViewState<T> extends State<LazyLoadingGridView<T>> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    widget.controller.addListener(_onControllerUpdate);

    // Load initial data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.controller.items.isEmpty) {
        widget.controller.loadInitial();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent *
            widget.controller.loadMoreThreshold) {
      widget.controller.loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show empty state
    if (widget.controller.isEmpty && !widget.controller.isLoading) {
      return widget.emptyWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  'Tidak ada data',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
    }

    // Show error state
    if (widget.controller.error != null && widget.controller.items.isEmpty) {
      return widget.errorWidget ??
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 64, color: Colors.red[400]),
                const SizedBox(height: 16),
                Text(
                  'Terjadi kesalahan',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => widget.controller.loadInitial(),
                  child: const Text('Coba Lagi'),
                ),
              ],
            ),
          );
    }

    return RefreshIndicator(
      onRefresh: widget.controller.refresh,
      child: GridView.builder(
        controller: _scrollController,
        padding: widget.padding,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.crossAxisCount,
          crossAxisSpacing: widget.crossAxisSpacing,
          mainAxisSpacing: widget.mainAxisSpacing,
          childAspectRatio: widget.childAspectRatio,
        ),
        itemCount: widget.controller.items.length +
            (widget.controller.hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          // Show loading indicator at bottom
          if (index >= widget.controller.items.length) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return widget.itemBuilder(
            context,
            widget.controller.items[index],
          );
        },
      ),
    );
  }
}
