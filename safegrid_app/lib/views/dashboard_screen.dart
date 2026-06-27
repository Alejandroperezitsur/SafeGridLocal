import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/providers.dart';
import '../core/theme.dart';
import 'widgets/educational_widgets.dart';
import 'widgets/screen_onboarding.dart';
import 'widgets/onboarding_data.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final riskScore = ref.watch(riskScoreProvider);
    final user = ref.watch(currentUserProvider);
    final devicesAsync = ref.watch(devicesProvider);
    final incidentsAsync = ref.watch(incidentsProvider);

    final activeIncidents = incidentsAsync.value?.where((i) => i.status == 'active').toList() ?? [];

    Color gaugeColor = SG.safe;
    String riskLevel = 'BAJO';
    String observation = 'Operación normal de infraestructura';

    if (riskScore >= 50) {
      gaugeColor = SG.danger;
      riskLevel = 'CRÍTICO';
      observation = 'Ataque activo detectado';
    } else if (riskScore >= 16) {
      gaugeColor = SG.warning;
      riskLevel = 'ALTO';
      observation = 'Compromiso parcial detectado';
    } else if (riskScore >= 6) {
      gaugeColor = SG.amber;
      riskLevel = 'MEDIO';
      observation = 'Actividad sospechosa';
    }

    return Scaffold(
      body: ScreenOnboarding(
        screenKey: 'dashboard',
        slides: kDashboardSlides,
        child: Stack(
          children: [
            const ScanLinesOverlay(opacity: 0.01),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ─── Hero Header ─────────────────────────────
                    FadeInDown(
                      duration: const Duration(milliseconds: 600),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: SG.cyan.withOpacity(0.1),
                                  border: Border.all(color: SG.cyan.withOpacity(0.3)),
                                ),
                                child: const Icon(Icons.shield_rounded, color: SG.cyan, size: 28),
                              ),
                              const SizedBox(width: 14),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('SAFEGRID LOCAL', style: SG.heading(24, color: SG.cyan)),
                                  Text('Simulador de ciberseguridad para infraestructuras críticas',
                                      style: SG.body(13, color: Colors.white38)),
                                  const SizedBox(height: 2),
                                  Text('Firmado por: Alejandro Pérez Vázquez',
                                      style: SG.mono(11, color: SG.cyan.withOpacity(0.8))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: SG.info.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: SG.info.withOpacity(0.15)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.lightbulb_rounded, size: 16, color: SG.info.withOpacity(0.6)),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Este sistema simula cómo un ciberataque puede afectar servicios como energía o agua, y cómo puedes detenerlo.',
                                    style: SG.body(12, color: SG.info.withOpacity(0.8)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ─── Situation Status Panel ──────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 100),
                      child: _buildSituationPanel(context, ref, user, activeIncidents, gaugeColor),
                    ),
                    const SizedBox(height: 24),

                    // ─── Score + Metrics Row ─────────────────────
                    FadeInUp(
                      duration: const Duration(milliseconds: 600),
                      delay: const Duration(milliseconds: 200),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth > 800;
                          return isWide
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    SizedBox(
                                      width: 320,
                                      child: _buildScoreGauge(context, riskScore, gaugeColor, riskLevel, observation),
                                    ),
                                    const SizedBox(width: 24),
                                    Expanded(flex: 2, child: _buildMetricsCard(context, devicesAsync)),
                                  ],
                                )
                              : Column(
                                  children: [
                                    _buildScoreGauge(context, riskScore, gaugeColor, riskLevel, observation, isCompact: true),
                                    const SizedBox(height: 24),
                                    _buildMetricsCard(context, devicesAsync),
                                  ],
                                );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSituationPanel(BuildContext context, WidgetRef ref, dynamic user, List<dynamic> activeIncidents, Color gaugeColor) {
    final isUnderAttack = activeIncidents.isNotEmpty;

    return NeonGlowBox(
      color: isUnderAttack ? SG.danger : SG.safe,
      intensity: isUnderAttack ? 0.25 : 0.1,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  PulsingDot(color: isUnderAttack ? SG.danger : SG.safe, size: 12),
                  const SizedBox(width: 12),
                  Text(
                    '¿QUÉ ESTÁ PASANDO AHORA?',
                    style: SG.heading(16, color: isUnderAttack ? SG.danger : SG.safe),
                  ),
                ]),
                if (user?.role == 'admin')
                  _buildResetButton(context, ref, user),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              isUnderAttack
                  ? 'Se está propagando un ransomware en la red OT. Se recomienda actuar.'
                  : 'No hay amenazas activas. El sistema está funcionando normalmente.',
              style: SG.body(16, color: Colors.white.withOpacity(0.85)),
            ),
            if (isUnderAttack) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: SG.amber.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: SG.amber.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.arrow_forward_rounded, color: SG.amber, size: 18),
                    const SizedBox(width: 10),
                    Text('ACCIÓN RECOMENDADA', style: SG.heading(13, color: SG.amber)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.account_tree_rounded,
                    label: 'Ir al mapa de red',
                    color: SG.neonBlue,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Selecciona "Red / Purdue" en el menú.', style: SG.body(13))),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.security_rounded,
                    label: 'Aislar dispositivo',
                    color: SG.danger,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Ve al Mapa de Red y presiona "AISLAR" en los comprometidos.', style: SG.body(13))),
                      );
                    },
                  ),
                ],
              ),
            ],
            if (!isUnderAttack && user?.role == 'admin') ...[
              const SizedBox(height: 20),
              _buildAttackButton(context, ref, user),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResetButton(BuildContext context, WidgetRef ref, dynamic user) {
    return Container(
      decoration: SG.neonBorder(SG.safe, radius: 8, width: 1),
      child: IconButton(
        tooltip: 'Reiniciar todo el sistema',
        onPressed: () async {
          await ref.read(dataRepoProvider).resetSimulation(user!.role);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Sistema restaurado a la normalidad.', style: SG.body(13)), backgroundColor: SG.safe.withOpacity(0.2)),
            );
          }
        },
        icon: Icon(Icons.refresh_rounded, color: SG.safe, size: 20),
      ),
    );
  }

  Widget _buildAttackButton(BuildContext context, WidgetRef ref, dynamic user) {
    return Center(
      child: _NuclearButton(
        onPressed: () async {
          await ref.read(dataRepoProvider).simulateAttack(user!.role);
        },
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, {required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return Container(
      decoration: SG.neonBorder(color, radius: 10, width: 1),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label, style: SG.heading(12, color: color)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  Widget _buildScoreGauge(BuildContext context, int riskScore, Color gaugeColor, String riskLevel, String observation, {bool isCompact = false}) {
    return ExplainWrapper(
      title: 'Puntaje de Riesgo (Risk Score)',
      techDesc: 'Cálculo algorítmico basado en la severidad de incidentes activos (Critical=50pts) y eventos correlacionados.',
      analogyDesc: 'Es como el semáforo de salud de la fábrica: Verde es sano, Rojo significa que hay una emergencia médica digital.',
      child: InkWell(
        onTap: () => _showLegend(context),
        borderRadius: BorderRadius.circular(16),
        child: NeonGlowBox(
          color: gaugeColor,
          intensity: riskScore >= 50 ? 0.3 : 0.15,
          child: SizedBox(
            width: isCompact ? double.infinity : 320,
            height: isCompact ? 300 : 380,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('NIVEL DE IMPACTO', style: SG.heading(12, color: gaugeColor)),
                  const SizedBox(height: 16),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: riskScore.toDouble()),
                    duration: const Duration(seconds: 2),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, child) {
                      return SizedBox(
                        width: 160,
                        height: 160,
                        child: CustomPaint(
                          painter: _RiskGaugePainter(
                            progress: (value / 100).clamp(0, 1),
                            color: gaugeColor,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  value >= 50
                                      ? Icons.dangerous_rounded
                                      : (value >= 6 ? Icons.warning_amber_rounded : Icons.shield_rounded),
                                  size: 36,
                                  color: gaugeColor,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${value.toInt()}',
                                  style: SG.heading(40, color: gaugeColor),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(riskLevel, style: SG.heading(20, color: gaugeColor)),
                  const SizedBox(height: 4),
                  Text(observation, textAlign: TextAlign.center, style: SG.body(11, color: Colors.white38)),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 12, color: SG.cyan.withOpacity(0.4)),
                      const SizedBox(width: 4),
                      Text('Ver escala de riesgo', style: SG.mono(9, color: SG.cyan.withOpacity(0.4))),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricsCard(BuildContext context, AsyncValue<List<dynamic>> devicesAsync) {
    return NeonGlowBox(
      color: SG.neonBlue,
      intensity: 0.08,
      animate: false,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics_rounded, size: 18, color: SG.neonBlue),
                const SizedBox(width: 8),
                Text('RESILIENCIA POR ZONA', style: SG.heading(15, color: SG.neonBlue)),
              ],
            ),
            const SizedBox(height: 4),
            Divider(color: SG.border),
            const SizedBox(height: 8),
            devicesAsync.when(
              data: (devices) {
                final itComp = devices.where((d) => d.zone == 'IT' && d.status == 'compromised').length;
                final otComp = devices.where((d) => d.zone == 'OT' && d.status == 'compromised').length;

                return Column(
                  children: [
                    _buildZoneTile(context, 'Zona IT (Enterprise)', itComp > 0 ? 'AMENAZADA' : 'SEGURA',
                        Icons.computer_rounded, itComp > 0 ? SG.danger : SG.neonBlue,
                        'Nivel 4/5 del Modelo Purdue. Contiene sistemas corporativos y administración.',
                        'Es el cerebro administrativo: donde se gestionan correos y facturas.'),
                    const SizedBox(height: 8),
                    _buildZoneTile(context, 'Zona OT (Control)', otComp > 0 ? 'BAJO ATAQUE' : 'MONITOREADA',
                        Icons.precision_manufacturing_rounded, otComp > 0 ? SG.danger : SG.neonPurple,
                        'Nivel 1-3 del Modelo Purdue. Contiene PLCs y sistemas de control industrial.',
                        'Es el corazón físico: las máquinas que realmente mueven el agua o la luz.'),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => Text('Error al cargar métricas', style: SG.body(13, color: SG.danger)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZoneTile(BuildContext context, String title, String status, IconData icon, Color color, String tech, String analogy) {
    return ExplainWrapper(
      title: title,
      techDesc: tech,
      analogyDesc: analogy,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Row(children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: SG.heading(16)),
              ]),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Estado actual: $status', style: SG.heading(14, color: color)),
                  const SizedBox(height: 12),
                  Text('Rol Técnico:\n$tech', style: SG.body(13)),
                  const SizedBox(height: 12),
                  Text('Analogía:\n$analogy', style: SG.body(13, color: SG.info)),
                ],
              ),
              actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text('Entendido', style: SG.heading(13, color: SG.cyan)))],
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.1),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: SG.heading(13, color: Colors.white)),
                    Text(status, style: SG.heading(11, color: color)),
                  ],
                ),
              ),
              Icon(Icons.touch_app_rounded, size: 14, color: SG.cyan.withOpacity(0.3)),
            ],
          ),
        ),
      ),
    );
  }

  void _showLegend(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.assessment_rounded, color: SG.cyan),
          const SizedBox(width: 8),
          Text('Interpretación de Impacto', style: SG.heading(18)),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('El Puntaje de Riesgo (Risk Score) se calcula en base a la severidad de los incidentes detectados, similar a la norma ISA/IEC 62443 para redes industriales.',
                style: SG.body(13)),
            const SizedBox(height: 16),
            _legendItem(SG.safe, '0-5 (Bajo)', 'Operación segura. Monitoreo constante activo.'),
            _legendItem(SG.amber, '6-15 (Medio)', 'Intento de intrusión o actividad anómala detectada.'),
            _legendItem(SG.warning, '16-49 (Alto)', 'Compromiso de dispositivos. Se requiere respuesta SOC (aislamiento).'),
            _legendItem(SG.danger, '50+ (Crítico)', 'Impacto masivo. La infraestructura crítica física está en riesgo de paro o daño.'),
          ],
        ),
        actions: [FilledButton(onPressed: () => Navigator.pop(context), child: Text('Entendido', style: SG.heading(13, color: SG.cyan)))],
      ),
    );
  }

  Widget _legendItem(Color color, String level, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 12, height: 12,
            margin: const EdgeInsets.only(top: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(level, style: SG.heading(12, color: color)),
                Text(desc, style: SG.body(11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular risk gauge painter
class _RiskGaugePainter extends CustomPainter {
  final double progress;
  final Color color;

  _RiskGaugePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    const startAngle = pi * 0.75;
    const sweepAngle = pi * 1.5;

    // Background arc
    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle, false, bgPaint);

    // Progress arc
    final fgPaint = Paint()
      ..color = color
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.outer, 4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, fgPaint);

    // Solid arc on top
    final solidPaint = Paint()
      ..color = color
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius), startAngle, sweepAngle * progress, false, solidPaint);

    // Tick marks
    final tickPaint = Paint()
      ..color = Colors.white.withOpacity(0.15)
      ..strokeWidth = 1;
    for (int i = 0; i <= 10; i++) {
      final angle = startAngle + (sweepAngle * i / 10);
      final inner = radius - 14;
      final outer = radius - 8;
      canvas.drawLine(
        Offset(center.dx + inner * cos(angle), center.dy + inner * sin(angle)),
        Offset(center.dx + outer * cos(angle), center.dy + outer * sin(angle)),
        tickPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_RiskGaugePainter old) => old.progress != progress || old.color != color;
}

/// The dramatic "nuclear" attack simulation button
class _NuclearButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _NuclearButton({required this.onPressed});

  @override
  State<_NuclearButton> createState() => _NuclearButtonState();
}

class _NuclearButtonState extends State<_NuclearButton> with SingleTickerProviderStateMixin {
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
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: SG.danger.withOpacity(0.1 + _ctrl.value * 0.15),
                blurRadius: 20 + _ctrl.value * 20,
                spreadRadius: _ctrl.value * 4,
              ),
            ],
          ),
          child: Container(
            decoration: SG.neonBorder(SG.danger, radius: 16, width: 2),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: SG.danger.withOpacity(0.12),
                foregroundColor: SG.danger,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: widget.onPressed,
              icon: const Icon(Icons.play_arrow_rounded, size: 28),
              label: Text('INICIAR SIMULACIÓN', style: SG.heading(16, color: SG.danger)),
            ),
          ),
        );
      },
    );
  }
}
