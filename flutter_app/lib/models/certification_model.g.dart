// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'certification_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CertificationModel _$CertificationModelFromJson(Map<String, dynamic> json) =>
    CertificationModel(
      id: json['id'] as String,
      userId: json['userId'] as String,
      skill: json['skill'] as String,
      provider: json['provider'] as String?,
      description: json['description'] as String?,
      issuedDate: json['issuedDate'] as String?,
      createdAt: json['createdAt'] as String?,
      proofUrl: json['proofUrl'] as String?,
    );

Map<String, dynamic> _$CertificationModelToJson(CertificationModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'skill': instance.skill,
      'provider': instance.provider,
      'description': instance.description,
      'issuedDate': instance.issuedDate,
      'createdAt': instance.createdAt,
      'proofUrl': instance.proofUrl,
    };
