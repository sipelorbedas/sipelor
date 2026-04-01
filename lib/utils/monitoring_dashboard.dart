import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'performance_optimizer.dart';

/// Monitoring Dashboard
/// 
/// Provides a comprehensive view of app performance and system health.
/// Only available in debug mode.
class MonitoringDashboard {
  /// Show monitoring dashboard as an overlay
  static void show(BuildContext context) {
    if (!kDebugMode) {
      debugPrint('⚠️  Monitoring dashboard only available in debug mode');
      return;
    }

    showDialog(
      context: context,
      builder: (context) => const _MonitoringDashboardDialog(),
    );
  }

  /// Print comprehensive system report
  static void printSystemReport() {
    if (!kDebugMode) return;

    debugPrint('');
    debugPrint('╔════════════════════════════════════════════════════════════╗');
    debugPrint('║           📊 SIPELOR SYSTEM MONITORING REPORT            ║');
    debugPrint('╠════════════════════════════════════════════════════════════╣');
    
    // Performance Stats
    _printPerformanceStats();
    
    // System Info
    _printSystemInfo();
    
    debugPrint('╚════════════════════════════════════════════════════════════╝');
    debugPrint('');
  }

  static void _printPerformanceStats() {
    debugPrint('║ ⚡ PERFORMANCE METRICS                                    ║');
    
    final optimizer = PerformanceOptimizer();
    final stats = optimizer.getAllStats();
    
    if (stats.isEmpty) {
      debugPrint('║   No operations recorded                                  ║');
    } else {
      final sortedStats = stats.entries.toList()
        ..sort((a, b) {
          final avgA = double.parse(a.value['avg_ms']);
          final avgB = double.parse(b.value['avg_ms']);
          return avgB.compareTo(avgA);
        });

      for (var i = 0; i < sortedStats.take(5).length; i++) {
        final entry = sortedStats[i];
        final name = _truncate(entry.key, 30);
        final avgMs = entry.value['avg_ms'];
        debugPrint('${'║   ${(i + 1)}. $name: ${avgMs}ms'.padRight(60)}║');
      }
    }
    
    debugPrint('╟────────────────────────────────────────────────────────────╢');
  }

  static void _printSystemInfo() {
    debugPrint('║ 🖥️  SYSTEM INFORMATION                                   ║');
    debugPrint('${'║   Platform: ${_getPlatformName()}'.padRight(60)}║');
    debugPrint('${'║   Debug Mode: ${kDebugMode ? 'Yes' : 'No'}'.padRight(60)}║');
    debugPrint('${'║   Release Mode: ${kReleaseMode ? 'Yes' : 'No'}'.padRight(60)}║');
    debugPrint('╟────────────────────────────────────────────────────────────╢');
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'Web';
    try {
      if (Platform.isAndroid) return 'Android';
      if (Platform.isIOS) return 'iOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isLinux) return 'Linux';
    } catch (e) {
      // Platform not available
    }
    return 'Unknown';
  }

  static String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}

/// Monitoring Dashboard Dialog Widget
class _MonitoringDashboardDialog extends StatefulWidget {
  const _MonitoringDashboardDialog();

  @override
  State<_MonitoringDashboardDialog> createState() =>
      _MonitoringDashboardDialogState();
}

class _MonitoringDashboardDialogState
    extends State<_MonitoringDashboardDialog> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '📊 Monitoring Dashboard',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),

            // Tabs
            Row(
              children: [
                _buildTab('Performance', 0),
                _buildTab('System', 1),
              ],
            ),
            const Divider(),

            // Content
            Expanded(
              child: _buildTabContent(),
            ),

            // Actions
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    MonitoringDashboard.printSystemReport();
                  },
                  child: const Text('Print Report'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    PerformanceOptimizer().reset();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Metrics reset successfully'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: const Text('Reset Metrics'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.blue : Colors.grey,
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return _buildPerformanceTab();
      case 1:
        return _buildSystemTab();
      default:
        return const SizedBox();
    }
  }

  Widget _buildPerformanceTab() {
    final optimizer = PerformanceOptimizer();
    final stats = optimizer.getAllStats();

    if (stats.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.speed, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No performance data recorded yet',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 8),
            Text(
              'Use PerformanceOptimizer to track operations',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }

    final sortedStats = stats.entries.toList()
      ..sort((a, b) {
        final avgA = double.parse(a.value['avg_ms']);
        final avgB = double.parse(b.value['avg_ms']);
        return avgB.compareTo(avgA);
      });

    return Column(
      children: [
        // Summary
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSummaryCard(
                'Total Operations',
                stats.length.toString(),
                Icons.functions,
                Colors.blue,
              ),
              _buildSummaryCard(
                'Monitored',
                sortedStats
                    .fold<int>(0, (sum, e) => sum + (e.value['count'] as int))
                    .toString(),
                Icons.analytics,
                Colors.green,
              ),
            ],
          ),
        ),
        const Divider(),
        // List
        Expanded(
          child: ListView.builder(
            itemCount: sortedStats.length,
            itemBuilder: (context, index) {
              final entry = sortedStats[index];
              final data = entry.value;
              final avgMs = double.parse(data['avg_ms']);
              
              // Color based on performance
              Color color = Colors.green;
              if (avgMs > 2000) {
                color = Colors.red;
              } else if (avgMs > 500) {
                color = Colors.orange;
              }

              return ListTile(
                leading: Icon(Icons.speed, color: color),
                title: Text(
                  entry.key,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Count: ${data['count']} | Min: ${data['min_ms']}ms | Max: ${data['max_ms']}ms',
                  style: const TextStyle(fontSize: 11),
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${data['avg_ms']} ms',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: color,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSystemTab() {
    return ListView(
      children: [
        _buildStatCard(
          'Platform',
          MonitoringDashboard._getPlatformName(),
          Icons.devices,
        ),
        _buildStatCard(
          'Debug Mode',
          kDebugMode ? 'Enabled' : 'Disabled',
          Icons.bug_report,
        ),
        _buildStatCard(
          'Release Mode',
          kReleaseMode ? 'Enabled' : 'Disabled',
          Icons.rocket_launch,
        ),
        _buildStatCard(
          'Profile Mode',
          kProfileMode ? 'Enabled' : 'Disabled',
          Icons.speed,
        ),
        _buildStatCard(
          'Web Platform',
          kIsWeb ? 'Yes' : 'No',
          Icons.web,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
