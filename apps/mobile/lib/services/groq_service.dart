import "dart:convert";
import "package:http/http.dart" as http;
import "../models/statute_model.dart";

/// Same pattern as the web app: GROQ_API_KEY lives only in Vercel's server
/// environment (apps/web/api/analyze.js, apps/web/api/chat.js). This app
/// calls those endpoints directly — it never holds a Groq key itself, so
/// there's nothing to protect against reverse-engineering the APK/IPA.
///
/// This points at the stable git-branch alias so it keeps working across
/// deployments; swap in a custom domain here later if you attach one.
const String kApiBaseUrl = "https://nyaya-agent-git-main-kushagra486s-projects.vercel.app";

class GroqService {
  GroqService._();
  static final GroqService instance = GroqService._();

  Future<StructuredAnalysis> analyzeCase(String caseText, List<StatuteRecord> candidates) async {
    final response = await http.post(
      Uri.parse("$kApiBaseUrl/api/analyze"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "caseText": caseText,
        "candidates": candidates
            .map((c) => {
                  "title": c.title,
                  "oldSection": c.oldSection,
                  "oldAct": c.oldAct,
                  "newSection": c.newSection,
                  "newAct": c.newAct,
                  "notes": c.notes,
                })
            .toList(),
      }),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Request failed (${response.statusCode})");
    }

    final raw = data["result"] as String? ?? "{}";
    try {
      return StructuredAnalysis.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      // Fallback for any non-JSON response — surface as a single step so the
      // UI still shows something instead of crashing on parse.
      return StructuredAnalysis(facts: const [], statutes: const [], steps: [raw]);
    }
  }

  Future<String> chatWithAgent(String caseContext, List<Map<String, String>> history) async {
    final response = await http.post(
      Uri.parse("$kApiBaseUrl/api/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"caseContext": caseContext, "history": history}),
    );

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode != 200) {
      throw Exception(data["error"] ?? "Request failed (${response.statusCode})");
    }
    return data["result"] as String? ?? "No response generated.";
  }
}
