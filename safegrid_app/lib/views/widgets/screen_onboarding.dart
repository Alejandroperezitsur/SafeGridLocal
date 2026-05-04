import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          color: Colors.blueAccent.withOpacity(0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.help_outline, size: 12, color: Colors.blueAccent),
            const SizedBox(width: 4),
            Text(term, style: const TextStyle(fontSize: 11, color: Colors.blueAccent, fontWeight: FontWeight.bold, decoration: TextDecoration.underline, decorationStyle: TextDecorationStyle.dotted)),
          ],
        ),
      ),
    );
  }
}

/// Full-screen onboarding overlay shown the first time a user enters a screen.
/// It cycles through a list of [OnboardingSlide]s with animations.
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

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic));
    _checkIfShouldShow();
  }

  Future<void> _checkIfShouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    final seen = prefs.getStringList('seen_onboardings') ?? [];
    // Also update the provider for in-memory tracking
    ref.read(seenOnboardingsProvider.notifier).state = seen.toSet();
    if (!seen.contains(widget.screenKey)) {
      if (mounted) {
        setState(() => _show = true);
        _animController.forward();
      }
    }
  }

  Future<void> _dismiss() async {
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
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() => _currentSlide++);
          _animController.forward();
        }
      });
    } else {
      _dismiss();
    }
  }

  void _prevSlide() {
    if (_currentSlide > 0) {
      _animController.reverse().then((_) {
        if (mounted) {
          setState(() => _currentSlide--);
          _animController.forward();
        }
      });
    }
  }

  @override
  void dispose() {
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

    return FadeTransition(
      opacity: _fadeAnim,
      child: Material(
        color: Colors.black.withOpacity(0.75),
        child: Center(
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              margin: const EdgeInsets.all(24),
              constraints: BoxConstraints(
                maxWidth: 480,
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF101C2E),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: slide.color.withOpacity(0.6), width: 2),
                boxShadow: [
                  BoxShadow(color: slide.color.withOpacity(0.3), blurRadius: 30, spreadRadius: 2),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      color: slide.color.withOpacity(0.15),
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.school, color: slide.color, size: 22),
                        const SizedBox(width: 10),
                        Text(
                          'TUTORIAL (${_currentSlide + 1}/$total)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: slide.color, letterSpacing: 1),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _dismiss,
                          child: const Text('Saltar ✕', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                  // Body
                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Animated icon
                            TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.8, end: 1.0),
                              duration: const Duration(milliseconds: 600),
                              curve: Curves.elasticOut,
                              builder: (context, value, child) {
                                return Transform.scale(scale: value, child: child);
                              },
                              child: Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: slide.color.withOpacity(0.15),
                                  border: Border.all(color: slide.color.withOpacity(0.5), width: 2),
                                ),
                                child: Icon(slide.icon, size: 48, color: slide.color),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              slide.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              slide.body,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14, height: 1.6, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Progress dots
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(total, (i) {
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentSlide ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentSlide ? slide.color : Colors.grey.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        );
                      }),
                    ),
                  ),
                  // Navigation buttons
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _currentSlide > 0
                            ? TextButton.icon(
                                onPressed: _prevSlide,
                                icon: const Icon(Icons.arrow_back, size: 16),
                                label: const Text('Anterior'),
                              )
                            : const SizedBox(width: 100),
                        FilledButton.icon(
                          onPressed: _nextSlide,
                          style: FilledButton.styleFrom(
                            backgroundColor: slide.color,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                          icon: Icon(isLast ? Icons.check : Icons.arrow_forward, size: 18),
                          label: Text(isLast ? '¡Entendido!' : 'Siguiente'),
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
    );
  }
}
