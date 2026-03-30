import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/repositories/base_repository.dart';

final appDataRepositoryProvider = Provider<AppDataRepository>(
  (ref) => AppDataRepository(),
);

class AppDataRepository extends BaseRepository {
  Future<List<UserModel>> getTeamMembers() async {
    final response = await api.get(ApiConstants.users, useCache: true);
    return listFromResponse(response, UserModel.fromJson);
  }

  Future<WeeklyAnalytics?> getWeeklyAnalytics({String? userId}) async {
    final Map<String, String>? queryParams = userId != null
        ? {'userId': userId}
        : null;
    final response = await api.get(
      ApiConstants.weeklyAnalytics,
      queryParams: queryParams,
      useCache: true,
    );
    return itemFromResponse(response, WeeklyAnalytics.fromJson);
  }

  Future<List<TaskAssignment>> getMyTasks() async {
    final response = await api.get(ApiConstants.myTasks, useCache: true);
    return listFromResponse(response, TaskAssignment.fromJson);
  }

  Future<List<TaskAssignment>> getAssignedTasks() async {
    final response = await api.get(ApiConstants.assignedTasks, useCache: true);
    return listFromResponse(response, TaskAssignment.fromJson);
  }

  Future<List<PersonalProject>> getPersonalProjects() async {
    final response = await api.get(
      ApiConstants.personalProjects,
      useCache: true,
    );
    return listFromResponse(response, PersonalProject.fromJson);
  }

  Future<List<TeamProject>> getTeamProjects() async {
    final response = await api.get(ApiConstants.teamProjects, useCache: true);
    return listFromResponse(response, TeamProject.fromJson);
  }

  Future<List<UserModel>> getLeaderboard() async {
    final response = await api.get(ApiConstants.leaderboard, useCache: true);
    return listFromResponse(response, UserModel.fromJson);
  }

  // Sync methods for instant loading
  List<UserModel> getCachedTeamMembers() =>
      getCachedList(ApiConstants.users, null, UserModel.fromJson);
  WeeklyAnalytics? getCachedAnalytics({String? userId}) => getCachedItem(
    ApiConstants.weeklyAnalytics,
    userId != null ? {'userId': userId} : null,
    WeeklyAnalytics.fromJson,
  );
  List<UserModel> getCachedLeaderboard() =>
      getCachedList(ApiConstants.leaderboard, null, UserModel.fromJson);
}
