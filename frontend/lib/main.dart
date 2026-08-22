import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Mark onboarding as completed for demo build
  try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (!prefs.containsKey('auth_jwt_token')) {
      await prefs.setString('auth_jwt_token', 'demo_jwt_token_2026_wanderlust_active');
    }
  } catch (_) {}

  runApp(
    const ProviderScope(
      child: WanderlustApp(),
    ),
  );
}

class WanderlustApp extends ConsumerWidget {
  final bool hasSeenOnboarding;

  const WanderlustApp({super.key, this.hasSeenOnboarding = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'WanderLust',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(), // Direct bypass to Main / Home screen
    );
  }
}
