import 'package:equatable/equatable.dart';
import '../../../domain/entities/regla_compatibilidad.dart';
import '../../../domain/entities/resultado_compatibilidad.dart';

abstract class CompatibilidadState extends Equatable {
  const CompatibilidadState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class CompatibilidadInitial extends CompatibilidadState {
  const CompatibilidadInitial();
}

/// Estado de carga
class CompatibilidadLoading extends CompatibilidadState {
  const CompatibilidadLoading();
}

/// Lista de reglas cargada
class CompatibilidadReglasLoaded extends CompatibilidadState {
  final List<ReglaCompatibilidad> reglas;

  const CompatibilidadReglasLoaded(this.reglas);

  @override
  List<Object?> get props => [reglas];
}

/// Operación CRUD exitosa
class CompatibilidadOperationSuccess extends CompatibilidadState {
  final String message;
  final List<ReglaCompatibilidad> reglas;

  const CompatibilidadOperationSuccess(this.message, this.reglas);

  @override
  List<Object?> get props => [message, reglas];
}

/// Resultado de validación de compatibilidad
class CompatibilidadValidacionResult extends CompatibilidadState {
  final ResultadoCompatibilidad resultado;

  const CompatibilidadValidacionResult(this.resultado);

  @override
  List<Object?> get props => [resultado];
}

/// Estado de error
class CompatibilidadError extends CompatibilidadState {
  final String message;

  const CompatibilidadError(this.message);

  @override
  List<Object?> get props => [message];
}
