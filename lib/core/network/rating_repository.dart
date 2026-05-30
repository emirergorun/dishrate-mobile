import '../constants/api_constants.dart';
import 'dio_client.dart';
import '../../shared/models/rating_model.dart';
import '../../shared/models/rating_request_model.dart';

class RatingRepository {
  RatingRepository._();
  static final RatingRepository instance = RatingRepository._();

  final _dio = DioClient.instance;

  /// Create or update a rating (UPSERT)
  Future<void> submitRating(RatingRequestModel request) async {
    await _dio.post(
      ApiConstants.ratings,
      data: request.toJson(),
    );
  }

  /// Get all ratings submitted by a user
  Future<List<RatingModel>> getRatingsByUser(int userId) async {
    final response = await _dio.get('${ApiConstants.ratings}/user/$userId');
    final list = response.data as List<dynamic>;
    return list
        .map((e) => RatingModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
