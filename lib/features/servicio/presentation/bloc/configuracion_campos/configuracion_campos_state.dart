import 'package:equatable/equatable.dart';
import '../../../domain/entities/configuracion_campo.dart';

abstract class ConfiguracionCamposState extends Equatable {
  const ConfiguracionCamposState();
  @override
  List<Object?> get props => [];
}

class ConfiguracionCamposInitial extends ConfiguracionCamposState {
  const ConfiguracionCamposInitial();
}

class ConfiguracionCamposLoading extends ConfiguracionCamposState {
  const ConfiguracionCamposLoading();
}

class ConfiguracionCamposLoaded extends ConfiguracionCamposState {
  final List<ConfiguracionCampo> campos;
  const ConfiguracionCamposLoaded(this.campos);
  @override
  List<Object?> get props => [campos];
}

class ConfiguracionCamposError extends ConfiguracionCamposState {
  final String message;
  const ConfiguracionCamposError(this.message);
  @override
  List<Object?> get props => [message];
}

class ConfiguracionCampoActionSuccess extends ConfiguracionCamposState {
  final String message;
  final List<ConfiguracionCampo> campos;
  const ConfiguracionCampoActionSuccess(this.message, this.campos);
  @override
  List<Object?> get props => [message, campos];
}
