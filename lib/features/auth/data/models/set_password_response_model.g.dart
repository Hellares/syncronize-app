// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'set_password_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SetPasswordResponseModel _$SetPasswordResponseModelFromJson(
  Map<String, dynamic> json,
) => SetPasswordResponseModel(
  success: json['success'] as bool,
  message: json['message'] as String,
);

Map<String, dynamic> _$SetPasswordResponseModelToJson(
  SetPasswordResponseModel instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
};
