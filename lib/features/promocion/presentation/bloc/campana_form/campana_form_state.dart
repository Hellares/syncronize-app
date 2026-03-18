import 'package:equatable/equatable.dart';
import '../../../domain/entities/campana.dart';

abstract class CampanaFormState extends Equatable {
  const CampanaFormState();

  @override
  List<Object?> get props => [];
}

class CampanaFormInitial extends CampanaFormState {
  const CampanaFormInitial();
}

class CampanaFormLoading extends CampanaFormState {
  const CampanaFormLoading();
}

class CampanaFormProductosLoaded extends CampanaFormState {
  final List<ProductoEnOferta> productos;

  const CampanaFormProductosLoaded({required this.productos});

  @override
  List<Object?> get props => [productos];
}

class CampanaFormSending extends CampanaFormState {
  const CampanaFormSending();
}

class CampanaFormSuccess extends CampanaFormState {
  final Campana campana;

  const CampanaFormSuccess({required this.campana});

  @override
  List<Object?> get props => [campana];
}

class CampanaFormError extends CampanaFormState {
  final String message;

  const CampanaFormError(this.message);

  @override
  List<Object?> get props => [message];
}
