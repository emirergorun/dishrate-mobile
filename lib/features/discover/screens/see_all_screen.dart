import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/menu_item_model.dart';
import '../widgets/menu_item_card.dart';

class SeeAllScreen extends StatelessWidget {
  const SeeAllScreen({
    super.key,
    required this.title,
    required this.items,
  });

  final String title;
  final List<MenuItemModel> items;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.bgColor,
      appBar: AppBar(
        backgroundColor: context.bgColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: context.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(title, style: AppTextStyles.titleMedium),
        titleSpacing: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: context.dividerColor),
        ),
      ),
      body: items.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_meals_rounded,
                      color: AppColors.textDisabled, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'İçerik bulunamadı',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 180 / 230,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) => MenuItemCard(
                item: items[index],
                onTap: () {
                  // TODO: menü öğesi detay sayfası
                },
              ),
            ),
    );
  }
}
