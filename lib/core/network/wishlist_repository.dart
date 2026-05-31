import '../constants/api_constants.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import '../../shared/models/wishlist_model.dart';

class WishlistRepository {
  WishlistRepository._();
  static final WishlistRepository instance = WishlistRepository._();

  final _dio = DioClient.instance;

  Future<List<WishlistModel>> getWishlist(int userId) async {
    if (MockData.enabled) {
      return MockData.getMockWishlist();
    }
    final response =
        await _dio.get('${ApiConstants.wishlist}/user/$userId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => WishlistModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> addToWishlist(int userId, int menuItemId) async {
    if (MockData.enabled) {
      MockData.addMockWishlistItem(menuItemId);
      return;
    }
    await _dio.post(ApiConstants.wishlist, data: {
      'userId': userId,
      'menuItemId': menuItemId,
    });
  }

  Future<void> removeFromWishlist(int wishId) async {
    if (MockData.enabled) {
      MockData.removeMockWishlistItem(wishId);
      return;
    }
    await _dio.delete('${ApiConstants.wishlist}/$wishId');
  }

  /// Bir menü öğesi değerlendirildiğinde istek listesinden otomatik kaldırmak için.
  Future<void> removeByMenuItemId(int userId, int menuItemId) async {
    if (MockData.enabled) {
      MockData.removeMockWishlistByMenuItemId(menuItemId);
      return;
    }
    try {
      final wishlist = await getWishlist(userId);
      final match = wishlist.where((w) => w.menuItemId == menuItemId).firstOrNull;
      if (match != null) {
        await removeFromWishlist(match.wishId);
      }
    } catch (_) {
      // best-effort — rating akışını etkilemesin
    }
  }
}
