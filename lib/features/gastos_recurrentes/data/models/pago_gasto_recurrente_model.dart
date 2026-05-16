import '../../domain/entities/pago_gasto_recurrente.dart';

class PagoGastoRecurrenteModel extends PagoGastoRecurrente {
  const PagoGastoRecurrenteModel({
    required super.id,
    required super.gastoRecurrenteId,
    required super.periodo,
    required super.montoReal,
    required super.fechaPago,
    required super.fuente,
    required super.metodoPago,
    super.bancoId,
    super.bancoNombre,
    super.bancoNumeroCuenta,
    super.movimientoCajaId,
    super.comprobanteUrl,
    super.notas,
    super.registradoPorNombre,
    super.anulado,
    super.motivoAnulacion,
    super.anuladoPorNombre,
    super.fechaAnulacion,
  });

  factory PagoGastoRecurrenteModel.fromJson(Map<String, dynamic> json) {
    final banco = json['banco'] as Map<String, dynamic>?;
    final mov = json['movimientoCaja'] as Map<String, dynamic>?;
    final reg = json['registradoPor'] as Map<String, dynamic>?;
    final anu = json['anuladoPor'] as Map<String, dynamic>?;
    String? nombreRegistrador;
    if (reg != null) {
      final persona = reg['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        nombreRegistrador =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
        if (nombreRegistrador.isEmpty) nombreRegistrador = null;
      }
    }
    String? nombreAnulador;
    if (anu != null) {
      final persona = anu['persona'] as Map<String, dynamic>?;
      if (persona != null) {
        nombreAnulador =
            '${persona['nombres'] ?? ''} ${persona['apellidos'] ?? ''}'.trim();
        if (nombreAnulador.isEmpty) nombreAnulador = null;
      }
    }

    return PagoGastoRecurrenteModel(
      id: json['id'] as String,
      gastoRecurrenteId: json['gastoRecurrenteId'] as String? ?? '',
      periodo: json['periodo'] as String? ?? '',
      montoReal: _toDouble(json['montoReal']),
      fechaPago: DateTime.parse(json['fechaPago'] as String),
      fuente: FuentePagoGasto.fromString(json['fuente'] as String? ?? 'CAJA'),
      metodoPago: MetodoPagoGasto.fromString(json['metodoPago'] as String? ?? 'EFECTIVO'),
      bancoId: json['bancoId'] as String?,
      bancoNombre: banco?['nombreBanco'] as String?,
      bancoNumeroCuenta: banco?['numeroCuenta'] as String?,
      movimientoCajaId: mov?['id'] as String? ?? json['movimientoCajaId'] as String?,
      comprobanteUrl: json['comprobanteUrl'] as String?,
      notas: json['notas'] as String?,
      registradoPorNombre: nombreRegistrador,
      anulado: json['anulado'] as bool? ?? false,
      motivoAnulacion: json['motivoAnulacion'] as String?,
      anuladoPorNombre: nombreAnulador,
      fechaAnulacion: json['fechaAnulacion'] != null
          ? DateTime.tryParse(json['fechaAnulacion'] as String)
          : null,
    );
  }

  PagoGastoRecurrente toEntity() => this;

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
