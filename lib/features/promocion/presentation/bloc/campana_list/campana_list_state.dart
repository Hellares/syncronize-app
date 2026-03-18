import 'package:equatable/equatable.dart';
import '../../../domain/entities/campana.dart';

abstract class CampanaListState extends Equatable {
  const CampanaListState();

  @override
  List<Object?> get props => [];
}

class CampanaListInitial extends CampanaListState {
  const CampanaListInitial();
}

class CampanaListLoading extends CampanaListState {
  const CampanaListLoading();
}

class CampanaListLoaded extends CampanaListState {
  final CampanasPaginadas resultado;

  const CampanaListLoaded({required this.resultado});

  @override
  List<Object?> get props => [resultado];
}

class CampanaListError extends CampanaListState {
  final String message;

  const CampanaListError(this.message);

  @override
  List<Object?> get props => [message];
}
