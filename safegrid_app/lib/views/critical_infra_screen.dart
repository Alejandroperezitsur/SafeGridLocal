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
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Estado de Infraestructura Crítica',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: systems.length,
                  itemBuilder: (context, index) {
                    final sys = systems[index];
                    Color statusColor = Colors.green;
                    IconData icon = Icons.check_circle;

                    if (sys.status == 'down') {
                      statusColor = Colors.red;
                      icon = Icons.cancel;
                    } else if (sys.status == 'degraded') {
                      statusColor = Colors.orange;
                      icon = Icons.warning;
                    }

                    return Card(
                      color: statusColor.withOpacity(0.1),
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: statusColor, width: 2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, color: statusColor, size: 48),
                            const SizedBox(height: 8),
                            Text(sys.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Estado: ${sys.status.toUpperCase()}', style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            const Spacer(),
                            if(sys.dependencies.isNotEmpty)
                              Text('Depende de: ${sys.dependencies.join(', ')}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                            const Spacer(),
                            if (sys.status != 'operational' && (user?.role == 'admin' || user?.role == 'operator'))
                              FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: Colors.blue),
                                onPressed: () => ref.read(dataRepoProvider).recoverSystem(user!.role, sys.id),
                                icon: const Icon(Icons.build),
                                label: const Text('Recuperar Sistema'),
                              )
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }
}
