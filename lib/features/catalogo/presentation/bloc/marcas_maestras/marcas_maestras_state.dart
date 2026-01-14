import 'package:equatable/equatable.dart';
import '../../../domain/entities/marca_maestra.dart';

/// Estados para el cubit de marcas maestras
abstract class MarcasMaestrasState extends Equatable {
  const MarcasMaestrasState();

  @override
  List<Object?> get props => [];
}

class MarcasMaestrasInitial extends MarcasMaestrasState {
  const MarcasMaestrasInitial();
}

class MarcasMaestrasLoading extends MarcasMaestrasState {
  const MarcasMaestrasLoading();
}

class MarcasMaestrasLoaded extends MarcasMaestrasState {
  final List<MarcaMaestra> marcas;

  const MarcasMaestrasLoaded(this.marcas);

  @override
  List<Object?> get props => [marcas];
}

class MarcasMaestrasError extends MarcasMaestrasState {
  final String message;

  const MarcasMaestrasError(this.message);

  @override
  List<Object?> get props => [message];
}
