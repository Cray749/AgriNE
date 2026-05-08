/// AgriSutra NE — App Entry Point
/// =================================
/// Sets up:
///   1. ThemeProvider (light/dark toggle, persisted to SharedPreferences)
///   2. Global theme (from core/theme.dart)
///   3. Named route table (all 7 screens)

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/login_screen.dart';
import 'screens/profile_setup_screen.dart';
import 'screens/input_wizard_screen.dart';
import 'screens/results_screen.dart';
import 'screens/farmer_profile_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait — farmers hold phones upright
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Status bar styling is handled dynamically per theme in AgriSutraApp
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const AgriSutraApp(),
    ),
  );
}

class AgriSutraApp extends StatelessWidget {
  const AgriSutraApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Update system UI bar colors to match the active theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            themeProvider.isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor:
            themeProvider.isDark ? kBgDark : kLightBgPrimary,
        systemNavigationBarIconBrightness:
            themeProvider.isDark ? Brightness.light : Brightness.dark,
      ),
    );

    return MaterialApp(
      title: 'AgriSutra NE',
      debugShowCheckedModeBanner: false,

      // Both themes defined — themeMode switches between them
      theme:     buildLightTheme(),
      darkTheme: buildAppTheme(),
      themeMode: themeProvider.isDark ? ThemeMode.dark : ThemeMode.light,

      initialRoute: '/',

      routes: {
        '/':               (ctx) => const SplashScreen(),
        '/landing':        (ctx) => const LandingScreen(),
        '/login':          (ctx) => const LoginScreen(),
        '/profile_setup':  (ctx) => const ProfileSetupScreen(),
        '/wizard':         (ctx) => const InputWizardScreen(),
        '/results':        (ctx) => const ResultsScreen(),
        '/farmer_profile': (ctx) => const FarmerProfileScreen(),
      },

      onUnknownRoute: (settings) => MaterialPageRoute(
        builder: (_) => _UnknownRouteScreen(routeName: settings.name ?? '?'),
      ),
    );
  }
}


// ════════════════════════════════════════════════════════════════════════════
//  FALLBACK SCREEN (unknown route)
// ════════════════════════════════════════════════════════════════════════════

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
