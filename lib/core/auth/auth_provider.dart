import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../shared/models/user_model.dart';
import 'auth_repository.dart';
import 'token_storage.dart';

// ── Auth Durumu ───────────────────────────────────────────────────────────────

enum AuthStatus { loading, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.user,
    this.errorMessage,
  });

  const AuthState.loading()
      : status = AuthStatus.loading,
        user = null,
        errorMessage = null;

  const AuthState.authenticated(UserModel user)
      : status = AuthStatus.authenticated,
        user = user,
        errorMessage = null;

  const AuthState.unauthenticated([String? error])
      : status = AuthStatus.unauthenticated,
        user = null,
        errorMessage = error;

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isLoading => status == AuthStatus.loading;
}

// ── Auth Notifier ─────────────────────────────────────────────────────────────

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState.loading()) {
    _initialize();
  }

  final _repo = AuthRepository.instance;
  final _storage = TokenStorage.instance;

  /// Uygulama açılışında token kontrolü
  Future<void> _initialize() async {
    try {
      final hasTokens = await _storage.hasTokens();
      if (!hasTokens) {
        state = const AuthState.unauthenticated();
        return;
      }

      // Refresh token ile access token yenile (süresi dolmuş olabilir)
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) {
        state = const AuthState.unauthenticated();
        return;
      }

      final authResponse = await _repo.refresh(refreshToken);
      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.userId,
      );
      state = AuthState.authenticated(authResponse.user);
    } catch (_) {
      // Token geçersiz veya süresi dolmuş
      await _storage.clearAll();
      state = const AuthState.unauthenticated();
    }
  }

  /// Giriş yap
  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final authResponse = await _repo.login(email: email, password: password);
      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.userId,
      );
      state = AuthState.authenticated(authResponse.user);
    } catch (e) {
      state = AuthState.unauthenticated(_parseError(e));
    }
  }

  /// Normal kullanıcı kaydı
  Future<void> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    state = const AuthState.loading();
    try {
      final authResponse = await _repo.register(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.userId,
      );
      state = AuthState.authenticated(authResponse.user);
    } catch (e) {
      state = AuthState.unauthenticated(_parseError(e));
    }
  }

  /// Restoran sahibi kaydı: önce kullanıcı oluşturur, sonra restoran başvurusu gönderir.
  /// Başvuru onaylanana kadar kullanıcı USER rolünde kalır.
  Future<void> registerAsOwner({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
    required String restaurantName,
    required String city,
    String? district,
    String? contactPhone,
    String? description,
  }) async {
    state = const AuthState.loading();
    try {
      // 1. Kullanıcı oluştur → token al
      final authResponse = await _repo.register(
        username: username,
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      await _storage.saveTokens(
        accessToken: authResponse.accessToken,
        refreshToken: authResponse.refreshToken,
        userId: authResponse.user.userId,
      );

      // 2. Restoran başvurusu gönder (token otomatik eklenir — DioClient interceptor)
      await _repo.submitRestaurantApplication(
        restaurantName: restaurantName,
        city: city,
        district: district,
        contactPhone: contactPhone,
        description: description,
      );

      state = AuthState.authenticated(authResponse.user);
    } catch (e) {
      state = AuthState.unauthenticated(_parseError(e));
    }
  }

  /// Çıkış yap
  Future<void> logout() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken != null) {
        await _repo.logout(refreshToken);
      }
    } catch (_) {
      // Backend'e ulaşamasak da local temizlik yapılır
    } finally {
      await _storage.clearAll();
      state = const AuthState.unauthenticated();
    }
  }

  /// Hata mesajını okunabilir hale getir
  String _parseError(Object e) {
    if (e is Exception) {
      final msg = e.toString();
      if (msg.contains('401') || msg.contains('Unauthorized')) {
        return 'E-posta veya şifre hatalı';
      }
      if (msg.contains('409') || msg.contains('already')) {
        return 'Bu e-posta veya kullanıcı adı zaten kullanımda';
      }
      if (msg.contains('SocketException') || msg.contains('connection')) {
        return 'Sunucuya bağlanılamadı';
      }
    }
    return 'Bir hata oluştu, tekrar dene';
  }
}

// ── Provider ──────────────────────────────────────────────────────────────────

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);

/// Giriş yapmış kullanıcının ID'si. Oturum yoksa null.
final currentUserIdProvider = Provider<int?>(
  (ref) => ref.watch(authProvider).user?.userId,
);
