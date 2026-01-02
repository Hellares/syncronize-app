import 'package:equatable/equatable.dart';
import 'usuario.dart';

/// Entity que representa la respuesta al registrar un usuario
class RegistroUsuarioResponse extends Equatable {
  final Usuario usuario;
  final bool yaExistia;
  final bool yaEraEmpleadoEmpresa;
  final String mensaje;

  const RegistroUsuarioResponse({
    required this.usuario,
    required this.yaExistia,
    required this.yaEraEmpleadoEmpresa,
    required this.mensaje,
  });

  /// Verifica si es un usuario completamente nuevo
  bool get esUsuarioNuevo => !yaExistia;

  /// Verifica si el usuario existía pero se agregó a la empresa
  bool get seAgregoAEmpresa => yaExistia && !yaEraEmpleadoEmpresa;

  /// Verifica si el usuario ya estaba en la empresa
  bool get yaEstabaEnEmpresa => yaExistia && yaEraEmpleadoEmpresa;

  /// Obtiene un mensaje de éxito formateado
  String get mensajeFormateado {
    if (esUsuarioNuevo) {
      return 'Usuario registrado exitosamente. Se ha creado una cuenta con contraseña temporal.';
    } else if (seAgregoAEmpresa) {
      return 'Usuario existente asignado exitosamente a la empresa.';
    } else {
      return mensaje;
    }
  }

  /// Obtiene el tipo de registro
  String get tipoRegistro {
    if (esUsuarioNuevo) {
      return 'Nuevo Usuario';
    } else if (seAgregoAEmpresa) {
      return 'Usuario Asignado';
    } else {
      return 'Usuario Existente';
    }
  }

  @override
  List<Object?> get props => [
        usuario,
        yaExistia,
        yaEraEmpleadoEmpresa,
        mensaje,
      ];
}

/// Entity que representa una lista paginada de usuarios
class UsuariosPaginados extends Equatable {
  final List<Usuario> data;
  final int total;
  final int page;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  const UsuariosPaginados({
    required this.data,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  /// Verifica si hay más páginas disponibles
  bool get hasMore => hasNext;

  /// Verifica si la lista está vacía
  bool get isEmpty => data.isEmpty;

  /// Verifica si es la primera página
  bool get isFirstPage => page == 1;

  /// Verifica si es la última página
  bool get isLastPage => !hasNext;

  /// Obtiene el número de la siguiente página
  int? get nextPage => hasNext ? page + 1 : null;

  /// Obtiene el número de la página anterior
  int? get prevPage => hasPrev ? page - 1 : null;

  @override
  List<Object?> get props => [
        data,
        total,
        page,
        totalPages,
        hasNext,
        hasPrev,
      ];
}
