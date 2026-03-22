import 'package:equatable/equatable.dart';

class AgenteBancario extends Equatable {
  final String id;
  final String empresaId;
  final String sedeId;
  final String banco;
  final String? codigoAgente;
  final String? sedeNombre;
  final String? responsableNombre;
  final double fondoAsignado;
  final double saldoActual;
  final double comisionDeposito;
  final double comisionRetiro;
  final String estado;
  // Stats (from list endpoint)
  final int depositosHoyCant;
  final int retirosHoyCant;
  final double depositosHoyMonto;
  final double retirosHoyMonto;
  final double comisionesHoy;

  const AgenteBancario({
    required this.id,
    required this.empresaId,
    required this.sedeId,
    required this.banco,
    this.codigoAgente,
    this.sedeNombre,
    this.responsableNombre,
    this.fondoAsignado = 0,
    this.saldoActual = 0,
    this.comisionDeposito = 0,
    this.comisionRetiro = 0,
    this.estado = 'ACTIVO',
    this.depositosHoyCant = 0,
    this.retirosHoyCant = 0,
    this.depositosHoyMonto = 0,
    this.retirosHoyMonto = 0,
    this.comisionesHoy = 0,
  });

  double get porcentajeFondoUsado => fondoAsignado > 0
      ? ((fondoAsignado - saldoActual) / fondoAsignado * 100).clamp(0, 100)
      : 0;

  bool get fondoBajo => saldoActual < fondoAsignado * 0.2;

  bool get estaActivo => estado == 'ACTIVO';

  @override
  List<Object?> get props => [
        id,
        empresaId,
        sedeId,
        banco,
        codigoAgente,
        sedeNombre,
        responsableNombre,
        fondoAsignado,
        saldoActual,
        comisionDeposito,
        comisionRetiro,
        estado,
        depositosHoyCant,
        retirosHoyCant,
        depositosHoyMonto,
        retirosHoyMonto,
        comisionesHoy,
      ];
}

class OperacionAgente extends Equatable {
  final String id;
  final String tipo; // DEPOSITO, RETIRO
  final double monto;
  final double comision;
  final String? nombreCliente;
  final String? documentoCliente;
  final String? numeroOperacion;
  final String? observaciones;
  final String? registradoPorNombre;
  final DateTime fechaOperacion;
  final bool anulado;

  const OperacionAgente({
    required this.id,
    required this.tipo,
    required this.monto,
    this.comision = 0,
    this.nombreCliente,
    this.documentoCliente,
    this.numeroOperacion,
    this.observaciones,
    this.registradoPorNombre,
    required this.fechaOperacion,
    this.anulado = false,
  });

  @override
  List<Object?> get props => [
        id,
        tipo,
        monto,
        comision,
        nombreCliente,
        documentoCliente,
        numeroOperacion,
        observaciones,
        registradoPorNombre,
        fechaOperacion,
        anulado,
      ];
}

class ResumenAgentes extends Equatable {
  final int totalAgentes;
  final int agentesActivos;
  final int depositosHoyCant;
  final int retirosHoyCant;
  final double depositosHoyMonto;
  final double retirosHoyMonto;
  final double comisionesHoy;
  final double comisionesMes;
  final double fondoTotalAsignado;
  final double saldoTotalActual;
  final List<AgenteBancario> porAgente;

  const ResumenAgentes({
    this.totalAgentes = 0,
    this.agentesActivos = 0,
    this.depositosHoyCant = 0,
    this.retirosHoyCant = 0,
    this.depositosHoyMonto = 0,
    this.retirosHoyMonto = 0,
    this.comisionesHoy = 0,
    this.comisionesMes = 0,
    this.fondoTotalAsignado = 0,
    this.saldoTotalActual = 0,
    this.porAgente = const [],
  });

  @override
  List<Object?> get props => [
        totalAgentes,
        agentesActivos,
        depositosHoyCant,
        retirosHoyCant,
        depositosHoyMonto,
        retirosHoyMonto,
        comisionesHoy,
        comisionesMes,
        fondoTotalAsignado,
        saldoTotalActual,
        porAgente,
      ];
}
