import 'package:equatable/equatable.dart';
import '../../domain/entities/gasto_recurrente.dart';

abstract class GastoFormState extends Equatable {
  const GastoFormState();
  @override
  List<Object?> get props => [];
}

class GastoFormInitial extends GastoFormState {
  const GastoFormInitial();
}

class GastoFormLoading extends GastoFormState {
  const GastoFormLoading();
}

class GastoFormSaving extends GastoFormState {
  const GastoFormSaving();
}

class GastoFormEditing extends GastoFormState {
  final GastoRecurrente gasto;
  const GastoFormEditing(this.gasto);
  @override
  List<Object?> get props => [gasto];
}

class GastoFormSaved extends GastoFormState {
  final GastoRecurrente gasto;
  const GastoFormSaved(this.gasto);
  @override
  List<Object?> get props => [gasto];
}

class GastoFormError extends GastoFormState {
  final String message;
  const GastoFormError(this.message);
  @override
  List<Object?> get props => [message];
}
