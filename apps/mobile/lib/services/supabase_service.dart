import "package:supabase_flutter/supabase_flutter.dart";
import "../models/case_model.dart";
import "../models/lawyer_model.dart";

/// Same Supabase project as the web app (apps/web/src/lib/supabaseClient.ts) —
/// same tables, same RLS policies, no schema changes needed. The anon key is
/// safe to ship in the app bundle; Row Level Security is what actually gates
/// access, not secrecy of this key.
const String kSupabaseUrl = "https://qojdhatypfuakhkkedar.supabase.co";
const String kSupabaseAnonKey = "sb_publishable_OX6lgIfO3vfeDsonPJnDuw_SpipH8_R";

class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(url: kSupabaseUrl, anonKey: kSupabaseAnonKey);
  }

  // --- Auth -----------------------------------------------------------------
  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> signUpWithPassword(String email, String password, String fullName) {
    return _client.auth.signUp(
      email: email,
      password: password,
      data: {"full_name": fullName},
    );
  }

  Future<void> signInWithPassword(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signInWithMagicLink(String email) {
    return _client.auth.signInWithOtp(email: email);
  }

  Future<void> signOut() => _client.auth.signOut();

  // --- Cases ------------------------------------------------------------------
  Future<List<CaseModel>> listCases(String userId) async {
    final rows = await _client
        .from("cases")
        .select()
        .eq("user_id", userId)
        .order("created_at", ascending: false);
    return (rows as List).map((r) => CaseModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  Future<CaseModel> createCase(String userId, String title, String rawDescription) async {
    final row = await _client
        .from("cases")
        .insert({"user_id": userId, "title": title, "raw_description": rawDescription})
        .select()
        .single();
    return CaseModel.fromJson(row);
  }

  Future<CaseModel?> getCase(String caseId) async {
    final row = await _client.from("cases").select().eq("id", caseId).maybeSingle();
    return row == null ? null : CaseModel.fromJson(row);
  }

  Future<void> updateCaseAnalysis(String caseId, String analysisJson) async {
    await _client.from("cases").update({
      "ai_analysis": analysisJson,
      "status": "analyzed",
      "updated_at": DateTime.now().toIso8601String(),
    }).eq("id", caseId);
  }

  // --- Messages (chat) -----------------------------------------------------------
  Future<List<Map<String, dynamic>>> listMessages(String caseId) async {
    final rows = await _client
        .from("messages")
        .select()
        .eq("case_id", caseId)
        .order("created_at", ascending: true);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  Future<void> addMessage(String caseId, String userId, String role, String content) async {
    await _client.from("messages").insert({
      "case_id": caseId,
      "user_id": userId,
      "role": role,
      "content": content,
    });
  }

  // --- Lawyers ---------------------------------------------------------------
  Future<List<LawyerModel>> listLawyers() async {
    final rows = await _client.from("lawyers").select().order("experience_years", ascending: false);
    return (rows as List).map((r) => LawyerModel.fromJson(r as Map<String, dynamic>)).toList();
  }

  // --- Consultations -----------------------------------------------------------
  Future<void> requestConsultation(String caseId, String userId, String lawyerId, DateTime preferredTime) async {
    await _client.from("consultations").insert({
      "case_id": caseId,
      "user_id": userId,
      "lawyer_id": lawyerId,
      "preferred_time": preferredTime.toIso8601String(),
    });
  }
}
