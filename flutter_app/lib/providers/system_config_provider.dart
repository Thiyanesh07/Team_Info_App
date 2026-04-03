import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_info_app/services/api_service.dart';
import 'package:team_info_app/core/constants/api_constants.dart';

class SystemConfig {
  final bool apSyncEnabled;

  SystemConfig({required this.apSyncEnabled});

  factory SystemConfig.fromJson(Map<String, dynamic> json) {
    return SystemConfig(
      apSyncEnabled: json['apSyncEnabled'] ?? true,
    );
  }
}

class SystemConfigNotifier extends StateNotifier<AsyncValue<SystemConfig>> {
  final ApiService _api;

  SystemConfigNotifier(this._api) : super(const AsyncValue.loading()) {
    fetchConfig();
  }

  Future<void> fetchConfig() async {
    try {
      final res = await _api.get(ApiConstants.systemConfig);
      if (res.success && res.data != null) {
        state = AsyncValue.data(SystemConfig.fromJson(res.data));
      } else {
        state = AsyncValue.error(res.message ?? 'Failed to fetch config', StackTrace.current);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<bool> updateConfig({bool? apSyncEnabled}) async {
    try {
      final res = await _api.patch(
        ApiConstants.systemConfig,
        body: {
          if (apSyncEnabled != null) 'apSyncEnabled': apSyncEnabled,
        },
      );
      if (res.success && res.data != null) {
        state = AsyncValue.data(SystemConfig.fromJson(res.data));
        return true;
      }
    } catch (e) {
      // Log or handle error
    }
    return false;
  }
}

final systemConfigProvider =
    StateNotifierProvider<SystemConfigNotifier, AsyncValue<SystemConfig>>((ref) {
  return SystemConfigNotifier(ApiService());
});
