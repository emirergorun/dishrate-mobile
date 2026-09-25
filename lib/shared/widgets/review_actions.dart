import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';

import '../../core/network/moderation_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_metrics.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/menu_item_review_model.dart';
import 'sheet_error.dart';

/// Yorum menüsünde yapılan iş.
enum ReviewActionResult { reported, blocked }

/// Menüden dönen sonuç. Çağıran listeyi sunucudan yeniden yükler
/// (bildirilen ya da engellenenin yorumları artık gelmez) ve [message] ile
/// "Geri al" düğmeli şerit gösterir — yanlış dokunuş için (karar 25 Eylül).
class ReviewActionOutcome {
  const ReviewActionOutcome({
    required this.result,
    required this.ratingId,
    required this.authorName,
  });

  final ReviewActionResult result;
  final int ratingId;

  /// Yorumdaki ad, "@kullanıcıadı".
  final String authorName;

  String get message => switch (result) {
        ReviewActionResult.reported => 'Bildirimin alındı, teşekkürler.',
        ReviewActionResult.blocked => '$authorName engellendi.',
      };

  /// "Geri al": bildirimi ya da engeli kaldırır.
  Future<void> undo() => switch (result) {
        ReviewActionResult.reported =>
          ModerationRepository.instance.undoReport(ratingId),
        ReviewActionResult.blocked =>
          ModerationRepository.instance.unblockAuthor(ratingId),
      };
}

/// Başkasının yorumundaki "⋯" menüsü: bildir ya da yazarı engelle (1.7).
///
/// Apple, kullanıcı içeriği olan uygulamalarda ikisini de istiyor (Guideline
/// 1.2). Kullanıcı içeriği gösteren yeni bir yer eklenirse bu menü de
/// eklenmeli.
///
/// Her şey tek panelde olur: "Bildir" sebep listesini aynı panelde açar,
/// engelleme onayı panelin üstünde çıkar. Önceden menü kapanıp yerine yeni
/// panel ya da pencere açılıyordu; karartma kalkıp yeniden geldiği için ekran
/// "yenileniyor" gibi yanıp sönüyordu (25 Eylül).
abstract final class ReviewActions {
  static Future<ReviewActionOutcome?> show(
      BuildContext context, MenuItemReviewModel review) {
    return showModalBottomSheet<ReviewActionOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.sheetColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => _ReviewActionsSheet(review: review),
    );
  }
}

class _ReviewActionsSheet extends StatefulWidget {
  const _ReviewActionsSheet({required this.review});
  final MenuItemReviewModel review;

  @override
  State<_ReviewActionsSheet> createState() => _ReviewActionsSheetState();
}

/// Panelin o anki görünümü.
enum _Step { menu, reasons, note }

class _ReviewActionsSheetState extends State<_ReviewActionsSheet> {
  _Step _step = _Step.menu;
  ReportReason? _sending;
  String? _error;

  /// "Başka bir sebep"in açıklaması; incelemede neyin yanlış olduğunu
  /// anlatsın diye (karar 25 Eylül). İsteğe bağlı.
  final _noteCtrl = TextEditingController();

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  ReviewActionOutcome _outcome(ReviewActionResult result) =>
      ReviewActionOutcome(
        result: result,
        ratingId: widget.review.ratingId,
        authorName: widget.review.reviewerName,
      );

  Future<void> _report(ReportReason reason, {String? note}) async {
    if (_sending != null) return;
    setState(() {
      _sending = reason;
      _error = null;
    });
    try {
      await ModerationRepository.instance
          .report(widget.review.ratingId, reason, note: note);
      if (mounted) {
        Navigator.pop(context, _outcome(ReviewActionResult.reported));
      }
    } catch (_) {
      // Panel açık kalır; hata SnackBar'la verilseydi panelin arkasında kalırdı.
      if (mounted) {
        setState(() {
          _sending = null;
          _error = 'Bildirim gönderilemedi, tekrar dene.';
        });
      }
    }
  }

