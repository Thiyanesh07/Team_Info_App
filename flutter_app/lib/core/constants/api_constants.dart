class ApiConstants {
  // Change this to your deployed backend URL
  static const String baseUrl = 'http://localhost:3000/api';
  static const String socketUrl = 'http://localhost:3000';

  // Auth
  static const String googleLogin = '/auth/google';
  static const String me = '/auth/me';
  static const String fcmToken = '/auth/fcm-token';

  // Users
  static const String users = '/users';
  static const String updateProfile = '/users/profile';
  static const String createUser = '/users/create';

  // Projects
  static const String personalProjects = '/personal-projects';
  static const String teamProjects = '/team-projects';
  static const String projectUpdates = '/project-updates';

  // Modules
  static const String hackathons = '/hackathons';
  static const String learning = '/learning';
  static const String activities = '/activities';
  static const String certifications = '/certifications';
  static const String psSkills = '/ps-skills';

  // Chat
  static const String teamChat = '/chat/team';
  static const String teamChatPinned = '/chat/team/pinned';
  static const String conversations = '/chat/conversations';

  // Analytics
  static const String weeklyAnalytics = '/analytics/weekly';
  static const String leaderboard = '/analytics/leaderboard';

  // Upload
  static const String uploadImage = '/upload/image';

  // Tasks
  static const String myTasks = '/tasks/my';
  static const String assignedTasks = '/tasks/assigned';
  static const String allTasks = '/tasks/all';
  static const String tasks = '/tasks';
}
