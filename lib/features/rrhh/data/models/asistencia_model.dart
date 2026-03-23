import '../../domain/entities/asistencia.dart';

class AsistenciaModel extends Asistencia {
  const AsistenciaModel({
    required super.id,
    required super.empleadoId,
    required super.empresaId,
    required super.sedeId,
    required super.fecha,
    super.horaEntrada,
    super.horaSalida,
    super.horaAlmuerzoInicio,
    super.horaAlmuerzoFin,
    super.horasTrabajadas,
    super.horasExtra,
    super.tipoAsistencia,
    super.estado,
    super.observaciones,
    super.empleadoNombre,
    super.empleadoDni,
  });

  factory AsistenciaModel.fromJson(Map<String, dynamic> json) {
    final empleado = json['empleado'] as Map<String, dynamic>?;
    final usuario = empleado?['usuario'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;

    String? empleadoNombre;
    if (persona != null) {
      final nombres = persona['nombres'] as String? ?? '';
      final apellidos = persona['apellidos'] as String? ?? '';
      empleadoNombre = '$nombres $apellidos'.trim();
    }

    return AsistenciaModel(
      id: json['id'] as String,
      empleadoId: json['empleadoId'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      sedeId: json['sedeId'] as String? ?? '',
      fecha: DateTime.parse(json['fecha'] as String),
      horaEntrada: json['horaEntrada'] != null
          ? DateTime.parse(json['horaEntrada'] as String)
          : null,
      horaSalida: json['horaSalida'] != null
          ? DateTime.parse(json['horaSalida'] as String)
          : null,
      horaAlmuerzoInicio: json['horaAlmuerzoInicio'] != null
          ? DateTime.parse(json['horaAlmuerzoInicio'] as String)
          : null,
      horaAlmuerzoFin: json['horaAlmuerzoFin'] != null
          ? DateTime.parse(json['horaAlmuerzoFin'] as String)
          : null,
      horasTrabajadas: _toDoubleNullable(json['horasTrabajadas']),
      horasExtra: _toDoubleNullable(json['horasExtra']),
      tipoAsistencia: TipoAsistencia.fromString(
          json['tipoAsistencia'] as String? ?? 'NORMAL'),
      estado: EstadoAsistencia.fromString(
          json['estado'] as String? ?? 'PRESENTE'),
      observaciones: json['observaciones'] as String?,
      empleadoNombre: empleadoNombre,
      empleadoDni: persona?['dni'] as String?,
    );
  }

  Asistencia toEntity() => this;

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

class AsistenciaResumenModel extends AsistenciaResumen {
  const AsistenciaResumenModel({
    super.diasPresente,
    super.diasTardanza,
    super.diasFalta,
    super.diasJustificado,
    super.diasVacacion,
    super.diasLicencia,
    super.diasDescanso,
    super.diasFeriado,
    super.totalHorasTrabajadas,
    super.totalHorasExtra,
  });

  factory AsistenciaResumenModel.fromJson(Map<String, dynamic> json) {
    return AsistenciaResumenModel(
      diasPresente: json['diasPresente'] as int? ?? 0,
      diasTardanza: json['diasTardanza'] as int? ?? 0,
      diasFalta: json['diasFalta'] as int? ?? 0,
      diasJustificado: json['diasJustificado'] as int? ?? 0,
      diasVacacion: json['diasVacacion'] as int? ?? 0,
      diasLicencia: json['diasLicencia'] as int? ?? 0,
      diasDescanso: json['diasDescanso'] as int? ?? 0,
      diasFeriado: json['diasFeriado'] as int? ?? 0,
      totalHorasTrabajadas: _toDouble(json['totalHorasTrabajadas']),
      totalHorasExtra: _toDouble(json['totalHorasExtra']),
    );
  }

  AsistenciaResumen toEntity() => this;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}
