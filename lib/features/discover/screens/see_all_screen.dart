import 'package:flutter/material.dart';
import 'package:flutter_tabler_icons/flutter_tabler_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_metrics.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../../../shared/widgets/state_message.dart';
import '../widgets/menu_item_card.dart';

class SeeAllScreen extends StatelessWidget {
  const SeeAllScreen({
    super.key,
    required this.title,
    required this.items,
    this.onItemTap,
  });

  final String title;
  final List<MenuItemModel> items;
  final void Function(MenuItemModel)? onItemTap;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        leading: IconButton(
          icon: const Icon(TablerIcons.chevron_left),
          tooltip: 'Geri',
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: AppTextStyles.titleMedium
              .copyWith(color: context.textPrimaryColor),
        ),
        titleSpacing: 0,
      ),
      body: items.isEmpty
          ? const Padding(
              padding: EdgeInsets.fromLTRB(
                  AppSpace.screen, AppSpace.xxl, AppSpace.screen, 0),
              child: StateMessage(
                title: 'İçerik bulunamadı',
                message: 'Bu listede henüz yemek yok.',
              ),
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                const gap = AppSpace.md;
                final cardWidth =
                    (constraints.maxWidth - AppSpace.screen * 2 - gap) / 2;
                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(AppSpace.screen,
                      AppSpace.md, AppSpace.screen, AppSpace.xxl),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: gap,
                    mainAxisSpacing: AppSpace.xl,
                    // Sabit oran yerine hesaplanan yükseklik: iki satırlık
                    // yemek adı ya da büyük yazı ölçeği kartı kesmesin.
                    mainAxisExtent: MenuItemCard.heightFor(context, cardWidth),
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) => MenuItemCard(
                    item: items[index],
                    onTap: () => onItemTap?.call(items[index]),
                  ),
                );
              },
            ),
    );
  }
}
