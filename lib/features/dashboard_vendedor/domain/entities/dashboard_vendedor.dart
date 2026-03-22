import 'package:equatable/equatable.dart';

class DashboardVendedor extends Equatable {
  final VendedorInfo vendedor;
  final ResumenVendedor resumen;
  final CreditosVendedor creditos;
  final Map<String, double> metodosPago;
  final List<VentaDia> ventasPorDia;
  final List<TopItem> topProductos;
  final List<TopItem> topClientes;
  final RankingVendedor ranking;

  const DashboardVendedor({
    required this.vendedor,
    required this.resumen,
    required this.creditos,
    required this.metodosPago,
    required this.ventasPorDia,
    required this.topProductos,
    required this.topClientes,
    required this.ranking,
  });

  @override
  List<Object?> get props => [vendedor, resumen, creditos, ranking];
}

class VendedorInfo extends Equatable {
  final String id, nombre;
  final String? email;
  const VendedorInfo({required this.id, required this.nombre, this.email});
  @override
  List<Object?> get props => [id, nombre];
}

class ResumenVendedor extends Equatable {
  final int ventasHoyCantidad;
  final double ventasHoyMonto;
  final int ventasSemanaCantidad;
  final double ventasSemanaMonto;
  final int ventasMesCantidad;
  final double ventasMesMonto;
  final double ticketPromedio;
  final int cotizacionesTotal, cotizacionesConvertidas;
  final double tasaConversion;

  const ResumenVendedor({
    this.ventasHoyCantidad = 0,
    this.ventasHoyMonto = 0,
    this.ventasSemanaCantidad = 0,
    this.ventasSemanaMonto = 0,
    this.ventasMesCantidad = 0,
    this.ventasMesMonto = 0,
    this.ticketPromedio = 0,
    this.cotizacionesTotal = 0,
    this.cotizacionesConvertidas = 0,
    this.tasaConversion = 0,
  });

  @override
  List<Object?> get props =>
      [ventasHoyCantidad, ventasMesMonto, tasaConversion];
}

class CreditosVendedor extends Equatable {
  final double totalPendiente;
  final int cantidadPendientes;
  final double totalVencido;
  final int cantidadVencidos;

  const CreditosVendedor({
    this.totalPendiente = 0,
    this.cantidadPendientes = 0,
    this.totalVencido = 0,
    this.cantidadVencidos = 0,
  });

  @override
  List<Object?> get props => [totalPendiente, totalVencido];
}

class VentaDia extends Equatable {
  final String fecha;
  final int cantidad;
  final double monto;

  const VentaDia({required this.fecha, this.cantidad = 0, this.monto = 0});

  @override
  List<Object?> get props => [fecha, monto];
}

class TopItem extends Equatable {
  final String nombre;
  final int cantidad;
  final double monto;

  const TopItem({required this.nombre, this.cantidad = 0, this.monto = 0});

  @override
  List<Object?> get props => [nombre, monto];
}

class RankingVendedor extends Equatable {
  final int posicion, totalVendedores;
  final double montoVendedor, montoLider;

  const RankingVendedor({
    this.posicion = 0,
    this.totalVendedores = 0,
    this.montoVendedor = 0,
    this.montoLider = 0,
  });

  double get porcentajeVsLider =>
      montoLider > 0 ? (montoVendedor / montoLider * 100).clamp(0, 100) : 0;

  @override
  List<Object?> get props => [posicion, totalVendedores, montoVendedor];
}
