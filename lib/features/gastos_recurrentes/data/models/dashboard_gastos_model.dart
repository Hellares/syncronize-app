import '../../domain/entities/dashboard_gastos.dart';
import '../../domain/entities/pago_gasto_recurrente.dart';
import 'gasto_recurrente_model.dart';
import 'pago_gasto_recurrente_model.dart';

class DashboardGastosModel extends DashboardGastos {
  const DashboardGastosModel({
    required super.periodo,
    required super.resumen,
    required super.items,
  });

  factory DashboardGastosModel.fromJson(Map<String, dynamic> json) {
    final resumenJson = json['resumen'] as Map<String, dynamic>;
    final itemsJson = (json['items'] as List).cast<Map<String, dynamic>>();

    return DashboardGastosModel(
      periodo: json['periodo'] as String,
      resumen: DashboardGastosResumen(
        total: resumenJson['total'] as int? ?? 0,
        pagados: resumenJson['pagados'] as int? ?? 0,
        pendientes: resumenJson['pendientes'] as int? ?? 0,
        vencidos: resumenJson['vencidos'] as int? ?? 0,
        montoPagado: _toDouble(resumenJson['montoPagado']),
        montoPendiente: _toDouble(resumenJson['montoPendiente']),
        montoVencido: _toDouble(resumenJson['montoVencido']),
      ),
      items: itemsJson.map(_itemFromJson).toList(),
    );
  }

  static DashboardGastoItem _itemFromJson(Map<String, dynamic> json) {
    final pagoJson = json['pagoPeriodo'] as Map<String, dynamic>?;
    PagoGastoRecurrente? pago;
    if (pagoJson != null) {
      // El dashboard devuelve sub-objeto pagoPeriodo sin gastoRecurrenteId — lo
      // sintetizamos desde el id del gasto envolvente para mantener la entidad sana.
      final pagoMap = Map<String, dynamic>.from(pagoJson);
      pagoMap['gastoRecurrenteId'] = json['id'];
      pago = PagoGastoRecurrenteModel.fromJson(pagoMap);
    }

    return DashboardGastoItem(
      gasto: GastoRecurrenteModel.fromJson(json),
      estado: EstadoPeriodoGasto.fromString(json['estado'] as String? ?? 'PENDIENTE'),
      pagoPeriodo: pago,
    );
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }
}
