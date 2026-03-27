// ─── Personal Project ─────────────────────────
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
    required this.id, required this.userId, required this.name,
    this.description, this.contribution, this.githubLink, this.liveLink,
    this.skillsUsed = const [], this.createdAt,
  });

  factory PersonalProject.fromJson(Map<String, dynamic> json) => PersonalProject(
    id: json['id'] ?? '', userId: json['userId'] ?? '', name: json['name'] ?? '',
    description: json['description'], contribution: json['contribution'],
    githubLink: json['githubLink'], liveLink: json['liveLink'],
    skillsUsed: List<String>.from(json['skillsUsed'] ?? []),
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'name': name, 'description': description, 'contribution': contribution,
    'githubLink': githubLink, 'liveLink': liveLink, 'skillsUsed': skillsUsed,
  };
}

// ─── Team Project ─────────────────────────────
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
    required this.id, required this.projectName,
    this.createdBy, this.assignedCaptain, this.domain, this.subDomain,
    this.problemStatement, this.solution, this.startDate,
    this.status = 'NOT_STARTED', this.members = const [], this.createdAt,
  });

  factory TeamProject.fromJson(Map<String, dynamic> json) => TeamProject(
    id: json['id'] ?? '', projectName: json['projectName'] ?? '',
    createdBy: json['createdBy'], assignedCaptain: json['assignedCaptain'],
    domain: json['domain'], subDomain: json['subDomain'],
    problemStatement: json['problemStatement'], solution: json['solution'],
    startDate: json['startDate'], status: json['status'] ?? 'NOT_STARTED',
    members: (json['members'] as List?)?.map((m) => TeamProjectMember.fromJson(m)).toList() ?? [],
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'projectName': projectName, 'domain': domain, 'subDomain': subDomain,
    'problemStatement': problemStatement, 'solution': solution,
    'startDate': startDate, 'status': status,
  };
}

class TeamProjectMember {
  final String id;
  final String userId;
  final Map<String, dynamic>? user;

  TeamProjectMember({required this.id, required this.userId, this.user});

  factory TeamProjectMember.fromJson(Map<String, dynamic> json) => TeamProjectMember(
    id: json['id'] ?? '', userId: json['userId'] ?? '', user: json['user'],
  );
}

// ─── Project Update ───────────────────────────
class ProjectUpdate {
  final String id;
  final String projectId;
  final String userId;
  final String updateText;
  final Map<String, dynamic>? user;
  final String? createdAt;

  ProjectUpdate({
    required this.id, required this.projectId, required this.userId,
    required this.updateText, this.user, this.createdAt,
  });

  factory ProjectUpdate.fromJson(Map<String, dynamic> json) => ProjectUpdate(
    id: json['id'] ?? '', projectId: json['projectId'] ?? '',
    userId: json['userId'] ?? '', updateText: json['updateText'] ?? '',
    user: json['user'], createdAt: json['createdAt'],
  );
}

// ─── Hackathon ────────────────────────────────
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
    required this.id, required this.userId, required this.hackName,
    this.projectName, this.description, this.contribution,
    this.skillsUsed = const [], this.date, this.isTeam = false,
    this.teamMembers = const [], this.status = 'UPCOMING',
    this.rounds = const [], this.createdAt,
  });

  factory Hackathon.fromJson(Map<String, dynamic> json) => Hackathon(
    id: json['id'] ?? '', userId: json['userId'] ?? '',
    hackName: json['hackName'] ?? '', projectName: json['projectName'],
    description: json['description'], contribution: json['contribution'],
    skillsUsed: List<String>.from(json['skillsUsed'] ?? []),
    date: json['date'], isTeam: json['isTeam'] ?? false,
    teamMembers: List<String>.from(json['teamMembers'] ?? []),
    status: json['status'] ?? 'UPCOMING',
    rounds: (json['rounds'] as List?)?.map((r) => HackathonRound.fromJson(r)).toList() ?? [],
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'hackName': hackName, 'projectName': projectName, 'description': description,
    'contribution': contribution, 'skillsUsed': skillsUsed, 'date': date,
    'isTeam': isTeam, 'teamMembers': teamMembers, 'status': status,
    'rounds': rounds.map((r) => r.toJson()).toList(),
  };
}

