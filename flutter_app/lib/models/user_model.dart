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

  String get rankName {
    if (rewardPoints >= 5000) return 'Diamond Strategist';
    if (rewardPoints >= 2500) return 'Platinum Architect';
    if (rewardPoints >= 1000) return 'Gold Captain';
    if (rewardPoints >= 500) return 'Silver Manager';
    if (rewardPoints >= 100) return 'Bronze Member';
    return 'Rookie';
  }

  double get rankProgress {
    if (rewardPoints >= 5000) return 1.0;
    if (rewardPoints >= 2500) return (rewardPoints - 2500) / 2500;
    if (rewardPoints >= 1000) return (rewardPoints - 1000) / 1500;
    if (rewardPoints >= 500) return (rewardPoints - 500) / 500;
    if (rewardPoints >= 100) return (rewardPoints - 100) / 400;
    return rewardPoints / 100;
  }

  UserModel copyWith({
    String? name, String? regNo, String? department, String? year,
    String? mobile, double? cgpa, String? profileImageUrl, UserRole? role,
    List<String>? primarySkills, List<String>? secondarySkills,
    List<String>? specialSkills, List<String>? programmingLangs,
    String? linkedinUrl, String? githubUrl, String? leetcodeUrl, String? twitterUrl,
  }) {
    return UserModel(
      id: id, email: email,
      name: name ?? this.name, regNo: regNo ?? this.regNo,
      department: department ?? this.department, year: year ?? this.year,
      mobile: mobile ?? this.mobile, cgpa: cgpa ?? this.cgpa,
      rewardPoints: rewardPoints, activityPoints: activityPoints,
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
