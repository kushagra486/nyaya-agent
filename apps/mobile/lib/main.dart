import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "core/theme/app_theme.dart";
import "providers/auth_provider.dart";
import "providers/case_provider.dart";
import "router/app_router.dart";
import "services/supabase_service.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseService.initialize();
  runApp(const NyayaAgentApp());
}

class NyayaAgentApp extends StatelessWidget {
  const NyayaAgentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => CaseProvider()),
      ],
      child: MaterialApp(
        title: "Nyaya-Agent",
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark,
        home: const AppRoot(),
      ),
    );
  }
}
