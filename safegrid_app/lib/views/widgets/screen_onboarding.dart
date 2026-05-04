import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:animate_do/animate_do.dart';
import '../../core/theme.dart';

/// Stores which screen onboardings the user has already seen.
final seenOnboardingsProvider = StateProvider<Set<String>>((ref) => {});

/// Model for a single onboarding slide.
class OnboardingSlide {
  final String title;
  final String body;
  final IconData icon;
  final Color color;

  const OnboardingSlide({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
  });
}

/// A glossary-tooltip chip that can be placed inline to explain jargon.
class GlossaryChip extends StatelessWidget {
  final String term;
  final String definition;
  final String? analogy;

  const GlossaryChip({
    super.key,
    required this.term,
    required this.definition,
    this.analogy,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      richMessage: TextSpan(
        children: [
          TextSpan(text: '$term\n', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          TextSpan(text: definition, style: const TextStyle(fontSize: 12)),
          if (analogy != null) ...[
            const TextSpan(text: '\n\n💡 '),
            TextSpan(text: analogy!, style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
          ],
        ],
      ),
      showDuration: const Duration(seconds: 8),
      waitDuration: Duration.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: SG.cyan.withOpacity(0.1),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: SG.cyan.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.help_outline_rounded, size: 12, color: SG.cyan),
            const SizedBox(width: 4),
            Text(term, style: SG.mono(10, color: SG.cyan)),
          ],
        ),
      ),
    );
  }
}

/// Full-screen onboarding overlay shown the first time a user enters a screen.
/// Styled as a "Mission Briefing" with typing animations and tactical aesthetics.
class ScreenOnboarding extends ConsumerStatefulWidget {
  final String screenKey;
  final List<OnboardingSlide> slides;
  final Widget child;

  const ScreenOnboarding({
    super.key,
    required this.screenKey,
    required this.slides,
    required this.child,
  });

  @override
  ConsumerState<ScreenOnboarding> createState() => _ScreenOnboardingState();
}

