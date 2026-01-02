import '../../domain/entities/registro_usuario_response.dart';
import 'usuario_model.dart';

/// Model que maneja la serialización JSON de la respuesta de registro
class RegistroUsuarioResponseModel extends RegistroUsuarioResponse {
  const RegistroUsuarioResponseModel({
    required super.usuario,
    required super.yaExistia,
    required super.yaEraEmpleadoEmpresa,
    required super.mensaje,
  });

  /// Crea un RegistroUsuarioResponseModel desde JSON
  factory RegistroUsuarioResponseModel.fromJson(Map<String, dynamic> json) {
    return RegistroUsuarioResponseModel(
      usuario: UsuarioModel.fromJson(json['usuario'] as Map<String, dynamic>),
      yaExistia: json['yaExistia'] as bool,
      yaEraEmpleadoEmpresa: json['yaEraEmpleadoEmpresa'] as bool,
      mensaje: json['mensaje'] as String,
    );
  }

  /// Convierte el model a JSON
  Map<String, dynamic> toJson() {
    return {
      'usuario': (usuario as UsuarioModel).toJson(),
      'yaExistia': yaExistia,
      'yaEraEmpleadoEmpresa': yaEraEmpleadoEmpresa,
      'mensaje': mensaje,
    };
  }

  /// Convierte el model a entity
  RegistroUsuarioResponse toEntity() => this;
}
