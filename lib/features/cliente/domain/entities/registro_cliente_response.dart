import 'package:equatable/equatable.dart';
import 'cliente.dart';

/// Respuesta del registro/asociación de cliente
class RegistroClienteResponse extends Equatable {
  final Cliente cliente;
  final bool yaExistia;
  final bool yaEraClienteEmpresa;
  final String mensaje;

  const RegistroClienteResponse({
    required this.cliente,
    required this.yaExistia,
    required this.yaEraClienteEmpresa,
    required this.mensaje,
  });

  /// Verifica si es un cliente completamente nuevo
  bool get esClienteNuevo => !yaExistia;

  /// Verifica si es un cliente que ya existía pero se asoció a la empresa
  bool get seAgregoAEmpresa => yaExistia && !yaEraClienteEmpresa;

  /// Verifica si el cliente ya estaba registrado en esta empresa
  bool get yaEstabaEnEmpresa => yaExistia && yaEraClienteEmpresa;

  @override
  List<Object?> get props => [cliente, yaExistia, yaEraClienteEmpresa, mensaje];
}

/// Respuesta paginada de clientes
class ClientesPaginados extends Equatable {
  final List<Cliente> data;
  final int total;
  final int page;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const ClientesPaginados({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  @override
  List<Object?> get props => [data, total, page, totalPages, hasNext, hasPrev];
}
