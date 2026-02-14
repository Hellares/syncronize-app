import 'package:syncronize/core/utils/type_converters.dart';
import '../../domain/entities/reporte_incidencia.dart';

class UsuarioReporteModel extends UsuarioReporte {
  const UsuarioReporteModel({
    required super.id,
    required super.nombre,
    super.email,
  });

  factory UsuarioReporteModel.fromJson(Map<String, dynamic> json) {
    // El API puede retornar persona dentro del usuario
    final persona = json['persona'] as Map<String, dynamic>?;

    return UsuarioReporteModel(
      id: json['id'] as String,
      nombre: persona != null
          ? '${persona['nombres']} ${persona['apellidos'] ?? ''}'.trim()
          : (json['nombre'] as String? ?? 'Usuario'),
      email: json['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
    };
  }
}

class SedeReporteModel extends SedeReporte {
  const SedeReporteModel({
    required super.id,
    required super.nombre,
    super.codigo,
  });

  factory SedeReporteModel.fromJson(Map<String, dynamic> json) {
    return SedeReporteModel(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      codigo: json['codigo'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'codigo': codigo,
    };
  }
}

class ReporteIncidenciaItemModel extends ReporteIncidenciaItem {
  const ReporteIncidenciaItemModel({
    required super.id,
    required super.reporteId,
    required super.productoStockId,
    required super.nombreProducto,
    super.codigoProducto,
    required super.tipo,
    required super.cantidadAfectada,
    required super.descripcion,
    super.observaciones,
    required super.estadoItem,
    super.accionTomada,
    super.fechaResolucion,
    super.movimientoStockId,
    super.transferenciaDevolucionId,
    super.sedeDestinoId,
    super.sedeDestinoNombre,
    required super.creadoEn,
  });

  factory ReporteIncidenciaItemModel.fromJson(Map<String, dynamic> json) {
    // Extraer sedeDestinoNombre del objeto sedeDestino si existe
    String? sedeDestinoNombre;
    if (json['sedeDestino'] != null) {
      final sedeDestino = json['sedeDestino'] as Map<String, dynamic>;
      sedeDestinoNombre = sedeDestino['nombre'] as String?;
    }

    return ReporteIncidenciaItemModel(
      id: json['id'] as String,
      reporteId: json['reporteId'] as String,
      productoStockId: json['productoStockId'] as String,
      nombreProducto: json['nombreProducto'] as String,
      codigoProducto: json['codigoProducto'] as String?,
      tipo: TipoIncidenciaProducto.fromString(json['tipo'] as String),
      cantidadAfectada: toSafeInt(json['cantidadAfectada']),
      descripcion: json['descripcion'] as String,
      observaciones: json['observaciones'] as String?,
      estadoItem: EstadoItemIncidencia.fromString(json['estadoItem'] as String),
      accionTomada: json['accionTomada'] != null
          ? AccionIncidenciaProducto.fromString(json['accionTomada'] as String)
          : null,
      fechaResolucion: json['fechaResolucion'] != null
          ? DateTime.parse(json['fechaResolucion'] as String)
          : null,
      movimientoStockId: json['movimientoStockId'] as String?,
      transferenciaDevolucionId: json['transferenciaDevolucionId'] as String?,
      sedeDestinoId: json['sedeDestinoId'] as String?,
      sedeDestinoNombre: sedeDestinoNombre,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reporteId': reporteId,
      'productoStockId': productoStockId,
      'nombreProducto': nombreProducto,
      'codigoProducto': codigoProducto,
      'tipo': tipo.value,
      'cantidadAfectada': cantidadAfectada,
      'descripcion': descripcion,
      'observaciones': observaciones,
      'estadoItem': estadoItem.value,
      'accionTomada': accionTomada?.value,
      'fechaResolucion': fechaResolucion?.toIso8601String(),
      'movimientoStockId': movimientoStockId,
      'transferenciaDevolucionId': transferenciaDevolucionId,
      'sedeDestinoId': sedeDestinoId,
      'creadoEn': creadoEn.toIso8601String(),
    };
  }

}

class ReporteIncidenciaModel extends ReporteIncidencia {
  const ReporteIncidenciaModel({
    required super.id,
    required super.codigo,
    required super.empresaId,
    required super.sedeId,
    required super.titulo,
    super.descripcionGeneral,
    required super.tipoReporte,
    required super.estado,
    required super.reportadoPorId,
    super.supervisorId,
    super.resolvidoPorId,
    super.aprobadoPorId,
    required super.fechaIncidente,
    required super.fechaReporte,
    super.fechaRevision,
    super.fechaAprobacion,
    super.fechaResolucion,
    required super.totalProductosAfectados,
    required super.totalCantidadAfectada,
    required super.totalDanados,
    required super.totalPerdidos,
    required super.totalOtros,
    super.observacionesFinales,
    required super.creadoEn,
    required super.actualizadoEn,
    super.sede,
    super.reportadoPor,
    super.supervisor,
    super.resolvidoPor,
    super.aprobadoPor,
    super.items,
  });

