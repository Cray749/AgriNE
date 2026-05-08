/// AgriSutra NE — Screen 1: Splash Screen
/// ==========================================
/// Shows for ~2.5s while the app initialises.
/// Checks SharedPreferences to decide where to route:
///   - farmer_name present → returning user → /wizard
///   - no farmer_name      → new user       → /landing
///
/// No Lottie dependency needed — uses a custom _BouncingDots widget
/// so the screen works even before the assets folder is populated.
/// When you add assets/animations/loading_plant.json, swap _BouncingDots
/// for the Lottie.asset() call shown in the comment below.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {

  // ── Logo: fade-in + slide-up ─────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final Animation<double>   _logoFade;
  late final Animation<Offset>   _logoSlide;

  // ── Pulse ring that radiates from the logo ───────────────────────────────
  late final AnimationController _pulseCtrl;
  late final Animation<double>   _pulseScale;
  late final Animation<double>   _pulseFade;

  // ── Text: staggered fade-in after logo ──────────────────────────────────
  late final AnimationController _textCtrl;
  late final Animation<double>   _titleFade;
  late final Animation<double>   _taglineFade;

  @override
  void initState() {
    super.initState();

    // Logo animates in over 800ms
    _logoCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _logoFade  = CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut);
    _logoSlide = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOutCubic));

    // Pulse ring repeats forever
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat();
    _pulseScale   = Tween<double>(begin: 0.82, end: 1.5)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeOut));
    _pulseFade = Tween<double>(begin: 0.5, end: 0.0)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeIn));

    // Text fades in with a 400ms stagger
    _textCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));
    _titleFade   = CurvedAnimation(
        parent: _textCtrl, curve: const Interval(0.0, 0.6, curve: Curves.easeOut));
    _taglineFade = CurvedAnimation(
        parent: _textCtrl, curve: const Interval(0.4, 1.0, curve: Curves.easeOut));

    // Start animation sequence
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 350), () { if (mounted) _textCtrl.forward(); });

    _checkAndRoute();
  }

  Future<void> _checkAndRoute() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    final prefs      = await SharedPreferences.getInstance();
    final hasProfile = prefs.getString('farmer_name') != null;

    if (!mounted) return;
    Navigator.pushReplacementNamed(context, hasProfile ? '/wizard' : '/landing');
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _pulseCtrl.dispose();
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [

          // ── Ambient radial glow in screen centre ─────────────────────────
          Positioned.fill(
            child: FadeTransition(
              opacity: _logoFade,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 0.7,
                    colors: [
                      kGreenPrimary.withOpacity(0.22),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Centre content column ─────────────────────────────────────────
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // Logo with radiating pulse ring
                SizedBox(
                  width: 130,
                  height: 130,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse ring
                      AnimatedBuilder(
                        animation: _pulseCtrl,
                        builder: (_, __) => Opacity(
                          opacity: _pulseFade.value,
                          child: Transform.scale(
                            scale: _pulseScale.value,
                            child: Container(
                              width: 96,
                              height: 96,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: kGreenAccent, width: 2),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ICAR Logo circle (white bg so the logo is clearly visible)
                      SlideTransition(
                        position: _logoSlide,
                        child: FadeTransition(
                          opacity: _logoFade,
                          child: Container(
                            width: 96,
                            height: 96,
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              border: Border.all(
                                  color: kGreenAccent.withOpacity(0.65), width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: kGreenAccent.withOpacity(0.30),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(10),
                              child: Image.asset(
                                'assets/images/icar_logo.png',
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Icon(
                                  Icons.eco_rounded,
                                  color: kGreenAccent,
                                  size: 46,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                kGapL,

                // App name
                FadeTransition(
                  opacity: _titleFade,
                  child: Text(
                    'AgriSutra NE',
                    style: kStyleHeadingXL.copyWith(
                      color: kGreenAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                kGapS,

                // Tagline
                FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Smart Farming, Northeast India',
                    style: kStyleBodyM,
                    textAlign: TextAlign.center,
                  ),
                ),

                const SizedBox(height: 52),

                // Loading indicator
                // ── TODO (Phase 2): replace with Lottie ──────────────────
                // Lottie.asset('assets/animations/loading_plant.json',
                //   width: 100, height: 100, repeat: true)
                FadeTransition(
                  opacity: _taglineFade,
                  child: const _BouncingDots(),
                ),
              ],
            ),
          ),

          // ── Version badge pinned to bottom ────────────────────────────────
          Positioned(
            bottom: 40, left: 0, right: 0,
            child: FadeTransition(
              opacity: _taglineFade,
              child: Text(
                'v1.0 · STCR Method',
                style: kStyleLabel,
                textAlign: TextAlign.center,
              ),
            ),
          ),

        ],
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  Three bouncing mint dots — placeholder for loading_plant.json Lottie
// ════════════════════════════════════════════════════════════════════════════

class _BouncingDots extends StatefulWidget {
  const _BouncingDots();
  @override
  State<_BouncingDots> createState() => _BouncingDotsState();
}

class _BouncingDotsState extends State<_BouncingDots> with TickerProviderStateMixin {
  final List<AnimationController> _ctrls = [];
  final List<Animation<double>>   _anims = [];

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < 3; i++) {
      final c = AnimationController(vsync: this, duration: const Duration(milliseconds: 580));
      final a = Tween<double>(begin: 0, end: -11)
          .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut));
      _ctrls.add(c);
      _anims.add(a);
      Future.delayed(Duration(milliseconds: i * 190), () { if (mounted) c.repeat(reverse: true); });
    }
  }

  @override
  void dispose() {
    for (final c in _ctrls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => AnimatedBuilder(
        animation: _anims[i],
        builder: (_, __) => Transform.translate(
          offset: Offset(0, _anims[i].value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 9, height: 9,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: kGreenAccent,
            ),
          ),
        ),
      )),
    );
  }
}
