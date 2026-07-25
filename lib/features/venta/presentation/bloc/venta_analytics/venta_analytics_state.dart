import 'package:equatable/equatable.dart';

abstract class VentaAnalyticsState extends Equatable {
  const VentaAnalyticsState();
  @override
  List<Object?> get props => [];
}

class VentaAnalyticsInitial extends VentaAnalyticsState {
  const VentaAnalyticsInitial();
}

class VentaAnalyticsLoading extends VentaAnalyticsState {
  const VentaAnalyticsLoading();
}

class VentaAnalyticsLoaded extends VentaAnalyticsState {
  final Map<String, dynamic> resumen;
  final List<dynamic> ventasPeriodo;
  final List<dynamic> topProductos;
  final List<dynamic> topClientes;
  final Map<String, dynamic> comparativo;
  final List<dynamic> alertas;
  final List<dynamic> menosVendidos;

  /// { porCanal: [{canal, cantidad, monto}], porEnvio: [{conEnvio, cantidad, monto}] }
  final Map<String, dynamic> porCanal;
  final List<dynamic> porCategoria;
  final List<dynamic> porMarca;
  final List<dynamic> porProveedor;

  /// { porTipoEntrega: [{tipo, cantidad, monto}], zonasEnvio: [{zona,
  /// cantidad, monto}], zonasDelivery: [{zona, cantidad, monto}] }
  final Map<String, dynamic> entregas;

  /// [{metodo, cantidad, monto}] — pagos cobrados agrupados por método
  final List<dynamic> metodosPago;

  /// { porHora: [24 × {hora, cantidad, monto}], porDiaSemana: [7 × {dia,
  /// cantidad, monto}] } en hora Perú
  final Map<String, dynamic> horasPico;

  /// [{productoId, varianteId, nombre, ventaDiaria, stockActual,
  /// diasCobertura, nivel, sugeridoComprar}] — velocidad 30d vs stock
  final List<dynamic> reposicion;

  /// { suficiente, diasHistoria, ventasActual, proyeccionCierre,
  /// proyeccionMin/Max, mesAnterior, variacionPct } — cierre de mes
  final Map<String, dynamic> proyeccion;

  /// Multi-RUC: { emisores: [{ruc, razonSocial, esPrincipal, ventas, monto}],
  /// sinComprobante: {ventas, monto}, multiEmisor } — la card solo se
  /// muestra si multiEmisor es true.
  final Map<String, dynamic> porEmisor;

  /// true mientras se recargan los datos manteniendo los actuales en pantalla
  /// (evita el flash de la página al buscar de nuevo).
  final bool refreshing;

  const VentaAnalyticsLoaded({
    required this.resumen,
    required this.ventasPeriodo,
    required this.topProductos,
    required this.topClientes,
    required this.comparativo,
    required this.alertas,
    required this.menosVendidos,
    required this.porCanal,
    required this.porCategoria,
    required this.porMarca,
    required this.porProveedor,
    required this.entregas,
    required this.metodosPago,
    required this.horasPico,
    required this.reposicion,
    required this.proyeccion,
    this.porEmisor = const {},
    this.refreshing = false,
  });

  VentaAnalyticsLoaded copyWith({bool? refreshing}) {
    return VentaAnalyticsLoaded(
      resumen: resumen,
      ventasPeriodo: ventasPeriodo,
      topProductos: topProductos,
      topClientes: topClientes,
      comparativo: comparativo,
      alertas: alertas,
      menosVendidos: menosVendidos,
      porCanal: porCanal,
      porCategoria: porCategoria,
      porMarca: porMarca,
      porProveedor: porProveedor,
      entregas: entregas,
      metodosPago: metodosPago,
      horasPico: horasPico,
      reposicion: reposicion,
      proyeccion: proyeccion,
      porEmisor: porEmisor,
      refreshing: refreshing ?? this.refreshing,
    );
  }

  @override
  List<Object?> get props => [
        resumen,
        ventasPeriodo,
        topProductos,
        topClientes,
        comparativo,
        alertas,
        menosVendidos,
        porCanal,
        porCategoria,
        porMarca,
        porProveedor,
        entregas,
        metodosPago,
        horasPico,
        reposicion,
        proyeccion,
        porEmisor,
        refreshing,
      ];
}

class VentaAnalyticsError extends VentaAnalyticsState {
  final String message;
  const VentaAnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}
