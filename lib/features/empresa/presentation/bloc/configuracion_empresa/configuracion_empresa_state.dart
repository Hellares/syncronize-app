import 'package:equatable/equatable.dart';
import '../../../domain/entities/configuracion_empresa.dart';

/// Estados de la configuración de empresa
abstract class ConfiguracionEmpresaState extends Equatable {
  const ConfiguracionEmpresaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ConfiguracionEmpresaInitial extends ConfiguracionEmpresaState {
  const ConfiguracionEmpresaInitial();
}

/// Estado de carga
class ConfiguracionEmpresaLoading extends ConfiguracionEmpresaState {
  const ConfiguracionEmpresaLoading();
}

/// Estado de éxito con la configuración cargada
class ConfiguracionEmpresaLoaded extends ConfiguracionEmpresaState {
  final ConfiguracionEmpresa configuracion;

  const ConfiguracionEmpresaLoaded(this.configuracion);

  @override
  List<Object?> get props => [configuracion];
}

/// Estado de error
class ConfiguracionEmpresaError extends ConfiguracionEmpresaState {
  final String message;
  final String? errorCode;

  const ConfiguracionEmpresaError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
