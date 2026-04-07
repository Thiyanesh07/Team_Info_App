// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String,
  name: json['name'] as String,
  regNo: json['regNo'] as String?,
  enrollmentNo: json['enrollmentNo'] as String?,
  department: json['department'] as String?,
  year: json['year'] as String?,
  mobile: json['mobile'] as String?,
  cgpa: (json['cgpa'] as num?)?.toDouble(),
  rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
  activityPoints: (json['activityPoints'] as num?)?.toInt() ?? 0,
  groupPoints: (json['groupPoints'] as num?)?.toInt(),
  contributionPercent: (json['contributionPercent'] as num?)?.toDouble(),
  profileImageUrl: json['profileImageUrl'] as String?,
  role: $enumDecodeNullable(_$UserRoleEnumMap, json['role']) ?? UserRole.member,
  primarySkills:
      (json['primarySkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  secondarySkills:
      (json['secondarySkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  specialSkills:
      (json['specialSkills'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  programmingLangs:
      (json['programmingLangs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  linkedinUrl: json['linkedinUrl'] as String?,
  githubUrl: json['githubUrl'] as String?,
  leetcodeUrl: json['leetcodeUrl'] as String?,
  twitterUrl: json['twitterUrl'] as String?,
  createdAt: json['createdAt'] as String?,
  updatedAt: json['updatedAt'] as String?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'name': instance.name,
  'regNo': instance.regNo,
  'enrollmentNo': instance.enrollmentNo,
  'department': instance.department,
  'year': instance.year,
  'mobile': instance.mobile,
  'cgpa': instance.cgpa,
  'rewardPoints': instance.rewardPoints,
  'activityPoints': instance.activityPoints,
  'groupPoints': instance.groupPoints,
  'contributionPercent': instance.contributionPercent,
  'profileImageUrl': instance.profileImageUrl,
  'role': _$UserRoleEnumMap[instance.role]!,
  'primarySkills': instance.primarySkills,
  'secondarySkills': instance.secondarySkills,
  'specialSkills': instance.specialSkills,
  'programmingLangs': instance.programmingLangs,
  'linkedinUrl': instance.linkedinUrl,
  'githubUrl': instance.githubUrl,
  'leetcodeUrl': instance.leetcodeUrl,
  'twitterUrl': instance.twitterUrl,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
};

const _$UserRoleEnumMap = {
  UserRole.admin: 'ADMIN',
  UserRole.captain: 'CAPTAIN',
  UserRole.viceCaptain: 'VICE_CAPTAIN',
  UserRole.strategist: 'STRATEGIST',
  UserRole.manager: 'MANAGER',
  UserRole.member: 'MEMBER',
};
