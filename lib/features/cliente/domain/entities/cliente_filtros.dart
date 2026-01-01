import 'package:equatable/equatable.dart';

/// Enum para ordenamiento de clientes
enum OrdenCliente {
  nombreAsc('nombre_asc'),
  nombreDesc('nombre_desc'),
  recientes('recientes'),
  antiguos('antiguos');

  final String value;
  const OrdenCliente(this.value);
}

/// Filtros para consulta de clientes
class ClienteFiltros extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final bool? isActive;
  final OrdenCliente? orden;

  const ClienteFiltros({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.isActive,
    this.orden,
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

    return params;
  }

  /// Copia el objeto con nuevos valores
  ClienteFiltros copyWith({
    int? page,
    int? limit,
    String? search,
    bool? isActive,
    OrdenCliente? orden,
  }) {
    return ClienteFiltros(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: search ?? this.search,
      isActive: isActive ?? this.isActive,
      orden: orden ?? this.orden,
    );
  }

  @override
  List<Object?> get props => [page, limit, search, isActive, orden];
}
