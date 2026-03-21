import 'package:equatable/equatable.dart';
import '../../domain/entities/libro_contable.dart';

abstract class LibroContableState extends Equatable {
  const LibroContableState();

  @override
  List<Object?> get props => [];
}

class LibroContableInitial extends LibroContableState {
  const LibroContableInitial();
}

class LibroContableLoading extends LibroContableState {
  const LibroContableLoading();
}

class LibroContableLoaded extends LibroContableState {
  final LibroContable libro;

  const LibroContableLoaded({required this.libro});

  @override
  List<Object?> get props => [libro];
}

class LibroContableError extends LibroContableState {
  final String message;

  const LibroContableError(this.message);

  @override
  List<Object?> get props => [message];
}
