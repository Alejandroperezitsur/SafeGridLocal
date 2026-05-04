import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import 'core/theme.dart';
import 'views/login_screen.dart';
import 'views/dashboard_screen.dart';
import 'views/network_map_screen.dart';
import 'views/incidents_screen.dart';
import 'views/critical_infra_screen.dart';
import 'viewmodels/providers.dart';
import 'views/widgets/educational_widgets.dart';
import 'views/widgets/screen_onboarding.dart';

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
      theme: SG.theme,
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

class _MainLayoutState extends ConsumerState<MainLayout> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late AnimationController _pulseCtrl;

  final List<Widget> _screens = const [
    DashboardScreen(),
    NetworkMapScreen(),
    IncidentsScreen(),
    CriticalInfraScreen(),
  ];

  static const _navItems = [
    _NavItem(Icons.dashboard_rounded, 'Dashboard', 'Centro de Comando'),
    _NavItem(Icons.account_tree_rounded, 'Red / Purdue', 'Mapa Táctico'),
    _NavItem(Icons.security_rounded, 'Incidentes', 'Sala SOC'),
    _NavItem(Icons.factory_rounded, 'Infraestructura', 'Control de Planta'),
  ];

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dashboardRefreshProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 800;
    final riskScore = ref.watch(riskScoreProvider);
    final isUnderAttack = riskScore >= 16;

    // Listen for FULL MISSION SUCCESS (Risk 0 + Systems OK + Devices Reconnected)
    ref.listen(missionAccomplishedProvider, (prev, next) {
      if (next == true) {
        ref.read(showSuccessOverlayProvider.notifier).state = true;
      }
    });

    return Scaffold(
      appBar: _buildAppBar(context, isUnderAttack),
      body: Stack(
        children: [
          // Subtle scan lines overlay
          const ScanLinesOverlay(opacity: 0.015),
          Column(
            children: [
              const InsightPanel(),
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop) _buildNavRail(context, isUnderAttack),
                    if (isDesktop)
                      Container(
                        width: 1,
                        color: isUnderAttack
                            ? SG.danger.withOpacity(0.3)
                            : SG.border,
                      ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        switchInCurve: Curves.easeOut,
                        switchOutCurve: Curves.easeIn,
                        child: KeyedSubtree(
                          key: ValueKey(_currentIndex),
                          child: _screens[_currentIndex],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const TutorialOverlay(),
          const SuccessOverlay(),
        ],
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                if (user != null && user.role == 'admin') {
                  await ref.read(dataRepoProvider).simulateAttack(user.role);
                }
              },
              backgroundColor: SG.danger,
              icon: const Icon(Icons.warning_amber_rounded),
              label: Text('Simular ataque', style: SG.heading(13, color: Colors.white)),
            ),
      bottomNavigationBar: isDesktop
          ? null
          : _buildBottomNav(isUnderAttack),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, bool isUnderAttack) {
    return AppBar(
      backgroundColor: isUnderAttack
          ? SG.danger.withOpacity(0.08)
          : SG.surface,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseCtrl,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (isUnderAttack ? SG.danger : SG.cyan)
                          .withOpacity(0.2 + _pulseCtrl.value * 0.3),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.shield_rounded,
                  color: isUnderAttack ? SG.danger : SG.cyan,
                  size: 24,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Text(
            'SAFEGRID',
            style: SG.heading(20, color: isUnderAttack ? SG.danger : SG.cyan),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: (isUnderAttack ? SG.danger : SG.cyan).withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: (isUnderAttack ? SG.danger : SG.cyan).withOpacity(0.3),
              ),
            ),
            child: Text(
              isUnderAttack ? 'ALERTA' : 'ONLINE',
              style: SG.mono(9, color: isUnderAttack ? SG.danger : SG.safe),
            ),
          ),
        ],
      ),
      bottom: isUnderAttack
          ? PreferredSize(
              preferredSize: const Size.fromHeight(3),
              child: AnimatedBuilder(
                animation: _pulseCtrl,
                builder: (context, _) {
                  return Container(
                    height: 3,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          SG.danger.withOpacity(_pulseCtrl.value * 0.8),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          : null,
      actions: [
        // Simple explanation button
        IconButton(
          tooltip: 'Explicación simple',
          icon: Icon(Icons.psychology_rounded, color: SG.cyan.withOpacity(0.7), size: 20),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Row(children: [
                  Icon(Icons.lightbulb_rounded, color: SG.amber),
                  const SizedBox(width: 8),
                  Text('Explicación Simple', style: SG.heading(18)),
                ]),
                content: Text(
                  'Un ransomware es un virus que bloquea sistemas y exige un rescate. Aquí estamos simulando cómo se propaga desde las computadoras (IT) hasta las máquinas físicas de la fábrica (OT).',
                  style: SG.body(14),
                ),
                actions: [
                  FilledButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Entendido', style: SG.heading(13, color: SG.cyan)),
                  ),
                ],
              ),
            );
          },
        ),
        // Step-by-step guide
        IconButton(
          tooltip: 'Iniciar Guía Paso a Paso',
          icon: Icon(Icons.menu_book_rounded, color: SG.cyan.withOpacity(0.7), size: 20),
          onPressed: () {
            ref.read(demoStepProvider.notifier).state = 0;
            ref.read(isDemoActiveProvider.notifier).state = true;
          },
        ),
        // Reset tutorials
        IconButton(
          tooltip: 'Repetir tutoriales de pantalla',
          icon: Icon(Icons.replay_rounded, color: SG.amber.withOpacity(0.7), size: 20),
          onPressed: () async {
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('seen_onboardings');
            ref.read(seenOnboardingsProvider.notifier).state = {};
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Tutoriales reiniciados. Navega a otra pestaña para verlos de nuevo.', style: SG.body(13)),
                  backgroundColor: SG.amber.withOpacity(0.2),
                ),
              );
            }
          },
        ),
        // Logout
        IconButton(
          tooltip: 'Cerrar sesión',
          icon: Icon(Icons.logout_rounded, color: Colors.white38, size: 20),
          onPressed: () => context.go('/login'),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildNavRail(BuildContext context, bool isUnderAttack) {
    final isExtended = MediaQuery.of(context).size.width >= 1000;

    return Container(
      width: isExtended ? 220 : 72,
      color: SG.surface.withOpacity(0.5),
      child: Column(
        children: [
          const SizedBox(height: 8),
          ...List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final isSelected = _currentIndex == index;
            final isAttackTab = isUnderAttack && (index == 1 || index == 2);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 8),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _currentIndex = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.symmetric(
                      horizontal: isExtended ? 16 : 12,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isSelected
                          ? SG.cyan.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? SG.cyan.withOpacity(0.4)
                            : Colors.transparent,
                        width: 1,
                      ),
                      boxShadow: isSelected
                          ? [BoxShadow(color: SG.cyan.withOpacity(0.1), blurRadius: 12)]
                          : null,
                    ),
                    child: Row(
                      mainAxisAlignment: isExtended
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.center,
                      children: [
                        Stack(
                          children: [
                            Icon(
                              item.icon,
                              color: isSelected
                                  ? SG.cyan
                                  : isAttackTab
                                      ? SG.danger
                                      : Colors.white38,
                              size: 22,
                            ),
                            if (isAttackTab)
                              Positioned(
                                right: -2,
                                top: -2,
                                child: PulsingDot(color: SG.danger, size: 8),
                              ),
                          ],
                        ),
                        if (isExtended) ...[
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.label,
                                  style: SG.heading(
                                    13,
                                    color: isSelected ? SG.cyan : Colors.white.withOpacity(0.6),
                                  ),
                                ),
                                Text(
                                  item.subtitle,
                                  style: SG.mono(9, color: Colors.white.withOpacity(0.3)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBottomNav(bool isUnderAttack) {
    return Container(
      decoration: BoxDecoration(
        color: SG.surface,
        border: Border(top: BorderSide(color: SG.border, width: 1)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex > 2 ? 0 : _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: SG.cyan,
        unselectedItemColor: Colors.white38,
        selectedLabelStyle: SG.mono(10),
        unselectedLabelStyle: SG.mono(9),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.account_tree_rounded), label: 'Red'),
          BottomNavigationBarItem(icon: Icon(Icons.security_rounded), label: 'Incidentes'),
        ],
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String subtitle;
  const _NavItem(this.icon, this.label, this.subtitle);
}
