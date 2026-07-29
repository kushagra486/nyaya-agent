import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../core/theme/typography.dart";
import "../models/case_model.dart";
import "../providers/auth_provider.dart";
import "../providers/case_provider.dart";
import "../widgets/animated_background.dart";
import "../widgets/bottom_nav.dart";
import "../widgets/case_card.dart";
import "analysis/analysis_screen.dart";
import "chat/chat_screen.dart";
import "history/history_screen.dart";
import "home/home_screen.dart";
import "lawyers/lawyers_screen.dart";

/// Root shell for the signed-in experience: persistent bottom nav across the
/// four top-level tabs (Home / History / Chat / Lawyers). Analysis and the
/// per-case Chat screen are pushed as full-screen routes on top, matching
/// the mockup's back-arrow drill-in pattern rather than living in the tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _tabIndex = 0;
  CaseModel? _lastOpenedCase;

  void _openCase(CaseModel c) {
    _lastOpenedCase = c;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AnalysisScreen(
          caseModel: c,
          onBack: () => Navigator.of(context).pop(),
          onOpenChat: () {
            final userId = context.read<AuthProvider>().user?.id;
            if (userId == null) return;
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  caseModel: c,
                  userId: userId,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.watch<AuthProvider>().user?.id ?? "";

    final tabs = [
      HomeScreen(onOpenCase: _openCase),
      HistoryScreen(userId: userId, onOpenCase: _openCase),
      _ChatEntryTab(userId: userId, onOpenCase: _openCase),
      LawyersScreen(userId: userId, activeCase: _lastOpenedCase),
    ];

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AnimatedBackground(child: IndexedStack(index: _tabIndex, children: tabs)),
      bottomNavigationBar: AppBottomNav(
        activeIndex: _tabIndex,
        onSelect: (i) => setState(() => _tabIndex = i),
      ),
    );
  }
}

/// The "Chat" bottom-nav tab: since conversations are per-case, this is a
/// picker — tap a case to jump straight into its chat thread.
class _ChatEntryTab extends StatelessWidget {
  final String userId;
  final void Function(CaseModel) onOpenCase;

  const _ChatEntryTab({required this.userId, required this.onOpenCase});

  @override
  Widget build(BuildContext context) {
    final caseProvider = context.watch<CaseProvider>();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(child: Text("Chat with Agent", style: AppTypography.title.copyWith(fontSize: 26))),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text("Pick a case to continue its conversation.", style: AppTypography.body),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: caseProvider.cases.isEmpty
                ? SliverToBoxAdapter(
                    child: Text("No cases yet — create one from Home first.", style: AppTypography.body),
                  )
                : SliverList.separated(
                    itemCount: caseProvider.cases.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) => CaseCard(
                      caseModel: caseProvider.cases[i],
                      index: i,
                      onTap: () => onOpenCase(caseProvider.cases[i]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
