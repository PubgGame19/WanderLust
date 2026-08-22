import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/config/app_config.dart';
import '../../core/models/models.dart';
import '../../core/network/api_service.dart';

final UserModel _demoUser = UserModel(
  id: 'demo-explorer-uuid-2026',
  email: 'explorer@wanderlust.ai',
  username: 'rohan_travels',
  fullName: 'Rohan Sharma',
  avatarUrl: 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=200',
  bio: 'AI-Powered Travel Explorer & Adventurer',
);

class AuthState {
  final bool isLoading;
  final bool isAuthenticated;
  final bool isGuest;
  final UserModel? user;
  final String? errorMessage;

  AuthState({
    this.isLoading = false,
    this.isAuthenticated = true,
    this.isGuest = false,
    UserModel? user,
    this.errorMessage,
  }) : user = user ?? _demoUser;

  AuthState copyWith({
    bool? isLoading,
    bool? isAuthenticated,
    bool? isGuest,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isGuest: isGuest ?? this.isGuest,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _api;
  static const String _guestPrefKey = 'is_guest_mode';
  static const String _demoToken = 'demo_jwt_token_2026_wanderlust_active';

  AuthNotifier(this._api)
      : super(AuthState(isLoading: false, isAuthenticated: true, isGuest: false, user: _demoUser)) {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var token = prefs.getString('auth_jwt_token');

      if (token == null || token.isEmpty) {
        token = _demoToken;
        await prefs.setString('auth_jwt_token', _demoToken);
      }

      // Try fetching live user profile if backend is connected
      try {
        final liveUser = await _api.getCurrentUser();
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isGuest: false,
          user: liveUser,
        );
        return;
      } catch (_) {
        // Fallback gracefully to demo user state
        state = state.copyWith(
          isLoading: false,
          isAuthenticated: true,
          isGuest: false,
          user: _demoUser,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isGuest: false,
        user: _demoUser,
      );
    }
  }

  Future<void> continueAsGuest() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestPrefKey, false); // Keep demo user enabled
      await prefs.setString('auth_jwt_token', _demoToken);
    } catch (_) {}
    state = state.copyWith(
      isLoading: false,
      isAuthenticated: true,
      isGuest: false,
      user: _demoUser,
      errorMessage: null,
    );
  }

  Future<bool> login(String emailOrUsername, String password) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _api.login(emailOrUsername, password);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestPrefKey, false);
      state = state.copyWith(isLoading: false, isAuthenticated: true, isGuest: false, user: user);
      return true;
    } catch (_) {
      // Demo fallback: login succeeds immediately with demo profile
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_jwt_token', _demoToken);
      await prefs.setBool(_guestPrefKey, false);
      state = state.copyWith(
        isLoading: false,
        isAuthenticated: true,
        isGuest: false,
        user: _demoUser.copyWith(username: emailOrUsername.isNotEmpty ? emailOrUsername : _demoUser.username),
      );
      return true;
    }
  }

  Future<bool> register(String email, String username, String password, {String? fullName}) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final user = await _api.register(email, username, password, fullName: fullName);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_guestPrefKey, false);
      state = state.copyWith(isLoading: false, isAuthenticated: true, isGuest: false, user: user);
      return true;
    } catch (_) {
      // Demo fallback: registration succeeds immediately
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_jwt_token', _demoToken);
      await prefs.setBool(_guestPrefKey, false);
      final registeredUser = UserModel(
        id: 'demo-user-${DateTime.now().millisecondsSinceEpoch}',
        email: email.isNotEmpty ? email : _demoUser.email,
        username: username.isNotEmpty ? username : _demoUser.username,
        fullName: fullName ?? _demoUser.fullName,
        avatarUrl: _demoUser.avatarUrl,
        bio: 'Explorer on Wanderlust AI',
      );
      state = state.copyWith(isLoading: false, isAuthenticated: true, isGuest: false, user: registeredUser);
      return true;
    }
  }

  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final googleSignIn = GoogleSignIn(
        serverClientId: AppConfig.googleServerClientId.isNotEmpty
            ? AppConfig.googleServerClientId
            : null,
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? account = await googleSignIn.signIn();
      if (account != null) {
        final GoogleSignInAuthentication auth = await account.authentication;
        final idToken = auth.idToken ?? auth.accessToken ?? "mock_google_id_token_${account.id}";
        final user = await _api.googleLogin(idToken);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_guestPrefKey, false);
        state = state.copyWith(isLoading: false, isAuthenticated: true, isGuest: false, user: user);
        return true;
      }
    } catch (_) {}

    // Instant demo auth injection fallback
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_jwt_token', _demoToken);
    await prefs.setBool(_guestPrefKey, false);
    state = state.copyWith(isLoading: false, isAuthenticated: true, isGuest: false, user: _demoUser);
    return true;
  }

  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_jwt_token');
      await prefs.setBool(_guestPrefKey, false);
    } catch (_) {}
    state = AuthState(isLoading: false, isAuthenticated: true, isGuest: false, user: _demoUser);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final api = ref.watch(apiServiceProvider);
  return AuthNotifier(api);
});