  factory ReporteIncidenciaModel.fromJson(Map<String, dynamic> json) {
    return ReporteIncidenciaModel(
      id: json['id'] as String,
      codigo: json['codigo'] as String,
      empresaId: json['empresaId'] as String,
      sedeId: json['sedeId'] as String,
      titulo: json['titulo'] as String,
      descripcionGeneral: json['descripcionGeneral'] as String?,
      tipoReporte:
          TipoReporteIncidencia.fromString(json['tipoReporte'] as String),
      estado: EstadoReporteIncidencia.fromString(json['estado'] as String),
      reportadoPorId: json['reportadoPorId'] as String,
      supervisorId: json['supervisorId'] as String?,
      resolvidoPorId: json['resolvidoPorId'] as String?,
      aprobadoPorId: json['aprobadoPorId'] as String?,
      fechaIncidente: DateTime.parse(json['fechaIncidente'] as String),
      fechaReporte: DateTime.parse(json['fechaReporte'] as String),
      fechaRevision: json['fechaRevision'] != null
          ? DateTime.parse(json['fechaRevision'] as String)
          : null,
      fechaAprobacion: json['fechaAprobacion'] != null
          ? DateTime.parse(json['fechaAprobacion'] as String)
          : null,
      fechaResolucion: json['fechaResolucion'] != null
          ? DateTime.parse(json['fechaResolucion'] as String)
          : null,
      totalProductosAfectados: toSafeInt(json['totalProductosAfectados']),
      totalCantidadAfectada: toSafeInt(json['totalCantidadAfectada']),
      totalDanados: toSafeInt(json['totalDanados']),
      totalPerdidos: toSafeInt(json['totalPerdidos']),
      totalOtros: toSafeInt(json['totalOtros']),
      observacionesFinales: json['observacionesFinales'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      sede: json['sede'] != null
          ? SedeReporteModel.fromJson(json['sede'] as Map<String, dynamic>)
          : null,
      reportadoPor: json['reportadoPor'] != null
          ? UsuarioReporteModel.fromJson(
              json['reportadoPor'] as Map<String, dynamic>)
          : null,
      supervisor: json['supervisor'] != null
          ? UsuarioReporteModel.fromJson(
              json['supervisor'] as Map<String, dynamic>)
          : null,
      resolvidoPor: json['resolvidoPor'] != null
          ? UsuarioReporteModel.fromJson(
              json['resolvidoPor'] as Map<String, dynamic>)
          : null,
      aprobadoPor: json['aprobadoPor'] != null
          ? UsuarioReporteModel.fromJson(
              json['aprobadoPor'] as Map<String, dynamic>)
          : null,
      items: json['items'] != null
          ? (json['items'] as List)
              .map((item) => ReporteIncidenciaItemModel.fromJson(
                  item as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'codigo': codigo,
      'empresaId': empresaId,
      'sedeId': sedeId,
      'titulo': titulo,
      'descripcionGeneral': descripcionGeneral,
      'tipoReporte': tipoReporte.value,
      'estado': estado.value,
      'reportadoPorId': reportadoPorId,
      'supervisorId': supervisorId,
      'resolvidoPorId': resolvidoPorId,
      'aprobadoPorId': aprobadoPorId,
      'fechaIncidente': fechaIncidente.toIso8601String(),
      'fechaReporte': fechaReporte.toIso8601String(),
      'fechaRevision': fechaRevision?.toIso8601String(),
      'fechaAprobacion': fechaAprobacion?.toIso8601String(),
      'fechaResolucion': fechaResolucion?.toIso8601String(),
      'totalProductosAfectados': totalProductosAfectados,
      'totalCantidadAfectada': totalCantidadAfectada,
      'totalDanados': totalDanados,
      'totalPerdidos': totalPerdidos,
      'totalOtros': totalOtros,
      'observacionesFinales': observacionesFinales,
      'creadoEn': creadoEn.toIso8601String(),
      'actualizadoEn': actualizadoEn.toIso8601String(),
    };
  }

}
