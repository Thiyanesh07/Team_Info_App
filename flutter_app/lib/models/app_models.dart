// ignore_for_file: constant_identifier_names

import 'package:json_annotation/json_annotation.dart';

part 'app_models.g.dart';

// ─── Personal Project ─────────────────────────
@JsonSerializable()
class PersonalProject {
  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? contribution;
  final String? githubLink;
  final String? liveLink;
  final List<String> skillsUsed;
  final String? createdAt;

  PersonalProject({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.contribution,
    this.githubLink,
    this.liveLink,
    this.skillsUsed = const [],
    this.createdAt,
  });

  factory PersonalProject.fromJson(Map<String, dynamic> json) =>
      _$PersonalProjectFromJson(json);

  Map<String, dynamic> toJson() => _$PersonalProjectToJson(this);
}

// ─── Team Project ─────────────────────────────
@JsonSerializable()
class TeamProject {
  final String id;
  final String projectName;
  final Map<String, dynamic>? createdBy;
  final Map<String, dynamic>? assignedCaptain;
  final String? domain;
  final String? subDomain;
  final String? problemStatement;
  final String? solution;
  final String? startDate;
  final String status;
  final List<TeamProjectMember> members;
  final String? createdAt;

  TeamProject({
    required this.id,
    required this.projectName,
    this.createdBy,
    this.assignedCaptain,
    this.domain,
    this.subDomain,
    this.problemStatement,
    this.solution,
    this.startDate,
    this.status = 'NOT_STARTED',
    this.members = const [],
    this.createdAt,
  });

  factory TeamProject.fromJson(Map<String, dynamic> json) =>
      _$TeamProjectFromJson(json);

  Map<String, dynamic> toJson() => _$TeamProjectToJson(this);
}

@JsonSerializable()
class TeamProjectMember {
  final String id;
  final String userId;
  final Map<String, dynamic>? user;

  TeamProjectMember({required this.id, required this.userId, this.user});

  factory TeamProjectMember.fromJson(Map<String, dynamic> json) =>
      _$TeamProjectMemberFromJson(json);

  Map<String, dynamic> toJson() => _$TeamProjectMemberToJson(this);
}

@JsonSerializable()
class ProjectUpdate {
  final String id;
  final String projectId;
  final String userId;
  final String title;
  final String? description;
  final String? date;
  final Map<String, dynamic>? user;
  final String? createdAt;
  final String? updatedAt;

