import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';

/// Kullanım şartları paneli. Profil menüsünden ve kayıt ekranındaki
/// "Kayıt olarak Kullanım Şartları’nı kabul etmiş olursun." bağlantısından
/// açılır (1.7).
///
/// Metin geçici: yol haritası 4.3'te hukuki metinle değişecek. O yüzden hâlâ
/// siz dilinde (MARKA.md §6'daki tek istisna).
class TermsSheet extends StatelessWidget {
  const TermsSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: context.surfaceColor,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.lg))),
      builder: (_) => const TermsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, controller) => Column(
        children: [
          const _Handle(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.md),
            child: Row(
              children: [
                Icon(TablerIcons.file_text,
                    color: context.textSecondaryColor, size: 20),
                const SizedBox(width: AppSpace.sm),
                const Text('Kullanım Şartları',
                    style: AppTextStyles.titleSmall),
              ],
            ),
          ),
          Container(height: 0.5, color: context.dividerColor),
          Expanded(
            child: ListView(
              controller: controller,
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen, AppSpace.lg, AppSpace.screen, 40),
              children: [
                const _TermsSection(
                  title: '1. Kabul',
                  body:
                      'Dishrate\'i kullanarak bu kullanım şartlarını kabul etmiş olursunuz. Şartları kabul etmiyorsanız uygulamayı kullanmayı bırakınız.',
                ),
                const _TermsSection(
                  title: '2. Kullanıcı İçeriği',
                  body:
                      'Paylaştığınız değerlendirmeler ve yorumlar size aittir ve diğer kullanıcılara kullanıcı adınızla görünür; adınız ve soyadınız gösterilmez. Dishrate, bu içerikleri platform içinde görüntüleme ve analiz etme hakkına sahiptir. Yanıltıcı, hakaret içerikli veya yasadışı içerik paylaşmak yasaktır.',
                ),
                // Apple Guideline 1.2: kullanıcının kabul ettiği şartlarda
                // uygunsuz içeriğe tolerans olmadığı açıkça yazmalı.
                const _TermsSection(
                  title: '3. Uygunsuz İçerik',
                  body:
                      'Dishrate\'te hakaret, nefret söylemi, taciz, müstehcen ya da şiddet içeren içerik, spam ve reklam, başkalarına ait kişisel bilgiler ve yemekle ilgisi olmayan içerik paylaşmak yasaktır; bu tür içeriğe tolerans gösterilmez. Uygunsuz bulduğunuz bir yorumu ya da fotoğrafı "Bildir" ile bize iletebilir, yazarını engelleyebilirsiniz. Bildirilen içerik incelenir ve kurala aykırıysa kaldırılır; kuralı çiğneyen hesaplar kapatılır.',
                ),
                const _TermsSection(
                  title: '4. Gizlilik',
                  body:
                      'Kişisel verileriniz 6698 sayılı KVKK kapsamında korunmaktadır. Verileriniz üçüncü şahıslarla paylaşılmaz. Ayrıntılı bilgi için Gizlilik Politikamızı inceleyiniz.',
                ),
                const _TermsSection(
                  title: '5. Hesap Güvenliği',
                  body:
                      'Hesabınızın güvenliğinden siz sorumlusunuz. Şifrenizi güçlü tutun ve başkalarıyla paylaşmayın. Yetkisiz erişim şüphesinde derhal bizimle iletişime geçin.',
                ),
                const _TermsSection(
                  title: '6. Hizmet Değişiklikleri',
                  body:
                      'Dishrate, herhangi bir bildirim yapmaksızın hizmeti geçici veya kalıcı olarak değiştirme ya da sonlandırma hakkını saklı tutar.',
                ),
                const _TermsSection(
                  title: '7. İletişim',
                  body:
                      'Sorularınız için destek@dishrate.app adresine e-posta gönderebilirsiniz.',
                ),
                const SizedBox(height: AppSpace.sm),
                Text(
                  'Son güncelleme: Eylül 2026',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: context.textTertiaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TermsSection extends StatelessWidget {
  const _TermsSection({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.screen),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTextStyles.titleSmall
                  .copyWith(color: context.textPrimaryColor)),
          const SizedBox(height: 6),
          Text(body, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

class _Handle extends StatelessWidget {
  const _Handle();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.md, bottom: AppSpace.sm),
      child: Center(
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.dividerColor,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
        ),
      ),
    );
  }
}
