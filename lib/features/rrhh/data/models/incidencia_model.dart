import '../../domain/entities/incidencia.dart';

class IncidenciaModel extends Incidencia {
  const IncidenciaModel({
    required super.id,
    required super.empleadoId,
    required super.empresaId,
    required super.tipo,
    required super.fechaInicio,
    required super.fechaFin,
    required super.diasTotal,
    super.motivo,
    super.documentoAdjunto,
    super.estado,
    super.aprobadoPorId,
    super.fechaAprobacion,
    super.motivoRechazo,
    super.creadoEn,
    super.empleadoNombre,
    super.empleadoCodigo,
    super.empleadoCargo,
    super.empleadoDni,
    super.empleadoDepartamento,
    super.aprobadoPorNombre,
  });

  factory IncidenciaModel.fromJson(Map<String, dynamic> json) {
    final empleado = json['empleado'] as Map<String, dynamic>?;
    final usuario = empleado?['usuario'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;

    String? empleadoNombre;
    if (persona != null) {
      final nombres = persona['nombres'] as String? ?? '';
      final apellidos = persona['apellidos'] as String? ?? '';
      empleadoNombre = '$nombres $apellidos'.trim();
    }

    // Aprobador
    final aprobadoPor = json['aprobadoPor'] as Map<String, dynamic>?;
    String? aprobadoPorNombre;
    if (aprobadoPor != null) {
      final apPersona = aprobadoPor['persona'] as Map<String, dynamic>?;
      if (apPersona != null) {
        final n = apPersona['nombres'] as String? ?? '';
        final a = apPersona['apellidos'] as String? ?? '';
        aprobadoPorNombre = '$n $a'.trim();
      }
    }

    return IncidenciaModel(
      id: json['id'] as String,
      empleadoId: json['empleadoId'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      tipo: TipoIncidencia.fromString(json['tipo'] as String? ?? 'OTRO'),
      fechaInicio: DateTime.parse(json['fechaInicio'] as String),
      fechaFin: DateTime.parse(json['fechaFin'] as String),
      diasTotal: json['diasTotal'] as int? ?? 0,
      motivo: json['motivo'] as String?,
      documentoAdjunto: json['documentoAdjunto'] as String?,
      estado: EstadoIncidencia.fromString(
          json['estado'] as String? ?? 'PENDIENTE'),
      aprobadoPorId: json['aprobadoPorId'] as String?,
      fechaAprobacion: json['fechaAprobacion'] != null
          ? DateTime.parse(json['fechaAprobacion'] as String)
          : null,
      motivoRechazo: json['motivoRechazo'] as String?,
      creadoEn: json['creadoEn'] != null
          ? DateTime.parse(json['creadoEn'] as String)
          : null,
      empleadoNombre: empleadoNombre,
      empleadoCodigo: empleado?['codigo'] as String?,
      empleadoCargo: empleado?['cargo'] as String?,
      empleadoDni: persona?['dni'] as String?,
      empleadoDepartamento: empleado?['departamento'] as String?,
      aprobadoPorNombre: aprobadoPorNombre,
    );
  }

  Incidencia toEntity() => this;
}
