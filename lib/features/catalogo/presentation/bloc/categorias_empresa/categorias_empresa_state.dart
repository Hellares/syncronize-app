import 'package:equatable/equatable.dart';
import '../../../domain/entities/empresa_categoria.dart';

abstract class CategoriasEmpresaState extends Equatable {
  const CategoriasEmpresaState();

  @override
  List<Object?> get props => [];
}

class CategoriasEmpresaInitial extends CategoriasEmpresaState {
  const CategoriasEmpresaInitial();
}

class CategoriasEmpresaLoading extends CategoriasEmpresaState {
  const CategoriasEmpresaLoading();
}

class CategoriasEmpresaLoaded extends CategoriasEmpresaState {
  final List<EmpresaCategoria> categorias;

  const CategoriasEmpresaLoaded(this.categorias);

  @override
  List<Object?> get props => [categorias];
}

class CategoriasEmpresaError extends CategoriasEmpresaState {
  final String message;

  const CategoriasEmpresaError(this.message);

  @override
  List<Object?> get props => [message];
}
