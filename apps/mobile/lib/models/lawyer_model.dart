class LawyerModel {
  final String id;
  final String name;
  final String? photoUrl;
  final String barCouncilRegNo;
  final List<String> specializations;
  final List<String> courtPractices;
  final String? city;
  final int experienceYears;
  final double consultationFee;
  final bool isVerified;

  LawyerModel({
    required this.id,
    required this.name,
    this.photoUrl,
    required this.barCouncilRegNo,
    required this.specializations,
    required this.courtPractices,
    this.city,
    required this.experienceYears,
    required this.consultationFee,
    required this.isVerified,
  });

  String get initials {
    final cleaned = name.replaceFirst(RegExp(r"^Adv\.\s*"), "");
    final parts = cleaned.split(" ").where((p) => p.isNotEmpty).toList();
    return parts.take(2).map((p) => p[0]).join().toUpperCase();
  }

  factory LawyerModel.fromJson(Map<String, dynamic> json) {
    return LawyerModel(
      id: json["id"] as String,
      name: json["name"] as String,
      photoUrl: json["photo_url"] as String?,
      barCouncilRegNo: json["bar_council_reg_no"] as String? ?? "",
      specializations: List<String>.from(json["specializations"] as List? ?? []),
      courtPractices: List<String>.from(json["court_practices"] as List? ?? []),
      city: json["city"] as String?,
      experienceYears: (json["experience_years"] as num?)?.toInt() ?? 0,
      consultationFee: (json["consultation_fee"] as num?)?.toDouble() ?? 0,
      isVerified: json["is_verified"] as bool? ?? false,
    );
  }
}

class ChatMessageModel {
  final String id;
  final String caseId;
  final String role; // user | assistant
  final String content;
  final DateTime createdAt;

  ChatMessageModel({
    required this.id,
    required this.caseId,
    required this.role,
    required this.content,
    required this.createdAt,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json["id"] as String,
      caseId: json["case_id"] as String,
      role: json["role"] as String,
      content: json["content"] as String,
      createdAt: DateTime.parse(json["created_at"] as String),
    );
  }
}
