// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserModel _$UserModelFromJson(Map<String, dynamic> json) => UserModel(
  id: json['id'] as String,
  email: json['email'] as String?,
  dni: json['dni'] as String?,
  nombres: json['nombres'] as String,
  apellidos: json['apellidos'] as String,
  emailVerificado: json['emailVerificado'] as bool,
  telefonoVerificado: json['telefonoVerificado'] as bool?,
  telefono: json['telefono'] as String?,
  rolGlobal: json['rolGlobal'] as String?,
  photoUrl: json['photoUrl'] as String?,
  lastLoginAt: json['lastLoginAt'] == null
      ? null
      : DateTime.parse(json['lastLoginAt'] as String),
  createdAt: json['createdAt'] == null
      ? null
      : DateTime.parse(json['createdAt'] as String),
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  metodoPrincipalLogin: json['metodoPrincipalLogin'] as String?,
  requiereCambioPassword: json['requiereCambioPassword'] as bool?,
);

Map<String, dynamic> _$UserModelToJson(UserModel instance) => <String, dynamic>{
  'id': instance.id,
  'email': instance.email,
  'dni': instance.dni,
  'nombres': instance.nombres,
  'apellidos': instance.apellidos,
  'emailVerificado': instance.emailVerificado,
  'telefonoVerificado': instance.telefonoVerificado,
  'telefono': instance.telefono,
  'rolGlobal': instance.rolGlobal,
  'photoUrl': instance.photoUrl,
  'lastLoginAt': instance.lastLoginAt?.toIso8601String(),
  'createdAt': instance.createdAt?.toIso8601String(),
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'metodoPrincipalLogin': instance.metodoPrincipalLogin,
  'requiereCambioPassword': instance.requiereCambioPassword,
};