class _ScreenOnboardingState extends ConsumerState<ScreenOnboarding> with SingleTickerProviderStateMixin {
  bool _show = false;
  int _currentSlide = 0;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  // Typing animation
  String _displayedBody = '';
  Timer? _typingTimer;
  bool _typingComplete = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _checkIfShouldShow();
  }

  Future<void> _checkIfShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList('seen_onboardings') ?? [];
    ref.read(seenOnboardingsProvider.notifier).state = seen.toSet();
    if (!seen.contains(widget.screenKey)) {
      if (mounted) {
        setState(() => _show = true);
        _animController.forward();
        _startTyping();
      }
    }
  }

  void _startTyping() {
    _typingTimer?.cancel();
    _displayedBody = '';
    _typingComplete = false;
    final fullBody = widget.slides[_currentSlide].body;
    int charIndex = 0;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 12), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (charIndex < fullBody.length) {
        setState(() {
          // Add 2 chars at a time for speed
          final end = (charIndex + 2).clamp(0, fullBody.length);
          _displayedBody = fullBody.substring(0, end);
          charIndex = end;
        });
      } else {
        timer.cancel();
        if (mounted) setState(() => _typingComplete = true);
      }
    });
  }

  void _skipTyping() {
    _typingTimer?.cancel();
    setState(() {
      _displayedBody = widget.slides[_currentSlide].body;
      _typingComplete = true;
    });
  }

  Future<void> _dismiss() async {
    _typingTimer?.cancel();
    await _animController.reverse();
    if (mounted) {
      setState(() => _show = false);
    }
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList('seen_onboardings') ?? [];
    seen.add(widget.screenKey);
    await prefs.setStringList('seen_onboardings', seen);
    ref.read(seenOnboardingsProvider.notifier).state = seen.toSet();
  }

  void _nextSlide() {
    if (_currentSlide < widget.slides.length - 1) {
      _typingTimer?.cancel();
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() => _currentSlide++);
          _animController.forward();
          _startTyping();
        }
      });
    } else {
      _dismiss();
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      _typingTimer?.cancel();
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() => _currentSlide--);
          _animController.forward();
          _startTyping();
        }
      });
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_show) _buildOverlay(),
      ],
    );
  }

  Widget _buildOverlay() {
    final slide = widget.slides[_currentSlide];
    final isLast = _currentSlide == widget.slides.length - 1;
    final total = widget.slides.length;
    final progress = (_currentSlide + 1) / total;

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.black.withOpacity(0.85),
        child: Stack(
          children: [
            // Scan lines overlay on the briefing
            const ScanLinesOverlay(opacity: 0.02),
            Center(
              child: SlideTransition(
                position: _slideAnim,
                child: Container(
                  margin: const EdgeInsets.all(24),
                  constraints: BoxConstraints(
                    maxWidth: 520,
                    maxHeight: MediaQuery.of(context).size.height * 0.85,
                  ),
                  decoration: BoxDecoration(
                    color: SG.card.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: slide.color.withOpacity(0.5), width: 1.5),
                    boxShadow: [
                      BoxShadow(color: slide.color.withOpacity(0.15), blurRadius: 40, spreadRadius: 2),
                      BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 30),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ─── Header: MISSION BRIEFING ───
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              slide.color.withOpacity(0.15),
                              slide.color.withOpacity(0.05),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                          border: Border(bottom: BorderSide(color: slide.color.withOpacity(0.2))),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: slide.color.withOpacity(0.5)),
                              ),
                              child: Icon(Icons.radar_rounded, color: slide.color, size: 16),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'BRIEFING DE MISIÓN',
                                  style: SG.heading(12, color: slide.color),
                                ),
                                Text(
                                  'MÓDULO ${_currentSlide + 1} DE $total',
                                  style: SG.mono(9, color: slide.color.withOpacity(0.6)),
                                ),
                              ],
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: _dismiss,
                              icon: Icon(Icons.close_rounded, size: 14, color: Colors.white.withOpacity(0.38)),
                              label: Text('SALTAR', style: SG.mono(10, color: Colors.white.withOpacity(0.38))),
                            ),
                          ],
                        ),
                      ),

                      // ─── Progress bar ───
                      Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: Stack(
                            children: [
                              Container(color: Colors.white.withOpacity(0.05)),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                curve: Curves.easeOut,
                                width: MediaQuery.of(context).size.width * progress * 0.6,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [slide.color.withOpacity(0.3), slide.color],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: [BoxShadow(color: slide.color.withOpacity(0.5), blurRadius: 6)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── Body ───
                      Flexible(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(28, 24, 28, 8),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Animated icon with ring
                              _AnimatedBriefingIcon(
                                icon: slide.icon,
                                color: slide.color,
                              ),
                              const SizedBox(height: 24),
                              // Title
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: SG.heading(22, color: Colors.white),
                              ),
                              const SizedBox(height: 16),
                              // Typing body text
                              GestureDetector(
                                onTap: _typingComplete ? null : _skipTyping,
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: SG.surface.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: SG.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.terminal_rounded, size: 12, color: slide.color.withOpacity(0.6)),
                                          const SizedBox(width: 6),
                                          Text('intel_report.log', style: SG.mono(9, color: slide.color.withOpacity(0.5))),
                                          const Spacer(),
                                          if (!_typingComplete)
                                            Text('▸ toca para saltar', style: SG.mono(8, color: Colors.white.withOpacity(0.2))),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        _displayedBody + (_typingComplete ? '' : '▌'),
                                        style: SG.body(14, color: Colors.white.withOpacity(0.6)),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // ─── Navigation ───
                      Container(
                        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _currentSlide > 0
                                ? TextButton.icon(
                                    onPressed: _prevSlide,
                                    icon: Icon(Icons.arrow_back_rounded, size: 16, color: Colors.white54),
                                    label: Text('ANTERIOR', style: SG.heading(12, color: Colors.white54)),
                                  )
                                : const SizedBox(width: 100),
                            // Slide indicator dots
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(total, (i) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 3),
                                  width: i == _currentSlide ? 20 : 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: i == _currentSlide
                                        ? slide.color
                                        : Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: i == _currentSlide
                                        ? [BoxShadow(color: slide.color.withOpacity(0.4), blurRadius: 8)]
                                        : null,
                                  ),
                                );
                              }),
                            ),
                            // Next/Finish button
                            Container(
                              decoration: SG.neonBorder(slide.color, radius: 10, width: 1),
                              child: FilledButton.icon(
                                onPressed: _nextSlide,
                                style: FilledButton.styleFrom(
                                  backgroundColor: slide.color.withOpacity(0.15),
                                  foregroundColor: slide.color,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                icon: Icon(
                                  isLast ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
                                  size: 18,
                                ),
                                label: Text(
                                  isLast ? 'ENTENDIDO' : 'SIGUIENTE',
                                  style: SG.heading(12, color: slide.color),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated icon with expanding ring for briefing slides
class _AnimatedBriefingIcon extends StatefulWidget {
  final IconData icon;
  final Color color;
  const _AnimatedBriefingIcon({required this.icon, required this.color});

  @override
  State<_AnimatedBriefingIcon> createState() => _AnimatedBriefingIconState();
}

class _AnimatedBriefingIconState extends State<_AnimatedBriefingIcon> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
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
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: widget.color.withOpacity(0.2 + _ctrl.value * 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: widget.color.withOpacity(0.05 + _ctrl.value * 0.15),
                blurRadius: 20 + _ctrl.value * 20,
                spreadRadius: _ctrl.value * 8,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.color.withOpacity(0.1),
              border: Border.all(color: widget.color.withOpacity(0.3), width: 1),
            ),
            child: Icon(
              widget.icon,
              size: 40,
              color: widget.color,
            ),
          ),
        );
      },
    );
  }
}
