import "package:flutter/foundation.dart";
import "package:supabase_flutter/supabase_flutter.dart" show User, AuthState;
import "../services/supabase_service.dart";

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _loading = true;

  User? get user => _user;
  bool get loading => _loading;
  bool get isSignedIn => _user != null;

  AuthProvider() {
    _user = SupabaseService.instance.currentUser;
    _loading = false;
    SupabaseService.instance.authStateChanges.listen((AuthState state) {
      _user = state.session?.user;
      notifyListeners();
    });
  }

  Future<void> signOut() => SupabaseService.instance.signOut();
}
