import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/providers.dart';
import '../models/models.dart';
import '../core/theme.dart';
import 'widgets/educational_widgets.dart';
import 'widgets/screen_onboarding.dart';
import 'widgets/onboarding_data.dart';

class NetworkMapScreen extends ConsumerWidget {
  const NetworkMapScreen({super.key});

  static const _zoneConfigs = [
    _ZoneConfig('IT', 'ZONA IT', 'Red corporativa y oficinas', Icons.computer_rounded, SG.neonBlue, 'Enterprise Zone — Nivel 4/5 Purdue', 'Es como el lobby y las oficinas de un edificio.'),
    _ZoneConfig('DMZ', 'ZONA DMZ', 'Control de aduana entre IT y OT', Icons.shield_rounded, SG.warning, 'Zona Desmilitarizada Industrial', 'Es como una aduana: revisa todo lo que entra y sale.'),
    _ZoneConfig('OT', 'ZONA OT', 'Sistemas industriales críticos', Icons.precision_manufacturing_rounded, SG.neonPurple, 'Manufacturing Zone — Controla procesos físicos.', 'Es el taller de producción: donde están las máquinas reales.'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: ScreenOnboarding(
        screenKey: 'network',
        slides: kNetworkSlides,
        child: Stack(
          children: [
            const ScanLinesOverlay(opacity: 0.01),
            Column(
              children: [
                _buildMapLegend(),
                Expanded(
                  child: devicesAsync.when(
                    data: (devices) {
                      return Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: List.generate(_zoneConfigs.length, (i) {
                            final config = _zoneConfigs[i];
                            final zoneDevices = devices.where((d) => d.zone == config.id).toList();
                            return Expanded(
                              child: FadeInUp(
                                delay: Duration(milliseconds: 100 * i),
                                duration: const Duration(milliseconds: 500),
                                child: _buildPurdueZone(context, ref, user, config, zoneDevices),
                              ),
                            );
                          }),
                        ),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: SG.cyan)),
                    error: (err, stack) => Center(child: Text('Error: $err', style: SG.body(14, color: SG.danger))),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMapLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: SG.surface,
        border: Border(bottom: BorderSide(color: SG.border)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('MAPA TÁCTICO  ', style: SG.heading(12, color: SG.cyan)),
          const SizedBox(width: 16),
          _legendDot(SG.safe, 'Operativo'),
          const SizedBox(width: 16),
          _legendDot(SG.warning, 'Riesgo'),
          const SizedBox(width: 16),
          _legendDot(SG.danger, 'Comprometido'),
          const SizedBox(width: 16),
          _legendDot(SG.muted, 'Aislado'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8, height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            boxShadow: [BoxShadow(color: color.withOpacity(0.4), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: SG.mono(9, color: Colors.white54)),
      ],
    );
  }

  Widget _buildPurdueZone(BuildContext context, WidgetRef ref, User? user, _ZoneConfig config, List<Device> devices) {
    final hasCompromised = devices.any((d) => d.status == 'compromised');

    return ExplainWrapper(
      title: config.title,
      techDesc: config.tech,
      analogyDesc: config.analogy,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: config.color.withOpacity(0.03),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasCompromised
                ? SG.danger.withOpacity(0.4)
                : config.color.withOpacity(0.2),
            width: hasCompromised ? 2 : 1,
          ),
          boxShadow: hasCompromised
              ? [BoxShadow(color: SG.danger.withOpacity(0.1), blurRadius: 16)]
              : null,
        ),
        child: Column(
          children: [
            // Zone header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    config.color.withOpacity(0.15),
                    config.color.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
                border: Border(bottom: BorderSide(color: config.color.withOpacity(0.15))),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: config.color.withOpacity(0.15),
                      border: Border.all(color: config.color.withOpacity(0.3)),
                    ),
                    child: Icon(config.icon, color: config.color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(config.title, style: SG.heading(12, color: config.color)),
                        Text(config.subtitle, style: SG.mono(8, color: Colors.white.withOpacity(0.3))),
                      ],
                    ),
                  ),
                  if (hasCompromised)
                    PulsingDot(color: SG.danger, size: 8),
                  if (config.id == 'OT' && user?.role == 'admin')
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Apagado Emergencia OT',
                      icon: Icon(Icons.power_settings_new_rounded, color: SG.danger, size: 18),
                      onPressed: () => ref.read(dataRepoProvider).shutdownZone(user!.role, config.id),
                    ),
                ],
              ),
            ),
            // Device list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: devices.length,
                itemBuilder: (context, index) {
                  final d = devices[index];
                  return _buildDeviceNode(context, ref, user, d, config.color);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceNode(BuildContext context, WidgetRef ref, User? user, Device d, Color zoneColor) {
    IconData icon = d.type == 'router'
        ? Icons.router_rounded
        : (d.type == 'plc' ? Icons.settings_input_component_rounded : Icons.computer_rounded);
    Color borderColor = SG.safe;
    bool isAlert = false;

    if (d.isIsolated) {
      borderColor = SG.muted;
    } else if (d.status == 'compromised') {
      borderColor = SG.danger;
      isAlert = true;
    } else if (!d.isTrusted) {
      borderColor = SG.warning;
      isAlert = true;
    }

    Widget cardContent = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          isAlert
              ? _AnimatedAlertIcon(icon: icon, color: borderColor)
              : Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: borderColor.withOpacity(0.1),
                    border: Border.all(color: borderColor.withOpacity(0.3)),
                  ),
                  child: Icon(icon, color: borderColor, size: 20),
                ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(d.name, style: SG.heading(11, color: Colors.white)),
                Text(d.isIsolated ? '🚩 AISLADO' : d.status.toUpperCase(),
                    style: SG.mono(9, color: borderColor)),
              ],
            ),
          ),
          if (user?.role != 'viewer')
            d.isIsolated
                ? SizedBox(
                    height: 28,
                    child: Container(
                      decoration: SG.neonBorder(SG.safe, radius: 6, width: 1),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SG.safe.withOpacity(0.1),
                          foregroundColor: SG.safe,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () => ref.read(dataRepoProvider).reconnectDevice(user!.role, d.id),
                        child: Text('RECONECTAR', style: SG.heading(8, color: SG.safe)),
                      ),
                    ),
                  )
                : SizedBox(
                    height: 28,
                    child: Container(
                      decoration: SG.neonBorder(SG.cyan, radius: 6, width: 1),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: SG.cyan.withOpacity(0.1),
                          foregroundColor: SG.cyan,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          minimumSize: Size.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => SimulatedProgressDialog(
                              title: 'Aislando ${d.name}',
                              steps: const [
                                'Identificando puerto en Switch de Red...',
                                'Bloqueando tráfico TCP/IP y UDP...',
                                'Desconectando enlace físico lógico...',
                                'Aplicando reglas de Firewall de contención...'
                              ],
                              onComplete: () {
                                ref.read(dataRepoProvider).isolateDevice(user!.role, d.id);
                              },
                            ),
                          );
                        },
                        child: Text('AISLAR', style: SG.heading(8, color: SG.cyan)),
                      ),
                    ),
                  ),
        ],
      ),
    );

    return ExplainWrapper(
      title: d.name,
      techDesc: 'Dispositivo tipo ${d.type.toUpperCase()} con IP ${d.ip}. Estado actual: ${d.status}.',
      analogyDesc: d.type == 'plc'
          ? 'Es el interruptor inteligente que obedece órdenes para mover una máquina.'
          : 'Es una computadora que procesa datos.',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: isAlert && d.status == 'compromised'
            ? _AnimatedAlertCard(
                borderColor: borderColor,
                child: InkWell(
                  onTap: () => _showDeviceDetailsDialog(context, d),
                  child: cardContent,
                ),
              )
            : Container(
                decoration: BoxDecoration(
                  color: borderColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () => _showDeviceDetailsDialog(context, d),
                  child: cardContent,
                ),
              ),
      ),
    );
  }

  void _showDeviceDetailsDialog(BuildContext context, Device d) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(children: [
          Icon(Icons.memory_rounded, color: SG.cyan, size: 24),
          const SizedBox(width: 8),
          Expanded(child: Text('Inspección de Hardware', style: SG.heading(16))),
        ]),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: SG.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: SG.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nombre Físico: ${d.name}', style: SG.heading(13, color: Colors.white)),
                  Text('Dirección Lógica (IP): ${d.ip}', style: SG.mono(12)),
                  Text('Clasificación: ${d.type.toUpperCase()}', style: SG.mono(12)),
                  Text('Ubicación: Zona ${d.zone} (Purdue)', style: SG.mono(12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Estado de Seguridad:', style: SG.heading(13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (d.status == 'compromised' ? SG.danger : SG.safe).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: (d.status == 'compromised' ? SG.danger : SG.safe).withOpacity(0.3)),
              ),
              child: Row(children: [
                Icon(
                  d.status == 'compromised' ? Icons.coronavirus_rounded : Icons.verified_user_rounded,
                  color: d.status == 'compromised' ? SG.danger : SG.safe,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  d.status == 'compromised' ? 'INFECTADO / COMPROMETIDO' : 'OPERATIVO',
                  style: SG.heading(12, color: d.status == 'compromised' ? SG.danger : SG.safe),
                ),
              ]),
            ),
            if (d.isIsolated) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: SG.info.withOpacity(0.1),
                  border: Border.all(color: SG.info.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(children: [
                  Icon(Icons.link_off_rounded, color: SG.info, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text('AISLADO: El equipo está encendido pero sin acceso a la red.', style: SG.body(11, color: SG.info))),
                ]),
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: Text('Cerrar', style: SG.heading(13, color: SG.cyan))),
        ],
      ),
    );
  }
}

