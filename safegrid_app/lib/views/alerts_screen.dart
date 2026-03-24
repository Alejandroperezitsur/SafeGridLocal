import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';

class AlertsScreen extends ConsumerWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsProvider);

    return eventsAsync.when(
      data: (events) {
        if (events.isEmpty) {
          return const Center(
            child: Text('No security events. All secure.', style: TextStyle(color: Colors.green, fontSize: 18)),
          );
        }
        
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final e = events[index];
            Color avatarColor = Colors.grey;
            IconData icon = Icons.info;

            if (e.severity == 'high') {
              avatarColor = Colors.red;
              icon = Icons.error;
            } else if (e.severity == 'medium') {
              avatarColor = Colors.orange;
              icon = Icons.warning;
            } else if (e.severity == 'low') {
              avatarColor = Colors.yellow[700]!;
              icon = Icons.info_outline;
            }

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: avatarColor.withOpacity(0.2),
                  child: Icon(icon, color: avatarColor),
                ),
                title: Text(e.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${e.timestamp.toLocal().toString().split('.')[0]}\n${e.description}'),
                isThreeLine: true,
                trailing: Text(e.severity.toUpperCase(), style: TextStyle(color: avatarColor, fontWeight: FontWeight.bold)),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
