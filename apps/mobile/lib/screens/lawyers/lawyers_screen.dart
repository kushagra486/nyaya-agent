import "package:flutter/material.dart";
import "../../core/theme/colors.dart";
import "../../core/theme/constants.dart";
import "../../core/theme/typography.dart";
import "../../models/case_model.dart";
import "../../models/lawyer_model.dart";
import "../../services/supabase_service.dart";
import "../../widgets/lawyer_card.dart";

const _kSpecializations = ["Civil", "Criminal", "Corporate", "Family", "Cyber"];

class LawyersScreen extends StatefulWidget {
  final String userId;
  final CaseModel? activeCase;

  const LawyersScreen({super.key, required this.userId, this.activeCase});

  @override
  State<LawyersScreen> createState() => _LawyersScreenState();
}

class _LawyersScreenState extends State<LawyersScreen> {
  List<LawyerModel> _lawyers = [];
  bool _loading = true;
  String? _error;
  String? _specFilter;
  String? _courtFilter;
  int _minExperience = 0;
  String? _requestedId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final lawyers = await SupabaseService.instance.listLawyers();
      setState(() {
        _lawyers = lawyers;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  List<String> get _courts {
    final set = <String>{};
    for (final l in _lawyers) {
      set.addAll(l.courtPractices);
    }
    return set.toList()..sort();
  }

  List<LawyerModel> get _filtered {
    return _lawyers.where((l) {
      if (_specFilter != null && !l.specializations.contains(_specFilter)) return false;
      if (_courtFilter != null && !l.courtPractices.contains(_courtFilter)) return false;
      if (l.experienceYears < _minExperience) return false;
      return true;
    }).toList();
  }

  Future<void> _request(LawyerModel lawyer) async {
    if (widget.activeCase == null) {
      setState(() => _error = "Open a case first, then request a consultation from there.");
      return;
    }
    try {
      await SupabaseService.instance.requestConsultation(
        widget.activeCase!.id,
        widget.userId,
        lawyer.id,
        DateTime.now().add(const Duration(days: 1)),
      );
      setState(() => _requestedId = lawyer.id);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            sliver: SliverToBoxAdapter(child: Text("Verify & Book Lawyer", style: AppTypography.title.copyWith(fontSize: 26))),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _kSpecializations.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final spec = _kSpecializations[i];
                    final active = _specFilter == spec;
                    return GestureDetector(
                      onTap: () => setState(() => _specFilter = active ? null : spec),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: active ? AppColors.gold : AppColors.secondarySurface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          border: Border.all(color: active ? AppColors.gold : AppColors.border),
                        ),
                        child: Text(
                          spec,
                          style: TextStyle(color: active ? Colors.black87 : AppColors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(child: _dropdown("All courts", _courtFilter, _courts, (v) => setState(() => _courtFilter = v))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _dropdown(
                      "Any experience",
                      _minExperience == 0 ? null : "$_minExperience+ years",
                      const ["5+ years", "10+ years", "15+ years"],
                      (v) => setState(() => _minExperience = v == null ? 0 : int.parse(v.split("+").first)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error != null)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              sliver: SliverToBoxAdapter(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13))),
            ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: _loading
                ? const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator(color: AppColors.gold)))
                : SliverList.separated(
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (context, i) {
                      final lawyer = _filtered[i];
                      return LawyerCard(
                        lawyer: lawyer,
                        requested: _requestedId == lawyer.id,
                        onRequestConsultation: () => _request(lawyer),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String hint, String? value, List<String> options, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.secondarySurface.withOpacity(0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: const TextStyle(color: AppColors.hintText, fontSize: 13)),
          dropdownColor: AppColors.secondarySurface,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.hintText),
          style: const TextStyle(color: AppColors.white, fontSize: 13),
          items: [
            DropdownMenuItem(value: null, child: Text(hint)),
            ...options.map((o) => DropdownMenuItem(value: o, child: Text(o))),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}
