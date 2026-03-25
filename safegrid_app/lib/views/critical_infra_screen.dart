import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';
import 'widgets/educational_widgets.dart';

class CriticalInfraScreen extends ConsumerWidget {
  const CriticalInfraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: systemsAsync.when(
        data: (systems) {
          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Infraestructura Crítica Local',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Text('Monitoreo del impacto físico de los incidentes digitales', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: systems.length,
                    itemBuilder: (context, index) {
                      final sys = systems[index];
                      Color statusColor = Colors.green;
                      IconData icon = Icons.check_circle_outline;
                      String statusText = 'Operacional';

                      if (sys.status == 'down') {
                        statusColor = Colors.red;
                        icon = Icons.error_outline;
                        statusText = 'FUERA DE SERVICIO';
                      } else if (sys.status == 'degraded') {
                        statusColor = Colors.orange;
                        icon = Icons.warning_amber_outlined;
                        statusText = 'DEGRADADO';
                      }

                      return ExplainWrapper(
                        title: sys.name,
                        techDesc: '${sys.name} es un activo crítico que depende de la red OT. Estado: ${sys.status}.',
                        analogyDesc: _getSystemAnalogy(sys.name),
                        child: Card(
                          color: statusColor.withOpacity(0.05),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(color: statusColor, width: 2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(icon, color: statusColor, size: 40),
                                const SizedBox(height: 8),
                                Text(sys.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                const SizedBox(height: 4),
                                Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 11)),
                                const Spacer(),
                                if (sys.status != 'operational')
                                   _buildCausalityNote(sys),
                                const Spacer(),
                                if (sys.status != 'operational' && user?.role != 'viewer')
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(0, 44)),
                                      onPressed: () => ref.read(dataRepoProvider).recoverSystem(user!.role, sys.id),
                                      icon: const Icon(Icons.build_circle, size: 16),
                                      label: const Text('RECUPERAR', style: TextStyle(fontSize: 11)),
                                    ),
                                  )
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                _buildAcademicFooter(),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  String _getSystemAnalogy(String name) {
    if (name.contains('Agua')) return 'Es como la tubería maestra de la ciudad: si el motor digital se apaga, no llega agua a las casas.';
    if (name.contains('Energía')) return 'Es el interruptor principal: sin él, todo lo demás en la fábrica se detiene.';
    if (name.contains('HVAC')) return 'Es el aire acondicionado de los servidores: si falla, los equipos se sobrecalientan y se apagan.';
    return 'Es un servicio industrial esencial para la operación continua.';
  }

  Widget _buildCausalityNote(dynamic sys) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
      child: Text(
        'Causa: Dependencias en zona OT comprometidas.',
        style: const TextStyle(fontSize: 9, color: Colors.redAccent, fontStyle: FontStyle.italic),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAcademicFooter() {
    return ExplainWrapper(
      title: 'Fallas en Cascada',
      techDesc: 'Concepto donde el fallo de un componente (PLC) provoca la interrupción de servicios superiores (SCADA/ERP).',
      analogyDesc: 'Es como el efecto dominó: si empujas la primera pieza (PLC), todas las demás caen.',
      child: const Card(
        color: Colors.white10,
        child: Padding(
          padding: EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: Colors.blueAccent),
              SizedBox(width: 12),
              Expanded(child: Text('Nota Académica: Las fallas en cascada demuestran la interconexión entre IT y OT. Toca para ver más.', style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic))),
            ],
          ),
        ),
      ),
    );
  }
}