  /// Onay penceresi bu panelin üstünde açılır; panel kapanmaz.
  Future<void> _confirmBlock() async {
    final blocked = await showDialog<bool>(
      context: context,
      builder: (_) => _BlockDialog(
        ratingId: widget.review.ratingId,
        authorName: widget.review.reviewerName,
      ),
    );
    if (blocked == true && mounted) {
      Navigator.pop(context, _outcome(ReviewActionResult.blocked));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        alignment: Alignment.topCenter,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: switch (_step) {
            _Step.menu => _buildMenu(),
            _Step.reasons => _buildReasons(),
            _Step.note => _buildNote(),
          },
        ),
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      key: const ValueKey('menu'),
      mainAxisSize: MainAxisSize.min,
      children: [
        const _Handle(),
        ListTile(
          leading: Icon(TablerIcons.flag, color: context.textPrimaryColor),
          title: const Text('Bildir'),
          subtitle: const Text('Uygunsuz yorum ya da fotoğraf'),
          onTap: () => setState(() => _step = _Step.reasons),
        ),
        // İki seçenek arasında çizgi ve boşluk: yanlışlıkla engellemeye
        // basılmasın (karar 25 Eylül).
        const SizedBox(height: AppSpace.xs),
        Divider(
            height: 1,
            indent: AppSpace.screen,
            endIndent: AppSpace.screen,
            color: context.dividerColor),
        const SizedBox(height: AppSpace.xs),
        ListTile(
          leading: Icon(TablerIcons.user_off, color: context.errorTextColor),
          title: Text('Kullanıcıyı engelle',
              style: TextStyle(color: context.errorTextColor)),
          subtitle: const Text('Birbirinizin değerlendirmelerini görmezsiniz'),
          onTap: _confirmBlock,
        ),
        const SizedBox(height: AppSpace.sm),
      ],
    );
  }

  Widget _buildReasons() {
    return Column(
      key: const ValueKey('reasons'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(child: _Handle()),
        const Padding(
          padding: EdgeInsets.fromLTRB(
              AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.xxs),
          child: Text('Neden Bildiriyorsun?', style: AppTextStyles.titleSmall),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpace.screen, 0, AppSpace.screen, AppSpace.sm),
          child: Text(
            'Bildirimin incelenir; yorumu yazan kişi kimin bildirdiğini görmez.',
            style: AppTextStyles.bodySmall
                .copyWith(color: context.textSecondaryColor),
          ),
        ),
        // Büyük yazı boyutunda altı sebep ekrana sığmayabiliyor.
        Flexible(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final reason in ReportReason.values)
                  ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: AppSpace.screen),
                    title: Text(reason.label),
                    trailing: _sending == reason
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.primary),
                          )
                        : Icon(Icons.chevron_right_rounded,
                            color: context.textTertiaryColor),
                    enabled: _sending == null,
                    // "Başka bir sebep" açıklama adımına geçer; diğerleri
                    // tek dokunuşla gider.
                    onTap: reason == ReportReason.other
                        ? () => setState(() {
                              _step = _Step.note;
                              _error = null;
                            })
                        : () => _report(reason),
                  ),
              ],
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, 0),
            child: SheetError(_error!),
          ),
        const SizedBox(height: AppSpace.md),
      ],
    );
  }
}

extension on _ReviewActionsSheetState {
  Widget _buildNote() {
    final sending = _sending != null;
    return Padding(
      key: const ValueKey('note'),
      // Klavye açılınca alan ve düğme görünür kalsın.
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Center(child: _Handle()),
          const Padding(
            padding: EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.xs, AppSpace.screen, AppSpace.xxs),
            child: Text('Başka Bir Sebep', style: AppTextStyles.titleSmall),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, 0, AppSpace.screen, AppSpace.md),
            child: Text(
              'Kısaca anlatırsan inceleme kolaylaşır. İstersen boş bırakabilirsin.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: context.textSecondaryColor),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpace.screen),
            child: TextField(
              controller: _noteCtrl,
              autofocus: true,
              enabled: !sending,
              maxLines: 3,
              maxLength: 300,
              textCapitalization: TextCapitalization.sentences,
              style: AppTextStyles.bodyMedium,
              decoration: InputDecoration(
                hintText: 'Neyi uygunsuz buldun?',
                counterStyle: AppTextStyles.caption
                    .copyWith(color: context.textTertiaryColor),
              ),
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpace.screen, AppSpace.xs, AppSpace.screen, 0),
              child: SheetError(_error!),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpace.screen, AppSpace.md, AppSpace.screen, AppSpace.lg),
            child: ElevatedButton(
              onPressed: sending
                  ? null
                  : () => _report(ReportReason.other, note: _noteCtrl.text),
              child: sending
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : const Text('Gönder'),
            ),
          ),
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
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: context.dividerColor,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      ),
    );
  }
}

// ── Engelleme onayı ─────────────────────────────────────────────────────────

/// Engelleme penceresi; başarıyla engellerse `true` döner. Hata olursa
/// pencere açık kalır ve içinde gösterilir.
class _BlockDialog extends StatefulWidget {
  const _BlockDialog({required this.ratingId, required this.authorName});
  final int ratingId;
  final String authorName;

  @override
  State<_BlockDialog> createState() => _BlockDialogState();
}

class _BlockDialogState extends State<_BlockDialog> {
  bool _sending = false;
  String? _error;

  Future<void> _block() async {
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ModerationRepository.instance.blockAuthor(widget.ratingId);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _error = 'Engellenemedi, tekrar dene.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.surfaceColor,
      title: const Text('Kullanıcıyı Engelle', style: AppTextStyles.titleSmall),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${widget.authorName} ile birbirinizin değerlendirmelerini artık '
            'görmeyeceksiniz. Engeli Profil → Engellenenler’den kaldırabilirsin.',
            style: AppTextStyles.bodySmall,
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpace.md),
            SheetError(_error!),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _sending ? null : () => Navigator.pop(context, false),
          child: const Text('Vazgeç'),
        ),
        TextButton(
          onPressed: _sending ? null : _block,
          style: TextButton.styleFrom(foregroundColor: context.errorTextColor),
          child: _sending
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Engelle'),
        ),
      ],
    );
  }
}