class _ZoneConfig {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String tech;
  final String analogy;
  const _ZoneConfig(this.id, this.title, this.subtitle, this.icon, this.color, this.tech, this.analogy);
}

class _AnimatedAlertIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _AnimatedAlertIcon({required this.icon, required this.color});

  @override
  State<_AnimatedAlertIcon> createState() => _AnimatedAlertIconState();
}

class _AnimatedAlertIconState extends State<_AnimatedAlertIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
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
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withOpacity(0.1 + _controller.value * 0.15),
            boxShadow: [
              BoxShadow(color: widget.color.withOpacity(_controller.value * 0.3), blurRadius: 8),
            ],
          ),
          child: Transform.scale(
            scale: 1.0 + _controller.value * 0.15,
            child: Icon(widget.icon, color: widget.color, size: 20),
          ),
        );
      },
    );
  }
}

class _AnimatedAlertCard extends StatefulWidget {
  final Widget child;
  final Color borderColor;
  const _AnimatedAlertCard({required this.child, required this.borderColor});

  @override
  State<_AnimatedAlertCard> createState() => _AnimatedAlertCardState();
}

class _AnimatedAlertCardState extends State<_AnimatedAlertCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.05, end: 0.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: widget.borderColor.withOpacity(_animation.value),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: widget.borderColor.withOpacity(0.5), width: 1.5),
            boxShadow: [
              BoxShadow(color: widget.borderColor.withOpacity(_animation.value * 0.5), blurRadius: 12),
            ],
          ),
          child: widget.child,
        );
      },
    );
  }
}
