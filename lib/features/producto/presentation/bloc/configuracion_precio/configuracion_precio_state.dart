import 'package:equatable/equatable.dart';
import '../../../domain/entities/configuracion_precio.dart';

/// Estados para gestión de configuraciones de precios
abstract class ConfiguracionPrecioState extends Equatable {
  const ConfiguracionPrecioState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ConfiguracionPrecioInitial extends ConfiguracionPrecioState {
  const ConfiguracionPrecioInitial();
}

/// Estado de carga
class ConfiguracionPrecioLoading extends ConfiguracionPrecioState {
  const ConfiguracionPrecioLoading();
}

/// Estado con configuraciones cargadas
class ConfiguracionPrecioLoaded extends ConfiguracionPrecioState {
  final List<ConfiguracionPrecio> configuraciones;
  final bool isLoading; // Para operaciones en progreso
  final String? errorMessage;

  const ConfiguracionPrecioLoaded({
    required this.configuraciones,
    this.isLoading = false,
    this.errorMessage,
  });

  ConfiguracionPrecioLoaded copyWith({
    List<ConfiguracionPrecio>? configuraciones,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ConfiguracionPrecioLoaded(
      configuraciones: configuraciones ?? this.configuraciones,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [configuraciones, isLoading, errorMessage];
}

/// Estado de error
class ConfiguracionPrecioError extends ConfiguracionPrecioState {
  final String message;

  const ConfiguracionPrecioError(this.message);

  @override
  List<Object?> get props => [message];
}
