import 'package:equatable/equatable.dart';
import '../../domain/entities/categoria_gasto.dart';

abstract class CategoriaGastoState extends Equatable {
  const CategoriaGastoState();

  @override
  List<Object?> get props => [];
}

class CategoriaGastoInitial extends CategoriaGastoState {
  const CategoriaGastoInitial();
}

class CategoriaGastoLoading extends CategoriaGastoState {
  const CategoriaGastoLoading();
}

class CategoriaGastoLoaded extends CategoriaGastoState {
  final List<CategoriaGasto> categorias;

  const CategoriaGastoLoaded({required this.categorias});

  @override
  List<Object?> get props => [categorias];
}

class CategoriaGastoError extends CategoriaGastoState {
  final String message;

  const CategoriaGastoError(this.message);

  @override
  List<Object?> get props => [message];
}
