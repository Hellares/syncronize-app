import '../../domain/entities/dashboard_vendedor.dart';

class DashboardVendedorModel {
  final VendedorInfoModel vendedor;
  final ResumenVendedorModel resumen;
  final CreditosVendedorModel creditos;
  final Map<String, double> metodosPago;
  final List<VentaDiaModel> ventasPorDia;
  final List<TopItemModel> topProductos;
  final List<TopItemClienteModel> topClientes;
  final RankingVendedorModel ranking;

  const DashboardVendedorModel({
    required this.vendedor,
    required this.resumen,
    required this.creditos,
    required this.metodosPago,
    required this.ventasPorDia,
    required this.topProductos,
    required this.topClientes,
    required this.ranking,
  });

  factory DashboardVendedorModel.fromJson(Map<String, dynamic> json) {
    // Parse metodosPago
    final metodosPagoRaw = json['metodosPago'] as Map<String, dynamic>? ?? {};
    final metodosPago = metodosPagoRaw.map(
      (key, value) => MapEntry(key, (value as num?)?.toDouble() ?? 0),
    );

    // Parse ventasPorDia
    final ventasPorDiaRaw = json['ventasPorDia'] as List<dynamic>? ?? [];
    final ventasPorDia = ventasPorDiaRaw
        .map((e) => VentaDiaModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse topProductos
    final topProductosRaw = json['topProductos'] as List<dynamic>? ?? [];
    final topProductos = topProductosRaw
        .map((e) => TopItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Parse topClientes
    final topClientesRaw = json['topClientes'] as List<dynamic>? ?? [];
    final topClientes = topClientesRaw
        .map((e) => TopItemClienteModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardVendedorModel(
      vendedor: VendedorInfoModel.fromJson(
        json['vendedor'] as Map<String, dynamic>? ?? {},
      ),
      resumen: ResumenVendedorModel.fromJson(
        json['resumen'] as Map<String, dynamic>? ?? {},
      ),
      creditos: CreditosVendedorModel.fromJson(
        json['creditos'] as Map<String, dynamic>? ?? {},
      ),
      metodosPago: metodosPago,
      ventasPorDia: ventasPorDia,
      topProductos: topProductos,
      topClientes: topClientes,
      ranking: RankingVendedorModel.fromJson(
        json['ranking'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  DashboardVendedor toEntity() {
    return DashboardVendedor(
      vendedor: vendedor.toEntity(),
      resumen: resumen.toEntity(),
      creditos: creditos.toEntity(),
      metodosPago: metodosPago,
      ventasPorDia: ventasPorDia.map((e) => e.toEntity()).toList(),
      topProductos: topProductos.map((e) => e.toEntity()).toList(),
      topClientes: topClientes.map((e) => e.toEntity()).toList(),
      ranking: ranking.toEntity(),
    );
  }
}

class VendedorInfoModel {
  final String id, nombre;
  final String? email;

  const VendedorInfoModel({
    required this.id,
    required this.nombre,
    this.email,
  });

  factory VendedorInfoModel.fromJson(Map<String, dynamic> json) {
    return VendedorInfoModel(
      id: json['id'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String?,
    );
  }

  VendedorInfo toEntity() {
    return VendedorInfo(id: id, nombre: nombre, email: email);
  }
}

class ResumenVendedorModel {
  final int ventasHoyCantidad;
  final double ventasHoyMonto;
  final int ventasSemanaCantidad;
  final double ventasSemanaMonto;
  final int ventasMesCantidad;
  final double ventasMesMonto;
  final double ticketPromedio;
  final int cotizacionesTotal, cotizacionesConvertidas;
  final double tasaConversion;

  const ResumenVendedorModel({
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

  factory ResumenVendedorModel.fromJson(Map<String, dynamic> json) {
    return ResumenVendedorModel(
      ventasHoyCantidad: json['ventasHoyCantidad'] as int? ?? 0,
      ventasHoyMonto: (json['ventasHoyMonto'] as num?)?.toDouble() ?? 0,
      ventasSemanaCantidad: json['ventasSemanaCantidad'] as int? ?? 0,
      ventasSemanaMonto: (json['ventasSemanaMonto'] as num?)?.toDouble() ?? 0,
      ventasMesCantidad: json['ventasMesCantidad'] as int? ?? 0,
      ventasMesMonto: (json['ventasMesMonto'] as num?)?.toDouble() ?? 0,
      ticketPromedio: (json['ticketPromedio'] as num?)?.toDouble() ?? 0,
      cotizacionesTotal: json['cotizacionesTotal'] as int? ?? 0,
      cotizacionesConvertidas: json['cotizacionesConvertidas'] as int? ?? 0,
      tasaConversion: (json['tasaConversion'] as num?)?.toDouble() ?? 0,
    );
  }

  ResumenVendedor toEntity() {
    return ResumenVendedor(
      ventasHoyCantidad: ventasHoyCantidad,
      ventasHoyMonto: ventasHoyMonto,
      ventasSemanaCantidad: ventasSemanaCantidad,
      ventasSemanaMonto: ventasSemanaMonto,
      ventasMesCantidad: ventasMesCantidad,
      ventasMesMonto: ventasMesMonto,
      ticketPromedio: ticketPromedio,
      cotizacionesTotal: cotizacionesTotal,
      cotizacionesConvertidas: cotizacionesConvertidas,
      tasaConversion: tasaConversion,
    );
  }
}

class CreditosVendedorModel {
  final double totalPendiente;
  final int cantidadPendientes;
  final double totalVencido;
  final int cantidadVencidos;

  const CreditosVendedorModel({
    this.totalPendiente = 0,
    this.cantidadPendientes = 0,
    this.totalVencido = 0,
    this.cantidadVencidos = 0,
  });

  factory CreditosVendedorModel.fromJson(Map<String, dynamic> json) {
    return CreditosVendedorModel(
      totalPendiente: (json['totalPendiente'] as num?)?.toDouble() ?? 0,
      cantidadPendientes: json['cantidadPendientes'] as int? ?? 0,
      totalVencido: (json['totalVencido'] as num?)?.toDouble() ?? 0,
      cantidadVencidos: json['cantidadVencidos'] as int? ?? 0,
    );
  }

  CreditosVendedor toEntity() {
    return CreditosVendedor(
      totalPendiente: totalPendiente,
      cantidadPendientes: cantidadPendientes,
      totalVencido: totalVencido,
      cantidadVencidos: cantidadVencidos,
    );
  }
}

class VentaDiaModel {
  final String fecha;
  final int cantidad;
  final double monto;

  const VentaDiaModel({
    required this.fecha,
    this.cantidad = 0,
    this.monto = 0,
  });

  factory VentaDiaModel.fromJson(Map<String, dynamic> json) {
    return VentaDiaModel(
      fecha: json['fecha'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 0,
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
    );
  }

  VentaDia toEntity() {
    return VentaDia(fecha: fecha, cantidad: cantidad, monto: monto);
  }
}

class TopItemModel {
  final String nombre;
  final int cantidad;
  final double monto;

  const TopItemModel({
    required this.nombre,
    this.cantidad = 0,
    this.monto = 0,
  });

  factory TopItemModel.fromJson(Map<String, dynamic> json) {
    return TopItemModel(
      nombre: json['nombre'] as String? ?? '',
      cantidad: json['cantidad'] as int? ?? 0,
      monto: (json['monto'] as num?)?.toDouble() ?? 0,
    );
  }

  TopItem toEntity() {
    return TopItem(nombre: nombre, cantidad: cantidad, monto: monto);
  }
}

class TopItemClienteModel {
  final String nombre;
  final int cantidad;
  final double monto;

  const TopItemClienteModel({
    required this.nombre,
    this.cantidad = 0,
    this.monto = 0,
  });

  factory TopItemClienteModel.fromJson(Map<String, dynamic> json) {
    return TopItemClienteModel(
      nombre: json['nombre'] as String? ?? '',
      cantidad: json['cantidadCompras'] as int? ?? 0,
      monto: (json['montoTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  TopItem toEntity() {
    return TopItem(nombre: nombre, cantidad: cantidad, monto: monto);
  }
}

class RankingVendedorModel {
  final int posicion, totalVendedores;
  final double montoVendedor, montoLider;

  const RankingVendedorModel({
    this.posicion = 0,
    this.totalVendedores = 0,
    this.montoVendedor = 0,
    this.montoLider = 0,
  });

  factory RankingVendedorModel.fromJson(Map<String, dynamic> json) {
    return RankingVendedorModel(
      posicion: json['posicion'] as int? ?? 0,
      totalVendedores: json['totalVendedores'] as int? ?? 0,
      montoVendedor: (json['montoVendedor'] as num?)?.toDouble() ?? 0,
      montoLider: (json['montoLider'] as num?)?.toDouble() ?? 0,
    );
  }

  RankingVendedor toEntity() {
    return RankingVendedor(
      posicion: posicion,
      totalVendedores: totalVendedores,
      montoVendedor: montoVendedor,
      montoLider: montoLider,
    );
  }
}
