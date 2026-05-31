import '../constants/api_constants.dart';
import '../mock/mock_data.dart';
import 'dio_client.dart';
import '../../shared/models/user_model.dart';

class UserRepository {
  UserRepository._();
  static final UserRepository instance = UserRepository._();

  final _dio = DioClient.instance;

  Future<UserModel> getUser(int userId) async {
    if (MockData.enabled) return MockData.mockUser;
    final response = await _dio.get('${ApiConstants.users}/$userId');
    return UserModel.fromJson(response.data as Map<String, dynamic>);
  }
}
