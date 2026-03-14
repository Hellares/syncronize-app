import 'package:equatable/equatable.dart';
import '../../../domain/entities/cita.dart';

abstract class CitaListState extends Equatable {
  const CitaListState();

  @override
  List<Object?> get props => [];
}

class CitaListInitial extends CitaListState {
  const CitaListInitial();
}

class CitaListLoading extends CitaListState {
  const CitaListLoading();
}

class CitaListLoaded extends CitaListState {
  final CitasPaginadas resultado;
  final String? filtroFecha;
  final String? filtroEstado;
  final String? filtroTecnicoId;
  final String? filtroSedeId;

  const CitaListLoaded({
    required this.resultado,
    this.filtroFecha,
    this.filtroEstado,
    this.filtroTecnicoId,
    this.filtroSedeId,
  });

  @override
  List<Object?> get props => [
        resultado,
        filtroFecha,
        filtroEstado,
        filtroTecnicoId,
        filtroSedeId,
      ];
}

class CitaListError extends CitaListState {
  final String message;

  const CitaListError(this.message);

  @override
  List<Object?> get props => [message];
}
