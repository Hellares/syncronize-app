import 'package:equatable/equatable.dart';

import '../../../domain/entities/boleta_pago.dart';

abstract class BoletaDetailState extends Equatable {
  const BoletaDetailState();

  @override
  List<Object?> get props => [];
}

class BoletaDetailInitial extends BoletaDetailState {
  const BoletaDetailInitial();
}

class BoletaDetailLoading extends BoletaDetailState {
  const BoletaDetailLoading();
}

class BoletaDetailLoaded extends BoletaDetailState {
  final BoletaPago boleta;

  const BoletaDetailLoaded(this.boleta);

  @override
  List<Object?> get props => [boleta];
}

class BoletaDetailError extends BoletaDetailState {
  final String message;

  const BoletaDetailError(this.message);

  @override
  List<Object?> get props => [message];
}
