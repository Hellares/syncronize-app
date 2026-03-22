import 'package:equatable/equatable.dart';

class BarcodeItem extends Equatable {
  final String id;
  final String productoId;
  final String nombre;
  final String? codigoBarras;
  final String? codigoEmpresa;
  final String? sku;
  final double? precio;
  final String? sedeNombre;
  final int stockActual;
  final int cantidadEtiquetas;

  const BarcodeItem({
    required this.id,
    required this.productoId,
    required this.nombre,
    this.codigoBarras,
    this.codigoEmpresa,
    this.sku,
    this.precio,
    this.sedeNombre,
    this.stockActual = 0,
    this.cantidadEtiquetas = 1,
  });

  bool get tieneBarcode => codigoBarras != null && codigoBarras!.isNotEmpty;

  BarcodeItem copyWith({int? cantidadEtiquetas, String? codigoBarras}) {
    return BarcodeItem(
      id: id,
      productoId: productoId,
      nombre: nombre,
      codigoBarras: codigoBarras ?? this.codigoBarras,
      codigoEmpresa: codigoEmpresa,
      sku: sku,
      precio: precio,
      sedeNombre: sedeNombre,
      stockActual: stockActual,
      cantidadEtiquetas: cantidadEtiquetas ?? this.cantidadEtiquetas,
    );
  }

  @override
  List<Object?> get props => [id, productoId, nombre, codigoBarras, cantidadEtiquetas];
}

class GenerarCodigosResult extends Equatable {
  final int generados;
  final List<CodigoGenerado> resultados;

  const GenerarCodigosResult({required this.generados, required this.resultados});

  @override
  List<Object?> get props => [generados, resultados];
}

class CodigoGenerado extends Equatable {
  final String productoId;
  final String? varianteId;
  final String tipo;
  final String codigo;
  final String nombre;

  const CodigoGenerado({
    required this.productoId,
    this.varianteId,
    required this.tipo,
    required this.codigo,
    required this.nombre,
  });

  @override
  List<Object?> get props => [productoId, codigo];
}
