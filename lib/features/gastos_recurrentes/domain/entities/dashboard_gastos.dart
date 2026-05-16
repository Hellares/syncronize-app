import 'package:equatable/equatable.dart';
import 'gasto_recurrente.dart';
import 'pago_gasto_recurrente.dart';

class DashboardGastoItem extends Equatable {
  final GastoRecurrente gasto;
  final EstadoPeriodoGasto estado;
  final PagoGastoRecurrente? pagoPeriodo;

  const DashboardGastoItem({
    required this.gasto,
    required this.estado,
    this.pagoPeriodo,
  });

  @override
  List<Object?> get props => [gasto, estado, pagoPeriodo];
}

class DashboardGastosResumen extends Equatable {
  final int total;
  final int pagados;
  final int pendientes;
  final int vencidos;
  final double montoPagado;
  final double montoPendiente;
  final double montoVencido;

  const DashboardGastosResumen({
    required this.total,
    required this.pagados,
    required this.pendientes,
    required this.vencidos,
    required this.montoPagado,
    required this.montoPendiente,
    required this.montoVencido,
  });

  @override
  List<Object?> get props => [
        total,
        pagados,
        pendientes,
        vencidos,
        montoPagado,
        montoPendiente,
        montoVencido,
      ];
}

class DashboardGastos extends Equatable {
  final String periodo; // YYYY-MM
  final DashboardGastosResumen resumen;
  final List<DashboardGastoItem> items;

  const DashboardGastos({
    required this.periodo,
    required this.resumen,
    required this.items,
  });

  @override
  List<Object?> get props => [periodo, resumen, items];
}

class ComprobanteUploadResult extends Equatable {
  final String archivoId;
  final String url;
  final String tipoArchivo;
  final int tamanoBytes;

  const ComprobanteUploadResult({
    required this.archivoId,
    required this.url,
    required this.tipoArchivo,
    required this.tamanoBytes,
  });

  @override
  List<Object?> get props => [archivoId, url, tipoArchivo, tamanoBytes];
}
