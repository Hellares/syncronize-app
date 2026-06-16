import 'package:equatable/equatable.dart';

abstract class AsignarClientesState extends Equatable {
  const AsignarClientesState();

  @override
  List<Object?> get props => [];
}

class AsignarClientesInitial extends AsignarClientesState {
  const AsignarClientesInitial();
}

class AsignarClientesLoading extends AsignarClientesState {
  const AsignarClientesLoading();
}

class AsignarClientesLoaded extends AsignarClientesState {
  /// Clientes asignados (cada item: id, clienteId/clienteEmpresaId, tipo,
  /// nombre, documento). `working` indica una operación en curso (alta/baja).
  final List<Map<String, dynamic>> clientes;
  final bool working;

  const AsignarClientesLoaded({
    required this.clientes,
    this.working = false,
  });

  AsignarClientesLoaded copyWith({
    List<Map<String, dynamic>>? clientes,
    bool? working,
  }) {
    return AsignarClientesLoaded(
      clientes: clientes ?? this.clientes,
      working: working ?? this.working,
    );
  }

  @override
  List<Object?> get props => [clientes, working];
}

class AsignarClientesError extends AsignarClientesState {
  final String message;
  final String? errorCode;

  const AsignarClientesError(this.message, {this.errorCode});

  @override
  List<Object?> get props => [message, errorCode];
}
