import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';

class CriticalInfraScreen extends ConsumerWidget {
  const CriticalInfraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);
    final user = ref.watch(currentUserProvider);

    return systemsAsync.when(
      data: (systems) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Estado de Infraestructura Crítica Local',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const Text('Impacto operacional directo por dependencias de red', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
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
                      statusText = 'CAÍDO / SIN SERVICIO';
                    } else if (sys.status == 'degraded') {
                      statusColor = Colors.orange;
                      icon = Icons.warning_amber_outlined;
                      statusText = 'DEGRADADO';
                    }

                    return Card(
                      color: statusColor.withOpacity(0.05),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: statusColor, width: 2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: statusColor, size: 48),
                            const SizedBox(height: 12),
                            Text(sys.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 13)),
                            const Spacer(),
                            if(sys.dependencies.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text('Dep: ${sys.dependencies.join(', ')}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              ),
                            if (sys.status != 'operational' && user?.role != 'viewer')
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 8)),
                                  onPressed: () => ref.read(dataRepoProvider).recoverSystem(user!.role, sys.id),
                                  icon: const Icon(Icons.build_circle, size: 16),
                                  label: const Text('RECUPERAR', style: TextStyle(fontSize: 12)),
                                ),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                color: Colors.white10,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, size: 16),
                      SizedBox(width: 12),
                      Expanded(child: Text('Nota Académica: Las fallas en cascada ocurren cuando un sistema OT (ej. PLC de Energía) es comprometido, afectando a sistemas TI y de Servicios que dependen de él.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic))),
                    ],
                  ),
                ),
              )
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
