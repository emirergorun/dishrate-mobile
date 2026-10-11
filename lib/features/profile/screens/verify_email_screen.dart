import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_errors.dart';
import '../../../core/network/user_repository.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../auth/widgets/auth_form_widgets.dart';

/// E-posta doğrulama (2.8): kayıtta gönderilen 6 haneli kod girilir.
///
/// Ekran açılınca yeni kod gönderilmez — kayıttaki kod 24 saat geçerli;
/// gelmediyse kullanıcı "Kodu tekrar gönder"e basar (saatte 3 kod sınırı
/// boşa harcanmasın). Başarıda `true` ile kapanır.
class VerifyEmailScreen extends StatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  static const _resendSeconds = 60;

  /// Son "Kodu tekrar gönder" anı, adrese göre. Ekrandan çıkıp girince sayaç
  /// sıfırlanmasın diye ekrandan bağımsız tutulur (uygulama açık kaldıkça).
  static final Map<String, DateTime> _lastSentAt = {};

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();

  bool _isLoading = false;
  String? _error;
  String? _info;
  int _resendLeft = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    final last = _lastSentAt[widget.email];
    if (last != null) {
      final left =
          _resendSeconds - DateTime.now().difference(last).inSeconds;
      if (left > 0) _startCountdown(left);
    }
  }

  void _startCountdown(int seconds) {
    _resendTimer?.cancel();
    _resendLeft = seconds;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _resendLeft--);
      if (_resendLeft <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await UserRepository.instance.verifyEmail(_codeController.text.trim());
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = userMessageFor(e, fallback: 'Doğrulanamadı, tekrar dene.');
      });
    }
  }

  Future<void> _resend() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _info = null;
    });
    try {
      await UserRepository.instance.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _info = 'Yeni kodu gönderdik.';
      });
      _lastSentAt[widget.email] = DateTime.now();
      setState(() => _startCountdown(_resendSeconds));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = userMessageFor(e,
            fallback: 'Kod gönderilemedi, biraz sonra tekrar dene.');
      });
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
              const Text('E-postanı doğrula',
                  style: AppTextStyles.headlineLarge),
              const SizedBox(height: 8),
              Text.rich(
                TextSpan(children: [
                  TextSpan(
                    text: widget.email,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(
                      text: ' adresine gönderdiğimiz 6 haneli kodu gir.'),
                ]),
                style: AppTextStyles.bodyMedium
                    .copyWith(color: context.textSecondaryColor),
              ),
              const SizedBox(height: 28),
              Form(
                key: _formKey,
                child: AuthTextField(
                  controller: _codeController,
                  hint: '6 haneli kod',
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _verify(),
                  validator: (v) => (v == null || v.trim().length != 6)
                      ? 'Kod 6 haneli olmalı'
                      : null,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AuthErrorBox(message: _error!),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _verify,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
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
                          'Doğrula',
                          style: AppTextStyles.titleSmall.copyWith(
                              color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _info ??
                    'Kod gelmediyse spam klasörüne bakabilir veya yeni kod '
                        'isteyebilirsin.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySmall
                    .copyWith(color: context.textSecondaryColor),
              ),
              const SizedBox(height: 4),
              Center(
                child: TextButton(
                  onPressed: _isLoading || _resendLeft > 0 ? null : _resend,
                  child: Text(_resendLeft > 0
                      ? 'Kodu tekrar gönder ($_resendLeft sn)'
                      : 'Kodu tekrar gönder'),
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
