import 'package:equatable/equatable.dart';

class CotizacionPOS extends Equatable {
  final String id;
  final String codigo;
  final String estado;
  final String nombreCliente;
  final String vendedor;
  final String? sede;
  final double total;
  final String moneda;
  final int totalItems;
  final List<DetallePOS> detalles;
  final DateTime creadoEn;

  const CotizacionPOS({
    required this.id,
    required this.codigo,
    required this.estado,
    required this.nombreCliente,
    required this.vendedor,
    this.sede,
    required this.total,
    required this.moneda,
    required this.totalItems,
    required this.detalles,
    required this.creadoEn,
  });

  bool get esPendiente => estado == 'PENDIENTE';
  bool get esAprobada => estado == 'APROBADA';

  /// Tiempo de espera en minutos
  int get minutosEspera => DateTime.now().difference(creadoEn).inMinutes;

  String get tiempoEsperaTexto {
    final min = minutosEspera;
    if (min < 1) return 'Ahora';
    if (min < 60) return '${min}min';
    return '${min ~/ 60}h ${min % 60}min';
  }

  @override
  List<Object?> get props => [id, codigo];
}

class DetallePOS extends Equatable {
  final String id;
  final String? producto;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;

  const DetallePOS({
    required this.id,
    this.producto,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
  });

  @override
  List<Object?> get props => [id];
}
