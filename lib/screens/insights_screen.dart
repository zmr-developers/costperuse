import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/purchase.dart';

class InsightsScreen extends StatelessWidget {
  final List<Purchase> purchases;
  final Map<int, int> usageCounts;

  const InsightsScreen({super.key, required this.purchases, required this.usageCounts});

  double _cpu(Purchase p) {
    final c = usageCounts[p.id] ?? 0;
    return c == 0 ? p.cost : p.cost / c;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final sorted = [...purchases]..sort((a, b) => _cpu(a).compareTo(_cpu(b)));
    final totalSpent = purchases.fold(0.0, (s, p) => s + p.cost);
    final totalUses = usageCounts.values.fold(0, (s, v) => s + v);
    final bestValue = sorted.isNotEmpty ? sorted.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: purchases.isEmpty
          ? Center(child: Text('No data yet', style: TextStyle(color: cs.onSurfaceVariant)))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: _card('Total Spent', '$${totalSpent.toStringAsFixed(2)}', Icons.attach_money, cs)),
                      const SizedBox(width: 12),
                      Expanded(child: _card('Total Uses', '$totalUses', Icons.repeat, cs)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (bestValue != null)
                    _card('Best Value Item', '${bestValue.name}\n\$${_cpu(bestValue).toStringAsFixed(2)}/use', Icons.star, cs),
                  const SizedBox(height: 24),
                  Text('Cost Per Use Comparison', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  if (purchases.isNotEmpty)
                    SizedBox(
                      height: 220,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: sorted.isNotEmpty ? (_cpu(sorted.last) * 1.3) : 100,
                          barTouchData: BarTouchData(enabled: true),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final idx = val.toInt();
                                  if (idx < 0 || idx >= sorted.length) return const SizedBox();
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(sorted[idx].name.length > 6 ? sorted[idx].name.substring(0, 6) : sorted[idx].name, style: const TextStyle(fontSize: 10)),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: sorted.asMap().entries.map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [BarChartRodData(toY: _cpu(e.value), color: cs.primary, width: 16, borderRadius: BorderRadius.circular(4))],
                          )).toList(),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Text('Depreciation Overview', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...sorted.map((p) {
                    final count = usageCounts[p.id] ?? 0;
                    final progress = (count / p.expectedLifespan).clamp(0.0, 1.0);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(p.name, style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text('$count / ${p.expectedLifespan} uses'),
                            ],
                          ),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: progress,
                            backgroundColor: cs.surfaceVariant,
                            color: progress > 0.8 ? Colors.red : progress > 0.5 ? Colors.orange : cs.primary,
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }

  Widget _card(String label, String value, IconData icon, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: cs.onPrimaryContainer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
                Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
