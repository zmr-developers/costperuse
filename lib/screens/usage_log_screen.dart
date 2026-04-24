import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../models/purchase.dart';
import '../models/usage_log.dart';

class UsageLogScreen extends StatefulWidget {
  final Purchase purchase;
  const UsageLogScreen({super.key, required this.purchase});

  @override
  State<UsageLogScreen> createState() => _UsageLogScreenState();
}

class _UsageLogScreenState extends State<UsageLogScreen> {
  List<UsageLog> _logs = [];
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    final logs = await DatabaseHelper.instance.getUsageLogs(widget.purchase.id!);
    setState(() => _logs = logs);
  }

  Future<void> _addUsage() async {
    _notesCtrl.clear();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Log Usage', style: Theme.of(ctx).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(labelText: 'Notes (optional)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final log = UsageLog(
                    purchaseId: widget.purchase.id!,
                    usageDate: DateTime.now().toIso8601String(),
                    notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
                  );
                  await DatabaseHelper.instance.insertUsageLog(log);
                  if (ctx.mounted) Navigator.pop(ctx);
                  _loadLogs();
                },
                child: const Text('Log Usage'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final count = _logs.length;
    final cpu = count == 0 ? widget.purchase.cost : widget.purchase.cost / count;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purchase.name),
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _stat('Total Cost', '\$${widget.purchase.cost.toStringAsFixed(2)}', cs),
                _stat('Total Uses', '$count', cs),
                _stat('Cost/Use', '\$${cpu.toStringAsFixed(2)}', cs),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
                ? Center(child: Text('No usage logs yet', style: TextStyle(color: cs.onSurfaceVariant)))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: _logs.length,
                    itemBuilder: (ctx, i) {
                      final log = _logs[i];
                      final date = DateTime.parse(log.usageDate);
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: cs.secondaryContainer,
                            child: Text('${i + 1}', style: TextStyle(color: cs.onSecondaryContainer)),
                          ),
                          title: Text('${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}'),
                          subtitle: log.notes != null ? Text(log.notes!) : null,
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              await DatabaseHelper.instance.deleteUsageLog(log.id!);
                              _loadLogs();
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addUsage,
        backgroundColor: cs.primary,
        foregroundColor: cs.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('Log Use'),
      ),
    );
  }

  Widget _stat(String label, String value, ColorScheme cs) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: cs.onPrimaryContainer)),
        Text(label, style: TextStyle(fontSize: 12, color: cs.onPrimaryContainer)),
      ],
    );
  }
}
