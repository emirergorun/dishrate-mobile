import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/email_validator.dart';
import '../../../core/utils/password_validator.dart';
import '../../../shared/widgets/min_tap_area.dart';
import '../../../shared/widgets/brand_logo.dart';
import '../../../shared/widgets/terms_sheet.dart';
import '../widgets/auth_form_widgets.dart';
import 'forgot_password_screen.dart';
import 'welcome_screen.dart';

/// Giriş ekranındaki yatay logonun genişliği; eski logonun görünen
/// genişliğiyle (168 pt) aynı.
const double _logoWidth = 168;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.fromRegister = false});

  /// Kayıt ekranındaki "Giriş yap"tan açıldı: "Kayıt ol" yeni bir kayıt
  /// ekranı açmaz, geri döner (ekranlar üst üste birikmesin).
  final bool fromRegister;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  /// Giriş denemesi başarısızsa formun içinde gösterilen mesaj.
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Kod ve yeni şifreyle giriş yapılırsa giriş ekranı da kapanır.
  Future<void> _forgotPassword() async {
    final ok = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ForgotPasswordScreen(
        initialIdentifier: _emailController.text.trim(),
      ),
    ));
    if (ok == true && mounted) Navigator.of(context).pop(true);
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    final authState = ref.read(authProvider);
    final errorText = authState.status == AuthStatus.unauthenticated
        ? (authState.errorMessage ?? 'Giriş yapılamadı, tekrar dene.')
        : null;

    setState(() {
      _isLoading = false;
      _error = errorText;
    });

    // Giriş ekranı içeriğin üstünde açıldı (1.8); başarıda kapanır ve
    // kullanıcı kaldığı yere döner.
    if (authState.isAuthenticated) {
      Navigator.of(context).pop(true);
      return;
    }

    // Hata mesajı formun içinde kalıyor (alttan çıkan bildirim yerine) ve
    // ekran yeniden kurulmuyor: kullanıcı adı yazdığı gibi duruyor, yalnızca
    // şifre temizleniyor — yanlış olan büyük ihtimalle o.
    if (errorText != null) _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 60),

                  // ── Logo & Başlık ──────────────────────────────────────────────
                  Center(
                    child: Column(
                      children: [
                        const BrandLogo(width: _logoWidth),
                        const SizedBox(height: 10),
                        Text(
                          'Yemek günlüğü ve keşfi',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 52),

                  // ── Form ──────────────────────────────────────────────────────
                  const Text('Giriş Yap', style: AppTextStyles.titleLarge),
                  const SizedBox(height: 24),

                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // E-posta veya kullanıcı adı
                        AuthTextField(
                          controller: _emailController,
                          label: null,
                          hint: 'Kullanıcı adı veya e-posta',
                          identifier: true,
                          textInputAction: TextInputAction.next,
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'E-posta veya kullanıcı adı gerekli';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Şifre
                        AuthTextField(
                          controller: _passwordController,
                          label: null,
                          hint: 'Şifre',
                          obscureText: _obscurePassword,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _login(),
                          suffixIcon: IconButton(
                            tooltip: _obscurePassword
                                ? 'Şifreyi göster'
                                : 'Şifreyi gizle',
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              color: context.textSecondaryColor,
                              size: 20,
                            ),
                            onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                          ),
                          // Girişte karmaşıklık kuralı uygulanmaz — eski şifresi
                          // olan kullanıcılar kilitlenmesin. Doğrulama sunucuda.
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Şifre gerekli' : null,
                        ),
                        // Şifremi unuttum (2.7): e-postaya kod, uygulamanın içinde.
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _isLoading ? null : _forgotPassword,
                            child: Text(
                              'Şifremi unuttum',
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          AuthErrorBox(message: _error!),
                        ],

                        const SizedBox(height: 28),

                        // Giriş Butonu
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  AppColors.primary.withValues(alpha: 0.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Giriş yap',
                                    style: AppTextStyles.titleSmall.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Kayıt Ol ──────────────────────────────────────────────────
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Hesabın yok mu? ',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: context.textSecondaryColor,
                          ),
                        ),
                        Semantics(
                          button: true,
                          label: 'Kayıt ol',
                          child: GestureDetector(
                            onTap: () async {
                              if (widget.fromRegister) {
                                Navigator.of(context).pop(false);
                                return;
                              }
                              final ok = await Navigator.of(context)
                                  .push<bool>(MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterScreen(fromLogin: true),
                              ));
                              // Kayıt başarılı: giriş ekranı da kapanır.
                              if (ok == true && context.mounted) {
                                Navigator.of(context).pop(true);
                              }
                            },
                            child: MinTapArea(
                              child: Text(
                                'Kayıt ol',
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          // İçeriğin üstünde açılıyor (1.8): vazgeçmek için geri.
          if (Navigator.of(context).canPop())
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(left: AppSpace.xs),
                child: IconButton(
                  icon: Icon(Icons.arrow_back_rounded,
                      color: context.textPrimaryColor),
                  tooltip: 'Geri',
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Kayıt ekranı burada da tanımlı — circular import olmadan ──────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.fromLogin = false});

  /// Giriş ekranındaki "Kayıt ol"dan açıldı: "Giriş yap" geri döner. Değilse
  /// (tanıtım, misafir daveti) giriş ekranını açar; geri dönmek kullanıcıyı
  /// tanıtıma atıyordu (11 Ekim).
  final bool fromLogin;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Ortak alanlar
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  /// Kayıt denemesi başarısızsa formun içinde gösterilen mesaj.
  String? _error;

  // Hesap türü

  // Restoran alanları
  // Ülke kodu numaradan ayrı tutulur; şimdilik yalnızca Türkiye.

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    await ref.read(authProvider.notifier).register(
          username: _usernameController.text.trim(),
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted) return;
    setState(() => _isLoading = false);

    final authState = ref.read(authProvider);
    if (authState.isAuthenticated) {
      // Kayıt başarılı → önce kayıt adisyonu, sonra ana ekran.
      // Bu ekran giriş ekranının ÜZERİNE açıldığı için kapatılmalı; yoksa
      // _AuthGate arkada MainScaffold'a geçse bile kullanıcı burada kalır.
      final user = authState.user;
      if (user != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => WelcomeScreen(user: user)),
        );
      }
      // Kayıt ekranı kapanır, kullanıcı kaldığı yere döner (1.8).
      if (mounted) Navigator.of(context).pop(true);
      return;
    }

    // Hata formun içinde kalıyor: alttan çıkan bildirim yerine, yazdıkları
    // silinmeden.
    if (authState.status == AuthStatus.unauthenticated) {
      setState(() => _error =
          authState.errorMessage ?? 'Kayıt tamamlanamadı, tekrar dene.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
          tooltip: 'Geri',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text('Hesap Oluştur', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    // ── Ortak Alanlar ────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AuthTextField(
                            controller: _firstNameController,
                            label: null,
                            hint: 'Ad',
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Ad gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AuthTextField(
                            controller: _lastNameController,
                            label: null,
                            hint: 'Soyad',
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Soyad gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _usernameController,
                      label: null,
                      hint: 'Kullanıcı adı',
                      identifier: true,
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Kullanıcı adı gerekli';
                        if (t.length < 3) return 'En az 3 karakter olmalı';
                        if (t.contains(RegExp(r'\s'))) {
                          return 'Kullanıcı adı boşluk içeremez';
                        }
                        if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(t)) {
                          return 'Türkçe karakter olamaz; yalnızca a-z, rakam, nokta, _ ve -';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _emailController,
                      label: null,
                      hint: 'E-posta',
                      identifier: true,
                      textInputAction: TextInputAction.next,
                      validator: EmailValidator.validate,
                    ),
                    const SizedBox(height: 16),
                    AuthTextField(
                      controller: _passwordController,
                      label: null,
                      hint: 'Şifre',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      onChanged: (_) =>
                          setState(() {}), // kural listesi güncellensin
                      suffixIcon: IconButton(
                        tooltip: _obscurePassword
                            ? 'Şifreyi göster'
                            : 'Şifreyi gizle',
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded,
                          color: context.textSecondaryColor,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      validator: PasswordValidator.validate,
                    ),

                    // Şifre kuralları — yazdıkça yeşile döner
                    PasswordRuleChips(password: _passwordController.text),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      AuthErrorBox(message: _error!),
                    ],

                    const SizedBox(height: 28),

                    // ── Submit Butonu ────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Text(
                                'Kayıt ol',
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Apple Guideline 1.2: kullanıcı içeriği olan uygulamada şartlar
              // (uygunsuz içeriğe tolerans yok) kayıtta kabul edilmeli (1.7).
              _TermsNotice(
                  textStyle: AppTextStyles.bodySmall.copyWith(
                color: context.textSecondaryColor,
              )),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Zaten hesabın var mı? ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: context.textSecondaryColor,
                      ),
                    ),
                    Semantics(
                      button: true,
                      label: 'Giriş yap',
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () async {
                          if (widget.fromLogin) {
                            Navigator.of(context).pop();
                            return;
                          }
                          final ok = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) =>
                                  const LoginScreen(fromRegister: true),
                            ),
                          );
                          // Giriş başarılı: kayıt ekranı da kapanır, bekleyen
                          // iş (ör. puan verme) sürer.
                          if (ok == true && context.mounted) {
                            Navigator.of(context).pop(true);
                          }
                        },
                        child: MinTapArea(
                          child: Text(
                            'Giriş yap',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Kayıt: şartların kabulü ──────────────────────────────────────────────────

/// "Kayıt olarak Kullanım Şartları’nı kabul etmiş olursun." — bağlantı
/// şartlar panelini açar. Parçalar `Wrap` içinde: büyük yazıda satır
/// bağlantının önünden kırılabiliyor.
class _TermsNotice extends StatelessWidget {
  const _TermsNotice({required this.textStyle});
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text('Kayıt olarak ', style: textStyle),
          Semantics(
            button: true,
            label: 'Kullanım şartlarını aç',
            excludeSemantics: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => TermsSheet.show(context),
              child: MinTapArea(
                child: Text(
                  'Kullanım Şartları',
                  style: textStyle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          Text('’nı kabul etmiş olursun.', style: textStyle),
        ],
      ),
    );
  }
}
