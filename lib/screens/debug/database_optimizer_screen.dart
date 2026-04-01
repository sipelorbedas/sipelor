import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/database_optimizer.dart';

/// Database Optimizer Monitoring Screen
/// Displays cache statistics and performance metrics
class DatabaseOptimizerScreen extends StatefulWidget {
  const DatabaseOptimizerScreen({super.key});

  @override
  State<DatabaseOptimizerScreen> createState() =>
      _DatabaseOptimizerScreenState();
}

class _DatabaseOptimizerScreenState extends State<DatabaseOptimizerScreen> {
  Timer? _refreshTimer;
  Map<String, dynamic> _cacheStats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
    // Auto-refresh every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _loadStats();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadStats() {
    setState(() {
      _cacheStats = DatabaseOptimizer.getCacheStats();
    });
  }

  void _clearCache() {
    DatabaseOptimizer.clearCache();
    _loadStats();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Cache cleared successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final entries = _cacheStats['entries'] as List? ?? [];
    final totalEntries = _cacheStats['total_entries'] ?? 0;
    final memoryEstimate = _cacheStats['memory_estimate'] ?? '0 KB';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Optimizer'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep),
            onPressed: _clearCache,
            tooltip: 'Clear Cache',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadStats();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Entries',
                    totalEntries.toString(),
                    Icons.storage,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Memory Est.',
                    memoryEstimate,
                    Icons.memory,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Cache Entries Section
            _buildSectionHeader('Cache Entries'),
            const SizedBox(height: 12),

            if (entries.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.inbox,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No cache entries',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Cache entries will appear here when queries are cached',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...entries.map((entry) => _buildCacheEntryCard(entry)),

            const SizedBox(height: 24),

            // Information Section
            _buildSectionHeader('Information'),
            const SizedBox(height: 12),
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildCacheEntryCard(String key) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: const Icon(Icons.storage, color: Colors.blue, size: 20),
        ),
        title: Text(
          key,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.red),
          onPressed: () {
            DatabaseOptimizer.invalidateCache(key);
            _loadStats();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Cache "$key" invalidated'),
                backgroundColor: Colors.orange,
              ),
            );
          },
          tooltip: 'Invalidate',
        ),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'About Database Optimizer',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'The Database Optimizer caches query results to improve performance and reduce database load.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Features:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            _buildFeatureItem('Query result caching'),
            _buildFeatureItem('Batch operations'),
            _buildFeatureItem('Optimized query patterns'),
            _buildFeatureItem('Automatic cache invalidation'),
            _buildFeatureItem('Query performance tracking'),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle, size: 16, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }
}
