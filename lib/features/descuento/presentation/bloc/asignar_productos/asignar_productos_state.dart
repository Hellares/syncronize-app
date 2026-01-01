import 'package:equatable/equatable.dart';

abstract class AsignarProductosState extends Equatable {
  const AsignarProductosState();

  @override
  List<Object?> get props => [];
}

class AsignarProductosInitial extends AsignarProductosState {
  const AsignarProductosInitial();
}

class AsignarProductosLoading extends AsignarProductosState {
  const AsignarProductosLoading();
}

class AsignarProductosSuccess extends AsignarProductosState {
  final String message;

  const AsignarProductosSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class AsignarProductosError extends AsignarProductosState {
  final String message;

  const AsignarProductosError(this.message);

  @override
  List<Object?> get props => [message];
}
