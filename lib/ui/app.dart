import 'package:flutter/material.dart';
import 'app_scope.dart';
import 'models.dart';
import 'theme.dart';
import 'screens/onboarding_screen.dart';
import 'screens/groups_screen.dart';

/// Racine de l'app. Le [Gate] choisit onboarding vs accueil selon l'identité.
class FriendsApp extends StatelessWidget {
  const FriendsApp({super.key});

  ThemeMode _modeFromChoice(AppThemeChoice c) => switch (c) {
        AppThemeChoice.auto => ThemeMode.system,
        AppThemeChoice.light => ThemeMode.light,
        AppThemeChoice.dark => ThemeMode.dark,
      };

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return MaterialApp(
          title: 'FriendsLocalizer',
          theme: buildLightTheme(),
          darkTheme: buildDarkTheme(),
          themeMode: _modeFromChoice(repo.settings.themeMode),
          debugShowCheckedModeBanner: false,
          home: const Gate(),
        );
      },
    );
  }
}

class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = AppScope.of(context);
    return ListenableBuilder(
      listenable: repo,
      builder: (context, _) {
        return repo.identity == null
            ? const OnboardingScreen()
            : const GroupsScreen();
      },
    );
  }
}
