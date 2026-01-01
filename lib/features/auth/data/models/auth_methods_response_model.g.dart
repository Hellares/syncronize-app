// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth_methods_response_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthMethodsResponseModel _$AuthMethodsResponseModelFromJson(
  Map<String, dynamic> json,
) => AuthMethodsResponseModel(
  email: json['email'] as String,
  exists: json['exists'] as bool,
  methods: (json['methods'] as List<dynamic>).map((e) => e as String).toList(),
  authMethodsCount: (json['authMethodsCount'] as num?)?.toInt(),
);

Map<String, dynamic> _$AuthMethodsResponseModelToJson(
  AuthMethodsResponseModel instance,
) => <String, dynamic>{
  'email': instance.email,
  'exists': instance.exists,
  'methods': instance.methods,
  'authMethodsCount': instance.authMethodsCount,
};
