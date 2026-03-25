import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';
import 'widgets/educational_widgets.dart';

class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsProvider);
    final user = ref.watch(currentUserProvider);

    return incidentsAsync.when(
      data: (incidents) {
        if (incidents.isEmpty) { 
          return Center(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.verified_user, size: 60, color: Colors.green),
              const SizedBox(height: 16),
              const Text('Sistema Seguro', style: TextStyle(color: Colors.green, fontSize: 18, fontWeight: FontWeight.bold)),
              const Text('No se detectan amenazas correlacionadas.', style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              ExplainWrapper(
                title: 'Monitoreo Pasivo',
                techDesc: 'El sistema escucha el tráfico de red buscando anomalías sin interrumpir el proceso industrial.',
                analogyDesc: 'Es como un guardia que observa las cámaras sin detener a nadie, a menos que vea algo prohibido.',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('¿Cómo funciona el monitoreo?', style: TextStyle(color: Colors.blue, fontSize: 12, decoration: TextDecoration.underline)),
                    ],
                  ),
                ),
              ),
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

            return ExplainWrapper(
              title: inc.type.toUpperCase(),
              techDesc: 'Evento de tipo ${inc.type}. Severidad ${inc.severity}. Estado: ${inc.status}.',
              analogyDesc: _getIncidentAnalogy(inc.type),
              child: Card(
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
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e,s) => Center(child: Text('Error: $e')),
    );
  }

  String _getIncidentAnalogy(String type) {
    if (type == 'ransomware') return 'Es como si alguien entrara a tu oficina y pusiera candados a todos tus cajones, exigiendo dinero para darte la llave.';
    if (type == 'unauthorized_access') return 'Es como si alguien intentara abrir la puerta de la fábrica con una llave maestra robada.';
    return 'Es un comportamiento inusual que el sistema ha marcado como sospechoso.';
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
                   style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(120, 48)),
                 )
            ]
          ),
          const Divider(),
          if (!isResolved) _buildDSSRecomendations(inc),
          const SizedBox(height: 16),
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
            padding: const EdgeInsets.only(bottom: 6.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.history, size: 14, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(child: Text(event.description, style: const TextStyle(fontSize: 12))),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDSSRecomendations(dynamic inc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.orange)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange, size: 18),
              SizedBox(width: 8),
              Text('Recomendación SOC (NIST):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.orange)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            inc.type == 'ransomware' 
              ? 'Aislar el segmento OT y deshabilitar servicios SMB temporalmente.' 
              : 'Verificar logs del Active Directory y rotar credenciales del operario afectado.',
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}
