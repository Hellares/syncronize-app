import 'package:equatable/equatable.dart';
import '../../domain/entities/empresa_banco.dart';

abstract class EmpresaBancoState extends Equatable {
  const EmpresaBancoState();

  @override
  List<Object?> get props => [];
}

class EmpresaBancoInitial extends EmpresaBancoState {
  const EmpresaBancoInitial();
}

class EmpresaBancoLoading extends EmpresaBancoState {
  const EmpresaBancoLoading();
}

class EmpresaBancoLoaded extends EmpresaBancoState {
  final List<EmpresaBanco> cuentas;

  const EmpresaBancoLoaded(this.cuentas);

  @override
  List<Object?> get props => [cuentas];
}

class EmpresaBancoError extends EmpresaBancoState {
  final String message;

  const EmpresaBancoError(this.message);

  @override
  List<Object?> get props => [message];
}