  ProjectUpdate({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.title,
    this.description,
    this.date,
    this.user,
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectUpdate.fromJson(Map<String, dynamic> json) =>
      _$ProjectUpdateFromJson(json);

  Map<String, dynamic> toJson() => _$ProjectUpdateToJson(this);
}

@JsonSerializable()
class Hackathon {
  final String id;
  final String userId;
  final String hackName;
  final String? projectName;
  final String? description;
  final String? contribution;
  final List<String> skillsUsed;
  final String? date;
  final bool isTeam;
  final List<String> teamMembers;
  final String status;
  final List<HackathonRound> rounds;
  final String? createdAt;

  Hackathon({
    required this.id,
    required this.userId,
    required this.hackName,
    this.projectName,
    this.description,
    this.contribution,
    this.skillsUsed = const [],
    this.date,
    this.isTeam = false,
    this.teamMembers = const [],
    this.status = 'UPCOMING',
    this.rounds = const [],
    this.createdAt,
  });

  factory Hackathon.fromJson(Map<String, dynamic> json) =>
      _$HackathonFromJson(json);

  Map<String, dynamic> toJson() => _$HackathonToJson(this);
}

@JsonSerializable()
class HackathonRound {
  final String? id;
  final String roundName;
  final String? description;

  HackathonRound({this.id, required this.roundName, this.description});

  factory HackathonRound.fromJson(Map<String, dynamic> json) =>
      _$HackathonRoundFromJson(json);

  Map<String, dynamic> toJson() => _$HackathonRoundToJson(this);
}

@JsonSerializable()
class Learning {
  final String id;
  final String userId;
  final String skillName;
  final List<String> topics;
  final String? startDate;
  final String? endDate;
  final String level;
  final String status;
  final String? createdAt;

  Learning({
    required this.id,
    required this.userId,
    required this.skillName,
    this.topics = const [],
    this.startDate,
    this.endDate,
    this.level = 'BEGINNER',
    this.status = 'ONGOING',
    this.createdAt,
  });

  factory Learning.fromJson(Map<String, dynamic> json) =>
      _$LearningFromJson(json);

  Map<String, dynamic> toJson() => _$LearningToJson(this);
}

// ─── Daily Activity ───────────────────────────
@JsonSerializable()
class DailyActivity {
  final String id;
  final String userId;
  final String type;
  final String? customType;
  final String? description;
  final String startTime;
  final String endTime;
  final String date;
  final Map<String, dynamic>? user;
  final String? createdAt;

  DailyActivity({
    required this.id,
    required this.userId,
    required this.type,
    this.customType,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.date,
    this.user,
    this.createdAt,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) =>
      _$DailyActivityFromJson(json);

  Map<String, dynamic> toJson() => _$DailyActivityToJson(this);
}

@JsonSerializable()
class Certification {
  final String id;
  final String userId;
  final String skill;
  final String? provider;
  final String? description;
  final String? issuedDate;
  final String? createdAt;

  Certification({
    required this.id,
    required this.userId,
    required this.skill,
    this.provider,
    this.description,
    this.issuedDate,
    this.createdAt,
  });

  factory Certification.fromJson(Map<String, dynamic> json) =>
      _$CertificationFromJson(json);

  Map<String, dynamic> toJson() => _$CertificationToJson(this);
}

@JsonSerializable()
class PsSkill {
  final String id;
  final String userId;
  final String type;
  final String skillName;
  final String? level;
  final String? completedDate;
  final bool completed;
  final String? createdAt;

  PsSkill({
    required this.id,
    required this.userId,
    required this.type,
    required this.skillName,
    this.level,
    this.completedDate,
    this.completed = false,
    this.createdAt,
  });

  factory PsSkill.fromJson(Map<String, dynamic> json) =>
      _$PsSkillFromJson(json);

  Map<String, dynamic> toJson() => _$PsSkillToJson(this);
}

@JsonSerializable()
class TeamMessage {
  final String id;
  final String? senderIdValue;
  final String? message;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final String? replyToId;
  final TeamMessage? replyTo;
  final Map<String, dynamic>? reactions;
  final bool isPinned;
  final bool isRead;
  final bool isDelivered;
  final String timestamp;
  final Map<String, dynamic>? sender;

  TeamMessage({
    required this.id,
    this.senderIdValue,
    this.message,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.replyToId,
    this.replyTo,
    this.reactions,
    this.isPinned = false,
    this.isRead = false,
    this.isDelivered = false,
    required this.timestamp,
    this.sender,
  });

  factory TeamMessage.fromJson(Map<String, dynamic> json) =>
      _$TeamMessageFromJson(json);

  Map<String, dynamic> toJson() => _$TeamMessageToJson(this);

  // Tactical ID getter
  String get senderId => (sender?['id'] ?? senderIdValue ?? '').toString();
}

@JsonSerializable()
class ChatConversation {
  final String id;
  final List<Map<String, dynamic>> participants;
  final List<Map<String, dynamic>> messages;
  final int unreadCount;
  final String? updatedAt;

  ChatConversation({
    required this.id,
    this.participants = const [],
    this.messages = const [],
    this.unreadCount = 0,
    this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) =>
      _$ChatConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ChatConversationToJson(this);
}

@JsonSerializable()
class ChatMessage {
  final String id;
  final String conversationId;
  final String? senderIdValue;
  final String? message;
  final String? imageUrl;
  final String? fileUrl;
  final String? fileName;
  final String? fileType;
  final String? replyToId;
  final ChatMessage? replyTo;
  final Map<String, dynamic>? reactions;
  final bool isPinned;
  final bool isRead;
  final bool isDelivered;
  final String timestamp;
  final Map<String, dynamic>? sender;

  ChatMessage({
    required this.id,
    required this.conversationId,
    this.senderIdValue,
    this.message,
    this.imageUrl,
    this.fileUrl,
    this.fileName,
    this.fileType,
    this.replyToId,
    this.replyTo,
    this.reactions,
    this.isPinned = false,
    this.isRead = false,
    this.isDelivered = false,
    required this.timestamp,
    this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) =>
      _$ChatMessageFromJson(json);

  Map<String, dynamic> toJson() => _$ChatMessageToJson(this);

  // Aliases for mission-critical synchronization
  factory ChatMessage.fromMap(Map<String, dynamic> map) =>
      ChatMessage.fromJson(map);
  Map<String, dynamic> toMap() => toJson();

  // Tactical ID getter
  String get senderId => (sender?['id'] ?? senderIdValue ?? '').toString();
}

@JsonSerializable()
class WeeklyAnalytics {
  final double totalHours;
  final double learningHours;
  final double projectHours;
  final double otherHours;
  final int activeDays;
  final int consistencyScore;
  final String? bestDay;
  final double bestDayHours;
  final Map<String, dynamic> dailyBreakdown;
  final Map<String, dynamic> dailyActivityCount;
  final int totalActivities;

  WeeklyAnalytics({
    this.totalHours = 0,
    this.learningHours = 0,
    this.projectHours = 0,
    this.otherHours = 0,
    this.activeDays = 0,
    this.consistencyScore = 0,
    this.bestDay,
    this.bestDayHours = 0,
    this.dailyBreakdown = const {},
    this.dailyActivityCount = const {},
    this.totalActivities = 0,
  });

  factory WeeklyAnalytics.fromJson(Map<String, dynamic> json) =>
      _$WeeklyAnalyticsFromJson(json);

  Map<String, dynamic> toJson() => _$WeeklyAnalyticsToJson(this);
}

@JsonSerializable()
class TaskAssignment {
  final String id;
  final String title;
  final String? description;
  final Map<String, dynamic>? assignedBy;
  final Map<String, dynamic>? assignedTo;
  final String? deadline;
  final String? originalDeadline;
  final String priority;
  final String status;
  // Use @JsonKey to map the Prisma count correctly
  @JsonKey(name: '_count')
  final Map<String, dynamic>? count;
  final String? createdAt;
  final String? updatedAt;

  TaskAssignment({
    required this.id,
    required this.title,
    this.description,
    this.assignedBy,
    this.assignedTo,
    this.deadline,
    this.originalDeadline,
    this.priority = 'MEDIUM',
    this.status = 'PENDING',
    this.count,
    this.createdAt,
    this.updatedAt,
  });

  // Getter for the report count from the count map
  int get reportCount => count?['reports'] ?? 0;

  factory TaskAssignment.fromJson(Map<String, dynamic> json) =>
      _$TaskAssignmentFromJson(json);

  Map<String, dynamic> toJson() => _$TaskAssignmentToJson(this);
}

@JsonSerializable()
class TaskReport {
  final String id;
  final String taskId;
  final String userId;
  final String reportText;
  final Map<String, dynamic>? user;
  final String? createdAt;

  TaskReport({
    required this.id,
    required this.taskId,
    required this.userId,
    required this.reportText,
    this.user,
    this.createdAt,
  });

  factory TaskReport.fromJson(Map<String, dynamic> json) =>
      _$TaskReportFromJson(json);

  Map<String, dynamic> toJson() => _$TaskReportToJson(this);
}

// ─── Engineering Powerhouse Extensions ──────────

enum ActivityItemType { DAILY_LOG, PROJECT_UPDATE, TASK_REPORT, SYSTEM_EVENT }

@JsonSerializable()
class ActivityItem {
  final String id;
  final String userId;
  final String title;
  final String content;
  final String timestamp;
  final ActivityItemType type;
  final Map<String, dynamic>? user;
  final String? metadata; // JSON string for extra data

  ActivityItem({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.timestamp,
    required this.type,
    this.user,
    this.metadata,
  });

  factory ActivityItem.fromJson(Map<String, dynamic> json) =>
      _$ActivityItemFromJson(json);
  Map<String, dynamic> toJson() => _$ActivityItemToJson(this);
}

enum MilestoneStatus { PENDING, IN_PROGRESS, COMPLETED }

@JsonSerializable()
class ProjectMilestone {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String? deadline;
  final MilestoneStatus status;
  final int order;

  ProjectMilestone({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.deadline,
    this.status = MilestoneStatus.PENDING,
    this.order = 0,
  });

  factory ProjectMilestone.fromJson(Map<String, dynamic> json) =>
      _$ProjectMilestoneFromJson(json);
  Map<String, dynamic> toJson() => _$ProjectMilestoneToJson(this);
}

// ─── General Report Submission ─────────────────

enum ReportAudience { INDIVIDUAL, ROLE, TEAM }

enum ReportSubmissionStatus { PENDING, COMPLETED, REDO }

@JsonSerializable()
class ReportRequest {
  final String id;
  final String title;
  final String? description;
  final String? deadline;
  final String? originalDeadline;
  final String assignedById;
  final ReportAudience targetAudience;
  final List<String> targetRoles;
  final List<String> targetUserIds;
  final List<String> allowedFormats;
  final String? createdAt;
  final Map<String, dynamic>? assignedBy;
  final List<ReportSubmission> submissions;
  
  @JsonKey(name: '_count')
  final Map<String, dynamic>? count;

  ReportRequest({
    required this.id,
    required this.title,
    this.description,
    this.deadline,
    this.originalDeadline,
    required this.assignedById,
    this.targetAudience = ReportAudience.TEAM,
    this.targetRoles = const [],
    this.targetUserIds = const [],
    this.allowedFormats = const [".pdf", ".docx", ".xlsx", ".pptx"],
    this.createdAt,
    this.assignedBy,
    this.submissions = const [],
    this.count,
  });

  // Getter for the submission count from the count map
  int get submissionsCount => count?['submissions'] ?? 0;

  factory ReportRequest.fromJson(Map<String, dynamic> json) =>
      _$ReportRequestFromJson(json);
  Map<String, dynamic> toJson() => _$ReportRequestToJson(this);
}

@JsonSerializable()
class ReportSubmission {
  final String id;
  final String reportRequestId;
  final String userId;
  final String fileUrl;
  final String? notes;
  final ReportSubmissionStatus status;
  final String? reviewerNotes;
  final String? createdAt;
  final String? updatedAt;
  final Map<String, dynamic>? user;
  final ReportRequest? reportRequest;

  ReportSubmission({
    required this.id,
    required this.reportRequestId,
    required this.userId,
    required this.fileUrl,
    this.notes,
    this.status = ReportSubmissionStatus.PENDING,
    this.reviewerNotes,
    this.createdAt,
    this.updatedAt,
    this.user,
    this.reportRequest,
  });

  factory ReportSubmission.fromJson(Map<String, dynamic> json) =>
      _$ReportSubmissionFromJson(json);
  Map<String, dynamic> toJson() => _$ReportSubmissionToJson(this);
}

@JsonSerializable()
class PaginationMetadata {
  final int total;
  final int page;
  final int limit;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationMetadata({
    required this.total,
    required this.page,
    required this.limit,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationMetadata.fromJson(Map<String, dynamic> json) =>
      _$PaginationMetadataFromJson(json);

  Map<String, dynamic> toJson() => _$PaginationMetadataToJson(this);
}
