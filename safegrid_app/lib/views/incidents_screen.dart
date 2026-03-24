import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';

class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsProvider);

    return incidentsAsync.when(
      data: (incidents) {
        if (incidents.isEmpty) {
          return const Center(child: Text('No correlated incidents detected.', style: TextStyle(color: Colors.green, fontSize: 18)));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final inc = incidents[index];
            
            Color severityColor = Colors.orange;
            if (inc.severity == 'critical') severityColor = Colors.purple;
            else if (inc.severity == 'high') severityColor = Colors.red;

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(side: BorderSide(color: severityColor, width: 2), borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                initiallyExpanded: inc.status == 'active',
                leading: Icon(Icons.dangerous, color: severityColor, size: 40),
                title: Text('INCIDENT: ${inc.type.toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text('Status: ${inc.status.toUpperCase()} | Severity: ${inc.severity.toUpperCase()}\nStarted: ${inc.startedAt.toLocal()}'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: severityColor.withOpacity(0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('INCIDENT TIMELINE', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                        const SizedBox(height: 12),
                        ...inc.timeline.map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${event.timestamp.toLocal().toString().split('.')[0]} - ', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                Expanded(child: Text(event.description, style: const TextStyle(fontWeight: FontWeight.w500))),
                                if (event.deviceId != null)
                                  Chip(label: Text('Device: ${event.deviceId}'), visualDensity: VisualDensity.compact)
                              ],
                            ),
                          );
                        }),
                        if (inc.timeline.isEmpty) const Text('No timeline events.'),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,s) => Center(child: Text('Error loading incidents: $e')),
    );
  }
}