class HackathonRound {
  final String? id;
  final String roundName;
  final String? description;

  HackathonRound({this.id, required this.roundName, this.description});

  factory HackathonRound.fromJson(Map<String, dynamic> json) => HackathonRound(
    id: json['id'], roundName: json['roundName'] ?? '', description: json['description'],
  );

  Map<String, dynamic> toJson() => {'roundName': roundName, 'description': description};
}

// ─── Learning ─────────────────────────────────
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
    required this.id, required this.userId, required this.skillName,
    this.topics = const [], this.startDate, this.endDate,
    this.level = 'BEGINNER', this.status = 'ONGOING', this.createdAt,
  });

  factory Learning.fromJson(Map<String, dynamic> json) => Learning(
    id: json['id'] ?? '', userId: json['userId'] ?? '',
    skillName: json['skillName'] ?? '',
    topics: List<String>.from(json['topics'] ?? []),
    startDate: json['startDate'], endDate: json['endDate'],
    level: json['level'] ?? 'BEGINNER', status: json['status'] ?? 'ONGOING',
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'skillName': skillName, 'topics': topics, 'startDate': startDate,
    'endDate': endDate, 'level': level, 'status': status,
  };
}

// ─── Daily Activity ───────────────────────────
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
    required this.id, required this.userId, required this.type,
    this.customType, this.description, required this.startTime,
    required this.endTime, required this.date, this.user, this.createdAt,
  });

  factory DailyActivity.fromJson(Map<String, dynamic> json) => DailyActivity(
    id: json['id'] ?? '', userId: json['userId'] ?? '',
    type: json['type'] ?? 'OTHERS', customType: json['customType'],
    description: json['description'], startTime: json['startTime'] ?? '',
    endTime: json['endTime'] ?? '', date: json['date'] ?? '',
    user: json['user'], createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'type': type, 'customType': customType, 'description': description,
    'startTime': startTime, 'endTime': endTime, 'date': date,
  };
}

// ─── Certification ────────────────────────────
class Certification {
  final String id;
  final String userId;
  final String skill;
  final String? provider;
  final String? description;
  final String? issuedDate;
  final String? createdAt;

  Certification({
    required this.id, required this.userId, required this.skill,
    this.provider, this.description, this.issuedDate, this.createdAt,
  });

  factory Certification.fromJson(Map<String, dynamic> json) => Certification(
    id: json['id'] ?? '', userId: json['userId'] ?? '',
    skill: json['skill'] ?? '', provider: json['provider'],
    description: json['description'], issuedDate: json['issuedDate'],
    createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'skill': skill, 'provider': provider, 'description': description,
    'issuedDate': issuedDate,
  };
}

// ─── PS Skill ─────────────────────────────────
class PsSkill {
  final String id;
  final String userId;
  final String type;
  final String skillName;
  final bool completed;
  final String? createdAt;

  PsSkill({
    required this.id, required this.userId, required this.type,
    required this.skillName, this.completed = false, this.createdAt,
  });

  factory PsSkill.fromJson(Map<String, dynamic> json) => PsSkill(
    id: json['id'] ?? '', userId: json['userId'] ?? '',
    type: json['type'] ?? 'TECHNICAL', skillName: json['skillName'] ?? '',
    completed: json['completed'] ?? false, createdAt: json['createdAt'],
  );

  Map<String, dynamic> toJson() => {
    'type': type, 'skillName': skillName, 'completed': completed,
  };
}

// ─── Chat Models ──────────────────────────────
class TeamMessage {
  final String id;
  final String? message;
  final String? imageUrl;
  final bool isPinned;
  final String timestamp;
  final Map<String, dynamic>? sender;

  TeamMessage({
    required this.id, this.message, this.imageUrl,
    this.isPinned = false, required this.timestamp, this.sender,
  });

  factory TeamMessage.fromJson(Map<String, dynamic> json) => TeamMessage(
    id: json['id'] ?? '', message: json['message'], imageUrl: json['imageUrl'],
    isPinned: json['isPinned'] ?? false, timestamp: json['timestamp'] ?? '',
    sender: json['sender'],
  );
}

