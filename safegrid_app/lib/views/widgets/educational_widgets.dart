import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../viewmodels/providers.dart';
import '../../models/models.dart';
import '../../core/theme.dart';

class InsightPanel extends ConsumerWidget {
  const InsightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);

    if (insights.isEmpty) return const SizedBox.shrink();

    final first = insights.first;
    final color = _getColor(first.type);
    final icon = _getIcon(first.type);

    return FadeInDown(
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(color: color.withOpacity(0.08), blurRadius: 16),
          ],
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
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(first.title, style: SG.heading(12, color: color)),
                  const SizedBox(height: 2),
                  Text(first.message, style: SG.body(12)),
                ],
              ),
            ),
            if (insights.length > 1)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text('+${insights.length - 1}', style: SG.mono(10, color: color)),
              ),
          ],
        ),
      ),
    );
  }

  Color _getColor(String type) {
    switch (type) {
      case 'critical': return SG.danger;
      case 'warning': return SG.warning;
      case 'tip': return SG.info;
      default: return SG.muted;
    }
  }

  IconData _getIcon(String type) {
    switch (type) {
      case 'critical': return Icons.gpp_bad_rounded;
      case 'warning': return Icons.report_problem_rounded;
      case 'tip': return Icons.lightbulb_rounded;
      default: return Icons.info_outline_rounded;
    }
  }
}

class ExplainWrapper extends ConsumerWidget {
  final Widget child;
  final String title;
  final String techDesc;
  final String analogyDesc;

  const ExplainWrapper({
    super.key,
    required this.child,
    required this.title,
    required this.techDesc,
    required this.analogyDesc,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final learningMode = ref.watch(learningModeProvider);

    return InkWell(
      onLongPress: () => _showExplainDialog(context, learningMode),
      child: child,
    );
  }

  void _showExplainDialog(BuildContext context, bool learningMode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SG.cyan.withOpacity(0.1),
                border: Border.all(color: SG.cyan.withOpacity(0.3)),
              ),
              child: Icon(Icons.school_rounded, color: SG.cyan, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: SG.heading(16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (learningMode) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: SG.amber.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: SG.amber.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.lightbulb_rounded, color: SG.amber, size: 18),
                      const SizedBox(width: 8),
                      Text('Para entenderlo fácil:', style: SG.heading(12, color: SG.amber)),
                    ]),
                    const SizedBox(height: 8),
                    Text(analogyDesc, style: SG.body(14, color: SG.amber.withOpacity(0.9))),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SG.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: SG.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.memory_rounded, size: 16, color: SG.cyan.withOpacity(0.6)),
                    const SizedBox(width: 8),
                    Text('Detalle Técnico:', style: SG.heading(12, color: Colors.white70)),
                  ]),
                  const SizedBox(height: 8),
                  Text(techDesc, style: SG.body(13)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          FilledButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.check_rounded, size: 18, color: SG.cyan),
            label: Text('Entendido', style: SG.heading(13, color: SG.cyan)),
          ),
        ],
      ),
    );
  }
}

class TutorialOverlay extends ConsumerWidget {
  const TutorialOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepIndex = ref.watch(demoStepProvider);
    final isActive = ref.watch(isDemoActiveProvider);

    if (!isActive) return const SizedBox.shrink();

    final steps = _getSteps();
    if (stepIndex >= steps.length) {
      return const SizedBox.shrink();
    }

    final currentStep = steps[stepIndex];
    final progress = (stepIndex + 1) / steps.length;

