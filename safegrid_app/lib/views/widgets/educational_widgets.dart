import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/providers.dart';
import '../../models/models.dart';

class InsightPanel extends ConsumerWidget {
  const InsightPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final insights = ref.watch(insightsProvider);
    
    if (insights.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _getBgColor(insights.first.type),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getBorderColor(insights.first.type), width: 1.5),
      ),
      child: Row(
        children: [
          Icon(_getIcon(insights.first.type), color: _getBorderColor(insights.first.type)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  insights.first.title,
                  style: TextStyle(fontWeight: FontWeight.bold, color: _getBorderColor(insights.first.type), fontSize: 13),
                ),
                Text(
                  insights.first.message,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          if (insights.length > 1) 
            Text('+${insights.length - 1} más', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getBgColor(String type) {
    if (type == 'critical') return Colors.red.withOpacity(0.1);
    if (type == 'warning') return Colors.orange.withOpacity(0.1);
    if (type == 'tip') return Colors.blue.withOpacity(0.1);
    return Colors.grey.withOpacity(0.1);
  }

  Color _getBorderColor(String type) {
    if (type == 'critical') return Colors.red;
    if (type == 'warning') return Colors.orange;
    if (type == 'tip') return Colors.blue;
    return Colors.grey;
  }

  IconData _getIcon(String type) {
    if (type == 'critical') return Icons.gpp_bad;
    if (type == 'warning') return Icons.report_problem;
    if (type == 'tip') return Icons.lightbulb_outline;
    return Icons.info_outline;
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
            const Icon(Icons.help_outline, color: Colors.blueAccent),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (learningMode) ...[
              const Text('Analogía Simple:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueAccent)),
              const SizedBox(height: 4),
              Text(analogyDesc, style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 16),
            ],
            const Text('Explicación Técnica:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(techDesc),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cerrar')),
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

    return Material(
      color: Colors.black54,
      child: InkWell(
        onTap: () {}, // Bloquear taps al fondo
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF1A2233),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.blueAccent, width: 2),
              boxShadow: [BoxShadow(color: Colors.blueAccent.withOpacity(0.5), blurRadius: 20)],
            ),
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.school, color: Colors.blueAccent),
                    const SizedBox(width: 12),
                    Text('GUÍA PASO A PASO (${stepIndex + 1}/${steps.length})', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blueAccent)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(currentStep.title ?? 'Siguiente Paso', 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Text(currentStep.instruction, 
                  textAlign: TextAlign.center, 
                  style: const TextStyle(fontSize: 15, height: 1.4)),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => ref.read(isDemoActiveProvider.notifier).state = false,
                      child: const Text('Salir Guía', style: TextStyle(color: Colors.grey)),
                    ),
                    FilledButton(
                      onPressed: () {
                        if (stepIndex == steps.length - 1) {
                           ref.read(isDemoActiveProvider.notifier).state = false;
                           ref.read(demoStepProvider.notifier).state = 0;
                        } else {
                           ref.read(demoStepProvider.notifier).state = stepIndex + 1;
                        }
                      },
                      child: Text(stepIndex == steps.length - 1 ? '¡Finalizar!' : 'Siguiente'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<DemoStep> _getSteps() {
    return [
      DemoStep(
        id: '1',
        title: 'Inicio de la Simulación',
        instruction: 'Toca el botón "Simular Ransomware" en el Dashboard para ver cómo reacciona el motor de inteligencia ante un ataque.',
        targetUIElement: 'btn_simulate'
      ),
      DemoStep(
        id: '1.5',
        title: 'Entendiendo el Riesgo',
        instruction: 'Mira el "Nivel de Impacto". Cuando el ransomware se propaga, el puntaje sube a Crítico (50+ pts). Toca cualquier métrica para ver su explicación.',
        targetUIElement: 'risk_gauge'
      ),
      DemoStep(
        id: '2',
        title: 'Respuesta Inmediata: Aislamiento',
        instruction: 'Ve a la pestaña "Red" y busca los dispositivos en Rojo. Toca "AISLAR" para detener la propagación lateral.',
        targetUIElement: 'nav_network'
      ),
      DemoStep(
        id: '3',
        title: 'Contención SOC (NIST)',
        instruction: 'En la pestaña "Incidentes", usa "CONTENER AHORA" para cerrar el puerto vulnerado y neutralizar la amenaza.',
        targetUIElement: 'nav_incidents'
      ),
      DemoStep(
        id: '4',
        title: 'Recuperación de Procesos',
        instruction: 'Finalmente, ve a "Infraestructura" y recupera los sistemas afectados (ej. Bomba de Agua) para volver a la normalidad.',
        targetUIElement: 'nav_infra'
      ),
    ];
  }
}
