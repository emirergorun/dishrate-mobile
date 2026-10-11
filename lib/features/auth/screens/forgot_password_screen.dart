import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/auth/auth_provider.dart';
import '../../../core/auth/auth_repository.dart';
import '../../../core/network/api_errors.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/password_validator.dart';
import '../widgets/auth_form_widgets.dart';

/// Şifremi unuttum (2.7): e-postaya gelen 6 haneli kodla, uygulamanın içinde.
///
/// 1. adım e-posta ya da kullanıcı adı → "Kod gönder". Cevap hesabın var
/// olup olmadığından bağımsız aynı (sunucu da söylemiyor).
/// 2. adım kod + yeni şifre → "Şifreyi değiştir". Başarıda yeni şifreyle
/// giriş yapılır, ekran `true` ile kapanır (giriş ekranı da kapanır).
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key, this.initialIdentifier});

  /// Giriş ekranında yazılmış kullanıcı adı / e-posta.
  final String? initialIdentifier;

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  /// "Kodu tekrar gönder" bu kadar saniye sonra açılır.
  static const _resendSeconds = 60;

  final _identifierFormKey = GlobalKey<FormState>();
  final _resetFormKey = GlobalKey<FormState>();
  late final _identifierController =
      TextEditingController(text: widget.initialIdentifier ?? '');
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _codeSent = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String? _error;
  int _resendLeft = 0;
  Timer? _resendTimer;

  @override
  void dispose() {
    _resendTimer?.cancel();
    _identifierController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String get _identifier => _identifierController.text.trim();

  Future<void> _sendCode() async {
    if (!_codeSent && !_identifierFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await AuthRepository.instance.requestPasswordReset(_identifier);
      if (!mounted) return;
      setState(() {
        _codeSent = true;
        _isLoading = false;
      });
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = userMessageFor(e,
            fallback: 'Kod gönderilemedi, biraz sonra tekrar dene.');
      });
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() => _resendLeft = _resendSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendLeft--);
      if (_resendLeft <= 0) t.cancel();
    });
  }

  Future<void> _resetPassword() async {
    if (!_resetFormKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final newPassword = _passwordController.text;
    try {
      await AuthRepository.instance.resetPassword(
        identifier: _identifier,
        code: _codeController.text.trim(),
        newPassword: newPassword,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error =
            userMessageFor(e, fallback: 'Şifre değiştirilemedi, tekrar dene.');
      });
      return;
    }

    // Şifre değişti: yeni şifreyle hemen giriş.
    await ref
        .read(authProvider.notifier)
        .login(email: _identifier, password: newPassword);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    final loggedIn = ref.read(authProvider).isAuthenticated;
    messenger.showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      content: Text(loggedIn
          ? 'Şifren değiştirildi.'
          : 'Şifren değiştirildi. Yeni şifrenle giriş yapabilirsin.'),
    ));
    Navigator.of(context).pop(loggedIn);
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
          onPressed: () => Navigator.of(context).pop(false),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const Text('Şifreni Sıfırla', style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text(
                // Metin hesabın var olup olmadığını söylemiyor; kod gelmezse
                // aşağıdaki not yönlendiriyor.
                _codeSent
                    ? 'E-postana gönderdiğimiz 6 haneli kodu gir.'
                    : 'Kullanıcı adı veya e-postanı gir. Şifreni sıfırlaman '
                        'için bir kod göndereceğiz.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textSecondaryColor),
              ),
              const SizedBox(height: 28),
              if (!_codeSent) _identifierStep() else _resetStep(),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBox(message: _error!),
              ],
              const SizedBox(height: 28),
              _primaryButton(
                label: _codeSent ? 'Şifreyi değiştir' : 'Kod gönder',
                onPressed: _codeSent ? _resetPassword : _sendCode,
              ),
              if (_codeSent) ...[
                const SizedBox(height: 16),
                Text(
                  'Kod gelmediyse girdiğin bilgilerin doğruluğunu kontrol '
                  'edebilir veya tekrardan kod isteyebilirsin.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: context.textSecondaryColor),
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: _isLoading || _resendLeft > 0 ? null : _sendCode,
                    child: Text(_resendLeft > 0
                        ? 'Kodu tekrar gönder ($_resendLeft sn)'
                        : 'Kodu tekrar gönder'),
                  ),
                ),
              ],
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _identifierStep() {
    return Form(
      key: _identifierFormKey,
      child: AuthTextField(
        controller: _identifierController,
        hint: 'Kullanıcı adı veya e-posta',
        identifier: true,
        autofocus: _identifierController.text.isEmpty,
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _sendCode(),
        validator: (v) => (v == null || v.trim().isEmpty)
            ? 'E-posta veya kullanıcı adı gerekli'
            : null,
      ),
    );
  }

  Widget _resetStep() {
    return Form(
      key: _resetFormKey,
      child: Column(
        children: [
          AuthTextField(
            controller: _codeController,
            hint: '6 haneli kod',
            keyboardType: TextInputType.number,
            autofocus: true,
            // iOS mailden gelen kodu klavyenin üstünde önerir.
            autofillHints: const [AutofillHints.oneTimeCode],
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(6),
            ],
            textInputAction: TextInputAction.next,
            validator: (v) => (v == null || v.trim().length != 6)
                ? 'Kod 6 haneli olmalı'
                : null,
          ),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _passwordController,
            hint: 'Yeni şifre',
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.next,
            onChanged: (_) => setState(() {}),
            suffixIcon: IconButton(
              tooltip: _obscurePassword ? 'Şifreyi göster' : 'Şifreyi gizle',
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: context.textSecondaryColor,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: PasswordValidator.validate,
          ),
          PasswordRuleChips(password: _passwordController.text),
          const SizedBox(height: 16),
          AuthTextField(
            controller: _confirmController,
            hint: 'Yeni şifre (tekrar)',
            obscureText: _obscureConfirm,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _resetPassword(),
            suffixIcon: IconButton(
              tooltip: _obscureConfirm ? 'Şifreyi göster' : 'Şifreyi gizle',
              icon: Icon(
                _obscureConfirm
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                color: context.textSecondaryColor,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Yeni şifreyi tekrar yaz';
              if (v != _passwordController.text) return 'Şifreler eşleşmiyor';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _primaryButton(
      {required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5),
              )
            : Text(
                label,
                style: AppTextStyles.titleSmall
                    .copyWith(color: Colors.white, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}
