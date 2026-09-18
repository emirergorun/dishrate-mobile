import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/turkish_text.dart';

/// Listenin en üstüne sabitlenen seçenek — aramadan etkilenmez.
///
/// "Tüm İstanbul" (il geneli) ve "Konumumu kullan" (GPS) gibi, alfabetik
/// sıranın parçası olmayan ama her zaman erişilebilir olması gereken
/// seçenekler için.
@immutable
class PinnedOption {
  const PinnedOption(this.label, {this.icon});
  final String label;
  final IconData? icon;
}

/// Aranabilir liste seçici.
///
/// Mahalle listesi bir ilçede yüzlerce kayıt olabiliyor; açılır menü yerine
/// arama kutulu tam ekran bir sayfa kullanıyoruz. Arama Türkçe'ye duyarlıdır:
/// "sisli" yazınca "Şişli" bulunur.
abstract final class SearchablePicker {
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    List<PinnedOption> pinned = const [],
    String? selected,
    String searchHint = 'Ara…',
  }) {
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.bgColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PickerSheet(
        title: title,
        options: options,
        pinned: pinned,
        selected: selected,
        searchHint: searchHint,
      ),
    );
  }
}

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.options,
    required this.pinned,
    required this.selected,
    required this.searchHint,
  });

  final String title;
  final List<String> options;
  final List<PinnedOption> pinned;
  final String? selected;
  final String searchHint;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  final _searchCtrl = TextEditingController();

  /// Alfabetik sıra Türkçe kurallarına göre — çağıran taraf sırasını
  /// korumak isterse bile burada garanti altına alınır.
  late final List<String> _sorted = TurkishText.sortedList(widget.options);
  late List<String> _visible = _sorted;

  /// Arama anahtarları önceden hesaplanır — her tuş vuruşunda 32.000 kaydı
  /// yeniden normalize etmemek için.
  late final Map<String, String> _keys = {
    for (final o in _sorted) o: TurkishText.searchKey(o),
  };

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filter(String query) {
    final q = TurkishText.searchKey(query.trim());
    setState(() {
      _visible = q.isEmpty
          ? _sorted
          : _sorted.where((o) => _keys[o]!.contains(q)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: context.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
              child: Row(
                children: [
                  Text(widget.title, style: AppTextStyles.titleMedium),
                  const Spacer(),
                  Text('${_visible.length}',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: context.textSecondaryColor)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchCtrl,
                autofocus: _sorted.length > 20,
                onChanged: _filter,
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchCtrl.text.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            _filter('');
                          },
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Sabit seçenekler ────────────────────────────────────────
            // Arama kutusunun altında, listenin dışında duruyorlar:
            // alfabetik sıraya karışmasınlar ve arama yapılırken de
            // kaybolmasınlar diye.
            for (final option in widget.pinned)
              ListTile(
                dense: true,
                leading: option.icon == null
                    ? null
                    : Icon(option.icon, color: AppColors.primary, size: 20),
                horizontalTitleGap: 8,
                title: Text(
                  option.label,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: option.label == widget.selected
                        ? AppColors.primary
                        : context.textPrimaryColor,
                  ),
                ),
                trailing: option.label == widget.selected
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.primary, size: 20)
                    : null,
                onTap: () => Navigator.pop(context, option.label),
              ),
            if (widget.pinned.isNotEmpty)
              Divider(height: 1, color: context.dividerColor),

            Expanded(
              child: _visible.isEmpty
                  ? Center(
                      child: Text('Sonuç bulunamadı',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: context.textSecondaryColor)),
                    )
                  : ListView.builder(
                      itemCount: _visible.length,
                      itemExtent: 52,
                      itemBuilder: (context, i) {
                        final option = _visible[i];
                        final isSelected = option == widget.selected;
                        return ListTile(
                          dense: true,
                          title: Text(
                            option,
                            style: AppTextStyles.bodyLarge.copyWith(
                              color: isSelected
                                  ? AppColors.primary
                                  : context.textPrimaryColor,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(Icons.check_rounded,
                                  color: AppColors.primary, size: 20)
                              : null,
                          onTap: () => Navigator.pop(context, option),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
