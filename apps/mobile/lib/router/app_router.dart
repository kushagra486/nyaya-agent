import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../providers/auth_provider.dart";
import "../screens/app_shell.dart";
import "../screens/auth/auth_screen.dart";
import "../widgets/animated_background.dart";
import "../core/theme/colors.dart";

/// Deliberately simple (no go_router StatefulShellRoute) — auth state is the
/// only thing that changes the top-level screen, and everything else within
/// the signed-in shell is plain Navigator.push, matching the mockup's
/// tab-bar + drill-in-with-back-arrow pattern.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    if (!auth.isSignedIn) {
      return const AuthScreen();
    }

    return const AppShell();
  }
}

/// Convenience wrapper if a screen needs the aurora background without the
/// bottom nav (kept here so screens don't each re-import both).
class BackgroundScaffold extends StatelessWidget {
  final Widget child;
  const BackgroundScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(child: child),
    );
  }
}
