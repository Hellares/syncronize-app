import 'package:equatable/equatable.dart';
import '../../domain/entities/meta_financiera.dart';

abstract class MetaFinancieraState extends Equatable {
  const MetaFinancieraState();

  @override
  List<Object?> get props => [];
}

class MetaFinancieraInitial extends MetaFinancieraState {
  const MetaFinancieraInitial();
}

class MetaFinancieraLoading extends MetaFinancieraState {
  const MetaFinancieraLoading();
}

class MetaFinancieraLoaded extends MetaFinancieraState {
  final List<MetaFinanciera> metas;

  const MetaFinancieraLoaded({required this.metas});

  @override
  List<Object?> get props => [metas];
}

class MetaFinancieraError extends MetaFinancieraState {
  final String message;

  const MetaFinancieraError(this.message);

  @override
  List<Object?> get props => [message];
}
