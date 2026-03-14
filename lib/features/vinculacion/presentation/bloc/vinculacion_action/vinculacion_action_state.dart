import 'package:equatable/equatable.dart';
import '../../../domain/entities/vinculacion.dart';

abstract class VinculacionActionState extends Equatable {
  const VinculacionActionState();
  @override
  List<Object?> get props => [];
}

class VinculacionActionInitial extends VinculacionActionState {
  const VinculacionActionInitial();
}

class VinculacionActionLoading extends VinculacionActionState {
  const VinculacionActionLoading();
}

class VinculacionActionSuccess extends VinculacionActionState {
  final VinculacionEmpresa vinculacion;
  final String mensaje;

  const VinculacionActionSuccess({
    required this.vinculacion,
    required this.mensaje,
  });

  @override
  List<Object?> get props => [vinculacion, mensaje];
}

class VinculacionCheckRucResult extends VinculacionActionState {
  final EmpresaVinculable? empresa;

  const VinculacionCheckRucResult({this.empresa});

  @override
  List<Object?> get props => [empresa];
}

class VinculacionActionError extends VinculacionActionState {
  final String message;
  const VinculacionActionError(this.message);
  @override
  List<Object?> get props => [message];
}
