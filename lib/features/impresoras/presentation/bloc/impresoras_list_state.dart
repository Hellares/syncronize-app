import 'package:equatable/equatable.dart';
import '../../domain/entities/impresora_config.dart';

abstract class ImpresorasListState extends Equatable {
  const ImpresorasListState();
  @override
  List<Object?> get props => [];
}

class ImpresorasListInitial extends ImpresorasListState {
  const ImpresorasListInitial();
}

class ImpresorasListLoading extends ImpresorasListState {
  const ImpresorasListLoading();
}

class ImpresorasListLoaded extends ImpresorasListState {
  final List<ImpresoraConfig> impresoras;
  const ImpresorasListLoaded(this.impresoras);
  @override
  List<Object?> get props => [impresoras];
}

class ImpresorasListError extends ImpresorasListState {
  final String message;
  const ImpresorasListError(this.message);
  @override
  List<Object?> get props => [message];
}
