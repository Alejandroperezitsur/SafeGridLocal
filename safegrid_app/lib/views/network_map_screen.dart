import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';
import '../models/models.dart';
import 'widgets/educational_widgets.dart';

class NetworkMapScreen extends ConsumerWidget {
  const NetworkMapScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: Column(
        children: [
          _buildMapLegend(context),
          Expanded(
            child: devicesAsync.when(
              data: (devices) {
                final itDevices = devices.where((d) => d.zone == 'IT').toList();
                final dmzDevices = devices.where((d) => d.zone == 'DMZ').toList();
                final otDevices = devices.where((d) => d.zone == 'OT').toList();

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildPurdueZone(
                        context, ref, user, 
                        'Nivel 4/5: Red Corp (IT)', 
                        Colors.blue, 'IT', itDevices,
                        'Zona Administrativa (Enterprise Zone).',
                        'Es como el lobby y las oficinas de un edificio: donde entra la gente y se gestiona el negocio.'
                      ),
                      _buildPurdueZone(
                        context, ref, user, 
                        'Nivel 3.5: DMZ', 
                        Colors.orange, 'DMZ', dmzDevices,
                        'Zona Desmilitarizada (DMZ) Industrial.',
                        'Es como una aduana: un punto de control donde se revisa todo lo que entra y sale entre la oficina y la fábrica.'
                      ),
                      _buildPurdueZone(
                        context, ref, user, 
                        'Nivel 1-3: Control (OT)', 
                        Colors.purple, 'OT', otDevices,
                        'Zona de Operaciones (Manufacturing Zone). Controla los procesos físicos.',
                        'Es el taller o la planta de producción: donde están las máquinas reales trabajando.',
                        hasShutdown: true,
                      ),
                    ],
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapLegend(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      color: Colors.black26,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _legendDot(Colors.green, 'Operativo'),
          _legendDot(Colors.orange, 'Sospechoso'),
          _legendDot(Colors.red, 'COMPROMETIDO'),
          _legendDot(Colors.grey, 'AISLADO'),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        CircleAvatar(backgroundColor: color, radius: 6),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 10)),
      ],
    );
  }

  Widget _buildPurdueZone(BuildContext context, WidgetRef ref, User? user, String title, Color color, String zoneId, List<Device> devices, String tech, String analogy, {bool hasShutdown = false}) {
    return Expanded(
      child: ExplainWrapper(
        title: title,
        techDesc: tech,
        analogyDesc: analogy,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            border: Border.all(color: color.withOpacity(0.3), width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13))),
                    if (hasShutdown && user?.role == 'admin')
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'Apagado Emergencia OT',
                        icon: const Icon(Icons.power_settings_new, color: Colors.red, size: 20),
                        onPressed: () => ref.read(dataRepoProvider).shutdownZone(user!.role, zoneId),
                      )
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final d = devices[index];
                    return _buildDeviceNode(ref, user, d);
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceNode(WidgetRef ref, User? user, Device d) {
    IconData icon = d.type == 'router' ? Icons.router : (d.type == 'plc' ? Icons.settings_input_component : Icons.computer);
    Color borderColor = Colors.green;
    bool isAlert = false;
    
    if (d.isIsolated) {
      borderColor = Colors.grey;
    } else if (d.status == 'compromised') {
      borderColor = Colors.red;
      isAlert = true;
    } else if (!d.isTrusted) {
      borderColor = Colors.orange;
      isAlert = true;
    }

    return ExplainWrapper(
      title: d.name,
      techDesc: 'Dispositivo tipo ${d.type.toUpperCase()} con IP ${d.ip}. Estado actual: ${d.status}.',
      analogyDesc: d.type == 'plc' ? 'Es el interruptor inteligente que obedece órdenes para mover una máquina.' : 'Es una computadora que procesa datos.',
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: isAlert ? 4 : 1,
        shape: RoundedRectangleBorder(side: BorderSide(color: borderColor, width: 2), borderRadius: BorderRadius.circular(8)),
        color: borderColor.withOpacity(0.1),
        child: ListTile(
          visualDensity: VisualDensity.compact,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
          leading: isAlert 
            ? _AnimatedAlertIcon(icon: icon, color: borderColor)
            : Icon(icon, color: borderColor, size: 28),
          title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          subtitle: Text(d.isIsolated ? '🚩 AISLADO' : d.status.toUpperCase(), style: const TextStyle(fontSize: 10)),
          trailing: user?.role != 'viewer' && !d.isIsolated
            ? SizedBox(
                height: 32,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 4)),
                  onPressed: () => ref.read(dataRepoProvider).isolateDevice(user!.role, d.id),
                  child: const Text('AISLAR', style: TextStyle(fontSize: 10)),
                ),
              )
            : null,
        ),
      ),
    );
  }
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
    super.initState();
  }
  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.2).animate(_controller),
      child: Icon(widget.icon, color: widget.color, size: 28),
    );
  }
}
