import 'package:json_annotation/json_annotation.dart';

part 'certification_model.g.dart';

@JsonSerializable()
class CertificationModel {
  final String id;
  final String userId;
  final String skill;
  final String? provider;
  final String? description;
  final String? issuedDate;
  final String? createdAt;

  CertificationModel({
    required this.id,
    required this.userId,
    required this.skill,
    this.provider,
    this.description,
    this.issuedDate,
    this.createdAt,
  });

  factory CertificationModel.fromJson(Map<String, dynamic> json) => 
      _$CertificationModelFromJson(json);

  Map<String, dynamic> toJson() => _$CertificationModelToJson(this);
}
