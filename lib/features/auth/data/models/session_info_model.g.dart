// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_info_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SessionInfoModel _$SessionInfoModelFromJson(Map<String, dynamic> json) =>
    SessionInfoModel(
      sessionId: json['sessionId'] as String,
      deviceInfo: json['deviceInfo'] as String,
      ipAddress: json['ipAddress'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      isCurrentSession: json['isCurrentSession'] as bool,
    );

Map<String, dynamic> _$SessionInfoModelToJson(SessionInfoModel instance) =>
    <String, dynamic>{
      'sessionId': instance.sessionId,
      'deviceInfo': instance.deviceInfo,
      'ipAddress': instance.ipAddress,
      'createdAt': instance.createdAt.toIso8601String(),
      'lastActivityAt': instance.lastActivityAt.toIso8601String(),
      'isCurrentSession': instance.isCurrentSession,
    };
