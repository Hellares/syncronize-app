import 'package:equatable/equatable.dart';

/// Tipo de reporte de incidencia
enum TipoReporteIncidencia {
  inventarioCompleto('INVENTARIO_COMPLETO', 'Inventario Completo'),
  incidenciaPuntual('INCIDENCIA_PUNTUAL', 'Incidencia Puntual'),
  revisionRutinaria('REVISION_RUTINARIA', 'Revisión Rutinaria'),
  eventoEspecifico('EVENTO_ESPECIFICO', 'Evento Específico'),
  auditoria('AUDITORIA', 'Auditoría'),
  otro('OTRO', 'Otro');

  final String value;
  final String descripcion;

  const TipoReporteIncidencia(this.value, this.descripcion);

  static TipoReporteIncidencia fromString(String value) {
    return TipoReporteIncidencia.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoReporteIncidencia.incidenciaPuntual,
    );
  }
}

/// Estado del reporte de incidencia
enum EstadoReporteIncidencia {
  borrador('BORRADOR', 'Borrador'),
  enviado('ENVIADO', 'Enviado'),
  enRevision('EN_REVISION', 'En Revisión'),
  aprobado('APROBADO', 'Aprobado'),
  enProceso('EN_PROCESO', 'En Proceso'),
  resuelto('RESUELTO', 'Resuelto'),
  rechazado('RECHAZADO', 'Rechazado'),
  cancelado('CANCELADO', 'Cancelado');

  final String value;
  final String descripcion;

  const EstadoReporteIncidencia(this.value, this.descripcion);

  static EstadoReporteIncidencia fromString(String value) {
    return EstadoReporteIncidencia.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoReporteIncidencia.borrador,
    );
  }

  bool get isBorrador => this == EstadoReporteIncidencia.borrador;
  bool get isEnviado => this == EstadoReporteIncidencia.enviado;
  bool get isAprobado => this == EstadoReporteIncidencia.aprobado;
  bool get isResuelto => this == EstadoReporteIncidencia.resuelto;
  bool get isRechazado => this == EstadoReporteIncidencia.rechazado;
  bool get isFinalizado =>
      isResuelto || isRechazado || this == EstadoReporteIncidencia.cancelado;
  bool get puedeEditar => isBorrador;
  bool get puedeEnviar => isBorrador;
  bool get puedeAprobar =>
      isEnviado || this == EstadoReporteIncidencia.enRevision;
}

/// Tipo de incidencia de producto
enum TipoIncidenciaProducto {
  danado('DANADO', 'Dañado'),
  perdido('PERDIDO', 'Perdido'),
  robo('ROBO', 'Robo'),
  caducado('CADUCADO', 'Caducado'),
  defectoFabrica('DEFECTO_FABRICA', 'Defecto de Fábrica'),
  malAlmacenamiento('MAL_ALMACENAMIENTO', 'Mal Almacenamiento'),
  accidente('ACCIDENTE', 'Accidente'),
  diferenciaInventario('DIFERENCIA_INVENTARIO', 'Diferencia de Inventario'),
  otro('OTRO', 'Otro');

  final String value;
  final String descripcion;

  const TipoIncidenciaProducto(this.value, this.descripcion);

  static TipoIncidenciaProducto fromString(String value) {
    return TipoIncidenciaProducto.values.firstWhere(
      (e) => e.value == value,
      orElse: () => TipoIncidenciaProducto.otro,
    );
  }
}

/// Acción a tomar para resolver incidencia
enum AccionIncidenciaProducto {
  marcarDanado('MARCAR_DANADO', 'Marcar como Dañado'),
  darDeBaja('DAR_DE_BAJA', 'Dar de Baja'),
  reparacionInterna('REPARACION_INTERNA', 'Reparación Interna'),
  devolverSedePrincipal('DEVOLVER_SEDE_PRINCIPAL', 'Devolver a Sede Principal'),
  enviarGarantia('ENVIAR_GARANTIA', 'Enviar a Garantía'),
  aceptarPerdida('ACEPTAR_PERDIDA', 'Aceptar Pérdida'),
  reportarRobo('REPORTAR_ROBO', 'Reportar Robo'),
  ajustarSistema('AJUSTAR_SISTEMA', 'Ajustar Sistema'),
  pendienteDecision('PENDIENTE_DECISION', 'Pendiente de Decisión');

  final String value;
  final String descripcion;

