import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:invoice_flow/blocs/history_cubit.dart';
import 'package:invoice_flow/utils/formatters.dart';
import 'package:invoice_flow/widgets/premium_widgets.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity History')),
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          if (state is HistoryLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HistoryLoaded) {
            final items = state.items;
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.history_outlined, size: 64, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    const Text('No activity history found',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 8),
                    const Text('Your actions will appear here.',
                        style: TextStyle(color: Colors.blueGrey)),
                  ],
                ),
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(32),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final color = _getTypeColor(context, item.type);
                return PremiumCard(
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getTypeIcon(item.type), color: color),
                    ),
                    title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(item.description, style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade400 : Colors.blueGrey.shade600)),
                        const SizedBox(height: 8),
                        Text(
                          '${AppFormatters.formatDate(item.timestamp)} at ${TimeOfDay.fromDateTime(item.timestamp).format(context)}',
                          style: TextStyle(fontSize: 11, color: Theme.of(context).brightness == Brightness.dark ? Colors.grey.shade500 : Colors.blueGrey.shade300),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }
          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  IconData _getTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'invoice':
        return Icons.description_outlined;
      case 'client':
        return Icons.person_outline;
      case 'settings':
        return Icons.settings_outlined;
      default:
        return Icons.history;
    }
  }

  Color _getTypeColor(BuildContext context, String type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (type.toLowerCase()) {
      case 'invoice':
        return isDark ? const Color(0xFFFED200) : const Color(0xFFB45309);
      case 'client':
        return const Color(0xFF10B981);
      case 'settings':
        return Colors.blueAccent;
      default:
        return Colors.grey;
    }
  }
}
