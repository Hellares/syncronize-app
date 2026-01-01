import 'package:json_annotation/json_annotation.dart';
import '../../domain/entities/user.dart';

part 'user_model.g.dart';

@JsonSerializable()
class UserModel {
  final String id;
  final String? email;
  final String? dni;
  final String nombres;
  final String apellidos;
  final bool emailVerificado;
  final bool? telefonoVerificado;
  final String? telefono;
  final String? rolGlobal;
  final String? photoUrl;
  final DateTime? lastLoginAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? metodoPrincipalLogin;
  final bool? requiereCambioPassword;

  UserModel({
    required this.id,
    this.email,
    this.dni,
    required this.nombres,
    required this.apellidos,
    required this.emailVerificado,
    this.telefonoVerificado,
    this.telefono,
    this.rolGlobal,
    this.photoUrl,
    this.lastLoginAt,
    this.createdAt,
    this.updatedAt,
    this.metodoPrincipalLogin,
    this.requiereCambioPassword,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  Map<String, dynamic> toJson() => _$UserModelToJson(this);

  User toEntity() {
    return User(
      id: id,
      email: email,
      dni: dni,
      nombres: nombres,
      apellidos: apellidos,
      emailVerificado: emailVerificado,
      telefonoVerificado: telefonoVerificado,
      telefono: telefono,
      rolGlobal: rolGlobal,
      photoUrl: photoUrl,
      lastLoginAt: lastLoginAt,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      metodoPrincipalLogin: metodoPrincipalLogin,
      requiereCambioPassword: requiereCambioPassword,
    );
  }

  factory UserModel.fromEntity(User user) {
    return UserModel(
      id: user.id,
      email: user.email,
      dni: user.dni,
      nombres: user.nombres,
      apellidos: user.apellidos,
      emailVerificado: user.emailVerificado,
      telefonoVerificado: user.telefonoVerificado,
      telefono: user.telefono,
      rolGlobal: user.rolGlobal,
      photoUrl: user.photoUrl,
      lastLoginAt: user.lastLoginAt,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      metodoPrincipalLogin: user.metodoPrincipalLogin,
      requiereCambioPassword: user.requiereCambioPassword,
    );
  }
}
