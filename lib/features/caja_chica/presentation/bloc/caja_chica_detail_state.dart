import 'package:equatable/equatable.dart';
import '../../domain/entities/caja_chica.dart';
import '../../domain/entities/gasto_caja_chica.dart';

abstract class CajaChicaDetailState extends Equatable {
  const CajaChicaDetailState();

  @override
  List<Object?> get props => [];
}

class CajaChicaDetailInitial extends CajaChicaDetailState {
  const CajaChicaDetailInitial();
}

class CajaChicaDetailLoading extends CajaChicaDetailState {
  const CajaChicaDetailLoading();
}

class CajaChicaDetailLoaded extends CajaChicaDetailState {
  final CajaChica cajaChica;
  final List<GastoCajaChica> gastosPendientes;

  const CajaChicaDetailLoaded({
    required this.cajaChica,
    required this.gastosPendientes,
  });

  @override
  List<Object?> get props => [cajaChica, gastosPendientes];
}

class CajaChicaDetailError extends CajaChicaDetailState {
  final String message;

  const CajaChicaDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
