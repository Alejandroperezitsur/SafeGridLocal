import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'views/login_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/network_map_screen.dart';
import 'views/incidents_screen.dart';
import 'views/critical_infra_screen.dart';
import 'viewmodels/providers.dart';
import 'views/widgets/educational_widgets.dart';

void main() {
  runApp(const ProviderScope(child: SafeGridApp()));
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainLayout(),
      ),
    ],
  );
});

class SafeGridApp extends ConsumerWidget {
  const SafeGridApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'SafeGrid Local',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0A192F),
          brightness: Brightness.dark,
        ),
        appBarTheme: const AppBarTheme(centerTitle: true, elevation: 0),
      ),
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    NetworkMapScreen(),
    IncidentsScreen(),
    CriticalInfraScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(dashboardRefreshProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final isLearningMode = ref.watch(learningModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('SafeGrid Control Center', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          Row(
            children: [
              TextButton.icon(
                icon: const Icon(Icons.psychology, color: Colors.blueAccent),
                label: const Text('Explicación simple', style: TextStyle(color: Colors.blueAccent)),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('💡 Explicación simple'),
                      content: const Text('Un ransomware es un virus que bloquea sistemas y exige un rescate. Aquí estamos simulando cómo se propaga desde las computadoras (IT) hasta las máquinas físicas de la fábrica (OT).'),
                      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Entendido'))],
                    )
                  );
                },
              ),
            ],
          ),
          IconButton(
            tooltip: 'Iniciar Guía Paso a Paso',
            icon: const Icon(Icons.menu_book, color: Colors.blueAccent),
            onPressed: () {
              ref.read(demoStepProvider.notifier).state = 0;
              ref.read(isDemoActiveProvider.notifier).state = true;
            },
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: () => context.go('/login')),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const InsightPanel(),
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop)
                      NavigationRail(
                        backgroundColor: const Color(0xFF0F2537),
                        selectedIndex: _currentIndex,
                        onDestinationSelected: (index) => setState(() => _currentIndex = index),
                        extended: MediaQuery.of(context).size.width >= 1000,
                        labelType: MediaQuery.of(context).size.width >= 1000 ? NavigationRailLabelType.none : NavigationRailLabelType.all,
                        destinations: const [
                          NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                          NavigationRailDestination(icon: Icon(Icons.account_tree), label: Text('Red / Purdue')),
                          NavigationRailDestination(icon: Icon(Icons.security), label: Text('Incidentes')),
                          NavigationRailDestination(icon: Icon(Icons.factory), label: Text('Infraestructura')),
                        ],
                      ),
                    if (isDesktop) const VerticalDivider(thickness: 1, width: 1),
                    Expanded(child: _screens[_currentIndex]),
                  ],
                ),
              ),
            ],
          ),
          const TutorialOverlay(),
        ],
      ),
      floatingActionButton: isDesktop ? null : FloatingActionButton.extended(
        onPressed: () async {
          final user = ref.read(currentUserProvider);
          if (user != null && user.role == 'admin') {
            await ref.read(dataRepoProvider).simulateAttack(user.role);
          }
        },
        backgroundColor: Colors.redAccent,
        icon: const Icon(Icons.warning_amber),
        label: const Text('Simular ataque'),
      ),
      bottomNavigationBar: isDesktop ? null : BottomNavigationBar(
        currentIndex: _currentIndex > 2 ? 0 : _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0F2537),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree), label: 'Red'),
          BottomNavigationBarItem(icon: Icon(Icons.security), label: 'Incidentes'),
        ],
      ),
    );
  }
}
