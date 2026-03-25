import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskScore = ref.watch(riskScoreProvider);
    final user = ref.watch(currentUserProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final systemsAsync = ref.watch(systemsProvider);

    Color gaugeColor = Colors.green;
    String riskLevel = 'BAJO';
    String observation = 'Operación normal de infraestructura';
    
    if (riskScore >= 50) {
      gaugeColor = Colors.red;
      riskLevel = 'CRÍTICO';
      observation = 'Ataque activo detectado';
    } else if (riskScore >= 16) {
      gaugeColor = Colors.orange;
      riskLevel = 'ALTO';
      observation = 'Compromiso parcial detectado';
    } else if (riskScore >= 6) {
      gaugeColor = Colors.yellow[700]!;
      riskLevel = 'MEDIO';
      observation = 'Actividad sospechosa';
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Visión General del Sistema',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Text('Centro de Monitoreo de Inteligencia Local', style: TextStyle(color: Colors.grey)),
                  ],
                ),
                if (user?.role == 'admin')
                  Row(
                    children: [
                      FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
                        onPressed: () async {
                          await ref.read(dataRepoProvider).simulateAttack(user!.role);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Simulación de Ransomware iniciada...'), backgroundColor: Colors.red),
                            );
                          }
                        },
                        icon: const Icon(Icons.warning_amber),
                        label: const Text('Simular Ransomware'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: () async {
                          await ref.read(dataRepoProvider).resetSimulation(user!.role);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Simulación reiniciada. Estado limpio.'), backgroundColor: Colors.green),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh),
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
                    child: InkWell(
                      onTap: () => _showLegend(context),
                      child: Card(
                        elevation: 6,
                        color: gaugeColor.withOpacity(0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: gaugeColor, width: 2)),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('NIVEL DE IMPACTO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: gaugeColor)),
                              const SizedBox(height: 16),
                              Icon(
                                riskScore >= 50 ? Icons.dangerous : (riskScore >= 6 ? Icons.warning_amber : Icons.shield_outlined),
                                size: 80,
                                color: gaugeColor,
                              ),
                              const SizedBox(height: 16),
                              Text(riskLevel, style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: gaugeColor)),
                              Text('Impacto: $riskScore pts', style: const TextStyle(fontSize: 16)),
                              const SizedBox(height: 8),
                              Text(observation, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic)),
                              const SizedBox(height: 16),
                              const Text('Ver Leyenda (Clic)', style: TextStyle(fontSize: 10, decoration: TextDecoration.underline)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    flex: 2,
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Métricas de Resiliencia', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const Divider(),
                            Expanded(
                              child: devicesAsync.when(
                                data: (devices) {
                                  final itComp = devices.where((d) => d.zone == 'IT' && d.status == 'compromised').length;
                                  final otComp = devices.where((d) => d.zone == 'OT' && d.status == 'compromised').length;
                                  final isolated = devices.where((d) => d.isIsolated).length;
                                  
                                  return GridView.count(
                                    crossAxisCount: 2,
                                    childAspectRatio: 2.2,
                                    children: [
                                      _buildMetricTile(
                                        'Zona IT', 
                                        itComp > 0 ? 'AMENAZADA' : 'SEGURA', 
                                        Icons.computer, 
                                        itComp > 0 ? Colors.red : Colors.blue
                                      ),
                                      _buildMetricTile(
                                        'Zona OT', 
                                        otComp > 0 ? 'CRÍTICO' : 'SEGURA', 
                                        Icons.precision_manufacturing, 
                                        otComp > 0 ? Colors.red : Colors.purple
                                      ),
                                      _buildMetricTile(
                                        'Contención', 
                                        isolated > 0 ? '$isolated Aislados' : 'Sin aislamiento', 
                                        Icons.shield_outlined, 
                                        isolated > 0 ? Colors.blue : Colors.teal
                                      ),
                                      _buildMetricTile(
                                        'Defensa', 
                                        'Activa (NIST)', 
                                        Icons.layers, 
                                        Colors.indigo
                                      ),
                                    ],
                                  );
                                },
                                loading: () => const Center(child: CircularProgressIndicator()),
                                error: (_, __) => const Center(child: Text('Error de datos')),
                              ),
                            ),
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

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Interpretación de Impacto (NIST/ISA)'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _legendItem(Colors.green, '0-5 (Bajo)', 'Operación segura. Monitoreo constante activo.'),
            _legendItem(Colors.yellow[700]!, '6-15 (Medio)', 'Intento de intrusión o actividad anómala detectada.'),
            _legendItem(Colors.orange, '16-49 (Alto)', 'Compromiso de dispositivos. Se requiere respuesta SOC.'),
            _legendItem(Colors.red, '50+ (Crítico)', 'Impacto masivo. La infraestructura crítica está en riesgo.'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
      ),
    );
  }

  Widget _legendItem(Color color, String level, String desc) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 10),
      title: Text(level, style: const TextStyle(fontWeight: FontWeight.bold)),
      subtitle: Text(desc),
    );
  }

  Widget _buildMetricTile(String title, String status, IconData icon, Color color) {
    return ListTile(
      leading: Icon(icon, color: color, size: 36),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }
}
