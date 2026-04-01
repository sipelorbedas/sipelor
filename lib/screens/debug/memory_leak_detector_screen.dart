import 'dart:async';
import 'package:flutter/material.dart';
import '../../utils/memory_leak_detector.dart';

/// Memory Leak Detector Monitoring Screen
/// Displays tracked resources and potential memory leaks
class MemoryLeakDetectorScreen extends StatefulWidget {
  const MemoryLeakDetectorScreen({super.key});

  @override
  State<MemoryLeakDetectorScreen> createState() =>
      _MemoryLeakDetectorScreenState();
}

class _MemoryLeakDetectorScreenState extends State<MemoryLeakDetectorScreen> {
  Timer? _refreshTimer;
  List<Map<String, dynamic>> _trackedResources = [];

  @override
  void initState() {
    super.initState();
    _loadResources();
    // Auto-refresh every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (mounted) {
        _loadResources();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _loadResources() {
    setState(() {
      _trackedResources = MemoryLeakDetector.getTrackedResources();
    });
  }

  void _printReport() {
    MemoryLeakDetector.printReport();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report printed to console'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Color _getStatusColor(int ageSeconds) {
    if (ageSeconds < 60) return Colors.green;
    if (ageSeconds < 300) return Colors.orange;
    if (ageSeconds < 600) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatAge(int ageSeconds) {
    if (ageSeconds < 60) {
      return '$ageSeconds seconds';
    } else if (ageSeconds < 3600) {
      return '${(ageSeconds / 60).floor()} minutes';
    } else {
      return '${(ageSeconds / 3600).floor()} hours';
    }
  }

  IconData _getTypeIcon(String type) {
    if (type.contains('Controller')) return Icons.settings_remote;
    if (type.contains('Notifier')) return Icons.notifications;
    if (type.contains('Timer')) return Icons.timer;
    if (type.contains('Stream')) return Icons.stream;
    return Icons.memory;
  }

  @override
  Widget build(BuildContext context) {
    final warningCount = _trackedResources
        .where((r) => (r['age_seconds'] as int) > 600)
        .length;
    final activeCount = _trackedResources.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Memory Leak Detector'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadResources,
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
          _loadResources();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Summary Cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    'Active Resources',
                    activeCount.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSummaryCard(
                    'Warnings',
                    warningCount.toString(),
                    Icons.warning,
                    warningCount > 0 ? Colors.red : Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Status Banner
            if (warningCount > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  border: Border.all(color: Colors.red),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: Colors.red),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '$warningCount potential memory leak(s) detected!',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tracked Resources Section
            _buildSectionHeader('Tracked Resources'),
            const SizedBox(height: 12),

            if (_trackedResources.isEmpty)
              Center(
                child: Column(
                  children: [
                    const SizedBox(height: 40),
                    Icon(
                      Icons.check_circle,
                      size: 64,
                      color: Colors.green[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No tracked resources',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'All resources have been properly disposed',
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
              ..._trackedResources
                  .map((resource) => _buildResourceCard(resource)),

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

  Widget _buildResourceCard(Map<String, dynamic> resource) {
    final id = resource['id'] as String;
    final type = resource['type'] as String;
    final ageSeconds = resource['age_seconds'] as int;
    final description = resource['description'] as String?;
    final statusColor = _getStatusColor(ageSeconds);
    final age = _formatAge(ageSeconds);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(_getTypeIcon(type), color: statusColor, size: 20),
        ),
        title: Text(
          id,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        subtitle: Text(
          type,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withOpacity(0.3)),
          ),
          child: Text(
            age,
            style: TextStyle(
              fontSize: 11,
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (description != null) ...[
                  Row(
                    children: [
                      Icon(Icons.description,
                          size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          description,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Row(
                  children: [
                    Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Created: ${resource['created_at']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                if (ageSeconds > 600) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning, size: 16, color: Colors.red),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This resource has been alive for more than 10 minutes. '
                            'Check if it\'s being properly disposed.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
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
                  'About Memory Leak Detector',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'The Memory Leak Detector tracks disposable resources to help identify memory leaks in your application.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 8),
            const Text(
              'Color Indicators:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            _buildColorItem(Colors.green, '< 1 minute: Normal'),
            _buildColorItem(Colors.orange, '1-5 minutes: Monitor'),
            _buildColorItem(Colors.deepOrange, '5-10 minutes: Warning'),
            _buildColorItem(Colors.red, '> 10 minutes: Potential leak'),
          ],
        ),
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
