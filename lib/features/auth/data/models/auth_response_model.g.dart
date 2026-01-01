// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponseModel _$AuthResponseModelFromJson(Map<String, dynamic> json) =>
    AuthResponseModel(
      user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      tenant: json['tenant'] == null
          ? null
          : TenantModel.fromJson(json['tenant'] as Map<String, dynamic>),
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      expiresIn: json['expiresIn'] as String?,
      sessionId: json['sessionId'] as String?,
      mode: json['mode'] as String?,
      requiresSelection: json['requiresSelection'] as bool?,
      message: json['message'] as String?,
      options: (json['options'] as List<dynamic>?)
          ?.map((e) => ModeOptionModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$AuthResponseModelToJson(AuthResponseModel instance) =>
    <String, dynamic>{
      'user': instance.user.toJson(),
      'tenant': instance.tenant?.toJson(),
      'accessToken': instance.accessToken,
      'refreshToken': instance.refreshToken,
      'expiresIn': instance.expiresIn,
      'sessionId': instance.sessionId,
      'mode': instance.mode,
      'requiresSelection': instance.requiresSelection,
      'message': instance.message,
      'options': instance.options?.map((e) => e.toJson()).toList(),
    };
