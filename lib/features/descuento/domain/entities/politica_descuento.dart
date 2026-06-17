import 'package:equatable/equatable.dart';

enum TipoDescuento {
  trabajador,
  familiarTrabajador,
  vip,
  promocional,
  lealtad,
  cumpleanios,
}

enum TipoCalculoDescuento {
  porcentaje,
  montoFijo,
  precioCosto, // VIP: vende al precio de costo (× markup opcional)
  precioMayorDesdeUnidad, // VIP: precio por mayor desde la unidad 1
}

/// Estrategia para resolver qué escalón por mayor aplicar desde la unidad 1
/// (solo para tipoCalculo = precioMayorDesdeUnidad).
enum EstrategiaMayor {
  primerNivel, // Primer escalón por mayor (menor cantidadMinima > 1)
  mejorNivel, // El nivel de menor precio disponible
}

enum Parentesco {
  conyuge,
  hijo,
  hija,
  padre,
  madre,
  hermano,
  hermana,
  abuelo,
  abuela,
  nieto,
  nieta,
  tio,
  tia,
  sobrino,
  sobrina,
  primo,
  prima,
}

class PoliticaDescuento extends Equatable {
  final String id;
  final String empresaId;
  final String nombre;
  final String? descripcion;
  final TipoDescuento tipoDescuento;
  final TipoCalculoDescuento tipoCalculo;
  final double valorDescuento;
  final double? descuentoMaximo;
  final double? montoMinCompra;
  final int? cantidadMaxUsos;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final bool aplicarATodos;
  final int prioridad;
  final int? maxFamiliaresPorTrabajador;
  // Precio especial VIP
  final double? markupSobreCosto; // % sobre costo (modo precioCosto)
  final EstrategiaMayor estrategiaMayor; // modo precioMayorDesdeUnidad
  final bool isActive;
  final DateTime creadoEn;
  final DateTime actualizadoEn;

  // Contadores
  final int? totalUsuarios;
  final int? totalProductos;
  final int? totalCategorias;
  final int? totalUsos;

  // IDs de productos/categorías asignados (del detalle GET /:id). Vacío si no
  // se cargaron. Usado por la pantalla de asignar para marcar "ya asignado".
  final List<String> productoIdsAplicables;
  final List<String> categoriaIdsAplicables;

  const PoliticaDescuento({
    required this.id,
    required this.empresaId,
    required this.nombre,
    this.descripcion,
    required this.tipoDescuento,
    required this.tipoCalculo,
    required this.valorDescuento,
    this.descuentoMaximo,
    this.montoMinCompra,
    this.cantidadMaxUsos,
    this.fechaInicio,
    this.fechaFin,
    this.aplicarATodos = false,
    this.prioridad = 0,
    this.maxFamiliaresPorTrabajador,
    this.markupSobreCosto,
    this.estrategiaMayor = EstrategiaMayor.primerNivel,
    this.isActive = true,
    required this.creadoEn,
    required this.actualizadoEn,
    this.totalUsuarios,
    this.totalProductos,
    this.totalCategorias,
    this.totalUsos,
    this.productoIdsAplicables = const [],
    this.categoriaIdsAplicables = const [],
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        nombre,
        descripcion,
        tipoDescuento,
        tipoCalculo,
        valorDescuento,
        descuentoMaximo,
        montoMinCompra,
        cantidadMaxUsos,
        fechaInicio,
        fechaFin,
        aplicarATodos,
        prioridad,
        maxFamiliaresPorTrabajador,
        markupSobreCosto,
        estrategiaMayor,
        isActive,
        creadoEn,
        actualizadoEn,
        totalUsuarios,
        totalProductos,
        totalCategorias,
        totalUsos,
        productoIdsAplicables,
        categoriaIdsAplicables,
      ];

  PoliticaDescuento copyWith({
    String? id,
    String? empresaId,
    String? nombre,
    String? descripcion,
    TipoDescuento? tipoDescuento,
    TipoCalculoDescuento? tipoCalculo,
    double? valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
    double? markupSobreCosto,
    EstrategiaMayor? estrategiaMayor,
    bool? isActive,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    int? totalUsuarios,
    int? totalProductos,
    int? totalCategorias,
    int? totalUsos,
    List<String>? productoIdsAplicables,
    List<String>? categoriaIdsAplicables,
  }) {
    return PoliticaDescuento(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      nombre: nombre ?? this.nombre,
      descripcion: descripcion ?? this.descripcion,
      tipoDescuento: tipoDescuento ?? this.tipoDescuento,
      tipoCalculo: tipoCalculo ?? this.tipoCalculo,
      valorDescuento: valorDescuento ?? this.valorDescuento,
      descuentoMaximo: descuentoMaximo ?? this.descuentoMaximo,
      montoMinCompra: montoMinCompra ?? this.montoMinCompra,
      cantidadMaxUsos: cantidadMaxUsos ?? this.cantidadMaxUsos,
      fechaInicio: fechaInicio ?? this.fechaInicio,
      fechaFin: fechaFin ?? this.fechaFin,
      aplicarATodos: aplicarATodos ?? this.aplicarATodos,
      prioridad: prioridad ?? this.prioridad,
      maxFamiliaresPorTrabajador:
          maxFamiliaresPorTrabajador ?? this.maxFamiliaresPorTrabajador,
      markupSobreCosto: markupSobreCosto ?? this.markupSobreCosto,
      estrategiaMayor: estrategiaMayor ?? this.estrategiaMayor,
      isActive: isActive ?? this.isActive,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      totalUsuarios: totalUsuarios ?? this.totalUsuarios,
      totalProductos: totalProductos ?? this.totalProductos,
      totalCategorias: totalCategorias ?? this.totalCategorias,
      totalUsos: totalUsos ?? this.totalUsos,
    );
  }
}
