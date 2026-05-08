/// AgriSutra NE — App Entry Point
/// =================================
/// Sets up:
///   1. Global theme (from core/theme.dart)
///   2. Named route table (all 6 screens)
///   3. Error widget for development (shows red border on widget errors)
///
/// Route table summary:
///   /              → SplashScreen    (auto-routes based on profile existence)
///   /landing       → LandingScreen   (first-time visitor, marketing page)
///   /login         → LoginScreen     (phone OTP — mock for Phase 1)
///   /profile_setup → ProfileSetupScreen (name + district + land size)
///   /wizard        → InputWizardScreen  (crop + soil + yield input, 3 pages)
///   /results       → ResultsScreen   (fertilizer prescription cards)
///
/// Arguments passing:
///   /results receives a RecommendResponse passed as Navigator argument:
///     Navigator.pushNamed(context, '/results', arguments: response)
///   ResultsScreen reads it via: ModalRoute.of(context)!.settings.arguments

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/input_wizard_screen.dart';
import 'screens/results_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait — the app's layout is portrait-first.
  // Farmers hold their phones upright. Landscape causes layout overflow on
  // cheap Android phones with small screens.
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Style the Android status bar to match the dark background.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: kBgDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const AgriSutraApp());
}

class AgriSutraApp extends StatelessWidget {
  const AgriSutraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // ── App metadata ──────────────────────────────────────────────────────
      title: 'AgriSutra NE',
      debugShowCheckedModeBanner: false, // Hide the red DEBUG ribbon

      // ── Theme ─────────────────────────────────────────────────────────────
      // buildAppTheme() is defined in core/theme.dart.
      // All colors, fonts, button styles, and input decoration come from there.
      theme: buildAppTheme(),

      // ── Initial route ─────────────────────────────────────────────────────
      // SplashScreen checks SharedPreferences and routes automatically.
      // Do NOT set home: and initialRoute: at the same time.
      initialRoute: '/',

      // ── Route table ───────────────────────────────────────────────────────
      routes: {
        '/':              (ctx) => const SplashScreen(),
        '/landing':       (ctx) => const LandingScreen(),
        '/login':         (ctx) => const LoginScreen(),
        '/profile_setup': (ctx) => const ProfileSetupScreen(),
        '/wizard':        (ctx) => const InputWizardScreen(),
        '/results':       (ctx) => const ResultsScreen(),
      },

      // ── Unknown route fallback ────────────────────────────────────────────
      // If navigation is ever called with a route that doesn't exist,
      // show a friendly error screen instead of a crash.
      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => _UnknownRouteScreen(routeName: settings.name ?? '?'),
      ),

      // ── Global page transitions ───────────────────────────────────────────
      // Default Material slide transition is fine. The flutter_animate package
      // adds micro-animations inside each screen (fade-in, slide-up cards).
      // No custom PageTransitionsTheme needed at this level.
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  FALLBACK SCREEN (unknown route)
// ════════════════════════════════════════════════════════════════════════════

/// Shown if Navigator is ever called with an unregistered route name.
/// This should never appear in production, but protects against typos during
/// development (e.g. Navigator.pushNamed(ctx, '/reults') with a typo).
class _UnknownRouteScreen extends StatelessWidget {
  final String routeName;
  const _UnknownRouteScreen({required this.routeName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      appBar: AppBar(
        title: const Text('Page Not Found'),
        backgroundColor: kBgDark,
      ),
      body: Padding(
        padding: kPaddingScreen,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: kError, size: 64),
            kGapL,
            Text(
              'Unknown route: "$routeName"',
              style: kStyleHeadingM,
              textAlign: TextAlign.center,
            ),
            kGapM,
            Text(
              'This is a development error. Please check your Navigator.pushNamed() calls.',
              style: kStyleBodyM,
              textAlign: TextAlign.center,
            ),
            kGapXL,
            ElevatedButton(
              onPressed: () => Navigator.pushReplacementNamed(context, '/'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    );
  }
}
