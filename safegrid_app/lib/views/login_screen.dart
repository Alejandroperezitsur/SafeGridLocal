import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../viewmodels/providers.dart';
import '../core/api_client.dart';
import '../core/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ipController = TextEditingController();
  bool _isLoading = false;
  bool _accessGranted = false;
  late AnimationController _gridCtrl;
  late AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _gridCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gridCtrl.dispose();
    _pulseCtrl.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _ipController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      String serverIp = _ipController.text.trim();
      if (serverIp.isEmpty) serverIp = '127.0.0.1';
      ApiClient.setServerIp(serverIp);

      final user = await ref.read(authRepoProvider).login(
            _usernameController.text,
            _passwordController.text,
          );
      if (user != null) {
        ref.read(currentUserProvider.notifier).state = user;
        if (mounted) {
          setState(() => _accessGranted = true);
          await Future.delayed(const Duration(milliseconds: 800));
          if (mounted) context.go('/dashboard');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error de conexión: Verifica tu IP y la red.\n$e', style: SG.body(13)),
            backgroundColor: SG.danger.withOpacity(0.3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated grid background
          AnimatedBuilder(
            animation: _gridCtrl,
            builder: (context, _) {
              return CustomPaint(
                painter: _CyberGridPainter(progress: _gridCtrl.value),
                size: Size.infinite,
              );
            },
          ),
          // Scan lines
          const ScanLinesOverlay(opacity: 0.02),
          // Radial gradient overlay
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  SG.bg.withOpacity(0.3),
                  SG.bg.withOpacity(0.95),
                ],
              ),
            ),
          ),
          // Login form
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: FadeInUp(
                duration: const Duration(milliseconds: 800),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    decoration: SG.glass(glow: _accessGranted ? SG.safe : SG.cyan, glowOpacity: 0.2),
                    child: Padding(
                      padding: const EdgeInsets.all(36),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Animated logo
                          AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) {
                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: (_accessGranted ? SG.safe : SG.cyan)
                                        .withOpacity(0.3 + _pulseCtrl.value * 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (_accessGranted ? SG.safe : SG.cyan)
                                          .withOpacity(0.1 + _pulseCtrl.value * 0.2),
                                      blurRadius: 24,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  _accessGranted ? Icons.check_circle_rounded : Icons.shield_rounded,
                                  size: 56,
                                  color: _accessGranted ? SG.safe : SG.cyan,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Title
                          FadeInDown(
                            delay: const Duration(milliseconds: 200),
                            child: Text(
                              'SAFEGRID',
                              style: SG.heading(32, color: SG.cyan),
                            ),
                          ),
                          const SizedBox(height: 4),
                          FadeInDown(
                            delay: const Duration(milliseconds: 400),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                color: SG.cyan.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: SG.cyan.withOpacity(0.2)),
                              ),
                              child: Text(
                                'MONITOR DE INFRAESTRUCTURA CRÍTICA',
                                style: SG.mono(10, color: SG.cyan.withOpacity(0.7)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Status indicator
                          if (_accessGranted)
                            FadeIn(
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 16),
                                decoration: BoxDecoration(
                                  color: SG.safe.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: SG.safe.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.verified_rounded, color: SG.safe, size: 20),
                                    const SizedBox(width: 8),
                                    Text('ACCESO CONCEDIDO', style: SG.heading(14, color: SG.safe)),
                                  ],
                                ),
                              ),
                            ),

                          // Demo Mode Banner
                          if (ApiClient.isDemo) ...[  
                            FadeIn(
                              delay: const Duration(milliseconds: 250),
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: SG.amber.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: SG.amber.withOpacity(0.35)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.science_rounded, color: SG.amber, size: 18),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        'MODO DEMO ACTIVO — No se requiere servidor local.',
                                        style: SG.mono(10, color: SG.amber),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                          // IP Field (hidden in demo mode)
                          if (!ApiClient.isDemo)
                            FadeInUp(
                              delay: const Duration(milliseconds: 300),
                              child: Column(
                                children: [
                                  TextField(
                                    controller: _ipController,
                                    style: SG.mono(14, color: Colors.white),
                                    decoration: InputDecoration(
                                      labelText: 'IP del Servidor',
                                      hintText: '192.168.1.100',
                                      hintStyle: SG.mono(13, color: Colors.white.withOpacity(0.2)),
                                      prefixIcon: Icon(Icons.dns_rounded, color: SG.cyan.withOpacity(0.5)),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                ],
                              ),
                            ),
                          // Username
                          FadeInUp(
                            delay: const Duration(milliseconds: 400),
                            child: TextField(
                              controller: _usernameController,
                              style: SG.mono(14, color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Usuario',
                                prefixIcon: Icon(Icons.person_rounded, color: SG.cyan.withOpacity(0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Password
                          FadeInUp(
                            delay: const Duration(milliseconds: 500),
                            child: TextField(
                              controller: _passwordController,
                              obscureText: true,
                              style: SG.mono(14, color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'Contraseña',
                                prefixIcon: Icon(Icons.lock_rounded, color: SG.cyan.withOpacity(0.5)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Login button
                          FadeInUp(
                            delay: const Duration(milliseconds: 600),
                            child: SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                decoration: SG.neonBorder(
                                  _accessGranted ? SG.safe : SG.cyan,
                                  radius: 12,
                                ),
                                child: FilledButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: (_accessGranted ? SG.safe : SG.cyan).withOpacity(0.15),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: _isLoading
                                      ? SizedBox(
                                          width: 22,
                                          height: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: SG.cyan,
                                          ),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.login_rounded, size: 20, color: _accessGranted ? SG.safe : SG.cyan),
                                            const SizedBox(width: 10),
                                            Text(
                                              'ACCEDER AL CENTRO DE CONTROL',
                                              style: SG.heading(14, color: _accessGranted ? SG.safe : SG.cyan),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Credentials hint
                          FadeIn(
                            delay: const Duration(milliseconds: 800),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: ApiClient.isDemo ? SG.cyan.withOpacity(0.05) : SG.surface,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: ApiClient.isDemo ? SG.cyan.withOpacity(0.25) : SG.border),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    ApiClient.isDemo ? '🔑  CREDENCIALES DE DEMO' : 'CREDENCIALES DE ACCESO',
                                    style: SG.mono(9, color: ApiClient.isDemo ? SG.cyan.withOpacity(0.8) : Colors.white.withOpacity(0.3)),
                                  ),
                                  const SizedBox(height: 6),
                                  if (ApiClient.isDemo) ...[
                                    _credRow('admin', 'admin123', 'Administrador'),
                                    const SizedBox(height: 3),
                                    _credRow('operator', 'op123', 'Operador'),
                                    const SizedBox(height: 3),
                                    _credRow('viewer', 'view123', 'Observador'),
                                  ] else
                                    Text('admin/admin123 · operator/op123 · viewer/view123',
                                        style: SG.mono(10, color: SG.cyan.withOpacity(0.5))),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          // Signature
                          FadeIn(
                            delay: const Duration(milliseconds: 900),
                            child: Column(
                              children: [
                                Text(
                                  'DESARROLLADO Y FIRMADO POR:',
                                  style: SG.mono(9, color: Colors.white.withOpacity(0.3)),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Alejandro Pérez Vázquez',
                                  style: SG.mono(11, color: SG.cyan).copyWith(fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _credRow(String user, String pass, String role) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(user, style: SG.mono(10, color: SG.cyan)),
        Text(pass, style: SG.mono(10, color: Colors.white54)),
        Text(role, style: SG.mono(9, color: Colors.white30)),
      ],
    );
  }
}

/// Animated cyber grid background painter
class _CyberGridPainter extends CustomPainter {
  final double progress;
  _CyberGridPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = SG.cyan.withOpacity(0.04)
      ..strokeWidth = 0.5;

    // Horizontal lines
    const spacing = 40.0;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    // Vertical lines
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Animated scan line
    final scanY = (progress * size.height * 1.2) % (size.height + 100) - 50;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.transparent,
          SG.cyan.withOpacity(0.08),
          SG.cyan.withOpacity(0.15),
          SG.cyan.withOpacity(0.08),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, scanY - 30, size.width, 60));
    canvas.drawRect(Rect.fromLTWH(0, scanY - 30, size.width, 60), scanPaint);

    // Floating nodes
    final rng = Random(42);
    final nodePaint = Paint()..color = SG.cyan.withOpacity(0.1);
    for (int i = 0; i < 12; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final radius = 2.0 + rng.nextDouble() * 3;
      final phase = (progress + i * 0.1) % 1.0;
      final opacity = (0.05 + sin(phase * pi * 2) * 0.08).clamp(0.0, 1.0);
      nodePaint.color = SG.cyan.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, nodePaint);
    }
  }

  @override
  bool shouldRepaint(_CyberGridPainter old) => old.progress != progress;
}
