import 'package:equatable/equatable.dart';
import '../../../domain/entities/unidad_medida.dart';

/// Estados para el manejo de unidades de medida
abstract class UnidadMedidaState extends Equatable {
  const UnidadMedidaState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class UnidadMedidaInitial extends UnidadMedidaState {}

/// Estado de carga de unidades maestras
class UnidadesMaestrasLoading extends UnidadMedidaState {}

/// Estado cuando las unidades maestras se cargaron exitosamente
class UnidadesMaestrasLoaded extends UnidadMedidaState {
  final List<UnidadMedidaMaestra> unidadesMaestras;

  const UnidadesMaestrasLoaded(this.unidadesMaestras);

  @override
  List<Object?> get props => [unidadesMaestras];
}

/// Estado de carga de unidades de empresa
class UnidadesEmpresaLoading extends UnidadMedidaState {}

/// Estado cuando las unidades de empresa se cargaron exitosamente
class UnidadesEmpresaLoaded extends UnidadMedidaState {
  final List<EmpresaUnidadMedida> unidadesEmpresa;

  const UnidadesEmpresaLoaded(this.unidadesEmpresa);

  @override
  List<Object?> get props => [unidadesEmpresa];
}

/// Estado de activación de unidad
class ActivandoUnidad extends UnidadMedidaState {}

/// Estado cuando se activó una unidad exitosamente
class UnidadActivada extends UnidadMedidaState {
  final EmpresaUnidadMedida unidad;

  const UnidadActivada(this.unidad);

  @override
  List<Object?> get props => [unidad];
}

/// Estado de desactivación de unidad
class DesactivandoUnidad extends UnidadMedidaState {}

/// Estado cuando se desactivó una unidad exitosamente
class UnidadDesactivada extends UnidadMedidaState {}

/// Estado de activación de unidades populares
class ActivandoUnidadesPopulares extends UnidadMedidaState {}

/// Estado cuando se activaron las unidades populares exitosamente
class UnidadesPopularesActivadas extends UnidadMedidaState {
  final List<EmpresaUnidadMedida> unidades;

  const UnidadesPopularesActivadas(this.unidades);

  @override
  List<Object?> get props => [unidades];
}

/// Estado de error
class UnidadMedidaError extends UnidadMedidaState {
  final String message;

  const UnidadMedidaError(this.message);

  @override
  List<Object?> get props => [message];
}
