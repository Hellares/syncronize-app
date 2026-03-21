import 'package:equatable/equatable.dart';
import '../../domain/entities/empresa_banco.dart';

abstract class ConciliacionState extends Equatable {
  const ConciliacionState();

  @override
  List<Object?> get props => [];
}

class ConciliacionInitial extends ConciliacionState {
  const ConciliacionInitial();
}

class ConciliacionLoading extends ConciliacionState {
  const ConciliacionLoading();
}

class ConciliacionLoaded extends ConciliacionState {
  final ConciliacionBancaria conciliacion;

  const ConciliacionLoaded(this.conciliacion);

  @override
  List<Object?> get props => [conciliacion];
}

class ConciliacionError extends ConciliacionState {
  final String message;

  const ConciliacionError(this.message);

  @override
  List<Object?> get props => [message];
}
