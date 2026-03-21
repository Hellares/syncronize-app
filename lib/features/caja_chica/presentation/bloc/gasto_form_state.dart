import 'package:equatable/equatable.dart';
import '../../domain/entities/gasto_caja_chica.dart';

abstract class GastoFormState extends Equatable {
  const GastoFormState();

  @override
  List<Object?> get props => [];
}

class GastoFormInitial extends GastoFormState {
  const GastoFormInitial();
}

class GastoFormSubmitting extends GastoFormState {
  const GastoFormSubmitting();
}

class GastoFormSuccess extends GastoFormState {
  final GastoCajaChica gasto;

  const GastoFormSuccess(this.gasto);

  @override
  List<Object?> get props => [gasto];
}

class GastoFormError extends GastoFormState {
  final String message;

  const GastoFormError(this.message);

  @override
  List<Object?> get props => [message];
}
