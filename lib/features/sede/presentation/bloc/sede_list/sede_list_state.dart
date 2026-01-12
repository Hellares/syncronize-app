import 'package:equatable/equatable.dart';
import '../../../../empresa/domain/entities/sede.dart';

/// Estados de la lista de sedes
abstract class SedeListState extends Equatable {
  const SedeListState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class SedeListInitial extends SedeListState {
  const SedeListInitial();
}

/// Estado de carga
class SedeListLoading extends SedeListState {
  const SedeListLoading();
}

/// Estado de éxito con sedes cargadas
class SedeListLoaded extends SedeListState {
  final List<Sede> sedes;

  const SedeListLoaded(this.sedes);

  @override
  List<Object?> get props => [sedes];
}

/// Estado de error
class SedeListError extends SedeListState {
  final String message;
  final String? errorCode;

  const SedeListError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
