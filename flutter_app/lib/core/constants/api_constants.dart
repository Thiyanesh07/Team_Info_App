import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  // Configured via assets/.env
  static String get baseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'https://team-info-app.onrender.com/api';
  static String get socketUrl =>
      dotenv.env['SOCKET_URL'] ?? 'https://team-info-app.onrender.com';

  // Auth
  static const String googleLogin = '/auth/google';
  static const String me = '/auth/me';
  static const String fcmToken = '/auth/fcm-token';

  // Users
  static const String users = '/users';
  static const String updateProfile = '/users/profile';
  static const String updateOwnPoints = '/users/profile/points';
  static const String createUser = '/users/create';
  static const String psSync = '/users/ps-sync';

  // Projects
  static const String personalProjects = '/personal-projects';
  static const String teamProjects = '/team-projects';
  static const String projectUpdates = '/project-updates';

  // Modules
  static const String hackathons = '/hackathons';
  static const String learning = '/learning';
  static const String activities = '/activities';
  static const String unifiedActivities = '/system-activities/unified';
  static const String milestones = '/milestones';
  static const String certifications = '/certifications';
  static const String psSkills = '/ps-skills';

  // Chat
  static const String teamChat = '/chat/team';
  static const String teamChatPinned = '/chat/team/pinned';
  static const String conversations = '/chat/conversations';

  // Analytics
  static const String weeklyAnalytics = '/analytics/weekly';
  static const String leaderboard = '/analytics/leaderboard';
  static const String teamWorkload = '/analytics/team-workload';
  static const String rewardStatus = '/analytics/reward-status';

  // Upload
  static const String uploadImage = '/upload/image';
  static const String uploadFile = '/upload/image'; // Backend now supports auto

  // Tasks
  static const String myTasks = '/tasks/my';
  static const String assignedTasks = '/tasks/assigned';
  static const String allTasks = '/tasks/all';
  static const String tasks = '/tasks';

  // Reports
  static const String myPendingReports = '/reports/my-pending';
  static const String reportRequest = '/reports/request';
  static const String reportSubmissions = '/reports/submissions';
  static const String reportReview = '/reports/review';
  static const String manageableReports = '/reports/manageable';
  static const String submitReport = '/reports/submit';

  // Admin
  static const String adminOverview = '/admin/overview';
  static const String adminUserDetail = '/admin/users';
  static const String syncRewards = '/admin/sync/rewards';

  // Export
  static const String exportActivities = '/export/activities';
  static const String exportProjects = '/export/projects';
  static const String exportHackathons = '/export/hackathons';
  static const String exportSkills = '/export/p-skills';
  static const String exportLearning = '/export/learning';
  static const String exportCertifications = '/export/certifications';

  // System
  static const String systemConfig = '/system/config';
}