class ChatConversation {
  final String id;
  final List<Map<String, dynamic>> participants;
  final List<Map<String, dynamic>> messages;
  final String? updatedAt;

  ChatConversation({
    required this.id, this.participants = const [],
    this.messages = const [], this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) => ChatConversation(
    id: json['id'] ?? '',
    participants: (json['participants'] as List?)
        ?.map((p) => Map<String, dynamic>.from(p)).toList() ?? [],
    messages: (json['messages'] as List?)
        ?.map((m) => Map<String, dynamic>.from(m)).toList() ?? [],
    updatedAt: json['updatedAt'],
  );
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String? message;
  final String? imageUrl;
  final String timestamp;
  final Map<String, dynamic>? sender;

  ChatMessage({
    required this.id, required this.conversationId,
    this.message, this.imageUrl, required this.timestamp, this.sender,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] ?? '', conversationId: json['conversationId'] ?? '',
    message: json['message'], imageUrl: json['imageUrl'],
    timestamp: json['timestamp'] ?? '', sender: json['sender'],
  );
}

// ─── Analytics ────────────────────────────────
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
  final int totalActivities;

  WeeklyAnalytics({
    this.totalHours = 0, this.learningHours = 0, this.projectHours = 0,
    this.otherHours = 0, this.activeDays = 0, this.consistencyScore = 0,
    this.bestDay, this.bestDayHours = 0, this.dailyBreakdown = const {},
    this.totalActivities = 0,
  });

  factory WeeklyAnalytics.fromJson(Map<String, dynamic> json) => WeeklyAnalytics(
    totalHours: (json['totalHours'] as num?)?.toDouble() ?? 0,
    learningHours: (json['learningHours'] as num?)?.toDouble() ?? 0,
    projectHours: (json['projectHours'] as num?)?.toDouble() ?? 0,
    otherHours: (json['otherHours'] as num?)?.toDouble() ?? 0,
    activeDays: json['activeDays'] ?? 0,
    consistencyScore: json['consistencyScore'] ?? 0,
    bestDay: json['bestDay'],
    bestDayHours: (json['bestDayHours'] as num?)?.toDouble() ?? 0,
    dailyBreakdown: Map<String, dynamic>.from(json['dailyBreakdown'] ?? {}),
    totalActivities: json['totalActivities'] ?? 0,
  );
}

// ─── Task Assignment ──────────────────────────
class TaskAssignment {
  final String id;
  final String title;
  final String? description;
  final Map<String, dynamic>? assignedBy;
  final Map<String, dynamic>? assignedTo;
  final String? deadline;
  final String priority;
  final String status;
  final int reportCount;
  final String? createdAt;
  final String? updatedAt;

  TaskAssignment({
    required this.id, required this.title, this.description,
    this.assignedBy, this.assignedTo, this.deadline,
    this.priority = 'MEDIUM', this.status = 'PENDING',
    this.reportCount = 0, this.createdAt, this.updatedAt,
  });

  factory TaskAssignment.fromJson(Map<String, dynamic> json) => TaskAssignment(
    id: json['id'] ?? '', title: json['title'] ?? '',
    description: json['description'],
    assignedBy: json['assignedBy'], assignedTo: json['assignedTo'],
    deadline: json['deadline'], priority: json['priority'] ?? 'MEDIUM',
    status: json['status'] ?? 'PENDING',
    reportCount: json['_count']?['reports'] ?? 0,
    createdAt: json['createdAt'], updatedAt: json['updatedAt'],
  );

  Map<String, dynamic> toJson() => {
    'title': title, 'description': description,
    'deadline': deadline, 'priority': priority,
  };
}

// ─── Task Report ──────────────────────────────
class TaskReport {
  final String id;
  final String taskId;
  final String userId;
  final String reportText;
  final Map<String, dynamic>? user;
  final String? createdAt;

  TaskReport({
    required this.id, required this.taskId, required this.userId,
    required this.reportText, this.user, this.createdAt,
  });

  factory TaskReport.fromJson(Map<String, dynamic> json) => TaskReport(
    id: json['id'] ?? '', taskId: json['taskId'] ?? '',
    userId: json['userId'] ?? '', reportText: json['reportText'] ?? '',
    user: json['user'], createdAt: json['createdAt'],
  );
}

