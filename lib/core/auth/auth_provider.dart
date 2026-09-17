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

  const AuthState.authenticated(UserModel this.user)
      : status = AuthStatus.authenticated,
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
  /// Giriş sırasında genel durum "loading" YAPILMAZ: o durumda uygulama
  /// açılış ekranına dönüyor, giriş ekranı baştan kuruluyor ve kullanıcının
  /// yazdıkları siliniyordu. Ekranın kendi bekleme göstergesi var.
  Future<void> login({
    required String email,
    required String password,
  }) async {
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
  /// Kayıt da giriş gibi: hata olursa form yerinde kalsın.
  Future<void> register({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
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
