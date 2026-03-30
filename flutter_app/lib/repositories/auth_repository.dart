import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/repositories/base_repository.dart';
import 'package:team_info_app/services/api_service.dart';

class AuthRepository extends BaseRepository {
  Future<UserModel?> getMe() async {
    final response = await api.get(ApiConstants.me);
    if (response.success && response.data != null) {
      return UserModel.fromJson(response.data as Map<String, dynamic>);
    }
    return null;
  }

  Future<ApiResponse> loginWithGoogle(String idToken) async {
    return await api.post(
      ApiConstants.googleLogin,
      body: {'idToken': idToken},
      withAuth: false,
    ).timeout(
      const Duration(seconds: 90),
      onTimeout: () => ApiResponse(
        success: false,
        message: 'Server is waking up. Please try again in 10-20 seconds.',
      ),
    );
  }

  Future<ApiResponse> healthCheck() => api.get('/health');

  Future<String?> getToken() => api.getToken();
  Future<void> saveToken(String token) => api.saveToken(token);
  Future<void> deleteToken() => api.deleteToken();
}
