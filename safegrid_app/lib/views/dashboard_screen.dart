import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';
import 'network_map_screen.dart';
import 'incidents_screen.dart'; // New V2 Incident Timeline Screen
import 'critical_infra_screen.dart';
import 'educational_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    ref.watch(dashboardRefreshProvider);
    
    final riskScore = ref.watch(riskScoreProvider);
    final user = ref.watch(currentUserProvider);
    final incidentsAsync = ref.watch(incidentsProvider);
    
    Color riskColor = Colors.green;
    String riskText = 'Low Impact';
    
    if (riskScore >= 50) { riskColor = Colors.purpleAccent; riskText = 'CRITICAL IMPACT'; }
    else if (riskScore >= 20) { riskColor = Colors.redAccent; riskText = 'High Impact'; } 
    else if (riskScore >= 10) { riskColor = Colors.amber; riskText = 'Medium Impact'; }

    final pages = [
      const NetworkMapScreen(),
      const IncidentsScreen(), // V2
      const CriticalInfraScreen(),
      const EducationalScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('ICS Intelligence Engine V2'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text('Logged in as: ${user?.name} (${user?.role})', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          if (user?.role == 'admin')
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: Colors.red[900]),
                onPressed: () async {
                  try {
                    await ref.read(dataRepoProvider).simulateAttack(user!.role);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ransomware Payload Executed!'), backgroundColor: Colors.red));
                  } catch(e) {}
                },
                icon: const Icon(Icons.dangerous, color: Colors.white),
                label: const Text('Simulate Ransomware', style: TextStyle(color: Colors.white)),
              ),
            ),
          if (user?.role == 'admin')
            IconButton(
              tooltip: 'Reset Engine',
              icon: const Icon(Icons.cloud_sync),
              onPressed: () async {
                await ref.read(dataRepoProvider).resetSimulation(user!.role);
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Engine Reset')));
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Indicator V2
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: riskColor.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(riskScore >= 50 ? Icons.warning : Icons.security, color: riskColor, size: 48),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('REAL IMPACT: $riskText', style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: riskColor, fontWeight: FontWeight.bold)),
                    Text('Intelligence Score: $riskScore', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
                const SizedBox(width: 32),
                // Show Active Incidents Count
                incidentsAsync.when(
                   data: (incs) {
                     final activeCount = incs.where((i) => i.status == 'active').length;
                     return Chip(
                       backgroundColor: activeCount > 0 ? Colors.red : Colors.green,
                       label: Text('$activeCount Active Incidents', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                     );
                   },
                   loading: () => const CircularProgressIndicator(),
                   error: (e,s) => const SizedBox()
                )
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(duration: const Duration(milliseconds: 300), child: pages[_currentIndex]),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(()=> _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Network Map'),
          BottomNavigationBarItem(icon: Icon(Icons.av_timer), label: 'Incident Timeline'),
          BottomNavigationBarItem(icon: Icon(Icons.precision_manufacturing), label: 'Infrastructure'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Education'),
        ],
      ),
    );
  }
}
