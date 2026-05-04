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
                        child: InkWell(
                          onTap: () => _showSystemDetailsDialog(context, sys),
                          borderRadius: BorderRadius.circular(16),
                          child: Card(
                            color: statusColor.withOpacity(0.05),
                            elevation: 0,
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
                                  if (sys.status == 'operational') ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const SizedBox(width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green)),
                                          const SizedBox(width: 8),
                                          const Text('Telemetría nominal', style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold)),
                                          const SizedBox(width: 8),
                                          _AnimatedFlowIndicator(isWater: sys.name.contains('Water') || sys.name.contains('Agua')),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(sys.name.contains('Water') || sys.name.contains('Agua') ? 'Flujo de agua constante: 450 L/s' : 'Frecuencia de red: 60.01 Hz', style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic)),
                                  ],
                                  if (sys.status != 'operational')
                                     _buildCausalityNote(sys),
                                  const Spacer(),
                                  if (sys.status != 'operational' && user?.role != 'viewer')
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, minimumSize: const Size(0, 44)),
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (context) => SimulatedProgressDialog(
                                                title: 'Recuperando ${sys.name}',
                                                steps: const [
                                                  'Reiniciando PLC a configuración segura (Modo ROM)...',
                                                  'Verificando integridad de memoria (Anti-Malware)...',
                                                  'Restableciendo comunicación con servidor SCADA...',
                                                  'Activando proceso físico...'
                                                ],
                                                onComplete: () {
                                                  ref.read(dataRepoProvider).recoverSystem(user!.role, sys.id);
                                                },
                                              )
                                            );
                                          },
                                          icon: const Icon(Icons.build_circle, size: 16),
                                          label: const Text('RECUPERAR', style: TextStyle(fontSize: 11)),
                                        ),
                                      )
                                ],
                              ),
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

  void _showSystemDetailsDialog(BuildContext context, dynamic sys) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.domain, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 8),
            Expanded(child: Text('Diagnóstico Físico: ${sys.name}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: sys.status == 'operational' ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                border: Border.all(color: sys.status == 'operational' ? Colors.green : Colors.red),
                borderRadius: BorderRadius.circular(8)
              ),
              child: Row(
                children: [
                  Icon(sys.status == 'operational' ? Icons.check_circle : Icons.warning, color: sys.status == 'operational' ? Colors.green : Colors.red),
                  const SizedBox(width: 8),
                  Text('Estado Actual: ${sys.status.toUpperCase()}', style: TextStyle(fontWeight: FontWeight.bold, color: sys.status == 'operational' ? Colors.green : Colors.red)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Dependencias Lógicas (Hardware):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            ...(sys.dependencies as List).map((dep) => Row(children: [const Icon(Icons.router, size: 16, color: Colors.grey), const SizedBox(width: 4), Text('$dep (Nivel 1/2)')])).toList(),
            if ((sys.dependencies as List).isEmpty) const Text('Ninguna externa (Sistema Raíz)'),
            const SizedBox(height: 16),
            const Row(
              children: [
                Icon(Icons.waves, color: Colors.orange, size: 20),
                SizedBox(width: 8),
                Text('Análisis de Impacto en Cascada:', style: TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            const Text('La interrupción de esta infraestructura detiene inmediatamente operaciones críticas. En el mundo real esto puede significar cortes de suministro a nivel ciudad o paros en líneas de ensamble de millones de dólares, demostrando por qué la seguridad OT es vital para la seguridad física.', style: TextStyle(fontSize: 13, height: 1.4)),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
        ],
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

class _AnimatedFlowIndicator extends StatefulWidget {
  final bool isWater;
  const _AnimatedFlowIndicator({required this.isWater});

  @override
  State<_AnimatedFlowIndicator> createState() => _AnimatedFlowIndicatorState();
}

class _AnimatedFlowIndicatorState extends State<_AnimatedFlowIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            double opacity = 1.0 - ((_controller.value - (index * 0.3)).abs() % 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.0),
              child: Icon(
                widget.isWater ? Icons.water_drop : Icons.bolt,
                size: 12,
                color: (widget.isWater ? Colors.blue : Colors.yellow).withOpacity(opacity.clamp(0.1, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
