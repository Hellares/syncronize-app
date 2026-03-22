import '../../domain/entities/agente_bancario.dart';

class OperacionAgenteModel {
  final String id;
  final String tipo;
  final double monto;
  final double comision;
  final String? nombreCliente;
  final String? documentoCliente;
  final String? numeroOperacion;
  final String? observaciones;
  final String? registradoPorNombre;
  final DateTime fechaOperacion;
  final bool anulado;

  const OperacionAgenteModel({
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

  factory OperacionAgenteModel.fromJson(Map<String, dynamic> json) {
    return OperacionAgenteModel(
      id: json['id'] as String? ?? '',
      tipo: json['tipo'] as String? ?? 'DEPOSITO',
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
      comision: (json['comision'] as num?)?.toDouble() ?? 0,
      nombreCliente: json['nombreCliente'] as String?,
      documentoCliente: json['documentoCliente'] as String?,
      numeroOperacion: json['numeroOperacion'] as String?,
      observaciones: json['observaciones'] as String?,
      registradoPorNombre: json['registradoPorNombre'] as String?,
      fechaOperacion: json['fechaOperacion'] != null
          ? DateTime.parse(json['fechaOperacion'] as String)
          : DateTime.now(),
      anulado: json['anulado'] as bool? ?? false,
    );
  }

  OperacionAgente toEntity() {
    return OperacionAgente(
      id: id,
      tipo: tipo,
      monto: monto,
      comision: comision,
      nombreCliente: nombreCliente,
      documentoCliente: documentoCliente,
      numeroOperacion: numeroOperacion,
      observaciones: observaciones,
      registradoPorNombre: registradoPorNombre,
      fechaOperacion: fechaOperacion,
      anulado: anulado,
    );
  }

  static List<OperacionAgenteModel> parseList(dynamic json) {
    if (json == null) return [];
    final list = json as List<dynamic>;
    return list
        .map((e) => OperacionAgenteModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
