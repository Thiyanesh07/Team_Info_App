import 'package:json_annotation/json_annotation.dart';

@JsonEnum(alwaysCreate: true)
enum UserRole {
  @JsonValue('ADMIN') admin,
  @JsonValue('CAPTAIN') captain,
  @JsonValue('VICE_CAPTAIN') viceCaptain,
  @JsonValue('STRATEGIST') strategist,
  @JsonValue('MANAGER') manager,
  @JsonValue('MEMBER') member;

  String get displayName {
    switch (this) {
      case UserRole.admin: return 'Admin';
      case UserRole.captain: return 'Captain';
      case UserRole.viceCaptain: return 'Vice Captain';
      case UserRole.strategist: return 'Strategist';
      case UserRole.manager: return 'Manager';
      case UserRole.member: return 'Member';
    }
  }

  String get apiValue {
    switch (this) {
      case UserRole.admin: return 'ADMIN';
      case UserRole.captain: return 'CAPTAIN';
      case UserRole.viceCaptain: return 'VICE_CAPTAIN';
      case UserRole.strategist: return 'STRATEGIST';
      case UserRole.manager: return 'MANAGER';
      case UserRole.member: return 'MEMBER';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toUpperCase()) {
      case 'ADMIN': return UserRole.admin;
      case 'CAPTAIN': return UserRole.captain;
      case 'VICE_CAPTAIN': return UserRole.viceCaptain;
      case 'STRATEGIST': return UserRole.strategist;
      case 'MANAGER': return UserRole.manager;
      default: return UserRole.member;
    }
  }

  bool get isLeader => [admin, captain, viceCaptain, strategist, manager].contains(this);
  bool get canCreateTeamProject => isLeader;
  bool get canAssignMembers => [admin, captain].contains(this);
  bool get canViewAllData => isLeader;
  bool get canManageUsers => this == admin;
  bool get canAssignRoles => this == admin;
  bool get canDeleteProjects => [admin, captain].contains(this);
}
