import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/performance_monitor.dart';

/// Performance Monitor Screen
/// Displays performance metrics and statistics
class PerformanceMonitorScreen extends StatefulWidget {
  const PerformanceMonitorScreen({super.key});

  @override
  State<PerformanceMonitorScreen> createState() =>
      _PerformanceMonitorScreenState();
}

class _PerformanceMonitorScreenState extends State<PerformanceMonitorScreen> {
  Timer? _refreshTimer;
  Map<String, Map<String, dynamic>> _metrics = {};

  @override
  void initState() {
    super.initState();
    _loadMetrics();
    // Auto-refresh every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _loadMetrics();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadMetrics() {
    setState(() {
      _metrics = PerformanceMonitor.getMetricsSummary();
    });
  }

  void _printReport() {
    PerformanceMonitor.printReport();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report printed to console'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getPerformanceColor(double avgMs) {
    if (avgMs < 50) return Colors.green;
    if (avgMs < 100) return Colors.orange;
    if (avgMs < 500) return Colors.deepOrange;
    return Colors.red;
  }

  String _getPerformanceLabel(double avgMs) {
    if (avgMs < 50) return 'Excellent';
    if (avgMs < 100) return 'Good';
    if (avgMs < 500) return 'Slow';
    return 'Very Slow';
  }

  @override
  Widget build(BuildContext context) {
    final totalMetrics = _metrics.length;
    final slowOperations =
        _metrics.values.where((m) => (m['avg'] as double) > 100).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Performance Monitor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMetrics,
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: _printReport,
            tooltip: 'Print Report',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _loadMetrics();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Total Operations',
                    totalMetrics.toString(),
                    Icons.functions,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Slow Operations',
                    slowOperations.toString(),
                    Icons.speed,
                    slowOperations > 0 ? Colors.orange : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Performance Metrics Section
            _buildSectionHeader('Performance Metrics'),
            const SizedBox(height: 12),

            if (_metrics.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.analytics,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No performance data',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Performance metrics will appear here when operations are tracked',
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
              ..._metrics.entries.map((entry) => _buildMetricCard(entry)),

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

  Widget _buildMetricCard(MapEntry<String, Map<String, dynamic>> entry) {
    final name = entry.key;
    final metrics = entry.value;
    final avg = metrics['avg'] as double;
    final min = metrics['min'] as int;
    final max = metrics['max'] as int;
    final p50 = metrics['p50'] as int;
    final p95 = metrics['p95'] as int;
    final p99 = metrics['p99'] as int;
    final count = metrics['count'] as int;

    final color = _getPerformanceColor(avg);
    final label = _getPerformanceLabel(avg);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(Icons.timer, color: color, size: 20),
        ),
        title: Text(
          name,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Row(
          children: [
            Text(
              '${avg.toStringAsFixed(1)}ms',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        trailing: Text(
          '$count calls',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                _buildMetricRow('Minimum', '$min ms', Colors.green),
                const SizedBox(height: 8),
                _buildMetricRow('Maximum', '$max ms', Colors.red),
                const SizedBox(height: 8),
                _buildMetricRow('P50 (Median)', '$p50 ms', Colors.blue),
                const SizedBox(height: 8),
                _buildMetricRow('P95', '$p95 ms', Colors.orange),
                const SizedBox(height: 8),
                _buildMetricRow('P99', '$p99 ms', Colors.deepOrange),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[800],
          ),
        ),
      ],
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
                  'About Performance Monitor',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'The Performance Monitor tracks operation durations and provides detailed statistics to help optimize application performance.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Metrics Explained:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            _buildMetricExplanation('Min/Max', 'Fastest and slowest executions'),
            _buildMetricExplanation('P50 (Median)', '50% of executions are faster'),
            _buildMetricExplanation('P95', '95% of executions are faster'),
            _buildMetricExplanation('P99', '99% of executions are faster'),
            const SizedBox(height: 12),
            const Text(
              'Performance Levels:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            _buildColorItem(Colors.green, '< 50ms: Excellent'),
            _buildColorItem(Colors.orange, '50-100ms: Good'),
            _buildColorItem(Colors.deepOrange, '100-500ms: Slow'),
            _buildColorItem(Colors.red, '> 500ms: Very Slow'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricExplanation(String name, String description) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          const Icon(Icons.timeline, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$name: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: description),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorItem(Color color, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, top: 4),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
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
