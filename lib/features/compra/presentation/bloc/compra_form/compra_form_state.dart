import 'package:equatable/equatable.dart';
import '../../../domain/entities/compra.dart';

abstract class CompraFormState extends Equatable {
  const CompraFormState();

  @override
  List<Object?> get props => [];
}

class CompraFormInitial extends CompraFormState {
  const CompraFormInitial();
}

class CompraFormLoading extends CompraFormState {
  const CompraFormLoading();
}

class CompraFormSuccess extends CompraFormState {
  final Compra compra;
  final bool isFromOc;

  const CompraFormSuccess(this.compra, {this.isFromOc = false});

  @override
  List<Object?> get props => [compra, isFromOc];
}

class CompraFormError extends CompraFormState {
  final String message;

  const CompraFormError(this.message);

  @override
  List<Object?> get props => [message];
}
