import 'package:equatable/equatable.dart';
import '../../../domain/entities/transferencia_stock.dart';

abstract class TransferenciaDetailState extends Equatable {
  const TransferenciaDetailState();

  @override
  List<Object?> get props => [];
}

class TransferenciaDetailInitial extends TransferenciaDetailState {
  const TransferenciaDetailInitial();
}

class TransferenciaDetailLoading extends TransferenciaDetailState {
  const TransferenciaDetailLoading();
}

class TransferenciaDetailLoaded extends TransferenciaDetailState {
  final TransferenciaStock transferencia;

  const TransferenciaDetailLoaded(this.transferencia);

  @override
  List<Object?> get props => [transferencia];
}

class TransferenciaDetailError extends TransferenciaDetailState {
  final String message;
  final String? errorCode;

  const TransferenciaDetailError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
