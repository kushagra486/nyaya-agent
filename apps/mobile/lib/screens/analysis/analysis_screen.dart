import "dart:convert";
import "package:flutter/material.dart";
import "../../core/theme/colors.dart";
import "../../core/theme/typography.dart";
import "../../models/case_model.dart";
import "../../models/statute_model.dart";
import "../../services/groq_service.dart";
import "../../services/statute_search_service.dart";
import "../../services/supabase_service.dart";
import "../../widgets/analysis_card.dart";
import "../../widgets/gold_button.dart";
import "../../widgets/status_chip.dart";
import "../../widgets/floating_chat_button.dart";

/// The Vercel /api/analyze endpoint returns the structured shape directly as
/// its JSON body already, so this just re-serializes the parsed result for
/// storage in Supabase's ai_analysis text column.
String encodeAnalysis(StructuredAnalysis a) {
  return jsonEncode({
    "facts": a.facts,
    "statutes": a.statutes
        .map((s) => {
              "citation": s.citation,
              "oldCitation": s.oldCitation,
              "title": s.title,
              "explanation": s.explanation,
              "confidence": s.confidence,
            })
        .toList(),
    "steps": a.steps,
    "disclaimer": a.disclaimer,
  });
}

class AnalysisScreen extends StatefulWidget {
  final CaseModel caseModel;
  final VoidCallback onBack;
  final VoidCallback onOpenChat;

  const AnalysisScreen({super.key, required this.caseModel, required this.onBack, required this.onOpenChat});

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late CaseModel _case;
  StructuredAnalysis? _structured;
  bool _analyzing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _case = widget.caseModel;
    _tryParseExisting();
  }

  void _tryParseExisting() {
    if (_case.aiAnalysis == null || _case.aiAnalysis!.isEmpty) return;
    try {
      final decoded = jsonDecode(_case.aiAnalysis!) as Map<String, dynamic>;
      _structured = StructuredAnalysis.fromJson(decoded);
    } catch (_) {
      _structured = null;
    }
  }

  Future<void> _analyze() async {
    setState(() {
      _analyzing = true;
      _error = null;
    });
    try {
      final candidates = await StatuteSearchService.instance.scoreCandidates(_case.rawDescription);
      final result = await GroqService.instance.analyzeCase(_case.rawDescription, candidates);
      final asJson = encodeAnalysis(result);
      await SupabaseService.instance.updateCaseAnalysis(_case.id, asJson);
      final refreshed = await SupabaseService.instance.getCase(_case.id);
      if (refreshed != null) {
        setState(() {
          _case = refreshed;
          _structured = result;
        });
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _analyzing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAnalyzed = _case.status == CaseStatus.analyzed;

    return SafeArea(
      child: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: widget.onBack,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.white, size: 20),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_case.title, style: AppTypography.cardTitle, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                      isAnalyzed
                          ? const StatusChip(kind: StatusKind.analyzed, label: "Analyzed")
                          : const StatusChip(kind: StatusKind.pending, label: "Draft"),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                sliver: SliverList.list(
                  children: [
                    AnalysisCard(
                      title: "Facts Extracted",
                      index: 0,
                      child: _structured != null
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: _structured!.facts
                                  .map((f) => Padding(
                                        padding: const EdgeInsets.only(bottom: 6),
                                        child: Text("•  $f", style: AppTypography.body),
                                      ))
                                  .toList(),
                            )
                          : Text(_case.rawDescription, style: AppTypography.body),
                    ),
                    const SizedBox(height: 18),
                    if (!isAnalyzed)
                      GoldButton(label: "Analyze", loading: _analyzing, onPressed: _analyze, height: 56),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13)),
                    ],
                    if (isAnalyzed && _structured != null) ...[
                      const SizedBox(height: 18),
                      AnalysisCard(
                        title: "Relevant Statutes",
                        index: 1,
                        child: _structured!.statutes.isEmpty
                            ? Text("No confident statute match found.", style: AppTypography.body)
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: _structured!.statutes
                                    .map((s) => Padding(
                                          padding: const EdgeInsets.only(bottom: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(s.citation, style: AppTypography.statuteCitation),
                                              if (s.oldCitation != null)
                                                Text("(${s.oldCitation})", style: const TextStyle(color: AppColors.hintText, fontSize: 13)),
                                              const SizedBox(height: 2),
                                              Text(s.explanation, style: AppTypography.body.copyWith(fontSize: 15)),
                                            ],
                                          ),
                                        ))
                                    .toList(),
                              ),
                      ),
                      const SizedBox(height: 18),
                      AnalysisCard(
                        title: "Suggested Steps",
                        index: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (int i = 0; i < _structured!.steps.length; i++)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 6),
                                child: Text("${i + 1}. ${_structured!.steps[i]}", style: AppTypography.body),
                              ),
                          ],
                        ),
                      ),
                      if (_structured!.disclaimer != null) ...[
                        const SizedBox(height: 14),
                        Text(_structured!.disclaimer!, style: AppTypography.caption, textAlign: TextAlign.center),
                      ],
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (isAnalyzed)
            Positioned(
              bottom: 24,
              right: 20,
              child: FloatingChatButton(onTap: widget.onOpenChat),
            ),
        ],
      ),
    );
  }
}
