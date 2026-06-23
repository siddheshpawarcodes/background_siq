import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../router/app_router.dart';

/// Animated launch screen, played as two sequential beats:
///  1. A colored circle blooms from the center and grows until it fully fills
///     the entire screen (a circular reveal).
///  2. Only once the screen is filled does the firefly logo rise slowly from
///     the bottom and pop into the center, on top of the filled background.
///
/// When the sequence finishes the screen replaces itself with the home route.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  /// Logo shown on the splash — the firefly extracted onto a transparent
  /// background so it floats over the growing color (no tile around it).
  static const String _logoAsset = 'assets/icon/firefly_logo.png';

  /// Color the screen starts on, before the circular reveal (icon backdrop).
  static const Color _baseColor = Color(0xFF0E2A3A);

  /// Color the growing circle paints — it fills the screen by the end (brand
  /// seed, mirrors [AppTheme]).
  static const Color _revealColor = Color(0xFF2E6CF6);

  late final AnimationController _controller;
  late final Animation<double> _circle; // 0 -> 1 reveal progress
  late final Animation<double> _logoSlide; // 1 (below) -> 0 (in place)
  late final Animation<double> _logoFade; // 0 -> 1
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    );

    // Beat 1: the circle blooms and FULLY fills the screen over the first 45%
    // of the timeline. easeInOutCubic ramps in and settles out so there's no
    // abrupt start or hard stop — a smooth expansion.
    _circle = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeInOutCubic),
    );
    // Beat 2: only after the circle has filled (starts at 50%) does the bee
    // rise from the bottom — a long, slow glide with a gentle overshoot so it
    // "pops" as it settles into the center.
    _logoSlide = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.50, 0.92, curve: Curves.easeOutBack),
      ),
    );
    _logoFade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.50, 0.70, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        context.go(Routes.home);
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // Respect the OS "reduce motion" setting: collapse the animation so the
    // status listener still fires and we move on to home promptly.
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _controller.duration = const Duration(milliseconds: 1);
    }
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    // Diameter the circle needs to fully cover the screen from its center: the
    // screen's diagonal (center-to-corner distance is half of this).
    final maxDiameter = math.sqrt(size.width * size.width + size.height * size.height);

    return ColoredBox(
      color: _baseColor,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              // (1) The expanding circle of color, beneath the logo.
              Center(
                child: Container(
                  width: maxDiameter * _circle.value,
                  height: maxDiameter * _circle.value,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: _revealColor,
                  ),
                ),
              ),
              // (2) The logo, rising from the bottom and fading in, on top.
              Center(
                child: Transform.translate(
                  offset: Offset(0, _logoSlide.value * size.height * 0.55),
                  child: Opacity(
                    opacity: _logoFade.value.clamp(0.0, 1.0),
                    child: const _SplashLogo(asset: _logoAsset),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The transparent firefly logo, floating with a soft warm glow behind it so
/// it reads cleanly against the reveal color.
class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.asset});

  final String asset;

  @override
  Widget build(BuildContext context) {
    const double dimension = 200;
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFCA62).withValues(alpha: 0.30),
            blurRadius: 48,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Image.asset(
        asset,
        width: dimension,
        height: dimension,
        fit: BoxFit.contain,
      ),
    );
  }
}
