import "package:flutter/foundation.dart";
import "../models/case_model.dart";
import "../services/supabase_service.dart";

class CaseProvider extends ChangeNotifier {
  List<CaseModel> _cases = [];
  bool _loading = false;
  String? _error;

  List<CaseModel> get cases => _cases;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadCases(String userId) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _cases = await SupabaseService.instance.listCases(userId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<CaseModel> createCase(String userId, String title, String description) async {
    final created = await SupabaseService.instance.createCase(userId, title, description);
    await loadCases(userId);
    return created;
  }
}