  const AccionIncidenciaProducto(this.value, this.descripcion);

  static AccionIncidenciaProducto fromString(String value) {
    return AccionIncidenciaProducto.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AccionIncidenciaProducto.pendienteDecision,
    );
  }
}

/// Estado de un item de incidencia
enum EstadoItemIncidencia {
  pendiente('PENDIENTE', 'Pendiente'),
  enProceso('EN_PROCESO', 'En Proceso'),
  resuelto('RESUELTO', 'Resuelto'),
  noProcede('NO_PROCEDE', 'No Procede');

  final String value;
  final String descripcion;

  const EstadoItemIncidencia(this.value, this.descripcion);

  static EstadoItemIncidencia fromString(String value) {
    return EstadoItemIncidencia.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EstadoItemIncidencia.pendiente,
    );
  }

  bool get isPendiente => this == EstadoItemIncidencia.pendiente;
  bool get isResuelto => this == EstadoItemIncidencia.resuelto;
}

/// Usuario simplificado para reportes
class UsuarioReporte extends Equatable {
  final String id;
  final String nombre;
  final String? email;

  const UsuarioReporte({
    required this.id,
    required this.nombre,
    this.email,
  });

  @override
  List<Object?> get props => [id, nombre, email];
}

/// Sede simplificada para reportes
class SedeReporte extends Equatable {
  final String id;
  final String nombre;
  final String? codigo;

  const SedeReporte({
    required this.id,
    required this.nombre,
    this.codigo,
  });

  @override
  List<Object?> get props => [id, nombre, codigo];
}

/// Item de reporte de incidencia
class ReporteIncidenciaItem extends Equatable {
  final String id;
  final String reporteId;
  final String productoStockId;
  final String nombreProducto;
  final String? codigoProducto;
  final TipoIncidenciaProducto tipo;
  final int cantidadAfectada;
  final String descripcion;
  final String? observaciones;
  final EstadoItemIncidencia estadoItem;
  final AccionIncidenciaProducto? accionTomada;
  final DateTime? fechaResolucion;
  final String? movimientoStockId;
  final String? transferenciaDevolucionId;
  final String? sedeDestinoId;
  final String? sedeDestinoNombre;
  final DateTime creadoEn;

  const ReporteIncidenciaItem({
    required this.id,
    required this.reporteId,
    required this.productoStockId,
    required this.nombreProducto,
    this.codigoProducto,
    required this.tipo,
    required this.cantidadAfectada,
    required this.descripcion,
    this.observaciones,
    required this.estadoItem,
    this.accionTomada,
    this.fechaResolucion,
    this.movimientoStockId,
    this.transferenciaDevolucionId,
    this.sedeDestinoId,
    this.sedeDestinoNombre,
    required this.creadoEn,
  });

  @override
  List<Object?> get props => [
        id,
        reporteId,
        productoStockId,
        nombreProducto,
        codigoProducto,
        tipo,
        cantidadAfectada,
        descripcion,
        observaciones,
        estadoItem,
        accionTomada,
        fechaResolucion,
        movimientoStockId,
        transferenciaDevolucionId,
        sedeDestinoId,
        sedeDestinoNombre,
        creadoEn,
      ];
}

/// Reporte de Incidencia completo
class ReporteIncidencia extends Equatable {
  final String id;
  final String codigo;
  final String empresaId;
  final String sedeId;
  final String titulo;
  final String? descripcionGeneral;
  final TipoReporteIncidencia tipoReporte;
  final EstadoReporteIncidencia estado;
  final String reportadoPorId;
  final String? supervisorId;
  final String? resolvidoPorId;
  final String? aprobadoPorId;
  final DateTime fechaIncidente;
  final DateTime fechaReporte;
  final DateTime? fechaRevision;
  final DateTime? fechaAprobacion;
  final DateTime? fechaResolucion;
  final int totalProductosAfectados;
  final int totalCantidadAfectada;
  final int totalDanados;
  final int totalPerdidos;
  final int totalOtros;
  final String? observacionesFinales;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Relaciones (opcionales, se cargan según necesidad)
  final SedeReporte? sede;
  final UsuarioReporte? reportadoPor;
  final UsuarioReporte? supervisor;
  final UsuarioReporte? resolvidoPor;
  final UsuarioReporte? aprobadoPor;
  final List<ReporteIncidenciaItem>? items;

