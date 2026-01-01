import 'package:equatable/equatable.dart';
import '../../../domain/entities/cliente.dart';
import '../../../domain/entities/cliente_filtros.dart';

/// Estados para la lista de clientes
abstract class ClienteListState extends Equatable {
  const ClienteListState();

  @override
  List<Object?> get props => [];
}

/// Estado inicial
class ClienteListInitial extends ClienteListState {
  const ClienteListInitial();
}

/// Estado de carga
class ClienteListLoading extends ClienteListState {
  const ClienteListLoading();
}

/// Estado con datos cargados
class ClienteListLoaded extends ClienteListState {
  final List<Cliente> clientes;
  final int total;
  final int currentPage;
  final int totalPages;
  final bool hasMore;
  final ClienteFiltros filtros;

  const ClienteListLoaded({
    required this.clientes,
    required this.total,
    required this.currentPage,
    required this.totalPages,
    required this.hasMore,
    required this.filtros,
  });

  @override
  List<Object?> get props => [
        clientes,
        total,
        currentPage,
        totalPages,
        hasMore,
        filtros,
      ];
}

/// Estado de error
class ClienteListError extends ClienteListState {
  final String message;

  const ClienteListError(this.message);

  @override
  List<Object?> get props => [message];
}
