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
      body: devicesAsync.when(
        data: (devices) {
          final itDevices = devices.where((d) => d.zone == 'IT').toList();
          final dmzDevices = devices.where((d) => d.zone == 'DMZ').toList();
          final otDevices = devices.where((d) => d.zone == 'OT').toList();

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildZoneColumn(context, ref, user, 'IT Zone (Level 4/5)', Colors.blue, 'IT', itDevices),
                const VerticalDivider(width: 32, thickness: 2, color: Colors.grey),
                _buildZoneColumn(context, ref, user, 'DMZ (Level 3.5)', Colors.orange, 'DMZ', dmzDevices),
                const VerticalDivider(width: 32, thickness: 2, color: Colors.grey),
                _buildZoneColumn(context, ref, user, 'OT Zone (Level 1/2/3)', Colors.purple, 'OT', otDevices, hasShutdown: true),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildZoneColumn(BuildContext context, WidgetRef ref, User? user, String title, Color color, String zoneId, List<Device> devices, {bool hasShutdown = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(8), border: Border.all(color: color)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text(title, textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 18))),
                if (hasShutdown && user?.role == 'admin')
                  IconButton(
                    tooltip: 'Emergency OT Shutdown',
                    icon: const Icon(Icons.power_settings_new, color: Colors.red),
                    onPressed: () => ref.read(dataRepoProvider).shutdownZone(user!.role, zoneId),
                  )
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: devices.length,
              itemBuilder: (context, index) {
                final d = devices[index];
                IconData icon;
                if (d.type == 'router') icon = Icons.router;
                else if (d.type == 'plc') icon = Icons.memory;
                else icon = Icons.computer;

                Color cardColor = Colors.green.withOpacity(0.1);
                Color borderColor = Colors.green;
                
                if (d.isIsolated) {
                  cardColor = Colors.grey.withOpacity(0.2);
                  borderColor = Colors.grey;
                } else if (!d.isTrusted) {
                  cardColor = Colors.orange.withOpacity(0.1);
                  borderColor = Colors.orange;
                } else if (d.status == 'compromised') {
                  cardColor = Colors.red.withOpacity(0.2);
                  borderColor = Colors.red;
                }

                return Card(
                  shape: RoundedRectangleBorder(side: BorderSide(color: borderColor, width: 1.5), borderRadius: BorderRadius.circular(8)),
                  color: cardColor,
                  child: ListTile(
                    leading: Icon(icon, color: borderColor),
                    title: Text(d.name, style: TextStyle(fontWeight: FontWeight.bold, decoration: d.isIsolated ? TextDecoration.lineThrough : null)),
                    subtitle: Text('IP: ${d.ip}\nStatus: ${d.isIsolated ? 'ISOLATED' : d.status.toUpperCase()}'),
                    isThreeLine: true,
                    trailing: (user?.role == 'admin' || user?.role == 'operator') && !d.isIsolated
                      ? FilledButton.tonal(
                          onPressed: () => ref.read(dataRepoProvider).isolateDevice(user!.role, d.id),
                          child: const Text('Isolate', style: TextStyle(fontSize: 12)),
                        )
                      : d.isIsolated 
                          ? const Icon(Icons.shield, color: Colors.blue)
                          : const Icon(Icons.check_circle, color: Colors.green),
                  ),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
