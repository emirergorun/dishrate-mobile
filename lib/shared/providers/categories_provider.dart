import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_categories.dart';
import '../../core/network/restaurant_repository.dart';
import '../models/category_model.dart';

/// Kategori listesi sunucudan, uygulama açıkken bir kez (2.10b). Sunucuya
/// eklenen kategori uygulama güncellenmeden çip olarak görünür.
///
/// Bağlantı yoksa ya da liste boş gelirse yedek liste döner; çip şeridi hiç
/// boş kalmaz.
final categoriesProvider = FutureProvider<List<CategoryModel>>((ref) async {
  try {
    final list = await RestaurantRepository.instance.getCategories();
    return list.isEmpty ? AppCategories.fallback : list;
  } catch (_) {
    return AppCategories.fallback;
  }
});

/// Liste yüklenene kadar yedek liste — ekranlar beklemeden çiz.
List<CategoryModel> watchCategories(WidgetRef ref) =>
    ref.watch(categoriesProvider).valueOrNull ?? AppCategories.fallback;
