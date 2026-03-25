import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskScore = ref.watch(riskScoreProvider);
    final user = ref.watch(currentUserProvider);

    Color gaugeColor = Colors.green;
    String riskLevel = 'BAJO';
    if (riskScore >= 16) {
      gaugeColor = Colors.red;
      riskLevel = 'CRÍTICO';
    } else if (riskScore >= 6) {
      gaugeColor = Colors.orange;
      riskLevel = 'MEDIO';
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Visión General del Sistema',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (user?.role == 'admin')
                  Row(
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () => ref.read(dataRepoProvider).simulateAttack(user!.role),
                        icon: const Icon(Icons.warning),
                        label: const Text('Simular Ransomware'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.grey),
                        onPressed: () => ref.read(dataRepoProvider).resetSimulation(user!.role),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reiniciar Engine'),
                      ),
                    ],
                  )
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Card(
                      elevation: 4,
                      color: gaugeColor.withOpacity(0.1),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('NIVEL DE IMPACTO', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            Icon(
                              riskScore >= 16 ? Icons.dangerous : (riskScore >= 6 ? Icons.warning : Icons.check_circle),
                              size: 100,
                              color: gaugeColor,
                            ),
                            const SizedBox(height: 16),
                            Text(riskLevel, style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: gaugeColor)),
                            Text('Puntuaje: $riskScore', style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 4,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Métricas en Tiempo Real', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Divider(),
                            Expanded(
                              child: GridView.count(
                                crossAxisCount: 2,
                                childAspectRatio: 2.5,
                                children: [
                                  _buildMetricTile('Zona IT Segura', Icons.computer, Colors.blue),
                                  _buildMetricTile('Zona OT Monitoreada', Icons.precision_manufacturing, Colors.purple),
                                  _buildMetricTile('Detección IDS/IPS', Icons.radar, Colors.teal),
                                  _buildMetricTile('Defensa Múltiple Activa', Icons.layers, Colors.indigo),
                                ],
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String title, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 36),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: const Text('Óptimo'),
    );
  }
}
