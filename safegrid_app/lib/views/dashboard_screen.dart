import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/providers.dart';
import 'widgets/educational_widgets.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskScore = ref.watch(riskScoreProvider);
    final user = ref.watch(currentUserProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final incidentsAsync = ref.watch(incidentsProvider);
    
    final activeIncidents = incidentsAsync.value?.where((i) => i.status == 'active').toList() ?? [];

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
        child: SingleChildScrollView(
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
                        'Visión General',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Text('Centro de Monitoreo de Inteligencia Local', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                  if (user?.role == 'admin')
                    Row(
                      children: [
                        FilledButton.icon(
                          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(100, 48)),
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
                          style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
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
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 800;
                  return isWide 
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildScoreCard(context, riskScore, gaugeColor, riskLevel, observation),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _buildMetricsCard(context, devicesAsync)),
                        ],
                      )
                    : Column(
                        children: [
                          _buildScoreCard(context, riskScore, gaugeColor, riskLevel, observation, height: 350),
                          const SizedBox(height: 24),
                          _buildMetricsCard(context, devicesAsync),
                        ],
                      );
                }
              ),
              if (activeIncidents.isNotEmpty) ...[
                const SizedBox(height: 24),
                _buildRecommendations(context, ref, user, activeIncidents),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(BuildContext context, int riskScore, Color gaugeColor, String riskLevel, String observation, {double? height}) {
    return Container(
      width: height != null ? double.infinity : 300,
      height: height ?? 380,
      child: ExplainWrapper(
        title: 'Puntaje de Riesgo (Risk Score)',
        techDesc: 'Cálculo algorítmico basado en la severidad de incidentes activos (Critical=50pts) y eventos correlacionados.',
        analogyDesc: 'Es como el semáforo de salud de la fábrica: Verde es sano, Rojo significa que hay una emergencia médica digital.',
        child: InkWell(
          onTap: () => _showLegend(context),
          child: Card(
            elevation: 6,
            color: gaugeColor.withOpacity(0.1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20), side: BorderSide(color: gaugeColor, width: 2)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('NIVEL DE IMPACTO', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: gaugeColor)),
                  const SizedBox(height: 16),
                  Icon(riskScore >= 50 ? Icons.dangerous : (riskScore >= 6 ? Icons.warning_amber : Icons.shield_outlined), size: 80, color: gaugeColor),
                  const SizedBox(height: 16),
                  Text(riskLevel, style: TextStyle(fontSize: 42, fontWeight: FontWeight.bold, color: gaugeColor)),
                  Text('Impacto: $riskScore pts', style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(observation, textAlign: TextAlign.center, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  const Spacer(),
                  const Text('Ver Detalles (Clic)', style: TextStyle(fontSize: 10, decoration: TextDecoration.underline)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsCard(BuildContext context, AsyncValue<List<dynamic>> devicesAsync) {
     return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Resiliencia por Zona', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Divider(),
            devicesAsync.when(
              data: (devices) {
                final itComp = devices.where((d) => d.zone == 'IT' && d.status == 'compromised').length;
                final otComp = devices.where((d) => d.zone == 'OT' && d.status == 'compromised').length;
                
                return Column(
                  children: [
                    _buildExplainableTile(
                      'Zona IT (Enterprise)', 
                      itComp > 0 ? 'AMENAZADA' : 'SEGURA', 
                      Icons.computer, 
                      itComp > 0 ? Colors.red : Colors.blue,
                      'Nivel 4/5 del Modelo Purdue. Contiene sistemas corporativos y administración.',
                      'Es el cerebro administrativo: donde se gestionan correos y facturas.'
                    ),
                    _buildExplainableTile(
                      'Zona OT (Control)', 
                      otComp > 0 ? 'BAJO ATAQUE' : 'MONITOREADA', 
                      Icons.precision_manufacturing, 
                      otComp > 0 ? Colors.red : Colors.purple,
                      'Nivel 1-3 del Modelo Purdue. Contiene PLCs y sistemas de control industrial.',
                      'Es el corazón físico: las máquinas que realmente mueven el agua o la luz.'
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error al cargar métricas'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExplainableTile(String title, String status, IconData icon, Color color, String tech, String analogy) {
    return ExplainWrapper(
      title: title,
      techDesc: tech,
      analogyDesc: analogy,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 4),
        leading: Icon(icon, color: color, size: 40),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        trailing: const Icon(Icons.help_outline, size: 16, color: Colors.grey),
      ),
    );
  }

  Widget _buildRecommendations(BuildContext context, WidgetRef ref, dynamic user, List<dynamic> incidents) {
    return Card(
      color: Colors.blueAccent.withOpacity(0.1),
      shape: RoundedRectangleBorder(side: const BorderSide(color: Colors.blueAccent, width: 1.5), borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.blueAccent),
                SizedBox(width: 8),
                Text('Sugerencias del Sistema (DSS)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Se detectó comportamiento de Ransomware. Acciones prioritarias:', style: TextStyle(fontSize: 13)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.go('/dashboard'), 
                  icon: const Icon(Icons.security),
                  label: const Text('AISLAR RED OT'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, minimumSize: const Size(140, 48)),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.go('/dashboard'),
                  icon: const Icon(Icons.visibility),
                  label: const Text('ANALIZAR TIMELINE'),
                  style: ElevatedButton.styleFrom(minimumSize: const Size(140, 48)),
                ),
              ],
            ),
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
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar'))],
      ),
    );
  }

  Widget _legendItem(Color color, String level, String desc) {
    return ListTile(
      leading: CircleAvatar(backgroundColor: color, radius: 10),
      title: Text(level, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
      subtitle: Text(desc, style: const TextStyle(fontSize: 11)),
    );
  }
}
