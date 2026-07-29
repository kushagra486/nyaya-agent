import "dart:convert";
import "package:flutter/services.dart" show rootBundle;
import "../models/statute_model.dart";

final _stopwords = {
  "the", "a", "an", "of", "to", "in", "on", "and", "or", "my", "me", "is",
  "was", "were", "he", "she", "they", "with", "by", "for", "at", "from",
  "has", "have", "had", "i", "his", "her", "their", "it", "that", "this",
};

List<String> _tokenize(String text) {
  final cleaned = text.toLowerCase().replaceAll(RegExp(r"[^a-z0-9\s]"), " ");
  return cleaned.split(RegExp(r"\s+")).where((t) => t.length > 2 && !_stopwords.contains(t)).toList();
}

class StatuteSearchService {
  StatuteSearchService._();
  static final StatuteSearchService instance = StatuteSearchService._();

  List<StatuteRecord>? _cache;

  Future<List<StatuteRecord>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString("assets/data/statutes.json");
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list.map((e) => StatuteRecord.fromJson(e as Map<String, dynamic>)).toList();
    return _cache!;
  }

  Future<List<StatuteRecord>> findBySection(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];
    final data = await _load();
    return data
        .where((r) =>
            r.oldSection.toLowerCase() == q ||
            r.newSection.toLowerCase() == q ||
            r.oldSection.toLowerCase().startsWith(q) ||
            r.newSection.toLowerCase().startsWith(q))
        .toList();
  }

  /// Lightweight keyword-overlap scorer, same approach as the web app —
  /// surfaces candidate sections to ground the Groq call, never invented.
  Future<List<StatuteRecord>> scoreCandidates(String caseText, {int topN = 6}) async {
    final queryTokens = _tokenize(caseText).toSet();
    if (queryTokens.isEmpty) return [];

    final data = await _load();
    final scored = <MapEntry<StatuteRecord, int>>[];
    for (final record in data) {
      final haystack = _tokenize("${record.title} ${record.notes}");
      final score = haystack.where(queryTokens.contains).length;
      if (score > 0) scored.add(MapEntry(record, score));
    }
    scored.sort((a, b) => b.value.compareTo(a.value));
    return scored.take(topN).map((e) => e.key).toList();
  }

  Future<List<StatuteRecord>> all() => _load();
}
