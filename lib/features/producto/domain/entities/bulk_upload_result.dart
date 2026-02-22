import 'package:equatable/equatable.dart';

class BulkUploadResult extends Equatable {
  final int totalFilas;
  final int creados;
  final int errores;
  final List<RowError> detalleErrores;
  final List<CreatedProductSummary> productosCreados;

  const BulkUploadResult({
    required this.totalFilas,
    required this.creados,
    required this.errores,
    required this.detalleErrores,
    required this.productosCreados,
  });

  @override
  List<Object?> get props => [totalFilas, creados, errores, detalleErrores, productosCreados];
}

class RowError extends Equatable {
  final int fila;
  final String columna;
  final String valor;
  final String mensaje;

  const RowError({
    required this.fila,
    required this.columna,
    required this.valor,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [fila, columna, valor, mensaje];
}

class CreatedProductSummary extends Equatable {
  final String id;
  final String nombre;
  final String codigoEmpresa;

  const CreatedProductSummary({
    required this.id,
    required this.nombre,
    required this.codigoEmpresa,
  });

  @override
  List<Object?> get props => [id, nombre, codigoEmpresa];
}
