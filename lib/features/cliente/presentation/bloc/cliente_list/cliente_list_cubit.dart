import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/cliente.dart';
import '../../../domain/entities/cliente_filtros.dart';
import '../../../domain/entities/registro_cliente_response.dart';
import '../../../domain/usecases/get_clientes_usecase.dart';
import 'cliente_list_state.dart';

@injectable
class ClienteListCubit extends Cubit<ClienteListState> {
  final GetClientesUseCase _getClientesUseCase;

  ClienteListCubit(this._getClientesUseCase)
      : super(const ClienteListInitial());

  String? _currentEmpresaId;
  ClienteFiltros _currentFiltros = const ClienteFiltros();
  List<Cliente> _allClientes = [];

  /// Carga la lista de clientes
  Future<void> loadClientes({
    required String empresaId,
    ClienteFiltros? filtros,
  }) async {
    // Validar que empresaId no esté vacío
    if (empresaId.isEmpty) {
      emit(const ClienteListError('ID de empresa no válido'));
      return;
    }

    _currentEmpresaId = empresaId;
    _currentFiltros = filtros ?? const ClienteFiltros();
    _allClientes = [];

    emit(const ClienteListLoading());

    final result = await _getClientesUseCase(
      empresaId: empresaId,
      filtros: _currentFiltros,
    );

    if (result is Success<ClientesPaginados>) {
      final data = result.data;
      _allClientes = data.data;

      emit(ClienteListLoaded(
        clientes: _allClientes,
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: _currentFiltros,
      ));
    } else if (result is Error<ClientesPaginados>) {
      emit(ClienteListError(result.message));
    }
  }

  /// Carga más clientes (paginación)
  Future<void> loadMore() async {
    if (_currentEmpresaId == null) return;

    final currentState = state;
    if (currentState is! ClienteListLoaded) return;
    if (!currentState.hasMore) return;

    final nextPage = currentState.currentPage + 1;
    final newFiltros = _currentFiltros.copyWith(page: nextPage);

    final result = await _getClientesUseCase(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );

    if (result is Success<ClientesPaginados>) {
      final data = result.data;
      _allClientes.addAll(data.data);
      _currentFiltros = newFiltros;

      emit(ClienteListLoaded(
        clientes: List.from(_allClientes),
        total: data.total,
        currentPage: data.page,
        totalPages: data.totalPages,
        hasMore: data.hasNext,
        filtros: _currentFiltros,
      ));
    }
  }

  /// Recarga la lista desde el inicio
  Future<void> reload() async {
    if (_currentEmpresaId == null) return;

    await loadClientes(
      empresaId: _currentEmpresaId!,
      filtros: _currentFiltros.copyWith(page: 1),
    );
  }

  /// Aplica filtros de búsqueda
  Future<void> search(String query) async {
    if (_currentEmpresaId == null) return;

    final newFiltros = _currentFiltros.copyWith(
      search: query.isEmpty ? null : query,
      page: 1,
    );

    await loadClientes(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );
  }

  /// Filtra por estado activo/inactivo
  Future<void> filterByActive(bool? isActive) async {
    if (_currentEmpresaId == null) return;

    final newFiltros = _currentFiltros.copyWith(
      isActive: isActive,
      page: 1,
    );

    await loadClientes(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );
  }

  /// Cambia el ordenamiento
  Future<void> changeOrder(OrdenCliente orden) async {
    if (_currentEmpresaId == null) return;

    final newFiltros = _currentFiltros.copyWith(
      orden: orden,
      page: 1,
    );

    await loadClientes(
      empresaId: _currentEmpresaId!,
      filtros: newFiltros,
    );
  }
}
