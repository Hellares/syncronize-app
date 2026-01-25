import 'package:equatable/equatable.dart';
import '../../../domain/entities/producto_stock.dart';

/// Estados del cubit de configurar precios
abstract class ConfigurarPreciosState extends Equatable {
  const ConfigurarPreciosState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ConfigurarPreciosInitial extends ConfigurarPreciosState {
  const ConfigurarPreciosInitial();
}

/// Estado de carga
class ConfigurarPreciosLoading extends ConfigurarPreciosState {
  const ConfigurarPreciosLoading();
}

/// Estado de éxito
class ConfigurarPreciosSuccess extends ConfigurarPreciosState {
  final ProductoStock stock;
  final String message;

  const ConfigurarPreciosSuccess({
    required this.stock,
    this.message = 'Precios actualizados correctamente',
  });

  @override
  List<Object?> get props => [stock, message];
}

/// Estado de error
class ConfigurarPreciosError extends ConfigurarPreciosState {
  final String message;

  const ConfigurarPreciosError(this.message);

  @override
  List<Object?> get props => [message];
}
