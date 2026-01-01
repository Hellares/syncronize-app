// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'available_company_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AvailableCompanyModel _$AvailableCompanyModelFromJson(
  Map<String, dynamic> json,
) => AvailableCompanyModel(
  id: json['id'] as String,
  nombre: json['nombre'] as String,
  subdominio: json['subdominio'] as String,
  logo: json['logo'] as String?,
  roles: (json['roles'] as List<dynamic>).map((e) => e as String).toList(),
);

Map<String, dynamic> _$AvailableCompanyModelToJson(
  AvailableCompanyModel instance,
) => <String, dynamic>{
  'id': instance.id,
  'nombre': instance.nombre,
  'subdominio': instance.subdominio,
  'logo': instance.logo,
  'roles': instance.roles,
};
