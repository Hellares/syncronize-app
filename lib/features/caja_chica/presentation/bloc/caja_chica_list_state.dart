import 'package:equatable/equatable.dart';
import '../../domain/entities/caja_chica.dart';

abstract class CajaChicaListState extends Equatable {
  const CajaChicaListState();

  @override
  List<Object?> get props => [];
}

class CajaChicaListInitial extends CajaChicaListState {
  const CajaChicaListInitial();
}

class CajaChicaListLoading extends CajaChicaListState {
  const CajaChicaListLoading();
}

class CajaChicaListLoaded extends CajaChicaListState {
  final List<CajaChica> cajasChicas;

  const CajaChicaListLoaded(this.cajasChicas);

  @override
  List<Object?> get props => [cajasChicas];
}

class CajaChicaListError extends CajaChicaListState {
  final String message;

  const CajaChicaListError(this.message);

  @override
  List<Object?> get props => [message];
}
