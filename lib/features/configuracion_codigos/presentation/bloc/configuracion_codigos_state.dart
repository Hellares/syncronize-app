import 'package:equatable/equatable.dart';
import '../../domain/entities/configuracion_codigos.dart';

/// Estados para gestión de configuración de códigos
abstract class ConfiguracionCodigosState extends Equatable {
  const ConfiguracionCodigosState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ConfiguracionCodigosInitial extends ConfiguracionCodigosState {
  const ConfiguracionCodigosInitial();
}

/// Estado de carga
class ConfiguracionCodigosLoading extends ConfiguracionCodigosState {
  const ConfiguracionCodigosLoading();
}

/// Estado con configuración cargada
class ConfiguracionCodigosLoaded extends ConfiguracionCodigosState {
  final ConfiguracionCodigos configuracion;
  final bool isLoading; // Para operaciones en progreso (actualizar, preview, etc.)
  final String? errorMessage;
  final PreviewCodigo? preview; // Vista previa temporal

  const ConfiguracionCodigosLoaded({
    required this.configuracion,
    this.isLoading = false,
    this.errorMessage,
    this.preview,
  });

  ConfiguracionCodigosLoaded copyWith({
    ConfiguracionCodigos? configuracion,
    bool? isLoading,
    String? errorMessage,
    PreviewCodigo? preview,
    bool clearPreview = false,
  }) {
    return ConfiguracionCodigosLoaded(
      configuracion: configuracion ?? this.configuracion,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      preview: clearPreview ? null : (preview ?? this.preview),
    );
  }

  @override
  List<Object?> get props => [
        configuracion,
        isLoading,
        errorMessage,
        preview,
      ];
}

/// Estado de error
class ConfiguracionCodigosError extends ConfiguracionCodigosState {
  final String message;

  const ConfiguracionCodigosError(this.message);

  @override
  List<Object?> get props => [message];
}
