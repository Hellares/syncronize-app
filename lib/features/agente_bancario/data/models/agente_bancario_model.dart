import '../../domain/entities/agente_bancario.dart';

double _toDouble(dynamic v) {
  if (v == null) return 0;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0;
  if (v is num) return v.toDouble();
  return 0;
}

class AgenteBancarioModel {
  final String id, empresaId, sedeId, banco;
  final String? codigoAgente, sedeNombre, responsableNombre;
  final double fondoAsignado, saldoActual, comisionDeposito, comisionRetiro;
  final String estado;
  final int depositosHoyCant, retirosHoyCant;
  final double depositosHoyMonto, retirosHoyMonto, comisionesHoy;

  const AgenteBancarioModel({
    required this.id, required this.empresaId, required this.sedeId,
    required this.banco, this.codigoAgente, this.sedeNombre, this.responsableNombre,
    this.fondoAsignado = 0, this.saldoActual = 0,
    this.comisionDeposito = 0, this.comisionRetiro = 0,
    this.estado = 'ACTIVO',
    this.depositosHoyCant = 0, this.retirosHoyCant = 0,
    this.depositosHoyMonto = 0, this.retirosHoyMonto = 0, this.comisionesHoy = 0,
  });

  factory AgenteBancarioModel.fromJson(Map<String, dynamic> json) {
    // Stats can come from nested 'estadisticasHoy' or flat fields
    final stats = json['estadisticasHoy'] as Map<String, dynamic>?;
    final depositos = stats?['depositos'] as Map<String, dynamic>?;
    final retiros = stats?['retiros'] as Map<String, dynamic>?;

    return AgenteBancarioModel(
      id: json['id'] as String? ?? '',
      empresaId: json['empresaId'] as String? ?? '',
      sedeId: json['sedeId'] as String? ?? '',
      banco: json['banco'] as String? ?? '',
      codigoAgente: json['codigoAgente'] as String?,
      sedeNombre: json['sedeNombre'] as String? ?? (json['sede'] is Map ? json['sede']['nombre'] as String? : null),
      responsableNombre: json['responsableNombre'] as String? ?? (json['responsable'] is Map ? json['responsable']['nombre'] as String? : null),
      fondoAsignado: _toDouble(json['fondoAsignado']),
      saldoActual: _toDouble(json['saldoActual']),
      comisionDeposito: _toDouble(json['comisionDeposito']),
      comisionRetiro: _toDouble(json['comisionRetiro']),
      estado: json['estado'] as String? ?? 'ACTIVO',
      depositosHoyCant: depositos?['cantidad'] as int? ?? json['depositosHoyCant'] as int? ?? 0,
      retirosHoyCant: retiros?['cantidad'] as int? ?? json['retirosHoyCant'] as int? ?? 0,
      depositosHoyMonto: _toDouble(depositos?['monto'] ?? json['depositosHoyMonto']),
      retirosHoyMonto: _toDouble(retiros?['monto'] ?? json['retirosHoyMonto']),
      comisionesHoy: _toDouble(stats?['comisiones'] ?? json['comisionesHoy']),
    );
  }

  AgenteBancario toEntity() {
    return AgenteBancario(
      id: id, empresaId: empresaId, sedeId: sedeId, banco: banco,
      codigoAgente: codigoAgente, sedeNombre: sedeNombre,
      responsableNombre: responsableNombre,
      fondoAsignado: fondoAsignado, saldoActual: saldoActual,
      comisionDeposito: comisionDeposito, comisionRetiro: comisionRetiro,
      estado: estado,
      depositosHoyCant: depositosHoyCant, retirosHoyCant: retirosHoyCant,
      depositosHoyMonto: depositosHoyMonto, retirosHoyMonto: retirosHoyMonto,
      comisionesHoy: comisionesHoy,
    );
  }
}

class ResumenAgentesModel {
  final int totalAgentes, agentesActivos;
  final int depositosHoyCant, retirosHoyCant;
  final double depositosHoyMonto, retirosHoyMonto;
  final double comisionesHoy, comisionesMes;
  final double fondoTotalAsignado, saldoTotalActual;
  final List<AgenteBancarioModel> porAgente;

  const ResumenAgentesModel({
    this.totalAgentes = 0, this.agentesActivos = 0,
    this.depositosHoyCant = 0, this.retirosHoyCant = 0,
    this.depositosHoyMonto = 0, this.retirosHoyMonto = 0,
    this.comisionesHoy = 0, this.comisionesMes = 0,
    this.fondoTotalAsignado = 0, this.saldoTotalActual = 0,
    this.porAgente = const [],
  });

  factory ResumenAgentesModel.fromJson(Map<String, dynamic> json) {
    final opsHoy = json['operacionesHoy'] as Map<String, dynamic>?;
    final dep = opsHoy?['depositos'] as Map<String, dynamic>?;
    final ret = opsHoy?['retiros'] as Map<String, dynamic>?;

    return ResumenAgentesModel(
      totalAgentes: json['totalAgentes'] as int? ?? 0,
      agentesActivos: json['agentesActivos'] as int? ?? 0,
      depositosHoyCant: dep?['cantidad'] as int? ?? json['depositosHoyCant'] as int? ?? 0,
      retirosHoyCant: ret?['cantidad'] as int? ?? json['retirosHoyCant'] as int? ?? 0,
      depositosHoyMonto: _toDouble(dep?['monto'] ?? json['depositosHoyMonto']),
      retirosHoyMonto: _toDouble(ret?['monto'] ?? json['retirosHoyMonto']),
      comisionesHoy: _toDouble(json['comisionesHoy']),
      comisionesMes: _toDouble(json['comisionesMes']),
      fondoTotalAsignado: _toDouble(json['fondoTotalAsignado']),
      saldoTotalActual: _toDouble(json['saldoTotalActual']),
      porAgente: _parseAgentes(json['porAgente']),
    );
  }

  static List<AgenteBancarioModel> _parseAgentes(dynamic json) {
    if (json == null) return [];
    return (json as List<dynamic>)
        .map((e) => AgenteBancarioModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  ResumenAgentes toEntity() {
    return ResumenAgentes(
      totalAgentes: totalAgentes, agentesActivos: agentesActivos,
      depositosHoyCant: depositosHoyCant, retirosHoyCant: retirosHoyCant,
      depositosHoyMonto: depositosHoyMonto, retirosHoyMonto: retirosHoyMonto,
      comisionesHoy: comisionesHoy, comisionesMes: comisionesMes,
      fondoTotalAsignado: fondoTotalAsignado, saldoTotalActual: saldoTotalActual,
      porAgente: porAgente.map((e) => e.toEntity()).toList(),
    );
  }
}