  const ReporteIncidencia({
    required this.id,
    required this.codigo,
    required this.empresaId,
    required this.sedeId,
    required this.titulo,
    this.descripcionGeneral,
    required this.tipoReporte,
    required this.estado,
    required this.reportadoPorId,
    this.supervisorId,
    this.resolvidoPorId,
    this.aprobadoPorId,
    required this.fechaIncidente,
    required this.fechaReporte,
    this.fechaRevision,
    this.fechaAprobacion,
    this.fechaResolucion,
    required this.totalProductosAfectados,
    required this.totalCantidadAfectada,
    required this.totalDanados,
    required this.totalPerdidos,
    required this.totalOtros,
    this.observacionesFinales,
    required this.creadoEn,
    required this.actualizadoEn,
    this.sede,
    this.reportadoPor,
    this.supervisor,
    this.resolvidoPor,
    this.aprobadoPor,
    this.items,
  });

  @override
  List<Object?> get props => [
        id,
        codigo,
        empresaId,
        sedeId,
        titulo,
        descripcionGeneral,
        tipoReporte,
        estado,
        reportadoPorId,
        supervisorId,
        resolvidoPorId,
        aprobadoPorId,
        fechaIncidente,
        fechaReporte,
        fechaRevision,
        fechaAprobacion,
        fechaResolucion,
        totalProductosAfectados,
        totalCantidadAfectada,
        totalDanados,
        totalPerdidos,
        totalOtros,
        observacionesFinales,
        creadoEn,
        actualizadoEn,
      ];

  ReporteIncidencia copyWith({
    String? id,
    String? codigo,
    String? empresaId,
    String? sedeId,
    String? titulo,
    String? descripcionGeneral,
    TipoReporteIncidencia? tipoReporte,
    EstadoReporteIncidencia? estado,
    String? reportadoPorId,
    String? supervisorId,
    String? resolvidoPorId,
    String? aprobadoPorId,
    DateTime? fechaIncidente,
    DateTime? fechaReporte,
    DateTime? fechaRevision,
    DateTime? fechaAprobacion,
    DateTime? fechaResolucion,
    int? totalProductosAfectados,
    int? totalCantidadAfectada,
    int? totalDanados,
    int? totalPerdidos,
    int? totalOtros,
    String? observacionesFinales,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    SedeReporte? sede,
    UsuarioReporte? reportadoPor,
    UsuarioReporte? supervisor,
    UsuarioReporte? resolvidoPor,
    UsuarioReporte? aprobadoPor,
    List<ReporteIncidenciaItem>? items,
  }) {
    return ReporteIncidencia(
      id: id ?? this.id,
      codigo: codigo ?? this.codigo,
      empresaId: empresaId ?? this.empresaId,
      sedeId: sedeId ?? this.sedeId,
      titulo: titulo ?? this.titulo,
      descripcionGeneral: descripcionGeneral ?? this.descripcionGeneral,
      tipoReporte: tipoReporte ?? this.tipoReporte,
      estado: estado ?? this.estado,
      reportadoPorId: reportadoPorId ?? this.reportadoPorId,
      supervisorId: supervisorId ?? this.supervisorId,
      resolvidoPorId: resolvidoPorId ?? this.resolvidoPorId,
      aprobadoPorId: aprobadoPorId ?? this.aprobadoPorId,
      fechaIncidente: fechaIncidente ?? this.fechaIncidente,
      fechaReporte: fechaReporte ?? this.fechaReporte,
      fechaRevision: fechaRevision ?? this.fechaRevision,
      fechaAprobacion: fechaAprobacion ?? this.fechaAprobacion,
      fechaResolucion: fechaResolucion ?? this.fechaResolucion,
      totalProductosAfectados:
          totalProductosAfectados ?? this.totalProductosAfectados,
      totalCantidadAfectada:
          totalCantidadAfectada ?? this.totalCantidadAfectada,
      totalDanados: totalDanados ?? this.totalDanados,
      totalPerdidos: totalPerdidos ?? this.totalPerdidos,
      totalOtros: totalOtros ?? this.totalOtros,
      observacionesFinales: observacionesFinales ?? this.observacionesFinales,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      sede: sede ?? this.sede,
      reportadoPor: reportadoPor ?? this.reportadoPor,
      supervisor: supervisor ?? this.supervisor,
      resolvidoPor: resolvidoPor ?? this.resolvidoPor,
      aprobadoPor: aprobadoPor ?? this.aprobadoPor,
      items: items ?? this.items,
    );
  }
}
