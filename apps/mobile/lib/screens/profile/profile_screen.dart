import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../core/theme/colors.dart";
import "../../core/theme/typography.dart";
import "../../providers/auth_provider.dart";
import "../../widgets/glass_card.dart";

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final email = user?.email ?? "Signed in";

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text("Profile", style: AppTypography.title.copyWith(fontSize: 26)),
            const SizedBox(height: 32),
            GlassCard(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: AppColors.gold,
                    child: Text(
                      email.isNotEmpty ? email[0].toUpperCase() : "?",
                      style: const TextStyle(color: Colors.black87, fontSize: 28, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(email, style: AppTypography.cardTitle),
                  const SizedBox(height: 4),
                  Text("Client account", style: AppTypography.caption),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => context.read<AuthProvider>().signOut(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                    ),
                    child: const Text("Sign out", style: TextStyle(color: AppColors.secondaryText)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
