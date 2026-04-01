import 'package:json_annotation/json_annotation.dart';
import 'package:team_info_app/core/enums/user_role.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String email;
  final String name;
  final String? regNo;
  final String? department;
  final String? year;
  final String? mobile;
  final double? cgpa;
  final int rewardPoints;
  final int activityPoints;
  final int? groupPoints;
  final double? contributionPercent;
  final String? profileImageUrl;
  final UserRole role;
  final List<String> primarySkills;
  final List<String> secondarySkills;
  final List<String> specialSkills;
  final List<String> programmingLangs;
  final String? linkedinUrl;
  final String? githubUrl;
  final String? leetcodeUrl;
  final String? twitterUrl;
  final String? createdAt;
  final String? updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.regNo,
    this.department,
    this.year,
    this.mobile,
    this.cgpa,
    this.rewardPoints = 0,
    this.activityPoints = 0,
    this.groupPoints,
    this.contributionPercent,
    this.profileImageUrl,
    this.role = UserRole.member,
    this.primarySkills = const [],
    this.secondarySkills = const [],
    this.specialSkills = const [],
    this.programmingLangs = const [],
    this.linkedinUrl,
    this.githubUrl,
    this.leetcodeUrl,
    this.twitterUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  UserModel copyWith({
    String? name, String? regNo, String? department, String? year,
    String? mobile, double? cgpa, String? profileImageUrl, UserRole? role,
    List<String>? primarySkills, List<String>? secondarySkills,
    List<String>? specialSkills, List<String>? programmingLangs,
    String? linkedinUrl, String? githubUrl, String? leetcodeUrl, String? twitterUrl,
    int? rewardPoints, int? activityPoints, int? groupPoints, double? contributionPercent,
  }) {
    return UserModel(
      id: id, email: email,
      name: name ?? this.name, regNo: regNo ?? this.regNo,
      department: department ?? this.department, year: year ?? this.year,
      mobile: mobile ?? this.mobile, cgpa: cgpa ?? this.cgpa,
      rewardPoints: rewardPoints ?? this.rewardPoints, 
      activityPoints: activityPoints ?? this.activityPoints,
      groupPoints: groupPoints ?? this.groupPoints,
      contributionPercent: contributionPercent ?? this.contributionPercent,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      role: role ?? this.role,
      primarySkills: primarySkills ?? this.primarySkills,
      secondarySkills: secondarySkills ?? this.secondarySkills,
      specialSkills: specialSkills ?? this.specialSkills,
      programmingLangs: programmingLangs ?? this.programmingLangs,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      leetcodeUrl: leetcodeUrl ?? this.leetcodeUrl,
      twitterUrl: twitterUrl ?? this.twitterUrl,
      createdAt: createdAt, updatedAt: updatedAt,
    );
  }
}
