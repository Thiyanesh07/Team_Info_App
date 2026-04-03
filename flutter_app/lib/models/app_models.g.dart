// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PersonalProject _$PersonalProjectFromJson(Map<String, dynamic> json) =>
    PersonalProject(
      id: json['id'] as String,
      userId: json['userId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      contribution: json['contribution'] as String?,
      githubLink: json['githubLink'] as String?,
      liveLink: json['liveLink'] as String?,
      skillsUsed: (json['skillsUsed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$PersonalProjectToJson(PersonalProject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'name': instance.name,
      'description': instance.description,
      'contribution': instance.contribution,
      'githubLink': instance.githubLink,
      'liveLink': instance.liveLink,
      'skillsUsed': instance.skillsUsed,
      'createdAt': instance.createdAt,
    };

TeamProject _$TeamProjectFromJson(Map<String, dynamic> json) => TeamProject(
      id: json['id'] as String,
      projectName: json['projectName'] as String,
      createdBy: json['createdBy'] as Map<String, dynamic>?,
      assignedCaptain: json['assignedCaptain'] as Map<String, dynamic>?,
      domain: json['domain'] as String?,
      subDomain: json['subDomain'] as String?,
      problemStatement: json['problemStatement'] as String?,
      solution: json['solution'] as String?,
      startDate: json['startDate'] as String?,
      status: json['status'] as String? ?? 'NOT_STARTED',
      members: (json['members'] as List<dynamic>?)
              ?.map(
                  (e) => TeamProjectMember.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$TeamProjectToJson(TeamProject instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectName': instance.projectName,
      'createdBy': instance.createdBy,
      'assignedCaptain': instance.assignedCaptain,
      'domain': instance.domain,
      'subDomain': instance.subDomain,
      'problemStatement': instance.problemStatement,
      'solution': instance.solution,
      'startDate': instance.startDate,
      'status': instance.status,
      'members': instance.members,
      'createdAt': instance.createdAt,
    };

TeamProjectMember _$TeamProjectMemberFromJson(Map<String, dynamic> json) =>
    TeamProjectMember(
      id: json['id'] as String,
      userId: json['userId'] as String,
      user: json['user'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TeamProjectMemberToJson(TeamProjectMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'user': instance.user,
    };

ProjectUpdate _$ProjectUpdateFromJson(Map<String, dynamic> json) =>
    ProjectUpdate(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      date: json['date'] as String?,
      user: json['user'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$ProjectUpdateToJson(ProjectUpdate instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'userId': instance.userId,
      'title': instance.title,
      'description': instance.description,
      'date': instance.date,
      'user': instance.user,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

Hackathon _$HackathonFromJson(Map<String, dynamic> json) => Hackathon(
      id: json['id'] as String,
      userId: json['userId'] as String,
      hackName: json['hackName'] as String,
      projectName: json['projectName'] as String?,
      description: json['description'] as String?,
      contribution: json['contribution'] as String?,
      skillsUsed: (json['skillsUsed'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      date: json['date'] as String?,
      isTeam: json['isTeam'] as bool? ?? false,
      teamMembers: (json['teamMembers'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      status: json['status'] as String? ?? 'UPCOMING',
      rounds: (json['rounds'] as List<dynamic>?)
              ?.map((e) => HackathonRound.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$HackathonToJson(Hackathon instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'hackName': instance.hackName,
      'projectName': instance.projectName,
      'description': instance.description,
      'contribution': instance.contribution,
      'skillsUsed': instance.skillsUsed,
      'date': instance.date,
      'isTeam': instance.isTeam,
      'teamMembers': instance.teamMembers,
      'status': instance.status,
      'rounds': instance.rounds,
      'createdAt': instance.createdAt,
    };

HackathonRound _$HackathonRoundFromJson(Map<String, dynamic> json) =>
    HackathonRound(
      id: json['id'] as String?,
      roundName: json['roundName'] as String,
      description: json['description'] as String?,
    );

Map<String, dynamic> _$HackathonRoundToJson(HackathonRound instance) =>
    <String, dynamic>{
      'id': instance.id,
      'roundName': instance.roundName,
      'description': instance.description,
    };

Learning _$LearningFromJson(Map<String, dynamic> json) => Learning(
      id: json['id'] as String,
      userId: json['userId'] as String,
      skillName: json['skillName'] as String,
      topics: (json['topics'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      startDate: json['startDate'] as String?,
      endDate: json['endDate'] as String?,
      level: json['level'] as String? ?? 'BEGINNER',
      status: json['status'] as String? ?? 'ONGOING',
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$LearningToJson(Learning instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'skillName': instance.skillName,
      'topics': instance.topics,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'level': instance.level,
      'status': instance.status,
      'createdAt': instance.createdAt,
    };

DailyActivity _$DailyActivityFromJson(Map<String, dynamic> json) =>
    DailyActivity(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      customType: json['customType'] as String?,
      description: json['description'] as String?,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      date: json['date'] as String,
      user: json['user'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$DailyActivityToJson(DailyActivity instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'customType': instance.customType,
      'description': instance.description,
      'startTime': instance.startTime,
      'endTime': instance.endTime,
      'date': instance.date,
      'user': instance.user,
      'createdAt': instance.createdAt,
    };

Certification _$CertificationFromJson(Map<String, dynamic> json) =>
    Certification(
      id: json['id'] as String,
      userId: json['userId'] as String,
      skill: json['skill'] as String,
      provider: json['provider'] as String?,
      description: json['description'] as String?,
      issuedDate: json['issuedDate'] as String?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$CertificationToJson(Certification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'skill': instance.skill,
      'provider': instance.provider,
      'description': instance.description,
      'issuedDate': instance.issuedDate,
      'createdAt': instance.createdAt,
    };

PsSkill _$PsSkillFromJson(Map<String, dynamic> json) => PsSkill(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: json['type'] as String,
      skillName: json['skillName'] as String,
      completed: json['completed'] as bool? ?? false,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$PsSkillToJson(PsSkill instance) => <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'type': instance.type,
      'skillName': instance.skillName,
      'completed': instance.completed,
      'createdAt': instance.createdAt,
    };

TeamMessage _$TeamMessageFromJson(Map<String, dynamic> json) => TeamMessage(
      id: json['id'] as String,
      senderIdValue: json['senderIdValue'] as String?,
      message: json['message'] as String?,
      imageUrl: json['imageUrl'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
      replyToId: json['replyToId'] as String?,
      replyTo: json['replyTo'] == null
          ? null
          : TeamMessage.fromJson(json['replyTo'] as Map<String, dynamic>),
      reactions: json['reactions'] as Map<String, dynamic>?,
      isPinned: json['isPinned'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      isDelivered: json['isDelivered'] as bool? ?? false,
      timestamp: json['timestamp'] as String,
      sender: json['sender'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$TeamMessageToJson(TeamMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'senderIdValue': instance.senderIdValue,
      'message': instance.message,
      'imageUrl': instance.imageUrl,
      'fileUrl': instance.fileUrl,
      'fileName': instance.fileName,
      'fileType': instance.fileType,
      'replyToId': instance.replyToId,
      'replyTo': instance.replyTo,
      'reactions': instance.reactions,
      'isPinned': instance.isPinned,
      'isRead': instance.isRead,
      'isDelivered': instance.isDelivered,
      'timestamp': instance.timestamp,
      'sender': instance.sender,
    };

ChatConversation _$ChatConversationFromJson(Map<String, dynamic> json) =>
    ChatConversation(
      id: json['id'] as String,
      participants: (json['participants'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      messages: (json['messages'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          const [],
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$ChatConversationToJson(ChatConversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'participants': instance.participants,
      'messages': instance.messages,
      'unreadCount': instance.unreadCount,
      'updatedAt': instance.updatedAt,
    };

ChatMessage _$ChatMessageFromJson(Map<String, dynamic> json) => ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderIdValue: json['senderIdValue'] as String?,
      message: json['message'] as String?,
      imageUrl: json['imageUrl'] as String?,
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      fileType: json['fileType'] as String?,
      replyToId: json['replyToId'] as String?,
      replyTo: json['replyTo'] == null
          ? null
          : ChatMessage.fromJson(json['replyTo'] as Map<String, dynamic>),
      reactions: json['reactions'] as Map<String, dynamic>?,
      isPinned: json['isPinned'] as bool? ?? false,
      isRead: json['isRead'] as bool? ?? false,
      isDelivered: json['isDelivered'] as bool? ?? false,
      timestamp: json['timestamp'] as String,
      sender: json['sender'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ChatMessageToJson(ChatMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'conversationId': instance.conversationId,
      'senderIdValue': instance.senderIdValue,
      'message': instance.message,
      'imageUrl': instance.imageUrl,
      'fileUrl': instance.fileUrl,
      'fileName': instance.fileName,
      'fileType': instance.fileType,
      'replyToId': instance.replyToId,
      'replyTo': instance.replyTo,
      'reactions': instance.reactions,
      'isPinned': instance.isPinned,
      'isRead': instance.isRead,
      'isDelivered': instance.isDelivered,
      'timestamp': instance.timestamp,
      'sender': instance.sender,
    };

WeeklyAnalytics _$WeeklyAnalyticsFromJson(Map<String, dynamic> json) =>
    WeeklyAnalytics(
      totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0,
      learningHours: (json['learningHours'] as num?)?.toDouble() ?? 0,
      projectHours: (json['projectHours'] as num?)?.toDouble() ?? 0,
      otherHours: (json['otherHours'] as num?)?.toDouble() ?? 0,
      activeDays: (json['activeDays'] as num?)?.toInt() ?? 0,
      consistencyScore: (json['consistencyScore'] as num?)?.toInt() ?? 0,
      bestDay: json['bestDay'] as String?,
      bestDayHours: (json['bestDayHours'] as num?)?.toDouble() ?? 0,
      dailyBreakdown:
          json['dailyBreakdown'] as Map<String, dynamic>? ?? const {},
      dailyActivityCount:
          json['dailyActivityCount'] as Map<String, dynamic>? ?? const {},
      totalActivities: (json['totalActivities'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$WeeklyAnalyticsToJson(WeeklyAnalytics instance) =>
    <String, dynamic>{
      'totalHours': instance.totalHours,
      'learningHours': instance.learningHours,
      'projectHours': instance.projectHours,
      'otherHours': instance.otherHours,
      'activeDays': instance.activeDays,
      'consistencyScore': instance.consistencyScore,
      'bestDay': instance.bestDay,
      'bestDayHours': instance.bestDayHours,
      'dailyBreakdown': instance.dailyBreakdown,
      'dailyActivityCount': instance.dailyActivityCount,
      'totalActivities': instance.totalActivities,
    };

TaskAssignment _$TaskAssignmentFromJson(Map<String, dynamic> json) =>
    TaskAssignment(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      assignedBy: json['assignedBy'] as Map<String, dynamic>?,
      assignedTo: json['assignedTo'] as Map<String, dynamic>?,
      deadline: json['deadline'] as String?,
      originalDeadline: json['originalDeadline'] as String?,
      priority: json['priority'] as String? ?? 'MEDIUM',
      status: json['status'] as String? ?? 'PENDING',
      count: json['_count'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );

Map<String, dynamic> _$TaskAssignmentToJson(TaskAssignment instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'assignedBy': instance.assignedBy,
      'assignedTo': instance.assignedTo,
      'deadline': instance.deadline,
      'originalDeadline': instance.originalDeadline,
      'priority': instance.priority,
      'status': instance.status,
      '_count': instance.count,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
    };

TaskReport _$TaskReportFromJson(Map<String, dynamic> json) => TaskReport(
      id: json['id'] as String,
      taskId: json['taskId'] as String,
      userId: json['userId'] as String,
      reportText: json['reportText'] as String,
      user: json['user'] as Map<String, dynamic>?,
      createdAt: json['createdAt'] as String?,
    );

Map<String, dynamic> _$TaskReportToJson(TaskReport instance) =>
    <String, dynamic>{
      'id': instance.id,
      'taskId': instance.taskId,
      'userId': instance.userId,
      'reportText': instance.reportText,
      'user': instance.user,
      'createdAt': instance.createdAt,
    };

ActivityItem _$ActivityItemFromJson(Map<String, dynamic> json) => ActivityItem(
      id: json['id'] as String,
      userId: json['userId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      timestamp: json['timestamp'] as String,
      type: $enumDecode(_$ActivityItemTypeEnumMap, json['type']),
      user: json['user'] as Map<String, dynamic>?,
      metadata: json['metadata'] as String?,
    );

Map<String, dynamic> _$ActivityItemToJson(ActivityItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'title': instance.title,
      'content': instance.content,
      'timestamp': instance.timestamp,
      'type': _$ActivityItemTypeEnumMap[instance.type]!,
      'user': instance.user,
      'metadata': instance.metadata,
    };

const _$ActivityItemTypeEnumMap = {
  ActivityItemType.DAILY_LOG: 'DAILY_LOG',
  ActivityItemType.PROJECT_UPDATE: 'PROJECT_UPDATE',
  ActivityItemType.TASK_REPORT: 'TASK_REPORT',
  ActivityItemType.SYSTEM_EVENT: 'SYSTEM_EVENT',
};

ProjectMilestone _$ProjectMilestoneFromJson(Map<String, dynamic> json) =>
    ProjectMilestone(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: json['deadline'] as String?,
      status: $enumDecodeNullable(_$MilestoneStatusEnumMap, json['status']) ??
          MilestoneStatus.PENDING,
      order: (json['order'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$ProjectMilestoneToJson(ProjectMilestone instance) =>
    <String, dynamic>{
      'id': instance.id,
      'projectId': instance.projectId,
      'title': instance.title,
      'description': instance.description,
      'deadline': instance.deadline,
      'status': _$MilestoneStatusEnumMap[instance.status]!,
      'order': instance.order,
    };

const _$MilestoneStatusEnumMap = {
  MilestoneStatus.PENDING: 'PENDING',
  MilestoneStatus.IN_PROGRESS: 'IN_PROGRESS',
  MilestoneStatus.COMPLETED: 'COMPLETED',
};

ReportRequest _$ReportRequestFromJson(Map<String, dynamic> json) =>
    ReportRequest(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      deadline: json['deadline'] as String?,
      originalDeadline: json['originalDeadline'] as String?,
      assignedById: json['assignedById'] as String,
      targetAudience: $enumDecodeNullable(
              _$ReportAudienceEnumMap, json['targetAudience']) ??
          ReportAudience.TEAM,
      targetRoles: (json['targetRoles'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      targetUserIds: (json['targetUserIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      allowedFormats: (json['allowedFormats'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [".pdf", ".docx", ".xlsx", ".pptx"],
      createdAt: json['createdAt'] as String?,
      assignedBy: json['assignedBy'] as Map<String, dynamic>?,
      submissions: (json['submissions'] as List<dynamic>?)
              ?.map((e) => ReportSubmission.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      count: json['_count'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$ReportRequestToJson(ReportRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'deadline': instance.deadline,
      'originalDeadline': instance.originalDeadline,
      'assignedById': instance.assignedById,
      'targetAudience': _$ReportAudienceEnumMap[instance.targetAudience]!,
      'targetRoles': instance.targetRoles,
      'targetUserIds': instance.targetUserIds,
      'allowedFormats': instance.allowedFormats,
      'createdAt': instance.createdAt,
      'assignedBy': instance.assignedBy,
      'submissions': instance.submissions,
      '_count': instance.count,
    };

const _$ReportAudienceEnumMap = {
  ReportAudience.INDIVIDUAL: 'INDIVIDUAL',
  ReportAudience.ROLE: 'ROLE',
  ReportAudience.TEAM: 'TEAM',
};

ReportSubmission _$ReportSubmissionFromJson(Map<String, dynamic> json) =>
    ReportSubmission(
      id: json['id'] as String,
      reportRequestId: json['reportRequestId'] as String,
      userId: json['userId'] as String,
      fileUrl: json['fileUrl'] as String,
      notes: json['notes'] as String?,
      status: $enumDecodeNullable(
              _$ReportSubmissionStatusEnumMap, json['status']) ??
          ReportSubmissionStatus.PENDING,
      reviewerNotes: json['reviewerNotes'] as String?,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      user: json['user'] as Map<String, dynamic>?,
      reportRequest: json['reportRequest'] == null
          ? null
          : ReportRequest.fromJson(
              json['reportRequest'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReportSubmissionToJson(ReportSubmission instance) =>
    <String, dynamic>{
      'id': instance.id,
      'reportRequestId': instance.reportRequestId,
      'userId': instance.userId,
      'fileUrl': instance.fileUrl,
      'notes': instance.notes,
      'status': _$ReportSubmissionStatusEnumMap[instance.status]!,
      'reviewerNotes': instance.reviewerNotes,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'user': instance.user,
      'reportRequest': instance.reportRequest,
    };

const _$ReportSubmissionStatusEnumMap = {
  ReportSubmissionStatus.PENDING: 'PENDING',
  ReportSubmissionStatus.COMPLETED: 'COMPLETED',
  ReportSubmissionStatus.REDO: 'REDO',
};
