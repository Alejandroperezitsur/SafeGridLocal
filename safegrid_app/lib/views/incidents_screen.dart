import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/providers.dart';
import '../core/theme.dart';
import 'widgets/educational_widgets.dart';
import 'widgets/screen_onboarding.dart';
import 'widgets/onboarding_data.dart';

class IncidentsScreen extends ConsumerWidget {
  const IncidentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(incidentsProvider);
    final user = ref.watch(currentUserProvider);

    return ScreenOnboarding(
      screenKey: 'incidents',
      slides: kIncidentsSlides,
      child: Stack(
        children: [
          const ScanLinesOverlay(opacity: 0.01),
          incidentsAsync.when(
            data: (incidents) {
              if (incidents.isEmpty) {
                return _buildEmptyState(context);
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: incidents.length + 1, // +1 for header
                itemBuilder: (context, index) {
                  if (index == 0) return _buildHeader(incidents);

                  final inc = incidents[index - 1];
                  Color severityColor = SG.warning;
                  if (inc.severity == 'critical') severityColor = SG.danger;
                  else if (inc.severity == 'high') severityColor = const Color(0xFFFF6D00);

                  bool isResolved = inc.status == 'resolved' || inc.status == 'contained';

                  return FadeInUp(
                    duration: const Duration(milliseconds: 400),
                    delay: Duration(milliseconds: index * 80),
                    child: _buildIncidentCard(context, ref, user, inc, isResolved, severityColor),
                  );
                },
              );
            },
            loading: () => Center(child: CircularProgressIndicator(color: SG.cyan)),
            error: (e, s) => Center(child: Text('Error: $e', style: SG.body(14, color: SG.danger))),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(List<dynamic> incidents) {
    final active = incidents.where((i) => i.status == 'active').length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (active > 0 ? SG.danger : SG.safe).withOpacity(0.1),
              border: Border.all(color: (active > 0 ? SG.danger : SG.safe).withOpacity(0.3)),
            ),
            child: Icon(
              active > 0 ? Icons.warning_amber_rounded : Icons.verified_user_rounded,
              color: active > 0 ? SG.danger : SG.safe,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SALA SOC', style: SG.heading(18, color: SG.cyan)),
              Text(
                active > 0 ? '$active incidente(s) activo(s)' : 'Todos los incidentes resueltos',
                style: SG.mono(10, color: active > 0 ? SG.danger : SG.safe),
              ),
            ],
          ),
          const Spacer(),
          if (active > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: SG.danger.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: SG.danger.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  PulsingDot(color: SG.danger, size: 8),
                  const SizedBox(width: 6),
                  Text('ALERTA ACTIVA', style: SG.heading(10, color: SG.danger)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _RadarScanWidget(),
            const SizedBox(height: 24),
            Text('MONITOREO ACTIVO', style: SG.heading(20, color: SG.safe)),
            const SizedBox(height: 8),
            Text('No hay incidentes activos.', style: SG.body(14, color: SG.safe)),
            Text('Puedes iniciar una simulación para ver cómo funciona.', style: SG.body(13, color: Colors.white38)),
            const SizedBox(height: 24),
            ExplainWrapper(
              title: 'Monitoreo Pasivo',
              techDesc: 'El sistema escucha el tráfico de red buscando anomalías sin interrumpir el proceso industrial.',
              analogyDesc: 'Es como un guardia que observa las cámaras sin detener a nadie, a menos que vea algo prohibido.',
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(children: [
                        Icon(Icons.monitor_heart_rounded, color: SG.info),
                        const SizedBox(width: 8),
                        Text('Monitoreo Pasivo (SOC)', style: SG.heading(16)),
                      ]),
                      content: Text(
                        'En infraestructuras críticas (OT), no podemos instalar antivirus normales porque podrían ralentizar o detener una máquina industrial.\n\nPor eso usamos "Monitoreo Pasivo": el sistema escucha el tráfico de red de forma invisible usando un puerto espejo (SPAN port). Así detectamos anomalías sin tocar los PLCs.',
                        style: SG.body(14),
                      ),
                      actions: [
                        FilledButton(onPressed: () => Navigator.pop(context), child: Text('Entendido', style: SG.heading(13, color: SG.cyan))),
                      ],
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: SG.info.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: SG.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: SG.info),
                      const SizedBox(width: 8),
                      Text('¿Cómo funciona el monitoreo?', style: SG.heading(12, color: SG.info)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncidentCard(BuildContext context, WidgetRef ref, dynamic user, dynamic inc, bool isResolved, Color color) {
    return ExplainWrapper(
      title: inc.type.toUpperCase(),
      techDesc: 'Evento de tipo ${inc.type}. Severidad ${inc.severity}. Estado: ${inc.status}.',
      analogyDesc: _getIncidentAnalogy(inc.type),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: (isResolved ? SG.safe : color).withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isResolved ? SG.safe.withOpacity(0.3) : color.withOpacity(0.4),
            width: isResolved ? 1 : 1.5,
          ),
          boxShadow: isResolved
              ? null
              : [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12)],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: !isResolved,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isResolved ? SG.safe : color).withOpacity(0.1),
                border: Border.all(color: (isResolved ? SG.safe : color).withOpacity(0.3)),
              ),
              child: Icon(
                isResolved ? Icons.check_circle_rounded : Icons.warning_rounded,
                color: isResolved ? SG.safe : color,
                size: 22,
              ),
            ),
            title: Text(
              isResolved ? 'Incidente Resuelto' : 'Ataque activo en la red (${inc.type})',
              style: SG.heading(14, color: isResolved ? SG.safe : Colors.white),
            ),
            subtitle: Row(
              children: [
                _buildStatusBadge(inc.status),
                const SizedBox(width: 8),
                _buildSeverityBadge(inc.severity),
              ],
            ),
            children: [
              _buildIncidentDetail(context, ref, user, inc, isResolved, color),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active':
        color = SG.danger;
        label = 'ACTIVO';
        break;
      case 'contained':
        color = SG.amber;
        label = 'CONTENIDO';
        break;
      case 'resolved':
        color = SG.safe;
        label = 'RESUELTO';
        break;
      default:
        color = SG.muted;
        label = status.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: SG.mono(9, color: color)),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    String label;
    switch (severity) {
      case 'critical':
        color = SG.danger;
        label = 'CRÍTICA';
        break;
      case 'high':
        color = SG.warning;
        label = 'ALTA';
        break;
      default:
        color = SG.amber;
        label = severity.toUpperCase();
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: SG.mono(9, color: color)),
    );
  }

  String _getIncidentAnalogy(String type) {
    if (type == 'ransomware') return 'Es como si alguien entrara a tu oficina y pusiera candados a todos tus cajones, exigiendo dinero para darte la llave.';
    if (type == 'unauthorized_access') return 'Es como si alguien intentara abrir la puerta de la fábrica con una llave maestra robada.';
    return 'Es un comportamiento inusual que el sistema ha marcado como sospechoso.';
  }

  Widget _buildIncidentDetail(BuildContext context, WidgetRef ref, dynamic user, dynamic inc, bool isResolved, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SG.surface.withOpacity(0.5),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ANÁLISIS DE LA AMENAZA', style: SG.heading(11, color: SG.cyan)),
              if (!isResolved && user?.role != 'viewer')
                Container(
                  decoration: SG.neonBorder(SG.safe, radius: 10, width: 1),
                  child: ElevatedButton.icon(
                    onPressed: () => ref.read(dataRepoProvider).containIncident(user!.role, inc.id),
                    icon: Icon(Icons.security_rounded, size: 16, color: SG.safe),
                    label: Text('CONTENER AHORA', style: SG.heading(11, color: SG.safe)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SG.safe.withOpacity(0.1),
                      foregroundColor: SG.safe,
                      minimumSize: const Size(120, 42),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
            ],
          ),
          Divider(color: SG.border),
          if (!isResolved) _buildDSSRecommendations(inc),
          const SizedBox(height: 12),
          if (inc.explanation != null && inc.explanation!.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SG.info.withOpacity(0.06),
                border: Border.all(color: SG.info.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(Icons.psychology_rounded, size: 16, color: SG.info),
                    const SizedBox(width: 6),
                    Text('MOTOR DE INTELIGENCIA', style: SG.heading(10, color: SG.info)),
                  ]),
                  const SizedBox(height: 6),
                  Text(inc.explanation!, style: SG.body(13)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Timeline
          Row(children: [
            Icon(Icons.timeline_rounded, size: 16, color: SG.cyan.withOpacity(0.6)),
            const SizedBox(width: 6),
            Text('TIMELINE DE EVENTOS', style: SG.heading(11, color: SG.cyan.withOpacity(0.6))),
          ]),
          const SizedBox(height: 10),
          ...List.generate(inc.timeline.length, (i) {
            final event = inc.timeline[i];
            final isLast = i == inc.timeline.length - 1;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  children: [
                    Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: SG.cyan,
                        boxShadow: [BoxShadow(color: SG.cyan.withOpacity(0.3), blurRadius: 4)],
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 1, height: 30,
                        color: SG.border,
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(event.description, style: SG.body(12)),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDSSRecommendations(dynamic inc) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SG.amber.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: SG.amber.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(Icons.lightbulb_rounded, color: SG.amber, size: 16),
            const SizedBox(width: 8),
            Text('Recomendación SOC (NIST):', style: SG.heading(11, color: SG.amber)),
          ]),
          const SizedBox(height: 8),
          Text(
            inc.type == 'ransomware'
                ? '1. Usa la pestaña "Red / Purdue" para ubicar los PLCs en riesgo.\n2. Presiona "AISLAR" en los equipos afectados para cortar su conexión.\n\n💡 Nota Educativa: El ransomware se propaga usando protocolos de red como SMB (Server Message Block, usado para compartir archivos). Al hacer clic en "Aislar", simulamos la deshabilitación del puerto en el switch de red, deteniendo la infección en seco.'
                : 'Verificar logs del Active Directory y rotar credenciales del operario afectado.',
            style: SG.body(12),
          ),
        ],
      ),
    );
  }
}

/// Animated radar scan widget for the empty state
class _RadarScanWidget extends StatefulWidget {
  @override
  State<_RadarScanWidget> createState() => _RadarScanWidgetState();
}

class _RadarScanWidgetState extends State<_RadarScanWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120, height: 120,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, child) {
          return CustomPaint(
            painter: _RadarPainter(progress: _ctrl.value),
          );
        },
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double progress;
  _RadarPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rings
    final ringPaint = Paint()
      ..color = SG.safe.withOpacity(0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, radius * i / 3, ringPaint);
    }

    // Cross lines
    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), ringPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), ringPaint);

    // Sweep
    final sweepAngle = progress * 3.14159 * 2;
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        startAngle: sweepAngle - 0.8,
        endAngle: sweepAngle,
        colors: [
          Colors.transparent,
          SG.safe.withOpacity(0.3),
        ],
        stops: const [0.0, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, sweepPaint);

    // Center dot
    canvas.drawCircle(center, 3, Paint()..color = SG.safe);
  }

  @override
  bool shouldRepaint(_RadarPainter old) => old.progress != progress;
}
