import "package:flutter/material.dart";
import "../../core/theme/typography.dart";
import "../../core/theme/colors.dart";
import "../../models/case_model.dart";
import "../../services/supabase_service.dart";
import "../../widgets/case_card.dart";

class HistoryScreen extends StatefulWidget {
  final String userId;
  final void Function(CaseModel) onOpenCase;

  const HistoryScreen({super.key, required this.userId, required this.onOpenCase});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<CaseModel> _cases = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    SupabaseService.instance.listCases(widget.userId).then((cases) {
      setState(() {
        _cases = cases;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(child: Text("Legal History", style: AppTypography.title.copyWith(fontSize: 26))),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
            sliver: _loading
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
                : _cases.isEmpty
                    ? SliverToBoxAdapter(child: Text("No past cases yet.", style: AppTypography.body))
                    : SliverList.separated(
                        itemCount: _cases.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, i) => CaseCard(
                          caseModel: _cases[i],
                          index: i,
                          onTap: () => widget.onOpenCase(_cases[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
