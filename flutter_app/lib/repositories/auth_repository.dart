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
    ApiResponse lastResponse = ApiResponse(
      success: false,
      message: 'Network issue while contacting server.',
    );

    for (int attempt = 1; attempt <= 3; attempt++) {
      final response = await api
          .post(
            ApiConstants.googleLogin,
            body: {'idToken': idToken},
            withAuth: false,
          )
          .timeout(
            const Duration(seconds: 90),
            onTimeout: () => ApiResponse(
              success: false,
              message:
                  'Server is waking up. Please try again in 10-20 seconds.',
            ),
          );

      if (response.success) return response;

      lastResponse = response;
      final msg = (response.message ?? '').toLowerCase();
      final transientNetworkFailure =
          msg.contains('network error') ||
          msg.contains('clientexception') ||
          msg.contains('software caused connection abort') ||
          msg.contains('connection closed');

      if (!transientNetworkFailure || attempt == 3) {
        break;
      }

      try {
        await healthCheck().timeout(const Duration(seconds: 20));
      } catch (_) {}

      await Future.delayed(Duration(seconds: attempt * 2));
    }

    final finalMsg = (lastResponse.message ?? '').toLowerCase();
    if (finalMsg.contains('clientexception') ||
        finalMsg.contains('network error')) {
      return ApiResponse(
        success: false,
        message:
            'Network issue while connecting to server. Please retry in 10-20 seconds.',
      );
    }

    return lastResponse;
  }

  Future<ApiResponse> healthCheck() => api.get('/health');

  Future<String?> getToken() => api.getToken();
  Future<void> saveToken(String token) => api.saveToken(token);
  Future<void> deleteToken() => api.deleteToken();
}
