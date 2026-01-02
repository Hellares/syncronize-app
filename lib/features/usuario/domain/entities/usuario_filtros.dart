import 'package:equatable/equatable.dart';

/// Enum para ordenamiento de usuarios
enum OrdenUsuario {
  nombreAsc('nombre_asc'),
  nombreDesc('nombre_desc'),
  recientes('recientes'),
  antiguos('antiguos');

  final String value;
  const OrdenUsuario(this.value);
}

/// Enum para roles de usuario
enum RolUsuario {
  vendedor('VENDEDOR'),
  cajero('CAJERO'),
  tecnico('TECNICO'),
  contador('CONTADOR'),
  empresaAdmin('EMPRESA_ADMIN'),
  sedeAdmin('SEDE_ADMIN'),
  superAdmin('SUPER_ADMIN'),
  operador('OPERADOR'),
  lectura('LECTURA');

  final String value;
  const RolUsuario(this.value);

  String get label {
    switch (this) {
      case RolUsuario.vendedor:
        return 'Vendedor';
      case RolUsuario.cajero:
        return 'Cajero';
      case RolUsuario.tecnico:
        return 'Técnico';
      case RolUsuario.contador:
        return 'Contador';
      case RolUsuario.empresaAdmin:
        return 'Admin Empresa';
      case RolUsuario.sedeAdmin:
        return 'Admin Sede';
      case RolUsuario.superAdmin:
        return 'Super Admin';
      case RolUsuario.operador:
        return 'Operador';
      case RolUsuario.lectura:
        return 'Solo Lectura';
    }
  }
}

/// Clase que representa los filtros para buscar usuarios
class UsuarioFiltros extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final bool? isActive;
  final OrdenUsuario? orden;
  final RolUsuario? rol;
  final String? sedeId;

  const UsuarioFiltros({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.isActive,
    this.orden,
    this.rol,
    this.sedeId,
  });

  /// Convierte los filtros a query parameters para la API
  Map<String, dynamic> toQueryParams() {
    final Map<String, dynamic> params = {
      'page': page,
      'limit': limit,
    };

    if (search != null && search!.isNotEmpty) {
      params['search'] = search;
    }

    if (isActive != null) {
      params['isActive'] = isActive;
    }

    if (orden != null) {
      params['orden'] = orden!.value;
    }

    if (rol != null) {
      params['rol'] = rol!.value;
    }

    if (sedeId != null && sedeId!.isNotEmpty) {
      params['sedeId'] = sedeId;
    }

    return params;
  }

  /// Crea una copia de los filtros con algunos valores modificados
  UsuarioFiltros copyWith({
    int? page,
    int? limit,
    String? search,
    bool? isActive,
    OrdenUsuario? orden,
    RolUsuario? rol,
    String? sedeId,
    bool clearSearch = false,
    bool clearIsActive = false,
    bool clearOrden = false,
    bool clearRol = false,
    bool clearSedeId = false,
  }) {
    return UsuarioFiltros(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      isActive: clearIsActive ? null : (isActive ?? this.isActive),
      orden: clearOrden ? null : (orden ?? this.orden),
      rol: clearRol ? null : (rol ?? this.rol),
      sedeId: clearSedeId ? null : (sedeId ?? this.sedeId),
    );
  }

  /// Resetea los filtros a sus valores por defecto
  UsuarioFiltros reset() {
    return const UsuarioFiltros();
  }

  /// Verifica si hay filtros activos
  bool get hasActiveFilters =>
      search != null ||
      isActive != null ||
      orden != null ||
      rol != null ||
      sedeId != null;

  @override
  List<Object?> get props => [page, limit, search, isActive, orden, rol, sedeId];
}
