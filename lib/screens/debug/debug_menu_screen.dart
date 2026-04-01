import 'package:flutter/material.dart';
import 'database_optimizer_screen.dart';
import 'memory_leak_detector_screen.dart';
import 'performance_monitor_screen.dart';
import '../../utils/database_optimizer.dart';
import '../../utils/memory_leak_detector.dart';
import '../../utils/performance_monitor.dart';

/// Debug Menu Screen
/// Central hub for accessing all debugging and monitoring tools
class DebugMenuScreen extends StatelessWidget {
  const DebugMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cacheStats = DatabaseOptimizer.getCacheStats();
    final trackedResources = MemoryLeakDetector.getTrackedResources();
    final performanceMetrics = PerformanceMonitor.getMetricsSummary();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug Menu'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepPurple, Colors.purple[300]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.bug_report, color: Colors.white, size: 32),
                    SizedBox(width: 12),
                    Text(
                      'Developer Tools',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Text(
                  'Monitor and optimize application performance',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Monitoring Tools Section
          _buildSectionHeader('Monitoring Tools'),
          const SizedBox(height: 12),

          // Database Optimizer Card
          _buildToolCard(
            context: context,
            title: 'Database Optimizer',
            description: 'Monitor query cache and database performance',
            icon: Icons.storage,
            color: Colors.blue,
            stats: '${cacheStats['total_entries'] ?? 0} cached queries',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const DatabaseOptimizerScreen(),
                ),
              );
            },
          ),

          // Memory Leak Detector Card
          _buildToolCard(
            context: context,
            title: 'Memory Leak Detector',
            description: 'Track resources and detect potential memory leaks',
            icon: Icons.memory,
            color: Colors.purple,
            stats: '${trackedResources.length} tracked resources',
            statusColor: trackedResources.any(
              (r) => (r['age_seconds'] as int) > 600,
            )
                ? Colors.red
                : Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MemoryLeakDetectorScreen(),
                ),
              );
            },
          ),

          // Performance Monitor Card
          _buildToolCard(
            context: context,
            title: 'Performance Monitor',
            description: 'View detailed performance metrics and statistics',
            icon: Icons.speed,
            color: Colors.orange,
            stats: '${performanceMetrics.length} operations tracked',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PerformanceMonitorScreen(),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Quick Actions Section
          _buildSectionHeader('Quick Actions'),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  label: 'Clear Cache',
                  icon: Icons.delete_sweep,
                  color: Colors.red,
                  onPressed: () {
                    DatabaseOptimizer.clearCache();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cache cleared successfully'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  label: 'Print Reports',
                  icon: Icons.print,
                  color: Colors.blue,
                  onPressed: () {
                    MemoryLeakDetector.printReport();
                    PerformanceMonitor.printReport();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reports printed to console'),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Information Card
          Card(
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
                        'About Debug Tools',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'These tools help developers monitor and optimize application performance. '
                    'They are only available in debug mode and will not appear in production builds.',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber[50],
                      border: Border.all(color: Colors.amber),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.amber),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Debug mode only. These features are disabled in release builds.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
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

  Widget _buildToolCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
    required String stats,
    Color? statusColor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (statusColor != null)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 6),
                            decoration: BoxDecoration(
                              color: statusColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          stats,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
