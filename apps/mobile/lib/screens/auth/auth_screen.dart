import "package:flutter/material.dart";
import "../../core/theme/colors.dart";
import "../../core/theme/typography.dart";
import "../../services/supabase_service.dart";
import "../../widgets/animated_background.dart";
import "../../widgets/glass_card.dart";
import "../../widgets/glass_input.dart";
import "../../widgets/gold_button.dart";

enum _AuthMode { signIn, signUp, magicLink }

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  _AuthMode _mode = _AuthMode.signIn;
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _fullName = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _notice;

  Future<void> _submit() async {
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    try {
      switch (_mode) {
        case _AuthMode.signUp:
          await SupabaseService.instance.signUpWithPassword(_email.text.trim(), _password.text, _fullName.text.trim());
          setState(() => _notice = "Account created — check your email to confirm, then sign in.");
          break;
        case _AuthMode.signIn:
          await SupabaseService.instance.signInWithPassword(_email.text.trim(), _password.text);
          break;
        case _AuthMode.magicLink:
          await SupabaseService.instance.signInWithMagicLink(_email.text.trim());
          setState(() => _notice = "Magic link sent — check your email.");
          break;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: GlassCard(
                padding: const EdgeInsets.all(28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: const [
                        Text("⚖️", style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Text("NYAYA-AGENT", style: TextStyle(color: AppColors.gold, fontWeight: FontWeight.w700, letterSpacing: 1.2)),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(_mode == _AuthMode.signUp ? "Create your account" : "Welcome back", style: AppTypography.section),
                    const SizedBox(height: 8),
                    Text(
                      _mode == _AuthMode.magicLink
                          ? "We'll email you a one-time sign-in link."
                          : "Track cases, get AI-assisted statute matching, and connect with verified advocates.",
                      style: AppTypography.body,
                    ),
                    const SizedBox(height: 24),
                    if (_mode == _AuthMode.signUp) ...[
                      GlassInput(hint: "Full name", controller: _fullName),
                      const SizedBox(height: 12),
                    ],
                    GlassInput(hint: "Email", controller: _email, keyboardType: TextInputType.emailAddress),
                    if (_mode != _AuthMode.magicLink) ...[
                      const SizedBox(height: 12),
                      GlassInput(hint: "Password", controller: _password, obscureText: true),
                    ],
                    const SizedBox(height: 20),
                    GoldButton(
                      label: _mode == _AuthMode.signUp
                          ? "Sign up"
                          : _mode == _AuthMode.magicLink
                              ? "Send magic link"
                              : "Sign in",
                      height: 56,
                      loading: _loading,
                      onPressed: _submit,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 14),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    if (_notice != null) ...[
                      const SizedBox(height: 14),
                      Text(_notice!, style: const TextStyle(color: AppColors.greenStatus, fontSize: 13)),
                    ],
                    const SizedBox(height: 20),
                    const Divider(color: AppColors.border),
                    const SizedBox(height: 12),
                    if (_mode != _AuthMode.signIn)
                      _switchLink("Sign in with password", () => setState(() => _mode = _AuthMode.signIn)),
                    if (_mode != _AuthMode.signUp)
                      _switchLink("Create an account", () => setState(() => _mode = _AuthMode.signUp)),
                    if (_mode != _AuthMode.magicLink)
                      _switchLink("Use a magic link instead", () => setState(() => _mode = _AuthMode.magicLink)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchLink(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Text(label, style: const TextStyle(color: AppColors.gold, fontSize: 14)),
      ),
    );
  }
}
