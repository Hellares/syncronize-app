import 'package:equatable/equatable.dart';
import '../../../domain/entities/bulk_editar_stock_precios.dart';
import '../../../domain/entities/producto_variante.dart';

abstract class EdicionMasivaStockState extends Equatable {
  const EdicionMasivaStockState();

  @override
  List<Object?> get props => [];
}

class EdicionMasivaStockInitial extends EdicionMasivaStockState {
  const EdicionMasivaStockInitial();
}

class EdicionMasivaStockLoading extends EdicionMasivaStockState {
  const EdicionMasivaStockLoading();
}

class EdicionMasivaStockLoaded extends EdicionMasivaStockState {
  final List<ProductoVariante> variantes;

  const EdicionMasivaStockLoaded(this.variantes);

  @override
  List<Object?> get props => [variantes];
}

/// Guardando cambios; mantiene las variantes para no desmontar la grilla.
class EdicionMasivaStockSaving extends EdicionMasivaStockState {
  final List<ProductoVariante> variantes;

  const EdicionMasivaStockSaving(this.variantes);

  @override
  List<Object?> get props => [variantes];
}

class EdicionMasivaStockSuccess extends EdicionMasivaStockState {
  final BulkEditarResumen resumen;
  final List<ProductoVariante> variantes;

  const EdicionMasivaStockSuccess(this.resumen, this.variantes);

  @override
  List<Object?> get props => [resumen, variantes];
}

class EdicionMasivaStockError extends EdicionMasivaStockState {
  final String message;
  final List<ProductoVariante> variantes;

  const EdicionMasivaStockError(this.message, {this.variantes = const []});

  @override
  List<Object?> get props => [message, variantes];
}
