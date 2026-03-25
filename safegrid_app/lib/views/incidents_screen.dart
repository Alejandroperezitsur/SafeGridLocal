import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';

class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsProvider);
    final user = ref.watch(currentUserProvider);

    return incidentsAsync.when(
      data: (incidents) {
        if (incidents.isEmpty) { return const Center(child: Text('No hay incidentes correlacionados activos.', style: TextStyle(color: Colors.green, fontSize: 18))); }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final inc = incidents[index];
            Color severityColor = Colors.orange;
            if (inc.severity == 'critical') severityColor = Colors.purple;
            else if (inc.severity == 'high') severityColor = Colors.red;
            
            bool isContained = inc.status == 'contained' || inc.status == 'resolved';

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(side: BorderSide(color: isContained ? Colors.green : severityColor, width: 2), borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                initiallyExpanded: !isContained,
                leading: Icon(isContained ? Icons.shield : Icons.dangerous, color: isContained ? Colors.green : severityColor, size: 40),
                title: Text('INCIDENTE: ${inc.type.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isContained ? Colors.green : null)),
                subtitle: Text('Estado: ${inc.status.toUpperCase()} | Severidad: ${inc.severity.toUpperCase()}\nIniciado: ${inc.startedAt.toLocal()}'),
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: isContained ? Colors.green.withOpacity(0.05) : severityColor.withOpacity(0.05),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                             const Text('LÍNEA DE TIEMPO DEL INCIDENTE', style: TextStyle(fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                             if (!isContained && (user?.role == 'admin' || user?.role == 'operator'))
                               FilledButton.icon(
                                 onPressed: () => ref.read(dataRepoProvider).containIncident(user!.role, inc.id),
                                 icon: const Icon(Icons.lock),
                                 label: const Text('Contener Incidente'),
                                 style: FilledButton.styleFrom(backgroundColor: Colors.green),
                               )
                          ]
                        ),
                        if (inc.explanation != null && inc.explanation!.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), border: Border.all(color: Colors.blue, width: 2), borderRadius: BorderRadius.circular(8)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.psychology, color: Colors.blue),
                                    SizedBox(width: 8),
                                    Text('ANÁLISIS DE CAUSA RAÍZ (IA)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 16)),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(inc.explanation!, style: const TextStyle(height: 1.5, fontSize: 15)),
                              ]
                            )
                          ),
                        ],
                        const SizedBox(height: 16),
                        ...inc.timeline.map((event) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${event.timestamp.toLocal().toString().split('.')[0]} - ', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                Expanded(child: Text(event.description, style: const TextStyle(fontWeight: FontWeight.w500))),
                                if (event.deviceId != null)
                                  Chip(label: Text('Disp: ${event.deviceId}'), visualDensity: VisualDensity.compact)
                              ],
                            ),
                          );
                        }),
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
      error: (e,s) => Center(child: Text('Error al cargar incidentes: $e')),
    );
  }
}
