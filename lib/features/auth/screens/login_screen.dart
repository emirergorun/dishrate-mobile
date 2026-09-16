import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/email_validator.dart';
import '../../../core/utils/password_validator.dart';
import '../../../shared/widgets/dishrate_logo.dart';
import 'splash_screen.dart';
import 'welcome_screen.dart';

/// Giriş ekranındaki logonun genişliği.
const double _logoWidth = 200;

/// Logo görselinin en-boy oranı (bkz. [DishrateWordmark]).
const double _wordmarkAspect = 2400 / 764;

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  /// Giriş denemesi başarısızsa formun içinde gösterilen mesaj.
  String? _error;

  // ── Açılıştan geçiş ─────────────────────────────────────────────────────
  // Açılış ekranında logo ortada ve büyük; giriş ekranı açılınca bir anda
  // yukarı sıçrayıp küçülüyordu. Artık logo açılıştaki yerinden kendi yerine
  // kayarak küçülüyor, form arkasından beliriyor.

  late final AnimationController _intro;
  late final Animation<double> _contentFade;
  bool _introDone = false;

  @override
  void initState() {
    super.initState();
    _intro = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _contentFade = CurvedAnimation(
      parent: _intro,
      curve: const Interval(0.45, 1, curve: Curves.easeOut),
    );
    // Yalnızca açılış ekranından gelindiyse oynat; çıkış yapıp girişe dönünce
    // logonun ortadan gelmesi için sebep yok.
    if (!SplashScreen.gosterildi) {
      _intro.value = 1;
      _introDone = true;
      return;
    }
    SplashScreen.gosterildi = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() {
          _intro.value = 1;
          _introDone = true;
        });
        return;
      }
      _intro.forward().whenComplete(() {
        if (mounted) setState(() => _introDone = true);
      });
    });
  }

  /// Logonun formdaki yeri. Ölçmek yerine düzenden hesaplanıyor: güvenli
  /// alanın üstü + 60 boşluk + logonun yarısı, yatayda orta.
  ///
  /// Önceden konum GlobalKey ile ölçülüyordu; ölçüm bir sebeple boş dönünce
  /// animasyon sessizce atlanıyor ve logo ortadan kaybolup yukarıda yeniden
  /// beliriyordu (cihazda tam olarak bu oluyordu).
  Offset _logoTarget(BuildContext context) {
    final mq = MediaQuery.of(context);
    final h = _logoWidth / _wordmarkAspect;
    return Offset(mq.size.width / 2, mq.padding.top + 60 + h / 2);
  }

  @override
  void dispose() {
    _intro.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Açılıştaki yerinden (ekranın ortası) formdaki yerine kayan logo.
  Widget _flyingLogo() {
    return AnimatedBuilder(
      animation: _intro,
      builder: (context, _) {
        final t = Curves.easeInOutCubic
            .transform((_intro.value / 0.6).clamp(0.0, 1.0));
        final start = MediaQuery.sizeOf(context).center(Offset.zero);
        final c = Offset.lerp(start, _logoTarget(context), t)!;
        final w = lerpDouble(splashLogoWidth, _logoWidth, t)!;
        final h = w / _wordmarkAspect;
        return Positioned(
          left: c.dx - w / 2,
          top: c.dy - h / 2,
          width: w,
          height: h,
          child: DishrateWordmark(width: w),
        );
      },
    );
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
    final hata = authState.status == AuthStatus.unauthenticated
        ? (authState.errorMessage ?? 'Giriş yapılamadı, tekrar dene')
        : null;

    setState(() {
      _isLoading = false;
      _error = hata;
    });

    // Hata mesajı formun içinde kalıyor (alttan çıkan bildirim yerine) ve
    // ekran yeniden kurulmuyor: kullanıcı adı yazdığı gibi duruyor, yalnızca
    // şifre temizleniyor — yanlış olan büyük ihtimalle o.
    if (hata != null) _passwordController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      body: Stack(
        children: [
          FadeTransition(
            opacity: _contentFade,
            child: SafeArea(
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
                    // Geçiş sürerken gerçek logo gizli; yerine üstte kayan
                    // kopyası görünüyor.
                    Opacity(
                      opacity: _introDone ? 1 : 0,
                      child: const DishrateWordmark(width: _logoWidth),
                    ),
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
                    _AuthTextField(
                      controller: _emailController,
                      label: null,
                      hint: 'Kullanıcı adı veya e-posta',
                      keyboardType: TextInputType.text,
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
                    _AuthTextField(
                      controller: _passwordController,
                      label: null,
                      hint: 'Şifre',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _login(),
                      suffixIcon: IconButton(
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
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBox(message: _error!),
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
                                'Giriş Yap',
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
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Kayıt Ol',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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
          ),
          if (!_introDone) _flyingLogo(),
        ],
      ),
    );
  }
}

/// Form içinde kalan hata kutusu.
///
/// Önceden hata alttan çıkan bir bildirimdi ve giriş ekranı baştan kuruluyordu;
/// kullanıcı yazdıklarını kaybediyordu.
class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded,
              size: 18, color: context.errorTextColor),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium
                  .copyWith(color: context.errorTextColor),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kayıt ekranı burada da tanımlı — circular import olmadan ──────────────────

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

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
      // Kayıt başarılı → önce karşılama ekranı, sonra ana ekran.
      // Bu ekran giriş ekranının ÜZERİNE açıldığı için kapatılmalı; yoksa
      // _AuthGate arkada MainScaffold'a geçse bile kullanıcı burada kalır.
      final name = authState.user?.firstName?.trim().isNotEmpty == true
          ? authState.user!.firstName!.trim()
          : (authState.user?.username ?? '');

      await Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => WelcomeScreen(name: name)),
      );
      if (mounted) Navigator.of(context).pop(); // kayıt ekranını kapat
      return;
    }

    // Hata formun içinde kalıyor: alttan çıkan bildirim yerine, yazdıkları
    // silinmeden.
    if (authState.status == AuthStatus.unauthenticated) {
      setState(() => _error =
          authState.errorMessage ?? 'Kayıt tamamlanamadı, tekrar dene');
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
                          child: _AuthTextField(
                            controller: _firstNameController,
                            label: null,
                            hint: 'İsim',
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'İsim gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _AuthTextField(
                            controller: _lastNameController,
                            label: null,
                            hint: 'Soyisim',
                            keyboardType: TextInputType.name,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Soyisim gerekli';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _AuthTextField(
                      controller: _usernameController,
                      label: null,
                      hint: 'Kullanıcı Adı',
                      textInputAction: TextInputAction.next,
                      validator: (v) {
                        final t = (v ?? '').trim();
                        if (t.isEmpty) return 'Kullanıcı adı gerekli';
                        if (t.length < 3) return 'En az 3 karakter olmalı';
                        if (t.contains(RegExp(r'\s'))) {
                          return 'Kullanıcı adı boşluk içeremez';
                        }
                        if (!RegExp(r'^[A-Za-z0-9._-]+$').hasMatch(t)) {
                          return 'Sadece harf, rakam, nokta, _ ve - kullanılabilir';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _AuthTextField(
                      controller: _emailController,
                      label: null,
                      hint: 'E-posta',
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      validator: EmailValidator.validate,
                    ),
                    const SizedBox(height: 16),
                    _AuthTextField(
                      controller: _passwordController,
                      label: null,
                      hint: 'Şifre',
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _submit(),
                      onChanged: (_) =>
                          setState(() {}), // kural listesi güncellensin
                      suffixIcon: IconButton(
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
                    if (_passwordController.text.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 6,
                          children: PasswordValidator.rules.map((rule) {
                            final ok = rule.test(_passwordController.text);
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  ok
                                      ? Icons.check_circle_rounded
                                      : Icons.circle_outlined,
                                  size: 14,
                                  color: ok
                                      ? AppColors.success
                                      : context.textSecondaryColor,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  rule.label,
                                  style: AppTextStyles.bodySmall.copyWith(
                                    fontSize: 11,
                                    color: ok
                                        ? AppColors.success
                                        : context.textSecondaryColor,
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    ],

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      _ErrorBox(message: _error!),
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
                                'Kayıt Ol',
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
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Text(
                        'Giriş Yap',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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

// ── Hesap Türü Toggle ─────────────────────────────────────────────────────────

class _AuthTextField extends StatelessWidget {
  const _AuthTextField({
    required this.controller,
    this.label,
    required this.hint,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onFieldSubmitted,
    this.onChanged,
    this.suffixIcon,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String hint;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: context.textSecondaryColor,
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          validator: validator,
          style: AppTextStyles.bodyMedium.copyWith(
            color: context.textPrimaryColor,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTextStyles.bodyMedium.copyWith(
              color: context.textSecondaryColor.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: context.surfaceColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: context.dividerColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error, width: 1.5),
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
