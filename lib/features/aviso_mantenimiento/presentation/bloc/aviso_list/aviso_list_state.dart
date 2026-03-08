import 'package:equatable/equatable.dart';
import '../../../domain/entities/aviso_mantenimiento.dart';

abstract class AvisoListState extends Equatable {
  const AvisoListState();
  @override
  List<Object?> get props => [];
}

class AvisoListInitial extends AvisoListState {
  const AvisoListInitial();
}

class AvisoListLoading extends AvisoListState {
  const AvisoListLoading();
}

class AvisoListLoaded extends AvisoListState {
  final List<AvisoMantenimiento> avisos;
  final AvisoResumen? resumen;
  final String? filtroEstado;

  const AvisoListLoaded({
    required this.avisos,
    this.resumen,
    this.filtroEstado,
  });

  @override
  List<Object?> get props => [avisos, resumen, filtroEstado];
}

class AvisoListError extends AvisoListState {
  final String message;
  const AvisoListError(this.message);
  @override
  List<Object?> get props => [message];
}
