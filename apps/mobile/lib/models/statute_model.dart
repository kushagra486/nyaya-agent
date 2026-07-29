class StatuteCitation {
  final String citation;
  final String? oldCitation;
  final String? title;
  final String explanation;
  final String? confidence; // high | medium | low

  StatuteCitation({
    required this.citation,
    this.oldCitation,
    this.title,
    required this.explanation,
    this.confidence,
  });

  factory StatuteCitation.fromJson(Map<String, dynamic> json) {
    return StatuteCitation(
      citation: json["citation"] as String? ?? "",
      oldCitation: json["oldCitation"] as String?,
      title: json["title"] as String?,
      explanation: json["explanation"] as String? ?? "",
      confidence: json["confidence"] as String?,
    );
  }
}

class StructuredAnalysis {
  final List<String> facts;
  final List<StatuteCitation> statutes;
  final List<String> steps;
  final String? disclaimer;

  StructuredAnalysis({
    required this.facts,
    required this.statutes,
    required this.steps,
    this.disclaimer,
  });

  factory StructuredAnalysis.fromJson(Map<String, dynamic> json) {
    return StructuredAnalysis(
      facts: (json["facts"] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      statutes: (json["statutes"] as List<dynamic>? ?? [])
          .map((e) => StatuteCitation.fromJson(e as Map<String, dynamic>))
          .toList(),
      steps: (json["steps"] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      disclaimer: json["disclaimer"] as String?,
    );
  }
}

/// Local, client-side statute mapping record (IPC/CrPC/Evidence Act <->
/// BNS/BNSS/BSA), same shape as apps/web/src/data/statutes.json. Ship the
/// same JSON file as a Flutter asset (assets/data/statutes.json) so both
/// clients stay in sync from one source of truth.
class StatuteRecord {
  final int id;
  final String group; // criminal | procedure | evidence
  final String oldSection;
  final String oldAct;
  final String newSection;
  final String newAct;
  final String title;
  final String notes;

  StatuteRecord({
    required this.id,
    required this.group,
    required this.oldSection,
    required this.oldAct,
    required this.newSection,
    required this.newAct,
    required this.title,
    required this.notes,
  });

  factory StatuteRecord.fromJson(Map<String, dynamic> json) {
    return StatuteRecord(
      id: json["id"] as int,
      group: json["group"] as String,
      oldSection: json["oldSection"] as String,
      oldAct: json["oldAct"] as String,
      newSection: json["newSection"] as String,
      newAct: json["newAct"] as String,
      title: json["title"] as String,
      notes: json["notes"] as String? ?? "",
    );
  }
}
