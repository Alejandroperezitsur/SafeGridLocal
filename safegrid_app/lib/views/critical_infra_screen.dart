import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/providers.dart';
import '../core/theme.dart';
import 'widgets/educational_widgets.dart';
import 'widgets/screen_onboarding.dart';
import 'widgets/onboarding_data.dart';

class CriticalInfraScreen extends ConsumerWidget {
  const CriticalInfraScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final systemsAsync = ref.watch(systemsProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: ScreenOnboarding(
        screenKey: 'infra',
        slides: kInfraSlides,
        child: Stack(
          children: [
            const ScanLinesOverlay(opacity: 0.01),
            systemsAsync.when(
              data: (systems) {
                final downCount = systems.where((s) => s.status != 'operational').length;
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      FadeInDown(
                        duration: const Duration(milliseconds: 500),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SG.neonPurple.withOpacity(0.1),
                                border: Border.all(color: SG.neonPurple.withOpacity(0.3)),
                              ),
                              child: const Icon(Icons.factory_rounded, color: SG.neonPurple, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('CONTROL DE PLANTA', style: SG.heading(22, color: SG.neonPurple)),
                                Text('Monitoreo del impacto físico de incidentes digitales',
                                    style: SG.mono(10, color: Colors.white38)),
                              ],
                            ),
                            const Spacer(),
                            if (downCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: SG.danger.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: SG.danger.withOpacity(0.3)),
                                ),
                                child: Row(
                                  children: [
                                    PulsingDot(color: SG.danger, size: 8),
                                    const SizedBox(width: 6),
                                    Text('$downCount SISTEMA(S) CAÍDO(S)', style: SG.heading(10, color: SG.danger)),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: systems.length,
                          itemBuilder: (context, index) {
                            final sys = systems[index];
                            return FadeInUp(
                              delay: Duration(milliseconds: 100 * index),
                              duration: const Duration(milliseconds: 500),
                              child: _buildSystemCard(context, ref, user, sys),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      FadeInUp(
                        delay: const Duration(milliseconds: 400),
                        child: _buildAcademicFooter(),
                      ),
                    ],
                  ),
                );
              },
              loading: () => Center(child: CircularProgressIndicator(color: SG.cyan)),
              error: (err, stack) => Center(child: Text('Error: $err', style: SG.body(14, color: SG.danger))),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSystemCard(BuildContext context, WidgetRef ref, dynamic user, dynamic sys) {
    Color statusColor = SG.safe;
    IconData statusIcon = Icons.check_circle_rounded;
    String statusText = 'OPERACIONAL';

    if (sys.status == 'down') {
      statusColor = SG.danger;
      statusIcon = Icons.error_rounded;
      statusText = 'FUERA DE SERVICIO';
    } else if (sys.status == 'degraded') {
      statusColor = SG.warning;
      statusIcon = Icons.warning_amber_rounded;
      statusText = 'DEGRADADO';
    }

    // Pick a themed icon for the system
    IconData systemIcon = Icons.bolt_rounded;
    if (sys.name.contains('Water') || sys.name.contains('Agua')) {
      systemIcon = Icons.water_drop_rounded;
    } else if (sys.name.contains('HVAC') || sys.name.contains('Refrigeración')) {
      systemIcon = Icons.ac_unit_rounded;
    }

    return ExplainWrapper(
      title: sys.name,
      techDesc: '${sys.name} es un activo crítico que depende de la red OT. Estado: ${sys.status}.',
      analogyDesc: _getSystemAnalogy(sys.name),
      child: InkWell(
        onTap: () => _showSystemDetailsDialog(context, sys),
        borderRadius: BorderRadius.circular(16),
        child: NeonGlowBox(
          color: statusColor,
          intensity: sys.status == 'down' ? 0.25 : 0.1,
          animate: sys.status != 'operational',
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Main icon with animation
                sys.status == 'operational'
                    ? _AnimatedSystemIcon(icon: systemIcon, color: statusColor)
                    : _SystemDownIcon(icon: statusIcon, color: statusColor),
                const SizedBox(height: 12),
                Text(sys.name, style: SG.heading(15, color: Colors.white), textAlign: TextAlign.center),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(statusText, style: SG.heading(10, color: statusColor)),
                ),
                const Spacer(),
                if (sys.status == 'operational') ...[
                  _buildTelemetryIndicator(sys),
                  const SizedBox(height: 6),
                  Text(
                    sys.name.contains('Water') || sys.name.contains('Agua')
                        ? 'Flujo: 450 L/s'
                        : 'Red: 60.01 Hz',
                    style: SG.mono(9, color: Colors.white.withOpacity(0.3)),
                  ),
                ],
                if (sys.status != 'operational')
                  _buildCausalityNote(sys),
                const Spacer(),
                if (sys.status != 'operational' && user?.role != 'viewer')
                  SizedBox(
                    width: double.infinity,
                    child: Container(
                      decoration: SG.neonBorder(SG.cyan, radius: 10, width: 1),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SG.cyan.withOpacity(0.1),
                          foregroundColor: SG.cyan,
                          minimumSize: const Size(0, 40),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
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
                            ),
                          );
                        },
                        icon: Icon(Icons.build_circle_rounded, size: 16, color: SG.cyan),
                        label: Text('RECUPERAR', style: SG.heading(10, color: SG.cyan)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTelemetryIndicator(dynamic sys) {
    final isWater = sys.name.contains('Water') || sys.name.contains('Agua');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: SG.safe.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SG.safe.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 12, height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: SG.safe),
          ),
          const SizedBox(width: 8),
          Text('Telemetría OK', style: SG.mono(9, color: SG.safe)),
          const SizedBox(width: 8),
          _AnimatedFlowIndicator(isWater: isWater),
        ],
      ),
    );
  }

  Widget _buildCausalityNote(dynamic sys) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      margin: const EdgeInsets.only(top: 6),
      decoration: BoxDecoration(
        color: SG.danger.withOpacity(0.06),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: SG.danger.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.link_rounded, size: 10, color: SG.danger.withOpacity(0.6)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Causa: PLCs en zona OT comprometidos',
              style: SG.mono(8, color: SG.danger.withOpacity(0.7)),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showSystemDetailsDialog(BuildContext context, dynamic sys) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.domain_rounded, color: SG.neonPurple, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text('Diagnóstico: ${sys.name}', style: SG.heading(16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (sys.status == 'operational' ? SG.safe : SG.danger).withOpacity(0.1),
                border: Border.all(color: (sys.status == 'operational' ? SG.safe : SG.danger).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(children: [
                Icon(
                  sys.status == 'operational' ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: sys.status == 'operational' ? SG.safe : SG.danger,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text('Estado: ${sys.status.toUpperCase()}',
                    style: SG.heading(13, color: sys.status == 'operational' ? SG.safe : SG.danger)),
              ]),
            ),
            const SizedBox(height: 16),
            Text('Dependencias Hardware:', style: SG.heading(13)),
            const SizedBox(height: 6),
            ...(sys.dependencies as List).map((dep) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(children: [
                    Icon(Icons.router_rounded, size: 14, color: SG.cyan.withOpacity(0.5)),
                    const SizedBox(width: 6),
                    Text('$dep (Nivel 1/2)', style: SG.mono(12)),
                  ]),
                )),
            if ((sys.dependencies as List).isEmpty)
              Text('Ninguna externa (Sistema Raíz)', style: SG.body(12, color: Colors.white38)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SG.warning.withOpacity(0.06),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SG.warning.withOpacity(0.15)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.waves_rounded, color: SG.warning, size: 16),
                    const SizedBox(width: 8),
                    Text('Análisis de Impacto en Cascada:', style: SG.heading(12, color: SG.warning)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    'La interrupción de esta infraestructura detiene inmediatamente operaciones críticas. En el mundo real esto puede significar cortes de suministro a nivel ciudad o paros en líneas de ensamble de millones de dólares.',
                    style: SG.body(12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar', style: SG.heading(13, color: SG.cyan))),
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

  Widget _buildAcademicFooter() {
    return ExplainWrapper(
      title: 'Fallas en Cascada',
      techDesc: 'Concepto donde el fallo de un componente (PLC) provoca la interrupción de servicios superiores (SCADA/ERP).',
      analogyDesc: 'Es como el efecto dominó: si empujas la primera pieza (PLC), todas las demás caen.',
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: SG.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: SG.border),
        ),
        child: Row(
          children: [
            Icon(Icons.school_rounded, size: 18, color: SG.cyan.withOpacity(0.6)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nota Académica: Las fallas en cascada demuestran la interconexión entre IT y OT. Toca para ver más.',
                style: SG.body(11, color: Colors.white38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated system icon with gentle pulse (for operational systems)
class _AnimatedSystemIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _AnimatedSystemIcon({required this.icon, required this.color});

  @override
  State<_AnimatedSystemIcon> createState() => _AnimatedSystemIconState();
}

class _AnimatedSystemIconState extends State<_AnimatedSystemIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.05 + _ctrl.value * 0.05),
            border: Border.all(color: widget.color.withOpacity(0.2 + _ctrl.value * 0.2)),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.05 + _ctrl.value * 0.1),
                blurRadius: 16,
                spreadRadius: _ctrl.value * 4,
              ),
            ],
          ),
          child: Icon(widget.icon, size: 36, color: widget.color),
        );
      },
    );
  }
}

/// Flashing system down icon
class _SystemDownIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _SystemDownIcon({required this.icon, required this.color});

  @override
  State<_SystemDownIcon> createState() => _SystemDownIconState();
}

class _SystemDownIconState extends State<_SystemDownIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.08 + _ctrl.value * 0.12),
            border: Border.all(
              color: widget.color.withOpacity(0.3 + _ctrl.value * 0.4),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(_ctrl.value * 0.3),
                blurRadius: 20,
                spreadRadius: _ctrl.value * 6,
              ),
            ],
          ),
          child: Icon(widget.icon, size: 36, color: widget.color),
        );
      },
    );
  }
}

/// Animated flow indicator (water drops or lightning bolts)
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
                widget.isWater ? Icons.water_drop_rounded : Icons.bolt_rounded,
                size: 10,
                color: (widget.isWater ? SG.info : SG.amber).withOpacity(opacity.clamp(0.1, 1.0)),
              ),
            );
          }),
        );
      },
    );
  }
}
