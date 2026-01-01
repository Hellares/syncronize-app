// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tenant_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TenantModel _$TenantModelFromJson(Map<String, dynamic> json) => TenantModel(
  id: json['id'] as String,
  name: json['name'] as String,
  role: json['role'] as String,
);

Map<String, dynamic> _$TenantModelToJson(TenantModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'role': instance.role,
    };
