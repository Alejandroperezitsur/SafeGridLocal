import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';
import '../models/models.dart';

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
                      _buildPurdueZone(context, ref, user, 'Nivel 4/5: Red Corp (IT)', Colors.blue, 'IT', itDevices),
                      _buildPurdueZone(context, ref, user, 'Nivel 3.5: DMZ', Colors.orange, 'DMZ', dmzDevices),
                      _buildPurdueZone(context, ref, user, 'Nivel 1-3: Control (OT)', Colors.purple, 'OT', otDevices, hasShutdown: true),
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
          _legendDot(Colors.orange, 'Amenazado'),
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
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildPurdueZone(BuildContext context, WidgetRef ref, User? user, String title, Color color, String zoneId, List<Device> devices, {bool hasShutdown = false}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: const BorderRadius.vertical(top: Radius.circular(10))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: color))),
                  if (hasShutdown && user?.role == 'admin')
                    IconButton(
                      tooltip: 'Apagado Emergencia OT (Zona Entera)',
                      icon: const Icon(Icons.power_settings_new, color: Colors.red),
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
                  IconData icon = d.type == 'router' ? Icons.router : (d.type == 'plc' ? Icons.settings_input_component : Icons.computer);

                  Color cardColor = Colors.green.withOpacity(0.1);
                  Color borderColor = Colors.green;
                  
                  if (d.isIsolated) {
                    cardColor = Colors.grey.withOpacity(0.2);
                    borderColor = Colors.grey;
                  } else if (d.status == 'compromised') {
                    cardColor = Colors.red.withOpacity(0.2);
                    borderColor = Colors.red;
                  } else if (!d.isTrusted) {
                    cardColor = Colors.orange.withOpacity(0.1);
                    borderColor = Colors.orange;
                  }

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(side: BorderSide(color: borderColor, width: 2), borderRadius: BorderRadius.circular(8)),
                    color: cardColor,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      leading: Icon(icon, color: borderColor, size: 32),
                      title: Text(d.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${d.ip}\n${d.isIsolated ? '🚩 AISLADO' : d.status.toUpperCase()}', style: const TextStyle(fontSize: 11)),
                      trailing: user?.role != 'viewer' && !d.isIsolated
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                            onPressed: () => ref.read(dataRepoProvider).isolateDevice(user!.role, d.id),
                            child: const Text('ISOLATE', style: TextStyle(fontSize: 10)),
                          )
                        : null,
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
