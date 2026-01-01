import 'package:equatable/equatable.dart';
import '../../../domain/entities/empresa_marca.dart';

abstract class MarcasEmpresaState extends Equatable {
  const MarcasEmpresaState();

  @override
  List<Object?> get props => [];
}

class MarcasEmpresaInitial extends MarcasEmpresaState {
  const MarcasEmpresaInitial();
}

class MarcasEmpresaLoading extends MarcasEmpresaState {
  const MarcasEmpresaLoading();
}

class MarcasEmpresaLoaded extends MarcasEmpresaState {
  final List<EmpresaMarca> marcas;

  const MarcasEmpresaLoaded(this.marcas);

  @override
  List<Object?> get props => [marcas];
}

class MarcasEmpresaError extends MarcasEmpresaState {
  final String message;

  const MarcasEmpresaError(this.message);

  @override
  List<Object?> get props => [message];
}
