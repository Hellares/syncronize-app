import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_stock.dart';

/// Estados para el formulario de ajuste de stock
abstract class AjustarStockState extends Equatable {
  const AjustarStockState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class AjustarStockInitial extends AjustarStockState {
  const AjustarStockInitial();
}

/// Estado de procesamiento
class AjustarStockProcessing extends AjustarStockState {
  const AjustarStockProcessing();
}

/// Estado de éxito
class AjustarStockSuccess extends AjustarStockState {
  final ProductoStock stockActualizado;
  final String message;

  const AjustarStockSuccess({
    required this.stockActualizado,
    this.message = 'Stock ajustado correctamente',
  });

  @override
  List<Object?> get props => [stockActualizado, message];
}

/// Estado de error
class AjustarStockError extends AjustarStockState {
  final String message;
  final String? errorCode;

  const AjustarStockError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