    return Material(
      color: Colors.black.withOpacity(0.8),
      child: Stack(
        children: [
          const ScanLinesOverlay(opacity: 0.02),
          InkWell(
            onTap: () {},
            child: Center(
              child: FadeIn(
                child: Container(
                  margin: const EdgeInsets.all(32),
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: SG.card.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: SG.cyan.withOpacity(0.4), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: SG.cyan.withOpacity(0.15), blurRadius: 30),
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 20),
                    ],
                  ),
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: SG.cyan.withOpacity(0.1),
                              border: Border.all(color: SG.cyan.withOpacity(0.3)),
                            ),
                            child: Icon(Icons.play_lesson_rounded, color: SG.cyan, size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('MISIÓN EN PROGRESO', style: SG.heading(12, color: SG.cyan)),
                              Text('PASO ${stepIndex + 1} DE ${steps.length}', style: SG.mono(9, color: SG.cyan.withOpacity(0.5))),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Progress bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: Stack(
                          children: [
                            Container(height: 3, color: Colors.white.withOpacity(0.05)),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              height: 3,
                              width: MediaQuery.of(context).size.width * progress * 0.5,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(colors: [SG.cyan.withOpacity(0.3), SG.cyan]),
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [BoxShadow(color: SG.cyan.withOpacity(0.5), blurRadius: 6)],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Title
                      Text(
                        currentStep.title ?? 'Siguiente Paso',
                        style: SG.heading(20, color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      // Instruction in terminal style
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: SG.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: SG.border),
                        ),
                        child: Text(
                          currentStep.instruction,
                          textAlign: TextAlign.center,
                          style: SG.body(14),
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Nav buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () => ref.read(isDemoActiveProvider.notifier).state = false,
                            child: Text('SALIR', style: SG.heading(12, color: Colors.white38)),
                          ),
                          Container(
                            decoration: SG.neonBorder(SG.cyan, radius: 10, width: 1),
                            child: FilledButton.icon(
                              onPressed: () {
                                if (stepIndex == steps.length - 1) {
                                  ref.read(isDemoActiveProvider.notifier).state = false;
                                  ref.read(demoStepProvider.notifier).state = 0;
                                } else {
                                  ref.read(demoStepProvider.notifier).state = stepIndex + 1;
                                }
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: SG.cyan.withOpacity(0.15),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: Icon(
                                stepIndex == steps.length - 1 ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                                size: 18,
                                color: SG.cyan,
                              ),
                              label: Text(
                                stepIndex == steps.length - 1 ? '¡FINALIZAR!' : 'SIGUIENTE',
                                style: SG.heading(12, color: SG.cyan),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<DemoStep> _getSteps() {
    return [
      DemoStep(
          id: '1',
          title: 'Inicio de la Simulación',
          instruction: 'Toca el botón "Simular Ransomware" en el Dashboard para ver cómo reacciona el motor de inteligencia ante un ataque.',
          targetUIElement: 'btn_simulate'),
      DemoStep(
          id: '1.5',
          title: 'Entendiendo el Riesgo',
          instruction: 'Mira el "Nivel de Impacto". Cuando el ransomware se propaga, el puntaje sube a Crítico (50+ pts). Toca cualquier métrica para ver su explicación.',
          targetUIElement: 'risk_gauge'),
      DemoStep(
          id: '2',
          title: 'Respuesta Inmediata: Aislamiento',
          instruction: 'Ve a la pestaña "Red" y busca los dispositivos en Rojo. Toca "AISLAR" para detener la propagación lateral.',
          targetUIElement: 'nav_network'),
      DemoStep(
          id: '3',
          title: 'Contención SOC (NIST)',
          instruction: 'En la pestaña "Incidentes", usa "CONTENER AHORA" para cerrar el puerto vulnerado y neutralizar la amenaza.',
          targetUIElement: 'nav_incidents'),
      DemoStep(
          id: '4',
          title: 'Recuperación de Procesos',
          instruction: 'Finalmente, ve a "Infraestructura" y recupera los sistemas afectados (ej. Bomba de Agua) para volver a la normalidad.',
          targetUIElement: 'nav_infra'),
    ];
  }
}

/// Overlay shown when a threat is mitigated (Risk returns to 0)
class SuccessOverlay extends ConsumerWidget {
  const SuccessOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showSuccess = ref.watch(showSuccessOverlayProvider);
    if (!showSuccess) return const SizedBox.shrink();

    final incidents = ref.watch(incidentsProvider).value ?? [];
    final systems = ref.watch(systemsProvider).value ?? [];
    
    final totalThreats = incidents.length;
    final systemsRecovered = systems.where((s) => s.status == 'operational').length;

    return Material(
      color: Colors.black.withOpacity(0.85),
      child: Stack(
        children: [
          const ScanLinesOverlay(opacity: 0.03),
          Center(
            child: FadeInUp(
              duration: const Duration(milliseconds: 600),
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 480),
                decoration: SG.glass(glow: SG.safe, glowOpacity: 0.3, radius: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated checkmark
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SG.safe.withOpacity(0.1),
                        border: Border.all(color: SG.safe.withOpacity(0.4), width: 2),
                        boxShadow: [
                          BoxShadow(color: SG.safe.withOpacity(0.2), blurRadius: 30, spreadRadius: 5),
                        ],
                      ),
                      child: Pulse(
                        infinite: true,
                        child: Icon(Icons.verified_user_rounded, size: 60, color: SG.safe),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      '¡MISIÓN CUMPLIDA!',
                      style: SG.heading(28, color: SG.safe),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'INFRAESTRUCTURA ASEGURADA',
                      style: SG.mono(12, color: SG.safe.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: SG.surface.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: SG.border),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Has neutralizado $totalThreats amenazas digitales y restaurado $systemsRecovered sistemas críticos.',
                            style: SG.body(15),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _statChip('AMENAZAS', '0', SG.safe),
                              const SizedBox(width: 12),
                              _statChip('RIESGO', '0', SG.safe),
                              const SizedBox(width: 12),
                              _statChip('SISTEMAS', 'OK', SG.safe),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      decoration: SG.neonBorder(SG.safe, radius: 12, width: 2),
                      child: FilledButton(
                        onPressed: () => ref.read(showSuccessOverlayProvider.notifier).state = false,
                        style: FilledButton.styleFrom(
                          backgroundColor: SG.safe.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                        ),
                        child: Text('CONTINUAR MONITOREO', style: SG.heading(14, color: SG.safe)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Confetti-like effect (simple dots)
          ...List.generate(15, (i) => _ConfettiDot()),
        ],
      ),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: SG.mono(8, color: Colors.white30)),
        Text(value, style: SG.heading(16, color: color)),
      ],
    );
  }
}

class _ConfettiDot extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final x = (DateTime.now().microsecondsSinceEpoch % 1000) / 1000;
    return FadeInDown(
      delay: Duration(milliseconds: (x * 2000).toInt()),
      child: Positioned(
        left: MediaQuery.of(context).size.width * x,
        top: -20,
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: SG.safe.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

final showSuccessOverlayProvider = StateProvider<bool>((ref) => false);
final wasUnderAttackProvider = StateProvider<bool>((ref) => false);

class SimulatedProgressDialog extends StatefulWidget {
  final String title;
  final List<String> steps;
  final VoidCallback onComplete;

  const SimulatedProgressDialog({
    super.key,
    required this.title,
    required this.steps,
    required this.onComplete,
  });

  @override
  State<SimulatedProgressDialog> createState() => _SimulatedProgressDialogState();
}

class _SimulatedProgressDialogState extends State<SimulatedProgressDialog> {
  int _currentStepIndex = 0;

  @override
  void initState() {
    super.initState();
    _startSimulation();
  }

  Future<void> _startSimulation() async {
    for (int i = 0; i < widget.steps.length; i++) {
      if (!mounted) return;
      setState(() {
        _currentStepIndex = i;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
    }

    if (mounted) {
      widget.onComplete();
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_currentStepIndex + 1) / widget.steps.length;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: SG.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: SG.cyan.withOpacity(0.3)),
        ),
        title: Column(
          children: [
            Icon(Icons.terminal_rounded, color: SG.cyan, size: 32),
            const SizedBox(height: 8),
            Text(widget.title, textAlign: TextAlign.center, style: SG.heading(18, color: SG.cyan)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Terminal style step display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: SG.bg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SG.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('safegrid@soc:~\$', style: SG.mono(10, color: SG.safe)),
                  const SizedBox(height: 6),
                  ...List.generate(_currentStepIndex + 1, (i) {
                    final isDone = i < _currentStepIndex;
                    final isCurrent = i == _currentStepIndex;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isDone ? '✓ ' : (isCurrent ? '▸ ' : '  '),
                            style: SG.mono(11, color: isDone ? SG.safe : SG.cyan),
                          ),
                          Expanded(
                            child: Text(
                              widget.steps[i],
                              style: SG.mono(11, color: isDone ? SG.safe.withOpacity(0.6) : Colors.white),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  if (_currentStepIndex < widget.steps.length - 1) ...[
                    const SizedBox(height: 4),
                    Text('▌', style: SG.mono(11, color: SG.cyan)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 4, color: Colors.white.withOpacity(0.05)),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    height: 4,
                    width: MediaQuery.of(context).size.width * progress * 0.5,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [SG.cyan.withOpacity(0.3), SG.cyan]),
                      borderRadius: BorderRadius.circular(4),
                      boxShadow: [BoxShadow(color: SG.cyan.withOpacity(0.4), blurRadius: 6)],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('Paso ${_currentStepIndex + 1} de ${widget.steps.length}', style: SG.mono(10, color: Colors.white.withOpacity(0.3))),
          ],
        ),
      ),
    );
  }
}
