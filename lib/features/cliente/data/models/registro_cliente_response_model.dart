import '../../domain/entities/registro_cliente_response.dart';
import 'cliente_model.dart';

/// Model para la respuesta de registro de cliente
class RegistroClienteResponseModel extends RegistroClienteResponse {
  const RegistroClienteResponseModel({
    required super.cliente,
    required super.yaExistia,
    required super.yaEraClienteEmpresa,
    required super.mensaje,
  });

  /// Crea una instancia desde JSON
  factory RegistroClienteResponseModel.fromJson(Map<String, dynamic> json) {
    return RegistroClienteResponseModel(
      cliente: ClienteModel.fromJson(json['cliente'] as Map<String, dynamic>),
      yaExistia: json['yaExistia'] as bool,
      yaEraClienteEmpresa: json['yaEraClienteEmpresa'] as bool,
      mensaje: json['mensaje'] as String,
    );
  }

  /// Convierte a JSON
  Map<String, dynamic> toJson() {
    return {
      'cliente': (cliente as ClienteModel).toJson(),
      'yaExistia': yaExistia,
      'yaEraClienteEmpresa': yaEraClienteEmpresa,
      'mensaje': mensaje,
    };
  }

  /// Convierte a Entity (ya es una entity, solo retorna this)
  RegistroClienteResponse toEntity() => this;
}
