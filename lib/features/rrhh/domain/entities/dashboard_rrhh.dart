import 'package:equatable/equatable.dart';

/// Empleados agrupados por estado
class EmpleadosPorEstado extends Equatable {
  final String estado;
  final int count;

  const EmpleadosPorEstado({required this.estado, required this.count});

  @override
  List<Object?> get props => [estado, count];
}

/// Empleados agrupados por sede
class EmpleadosPorSede extends Equatable {
  final String sedeId;
  final String sedeNombre;
  final int count;

  const EmpleadosPorSede({
    required this.sedeId,
    required this.sedeNombre,
    required this.count,
  });

  @override
  List<Object?> get props => [sedeId, sedeNombre, count];
}

/// Empleados agrupados por departamento
class EmpleadosPorDepartamento extends Equatable {
  final String departamento;
  final int count;

  const EmpleadosPorDepartamento({required this.departamento, required this.count});

  @override
  List<Object?> get props => [departamento, count];
}

/// Resumen de asistencia del día
class AsistenciaHoy extends Equatable {
  final int presentes;
  final int ausentes;
  final int tardanzas;
  final int justificados;
  final int enVacacion;
  final int enLicencia;
  final int sinRegistro;

  const AsistenciaHoy({
    this.presentes = 0,
    this.ausentes = 0,
    this.tardanzas = 0,
    this.justificados = 0,
    this.enVacacion = 0,
    this.enLicencia = 0,
    this.sinRegistro = 0,
  });

  @override
  List<Object?> get props => [
        presentes,
        ausentes,
        tardanzas,
        justificados,
        enVacacion,
        enLicencia,
        sinRegistro,
      ];
}

/// Resumen de planilla actual
class PlanillaActualResumen extends Equatable {
  final String periodo;
  final String estado;
  final double? totalBruto;
  final double? totalNeto;
  final int boletasPendientes;
  final int boletasPagadas;

  const PlanillaActualResumen({
    required this.periodo,
    required this.estado,
    this.totalBruto,
    this.totalNeto,
    this.boletasPendientes = 0,
    this.boletasPagadas = 0,
  });

  @override
  List<Object?> get props => [
        periodo,
        estado,
        totalBruto,
        totalNeto,
        boletasPendientes,
        boletasPagadas,
      ];
}

/// Alerta del dashboard
class AlertaRrhh extends Equatable {
  final String tipo;
  final String mensaje;
  final int cantidad;

  const AlertaRrhh({
    required this.tipo,
    required this.mensaje,
    required this.cantidad,
  });

  @override
  List<Object?> get props => [tipo, mensaje, cantidad];
}

/// Entity que representa el dashboard de RRHH
class DashboardRrhh extends Equatable {
  final int totalEmpleados;
  final List<EmpleadosPorEstado> empleadosPorEstado;
  final List<EmpleadosPorSede> empleadosPorSede;
  final List<EmpleadosPorDepartamento> empleadosPorDepartamento;
  final AsistenciaHoy asistenciaHoy;
  final int incidenciasPendientes;
  final PlanillaActualResumen? planillaActual;
  final int adelantosPendientes;
  final int adelantosAprobadosSinPagar;
  final double montoAdelantosAprobados;
  final List<AlertaRrhh> alertas;

  const DashboardRrhh({
    required this.totalEmpleados,
    this.empleadosPorEstado = const [],
    this.empleadosPorSede = const [],
    this.empleadosPorDepartamento = const [],
    this.asistenciaHoy = const AsistenciaHoy(),
    this.incidenciasPendientes = 0,
    this.planillaActual,
    this.adelantosPendientes = 0,
    this.adelantosAprobadosSinPagar = 0,
    this.montoAdelantosAprobados = 0,
    this.alertas = const [],
  });

  @override
  List<Object?> get props => [
        totalEmpleados,
        empleadosPorEstado,
        empleadosPorSede,
        empleadosPorDepartamento,
        asistenciaHoy,
        incidenciasPendientes,
        planillaActual,
        adelantosPendientes,
        adelantosAprobadosSinPagar,
        montoAdelantosAprobados,
        alertas,
      ];
}
