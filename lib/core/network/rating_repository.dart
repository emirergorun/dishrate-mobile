import '../constants/api_constants.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import '../../shared/models/rating_model.dart';
import '../../shared/models/rating_request_model.dart';

class RatingRepository {
  RatingRepository._();
  static final RatingRepository instance = RatingRepository._();

  final _dio = DioClient.instance;

  /// Create or update a rating (UPSERT)
  Future<void> submitRating(RatingRequestModel request) async {
    if (MockData.enabled) {
      MockData.addMockRating(
        userId: request.userId,
        menuItemId: request.menuItemId,
        score: request.score,
        comment: request.comment,
      );
      return;
    }
    await _dio.post(
      ApiConstants.ratings,
      data: request.toJson(),
    );
  }

  /// Get all ratings submitted by a user
  Future<List<RatingModel>> getRatingsByUser(int userId) async {
    if (MockData.enabled) {
      return MockData.getMockRatings(userId);
    }
    final response = await _dio.get('${ApiConstants.ratings}/user/$userId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RatingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Delete a rating by ID (average recalculated on backend)
  Future<void> deleteRating(int ratingId) async {
    if (MockData.enabled) {
      MockData.removeMockRating(ratingId);
      return;
    }
    await _dio.delete('${ApiConstants.ratings}/$ratingId');
  }
}
