import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SafeGrid Cyberpunk Design System
class SG {
  SG._();

  // ─── Core palette ───────────────────────────────────────────────
  static const Color bg        = Color(0xFF060D1A);
  static const Color surface   = Color(0xFF0C1829);
  static const Color card      = Color(0xFF111F33);
  static const Color border    = Color(0xFF1B2E4A);

  // Neon accents
  static const Color cyan      = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF39FF14);
  static const Color amber     = Color(0xFFFFAB00);
  static const Color neonRed   = Color(0xFFFF1744);
  static const Color neonPurple= Color(0xFFD500F9);
  static const Color neonBlue  = Color(0xFF2979FF);

  // Semantic
  static const Color safe      = Color(0xFF00E676);
  static const Color warning   = Color(0xFFFF9100);
  static const Color danger    = Color(0xFFFF1744);
  static const Color info      = Color(0xFF00B0FF);
  static const Color muted     = Color(0xFF546E7A);

  // ─── Typography ─────────────────────────────────────────────────
  static TextStyle heading(double size, {Color color = Colors.white, FontWeight weight = FontWeight.w700}) =>
      GoogleFonts.rajdhani(fontSize: size, fontWeight: weight, color: color, letterSpacing: 1.2);

  static TextStyle body(double size, {Color color = Colors.white70, FontWeight weight = FontWeight.w400}) =>
      GoogleFonts.inter(fontSize: size, fontWeight: weight, color: color, height: 1.5);

  static TextStyle mono(double size, {Color color = Colors.white70}) =>
      GoogleFonts.firaCode(fontSize: size, color: color, fontWeight: FontWeight.w400);

  // ─── Decorations ────────────────────────────────────────────────

  /// Glassmorphism card with neon border
  static BoxDecoration glass({Color glow = cyan, double glowOpacity = 0.15, double borderOpacity = 0.4, double radius = 16}) {
    return BoxDecoration(
      color: card.withOpacity(0.7),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: glow.withOpacity(borderOpacity), width: 1.5),
      boxShadow: [
        BoxShadow(color: glow.withOpacity(glowOpacity), blurRadius: 24, spreadRadius: 0),
      ],
    );
  }

  /// Neon glowing border decoration
  static BoxDecoration neonBorder(Color color, {double radius = 12, double width = 2}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: color.withOpacity(0.6), width: width),
      boxShadow: [
        BoxShadow(color: color.withOpacity(0.2), blurRadius: 16, spreadRadius: 0),
        BoxShadow(color: color.withOpacity(0.05), blurRadius: 40, spreadRadius: 4),
      ],
    );
  }

  /// Full ThemeData for the app
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cyan,
        brightness: Brightness.dark,
        surface: surface,
      ),
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: surface,
        titleTextStyle: heading(20, color: cyan),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border, width: 1),
        ),
      ),
      dividerColor: border,
      textTheme: TextTheme(
        headlineLarge: heading(32),
        headlineMedium: heading(26),
        headlineSmall: heading(22),
        titleLarge: heading(20),
        titleMedium: heading(18),
        bodyLarge: body(16),
        bodyMedium: body(14),
        bodySmall: body(12, color: Colors.white54),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: cyan.withOpacity(0.15),
          foregroundColor: cyan,
          side: BorderSide(color: cyan.withOpacity(0.4)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: heading(14),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cyan.withOpacity(0.15),
          foregroundColor: cyan,
          elevation: 0,
          side: BorderSide(color: cyan.withOpacity(0.3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          textStyle: heading(13),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cyan.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cyan, width: 2),
        ),
        labelStyle: body(14, color: Colors.white54),
        prefixIconColor: cyan.withOpacity(0.7),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: cyan.withOpacity(0.2)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: body(14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Animated neon glow container used across the app
class NeonGlowBox extends StatefulWidget {
  final Widget child;
  final Color color;
  final double radius;
  final double intensity;
  final bool animate;

  const NeonGlowBox({
    super.key,
    required this.child,
    this.color = SG.cyan,
    this.radius = 16,
    this.intensity = 0.3,
    this.animate = true,
  });

  @override
  State<NeonGlowBox> createState() => _NeonGlowBoxState();
}

class _NeonGlowBoxState extends State<NeonGlowBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.1, end: widget.intensity)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.animate) {
      return Container(
        decoration: SG.glass(glow: widget.color, glowOpacity: widget.intensity, radius: widget.radius),
        child: widget.child,
      );
    }
    return AnimatedBuilder(
      animation: _anim,
      builder: (context, child) {
        return Container(
          decoration: SG.glass(glow: widget.color, glowOpacity: _anim.value, radius: widget.radius),
          child: widget.child,
        );
      },
    );
  }
}

/// Scan-line overlay effect for that CRT/cyber feel
class ScanLinesOverlay extends StatelessWidget {
  final double opacity;
  const ScanLinesOverlay({super.key, this.opacity = 0.03});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ScanLinesPainter(opacity: opacity),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanLinesPainter extends CustomPainter {
  final double opacity;
  _ScanLinesPainter({required this.opacity});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(opacity)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += 3) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Pulsing dot indicator
class PulsingDot extends StatefulWidget {
  final Color color;
  final double size;
  const PulsingDot({super.key, required this.color, this.size = 10});

  @override
  State<PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.4 + _ctrl.value * 0.4),
                blurRadius: 6 + _ctrl.value * 8,
                spreadRadius: _ctrl.value * 3,
              ),
            ],
          ),
        );
      },
    );
  }
}
