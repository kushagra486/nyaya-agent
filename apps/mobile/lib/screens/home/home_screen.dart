import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../../core/theme/colors.dart";
import "../../core/theme/typography.dart";
import "../../models/case_model.dart";
import "../../providers/auth_provider.dart";
import "../../providers/case_provider.dart";
import "../../widgets/case_card.dart";
import "../../widgets/glass_card.dart";
import "../../widgets/glass_input.dart";
import "../../widgets/gold_button.dart";

class HomeScreen extends StatefulWidget {
  final void Function(CaseModel) onOpenCase;

  const HomeScreen({super.key, required this.onOpenCase});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showIntake = false;
  final _title = TextEditingController();
  final _description = TextEditingController();
  bool _creating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) context.read<CaseProvider>().loadCases(userId);
    });
  }

  Future<void> _createCase() async {
    final userId = context.read<AuthProvider>().user?.id;
    if (userId == null) return;
    if (_title.text.trim().isEmpty || _description.text.trim().isEmpty) {
      setState(() => _error = "Give the case a title and a short description first.");
      return;
    }
    setState(() {
      _creating = true;
      _error = null;
    });
    try {
      final created = await context.read<CaseProvider>().createCase(userId, _title.text.trim(), _description.text.trim());
      _title.clear();
      _description.clear();
      setState(() => _showIntake = false);
      widget.onOpenCase(created);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _creating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final caseProvider = context.watch<CaseProvider>();

    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: const [
                      Text("⚖️", style: TextStyle(fontSize: 22, color: AppColors.gold)),
                      SizedBox(width: 8),
                      Text("Nyaya-Agent", style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 18)),
                    ],
                  ),
                  const Icon(Icons.notifications_none_rounded, color: AppColors.gold, size: 26),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(child: Text("My Case Dashboard", style: AppTypography.title)),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: caseProvider.loading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(child: CircularProgressIndicator(color: AppColors.gold)),
                    )
                  : caseProvider.cases.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Text(
                            "No cases yet — start one below and get an instant AI read on the relevant statutes.",
                            style: AppTypography.body,
                          ),
                        )
                      : Column(
                          children: [
                            for (int i = 0; i < caseProvider.cases.length; i++) ...[
                              CaseCard(
                                caseModel: caseProvider.cases[i],
                                index: i,
                                onTap: () => widget.onOpenCase(caseProvider.cases[i]),
                              ),
                              const SizedBox(height: 14),
                            ],
                          ],
                        ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _showIntake ? _buildIntakePanel() : _buildIntakeButtons(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildIntakeButtons() {
    return Column(
      children: [
        GoldButton(label: "+ NEW CASE", onPressed: () => setState(() => _showIntake = true)),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: _uploadCard(
                icon: Icons.picture_as_pdf_rounded,
                iconColor: const Color(0xFFE5484D),
                label: "Upload Document",
                onTap: null, // coming soon — no OCR pipeline yet
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _uploadCard(
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF4C8DFF),
                label: "Describe Case",
                onTap: () => setState(() => _showIntake = true),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _uploadCard({required IconData icon, required Color iconColor, required String label, VoidCallback? onTap}) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: GlassCard(
        onTap: onTap,
        radius: 22,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 30),
            const SizedBox(height: 10),
            Text(label, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.white, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildIntakePanel() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("DESCRIBE CASE", style: TextStyle(color: AppColors.gold, fontSize: 12, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
          const SizedBox(height: 14),
          GlassInput(hint: "Give it a short title (e.g. Property Dispute)", controller: _title),
          const SizedBox(height: 12),
          GlassInput(hint: "Describe what happened in plain language…", controller: _description, maxLines: 4),
          if (_error != null) ...[
            const SizedBox(height: 10),
            Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showIntake = false),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.secondaryText)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: GoldButton(label: "Create case", height: 50, loading: _creating, onPressed: _createCase),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
