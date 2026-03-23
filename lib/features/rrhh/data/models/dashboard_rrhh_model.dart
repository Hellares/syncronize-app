import '../../domain/entities/dashboard_rrhh.dart';

class DashboardRrhhModel {
  final DashboardRrhh _entity;

  DashboardRrhhModel._(this._entity);

  factory DashboardRrhhModel.fromJson(Map<String, dynamic> json) {
    // Empleados por estado
    final estadoList = json['empleadosPorEstado'] as List? ?? [];
    final empleadosPorEstado = estadoList
        .map((e) => EmpleadosPorEstado(
              estado: e['estado'] as String? ?? '',
              count: e['count'] as int? ?? 0,
            ))
        .toList();

    // Empleados por sede
    final sedeList = json['empleadosPorSede'] as List? ?? [];
    final empleadosPorSede = sedeList
        .map((e) => EmpleadosPorSede(
              sedeId: e['sedeId'] as String? ?? '',
              sedeNombre: e['sedeNombre'] as String? ?? '',
              count: e['count'] as int? ?? 0,
            ))
        .toList();

    // Empleados por departamento
    final deptoList = json['empleadosPorDepartamento'] as List? ?? [];
    final empleadosPorDepartamento = deptoList
        .map((e) => EmpleadosPorDepartamento(
              departamento: e['departamento'] as String? ?? '',
              count: e['count'] as int? ?? 0,
            ))
        .toList();

    // Asistencia hoy
    final asistJson = json['asistenciaHoy'] as Map<String, dynamic>?;
    final asistenciaHoy = asistJson != null
        ? AsistenciaHoy(
            presentes: asistJson['presentes'] as int? ?? 0,
            ausentes: asistJson['ausentes'] as int? ?? 0,
            tardanzas: asistJson['tardanzas'] as int? ?? 0,
            justificados: asistJson['justificados'] as int? ?? 0,
            enVacacion: asistJson['enVacacion'] as int? ?? 0,
            enLicencia: asistJson['enLicencia'] as int? ?? 0,
            sinRegistro: asistJson['sinRegistro'] as int? ?? 0,
          )
        : const AsistenciaHoy();

    // Planilla actual
    final planillaJson = json['planillaActual'] as Map<String, dynamic>?;
    PlanillaActualResumen? planillaActual;
    if (planillaJson != null) {
      planillaActual = PlanillaActualResumen(
        periodo: planillaJson['periodo'] as String? ?? '',
        estado: planillaJson['estado'] as String? ?? '',
        totalBruto: _toDoubleNullable(planillaJson['totalBruto']),
        totalNeto: _toDoubleNullable(planillaJson['totalNeto']),
        boletasPendientes: planillaJson['boletasPendientes'] as int? ?? 0,
        boletasPagadas: planillaJson['boletasPagadas'] as int? ?? 0,
      );
    }

    // Alertas
    final alertasList = json['alertas'] as List? ?? [];
    final alertas = alertasList
        .map((e) => AlertaRrhh(
              tipo: e['tipo'] as String? ?? '',
              mensaje: e['mensaje'] as String? ?? '',
              cantidad: e['cantidad'] as int? ?? 0,
            ))
        .toList();

    return DashboardRrhhModel._(DashboardRrhh(
      totalEmpleados: json['totalEmpleados'] as int? ?? 0,
      empleadosPorEstado: empleadosPorEstado,
      empleadosPorSede: empleadosPorSede,
      empleadosPorDepartamento: empleadosPorDepartamento,
      asistenciaHoy: asistenciaHoy,
      incidenciasPendientes: json['incidenciasPendientes'] as int? ?? 0,
      planillaActual: planillaActual,
      adelantosPendientes: json['adelantosPendientes'] as int? ?? 0,
      adelantosAprobadosSinPagar:
          json['adelantosAprobadosSinPagar'] as int? ?? 0,
      montoAdelantosAprobados:
          _toDouble(json['montoAdelantosAprobados']),
      alertas: alertas,
    ));
  }

  DashboardRrhh toEntity() => _entity;

  static double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static double? _toDoubleNullable(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}
