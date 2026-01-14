import 'package:equatable/equatable.dart';
import '../../../domain/entities/categoria_maestra.dart';

abstract class CategoriasMaestrasState extends Equatable {
  const CategoriasMaestrasState();

  @override
  List<Object?> get props => [];
}

class CategoriasMaestrasInitial extends CategoriasMaestrasState {
  const CategoriasMaestrasInitial();
}

class CategoriasMaestrasLoading extends CategoriasMaestrasState {
  const CategoriasMaestrasLoading();
}

class CategoriasMaestrasLoaded extends CategoriasMaestrasState {
  final List<CategoriaMaestra> categorias;

  const CategoriasMaestrasLoaded(this.categorias);

  @override
  List<Object?> get props => [categorias];
}

class CategoriasMaestrasError extends CategoriasMaestrasState {
  final String message;

  const CategoriasMaestrasError(this.message);

  @override
  List<Object?> get props => [message];
}
