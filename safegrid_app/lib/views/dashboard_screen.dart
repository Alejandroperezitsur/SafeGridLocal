import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../viewmodels/providers.dart';
import 'network_map_screen.dart';
import 'alerts_screen.dart';
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
    // Watch polling provider to trigger auto-refreshes
    ref.watch(dashboardRefreshProvider);
    
    final riskScore = ref.watch(riskScoreProvider);
    final user = ref.watch(currentUserProvider);
    
    Color riskColor = Colors.green;
    String riskText = 'Low Risk';
    if (riskScore >= 16) { 
      riskColor = Colors.redAccent; 
      riskText = 'High Risk'; 
    } else if (riskScore >= 6) { 
      riskColor = Colors.amber; 
      riskText = 'Medium Risk'; 
    }

    final pages = [
      const NetworkMapScreen(),
      const AlertsScreen(),
      const CriticalInfraScreen(),
      const EducationalScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeGrid Local Control Center'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Logged in as: ${user?.name} (${user?.role})',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
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
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulated Attack Initiated!'), backgroundColor: Colors.red));
                  } catch(e) { /* ignore */ }
                },
                icon: const Icon(Icons.dangerous, color: Colors.white),
                label: const Text('Simulate Attack', style: TextStyle(color: Colors.white)),
              ),
            ),
          if (user?.role == 'admin')
            IconButton(
              tooltip: 'Reset Simulation',
              icon: const Icon(Icons.cloud_sync),
              onPressed: () async {
                await ref.read(dataRepoProvider).resetSimulation(user!.role);
                if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simulation Reset')));
              },
            ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          // Global Risk Header
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            color: riskColor.withOpacity(0.15),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security, color: riskColor, size: 48),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(riskText, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: riskColor, fontWeight: FontWeight.bold)),
                    Text('Global Risk Score: $riskScore', style: Theme.of(context).textTheme.bodyLarge),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: pages[_currentIndex],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(()=> _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.hub), label: 'Network Map'),
          BottomNavigationBarItem(icon: Icon(Icons.warning_amber), label: 'Alerts'),
          BottomNavigationBarItem(icon: Icon(Icons.precision_manufacturing), label: 'Critical Infra'),
          BottomNavigationBarItem(icon: Icon(Icons.school), label: 'Education'),
        ],
      ),
    );
  }
}
