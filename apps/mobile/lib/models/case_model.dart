enum CaseStatus { draft, analyzed, lawyerAssigned, closed }

CaseStatus caseStatusFromString(String value) {
  switch (value) {
    case "analyzed":
      return CaseStatus.analyzed;
    case "lawyer_assigned":
      return CaseStatus.lawyerAssigned;
    case "closed":
      return CaseStatus.closed;
    case "draft":
    default:
      return CaseStatus.draft;
  }
}

String caseStatusToString(CaseStatus status) {
  switch (status) {
    case CaseStatus.analyzed:
      return "analyzed";
    case CaseStatus.lawyerAssigned:
      return "lawyer_assigned";
    case CaseStatus.closed:
      return "closed";
    case CaseStatus.draft:
      return "draft";
  }
}

class CaseModel {
  final String id;
  final String userId;
  final String title;
  final String rawDescription;
  final String? aiAnalysis;
  final CaseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  CaseModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.rawDescription,
    required this.aiAnalysis,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) {
    return CaseModel(
      id: json["id"] as String,
      userId: json["user_id"] as String,
      title: json["title"] as String,
      rawDescription: json["raw_description"] as String,
      aiAnalysis: json["ai_analysis"] as String?,
      status: caseStatusFromString(json["status"] as String? ?? "draft"),
      createdAt: DateTime.parse(json["created_at"] as String),
      updatedAt: DateTime.parse(json["updated_at"] as String),
    );
  }
}
