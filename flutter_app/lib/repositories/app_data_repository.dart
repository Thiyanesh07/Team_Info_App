import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:team_info_app/core/constants/api_constants.dart';
import 'package:team_info_app/models/app_models.dart';
import 'package:team_info_app/models/user_model.dart';
import 'package:team_info_app/repositories/base_repository.dart';
import 'package:team_info_app/services/api_service.dart';

final appDataRepositoryProvider = Provider<AppDataRepository>(
  (ref) => AppDataRepository(),
);

class AppDataRepository extends BaseRepository {
  Future<PaginatedList<UserModel>> getTeamMembers({int page = 1, int limit = 20}) async {
    final response = await api.get(
      ApiConstants.users,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
      useCache: page == 1,
    );
    return paginatedFromResponse(response, UserModel.fromJson);
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

  Future<List<Map<String, dynamic>>> getTeamWorkload() async {
    final response = await api.get(ApiConstants.teamWorkload, useCache: true);
    final List<dynamic> data = response.data as List<dynamic>? ?? [];
    return data.cast<Map<String, dynamic>>();
  }

  Future<PaginatedList<TaskAssignment>> getMyTasks({int page = 1, int limit = 20}) async {
    final response = await api.get(
      ApiConstants.myTasks,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
      useCache: page == 1,
    );
    return paginatedFromResponse(response, TaskAssignment.fromJson);
  }

  Future<PaginatedList<TaskAssignment>> getAssignedTasks({int page = 1, int limit = 20}) async {
    final response = await api.get(
      ApiConstants.assignedTasks,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
      useCache: page == 1,
    );
    return paginatedFromResponse(response, TaskAssignment.fromJson);
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

  Future<List<ActivityItem>> getUnifiedActivity() async {
    final response = await api.get(
      ApiConstants.unifiedActivities,
      useCache: true,
    );
    return listFromResponse(response, ActivityItem.fromJson);
  }

  Future<List<ProjectMilestone>> getMilestones(String projectId) async {
    final response = await api.get(
      '${ApiConstants.milestones}/project/$projectId',
      useCache: true,
    );
    return listFromResponse(response, ProjectMilestone.fromJson);
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

  List<ActivityItem> getCachedUnifiedActivity() => getCachedList(
    ApiConstants.unifiedActivities,
    null,
    ActivityItem.fromJson,
  );

  // ─── Reports ───────────────────────────────

  Future<PaginatedList<ReportRequest>> getMyPendingReports({int page = 1, int limit = 20}) async {
    final response = await api.get(
      ApiConstants.myPendingReports,
      queryParams: {'page': page.toString(), 'limit': limit.toString()},
      useCache: page == 1,
    );
    return paginatedFromResponse(response, ReportRequest.fromJson);
  }

  Future<List<ReportRequest>> getManageableRequests() async {
    final response = await api.get(ApiConstants.manageableReports, useCache: true);
    return listFromResponse(response, ReportRequest.fromJson);
  }

  Future<ApiResponse> createReportRequest(Map<String, dynamic> data) async {
    return await api.post(ApiConstants.reportRequest, body: data);
  }

  Future<ApiResponse> submitReport(String requestId, String fileUrl, String notes) async {
    return await api.post(
      '${ApiConstants.submitReport}/$requestId',
      body: {
        'fileUrl': fileUrl,
        'notes': notes,
      },
    );
  }

  Future<List<ReportSubmission>> getSubmissionsForRequest(String requestId) async {
    final response = await api.get('${ApiConstants.reportSubmissions}/$requestId');
    return listFromResponse(response, ReportSubmission.fromJson);
  }

  Future<ApiResponse> reviewSubmission(String submissionId, String status, String notes) async {
    return await api.patch(
      '${ApiConstants.reportReview}/$submissionId',
      body: {
        'status': status,
        'reviewerNotes': notes,
      },
    );
  }

  Future<ApiResponse> deleteReportRequest(String requestId) async {
    return await api.delete('${ApiConstants.reportRequest}/$requestId');
  }

  Future<ApiResponse> deleteReportSubmission(String submissionId) async {
    return await api.delete('/reports/submission/$submissionId');
  }
}
