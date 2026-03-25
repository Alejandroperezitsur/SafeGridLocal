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
        if (incidents.isEmpty) { 
          return const Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.verified_user, size: 60, color: Colors.green),
              SizedBox(height: 16),
              Text('No hay amenazas correlacionadas.', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
              Text('Monitoreo pasivo en ejecución...', style: TextStyle(color: Colors.grey)),
            ],
          )); 
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final inc = incidents[index];
            Color severityColor = Colors.orange;
            if (inc.severity == 'critical') severityColor = Colors.red;
            else if (inc.severity == 'high') severityColor = Colors.orangeAccent;
            
            bool isResolved = inc.status == 'resolved' || inc.status == 'contained';

            return Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: isResolved ? Colors.green : severityColor, width: 2), 
                borderRadius: BorderRadius.circular(12)
              ),
              margin: const EdgeInsets.only(bottom: 16),
              child: ExpansionTile(
                initiallyExpanded: !isResolved,
                leading: Icon(isResolved ? Icons.check_circle : Icons.warning_rounded, color: isResolved ? Colors.green : severityColor, size: 36),
                title: Text('INCIDENTE: ${inc.type.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isResolved ? Colors.green : null)),
                subtitle: Text('Estado: ${inc.status.toUpperCase()} | Severidad: ${inc.severity.toUpperCase()}'),
                children: [
                   _buildIncidentDetail(context, ref, user, inc, isResolved, severityColor),
                ],
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildIncidentDetail(BuildContext context, WidgetRef ref, dynamic user, dynamic inc, bool isResolved, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: color.withOpacity(0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               const Text('ANÁLISIS DE LA AMENAZA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1.2)),
               if (!isResolved && user?.role != 'viewer')
                 ElevatedButton.icon(
                   onPressed: () => ref.read(dataRepoProvider).containIncident(user!.role, inc.id),
                   icon: const Icon(Icons.security, size: 16),
                   label: const Text('CONTENER AHORA'),
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                 )
            ]
          ),
          const Divider(),
          if (inc.explanation != null && inc.explanation!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), border: Border.all(color: Colors.blue), borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('🚀 EXPLICACIÓN (Motor de Inteligencia)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(inc.explanation!, style: const TextStyle(fontSize: 14)),
                ]
              )
            ),
            const SizedBox(height: 16),
          ],
          const Text('Timeline de Eventos:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          ...inc.timeline.map((event) => Padding(
            padding: const EdgeInsets.only(bottom: 4.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.arrow_right, size: 16, color: Colors.grey),
                Expanded(child: Text(event.description, style: const TextStyle(fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
