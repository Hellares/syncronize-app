import 'package:equatable/equatable.dart';

class ServicioFiltros extends Equatable {
  final int page;
  final int limit;
  final String? search;
  final String? sedeId;
  final String? empresaCategoriaId;
  final String? tipoServicio;
  final String? orden;

  const ServicioFiltros({
    this.page = 1,
    this.limit = 10,
    this.search,
    this.sedeId,
    this.empresaCategoriaId,
    this.tipoServicio,
    this.orden,
  });

  ServicioFiltros copyWith({
    int? page,
    int? limit,
    String? search,
    String? sedeId,
    String? empresaCategoriaId,
    String? tipoServicio,
    String? orden,
    bool clearSearch = false,
  }) {
    return ServicioFiltros(
      page: page ?? this.page,
      limit: limit ?? this.limit,
      search: clearSearch ? null : (search ?? this.search),
      sedeId: sedeId ?? this.sedeId,
      empresaCategoriaId: empresaCategoriaId ?? this.empresaCategoriaId,
      tipoServicio: tipoServicio ?? this.tipoServicio,
      orden: orden ?? this.orden,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      'page': page.toString(),
      'limit': limit.toString(),
      if (search != null && search!.isNotEmpty) 'search': search!,
      if (sedeId != null) 'sedeId': sedeId!,
      if (empresaCategoriaId != null) 'empresaCategoriaId': empresaCategoriaId!,
      if (tipoServicio != null) 'tipoServicio': tipoServicio!,
      if (orden != null) 'orden': orden!,
    };
  }

  @override
  List<Object?> get props => [page, limit, search, sedeId, empresaCategoriaId, tipoServicio, orden];
}

class OrdenServicioFiltros extends Equatable {
  final int limit;
  final String? cursor;
  final String? search;
  final String? estado;
  final String? tipoServicio;
  final String? prioridad;
  final String? clienteId;
  final String? tecnicoId;
  final String? fechaDesde;
  final String? fechaHasta;

  const OrdenServicioFiltros({
    this.limit = 15,
    this.cursor,
    this.search,
    this.estado,
    this.tipoServicio,
    this.prioridad,
    this.clienteId,
    this.tecnicoId,
    this.fechaDesde,
    this.fechaHasta,
  });

  OrdenServicioFiltros copyWith({
    int? limit,
    String? cursor,
    String? search,
    String? estado,
    String? tipoServicio,
    String? prioridad,
    String? clienteId,
    String? tecnicoId,
    String? fechaDesde,
    String? fechaHasta,
    bool clearSearch = false,
    bool clearEstado = false,
    bool clearCursor = false,
  }) {
    return OrdenServicioFiltros(
      limit: limit ?? this.limit,
      cursor: clearCursor ? null : (cursor ?? this.cursor),
      search: clearSearch ? null : (search ?? this.search),
      estado: clearEstado ? null : (estado ?? this.estado),
      tipoServicio: tipoServicio ?? this.tipoServicio,
      prioridad: prioridad ?? this.prioridad,
      clienteId: clienteId ?? this.clienteId,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      fechaDesde: fechaDesde ?? this.fechaDesde,
      fechaHasta: fechaHasta ?? this.fechaHasta,
    );
  }

  Map<String, dynamic> toQueryParams() {
    return {
      'limit': limit.toString(),
      if (cursor != null) 'cursor': cursor!,
      if (search != null && search!.isNotEmpty) 'search': search!,
      if (estado != null) 'estado': estado!,
      if (tipoServicio != null) 'tipoServicio': tipoServicio!,
      if (prioridad != null) 'prioridad': prioridad!,
      if (clienteId != null) 'clienteId': clienteId!,
      if (tecnicoId != null) 'tecnicoId': tecnicoId!,
      if (fechaDesde != null) 'fechaDesde': fechaDesde!,
      if (fechaHasta != null) 'fechaHasta': fechaHasta!,
    };
  }

  @override
  List<Object?> get props => [limit, cursor, search, estado, tipoServicio, prioridad, clienteId, tecnicoId];
}
