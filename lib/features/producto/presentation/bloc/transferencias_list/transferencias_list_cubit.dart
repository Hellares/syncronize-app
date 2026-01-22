import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../data/models/transferencia_stock_model.dart';
import '../../../domain/entities/transferencia_stock.dart';
import '../../../domain/usecases/listar_transferencias_usecase.dart';
import 'transferencias_list_state.dart';

@injectable
class TransferenciasListCubit extends Cubit<TransferenciasListState> {
  final ListarTransferenciasUseCase _listarTransferenciasUseCase;

  TransferenciasListCubit(
    this._listarTransferenciasUseCase,
  ) : super(const TransferenciasListInitial());

  String? _currentEmpresaId;
  String? _currentSedeId;
  EstadoTransferencia? _currentEstado;
  List<TransferenciaStock> _allTransferencias = [];
  int _currentPage = 1;

  /// Convierte un valor dinámico a int de forma segura
  int _safeToInt(dynamic value, {int defaultValue = 0}) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final parsed = int.tryParse(value);
      return parsed ?? defaultValue;
    }
    return defaultValue;
  }

  /// Carga las transferencias
  Future<void> loadTransferencias({
    required String empresaId,
    String? sedeId,
    EstadoTransferencia? estado,
    int page = 1,
  }) async {
    _currentEmpresaId = empresaId;
    _currentSedeId = sedeId;
    _currentEstado = estado;
    _currentPage = page;

    if (page == 1) {
      _allTransferencias = [];
      emit(const TransferenciasListLoading());
    }

    final result = await _listarTransferenciasUseCase(
      empresaId: empresaId,
      sedeId: sedeId,
      estado: estado,
      page: page,
      limit: 50,
    );

    if (isClosed) return;

    if (result is Success<Map<String, dynamic>>) {
      final data = result.data;

      // Soportar tanto estructura con 'data' como sin ella
      final transferenciasList =
          (data['data'] ?? data['transferencias']) as List? ?? [];
      final meta = data['meta'] as Map<String, dynamic>?;

      final transferencias = transferenciasList
          .map((e) =>
              TransferenciaStockModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (page == 1) {
        _allTransferencias = transferencias;
      } else {
        _allTransferencias.addAll(transferencias);
      }

      // Usar meta si existe, sino usar datos directos
      final total = meta != null
          ? _safeToInt(meta['total'])
          : _safeToInt(data['total']);
      final currentPage = meta != null
          ? _safeToInt(meta['page'], defaultValue: page)
          : _safeToInt(data['page'], defaultValue: page);
      final totalPages = meta != null
          ? _safeToInt(meta['totalPages'], defaultValue: 1)
          : _safeToInt(data['totalPages'], defaultValue: 1);
      final hasMore = meta != null
          ? (meta['hasNext'] as bool? ?? false)
          : (data['hasNext'] as bool? ?? false);

      if (_allTransferencias.isEmpty) {
        emit(const TransferenciasListEmpty());
      } else {
        emit(TransferenciasListLoaded(
          transferencias: _allTransferencias,
          total: total,
          currentPage: currentPage,
          totalPages: totalPages,
          hasMore: hasMore,
          filtroEstado: estado,
          filtroSedeId: sedeId,
        ));
      }
    } else if (result is Error<Map<String, dynamic>>) {
      emit(TransferenciasListError(result.message,
          errorCode: result.errorCode));
    }
  }

  /// Carga más transferencias (paginación)
  Future<void> loadMore() async {
    final currentState = state;
    if (currentState is! TransferenciasListLoaded) return;
    if (!currentState.hasMore) return;
    if (_currentEmpresaId == null) return;

    emit(TransferenciasListLoadingMore(_allTransferencias));

    await loadTransferencias(
      empresaId: _currentEmpresaId!,
      sedeId: _currentSedeId,
      estado: _currentEstado,
      page: _currentPage + 1,
    );
  }

  /// Recarga la lista actual
  Future<void> reload() async {
    if (_currentEmpresaId == null) return;
    await loadTransferencias(
      empresaId: _currentEmpresaId!,
      sedeId: _currentSedeId,
      estado: _currentEstado,
      page: 1,
    );
  }

  /// Limpia el estado
  void clear() {
    _currentEmpresaId = null;
    _currentSedeId = null;
    _currentEstado = null;
    _allTransferencias = [];
    _currentPage = 1;
    emit(const TransferenciasListInitial());
  }
}
