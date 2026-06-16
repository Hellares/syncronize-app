import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/asignar_clientes.dart';
import '../../../domain/usecases/obtener_clientes_asignados.dart';
import '../../../domain/usecases/remover_cliente.dart';
import 'asignar_clientes_state.dart';

@injectable
class AsignarClientesCubit extends Cubit<AsignarClientesState> {
  final AsignarClientes _asignarClientes;
  final ObtenerClientesAsignados _obtenerClientesAsignados;
  final RemoverCliente _removerCliente;

  AsignarClientesCubit(
    this._asignarClientes,
    this._obtenerClientesAsignados,
    this._removerCliente,
  ) : super(const AsignarClientesInitial());

  String? _politicaId;
  List<Map<String, dynamic>> _clientes = [];

  Future<void> loadData(String politicaId) async {
    _politicaId = politicaId;
    emit(const AsignarClientesLoading());
    final result = await _obtenerClientesAsignados(politicaId);
    if (result is Success<List<Map<String, dynamic>>>) {
      _clientes = result.data;
      emit(AsignarClientesLoaded(clientes: _clientes));
    } else if (result is Error<List<Map<String, dynamic>>>) {
      emit(AsignarClientesError(result.message, errorCode: result.errorCode));
    }
  }

  /// Asigna un cliente (B2C `clienteId` o B2B `clienteEmpresaId`).
  Future<void> agregarCliente({
    String? clienteId,
    String? clienteEmpresaId,
  }) async {
    if (_politicaId == null) return;
    emit(AsignarClientesLoaded(clientes: _clientes, working: true));

    final result = await _asignarClientes(
      politicaId: _politicaId!,
      clienteIds: clienteId != null ? [clienteId] : null,
      clienteEmpresaIds: clienteEmpresaId != null ? [clienteEmpresaId] : null,
    );

    if (result is Success<List<Map<String, dynamic>>>) {
      // Recargar para traer el item enriquecido (nombre/documento).
      await loadData(_politicaId!);
    } else if (result is Error<List<Map<String, dynamic>>>) {
      emit(AsignarClientesError(result.message, errorCode: result.errorCode));
      emit(AsignarClientesLoaded(clientes: _clientes));
    }
  }

  Future<void> removerClienteAsignado(String asignacionId) async {
    if (_politicaId == null) return;
    emit(AsignarClientesLoaded(clientes: _clientes, working: true));

    final result = await _removerCliente(
      politicaId: _politicaId!,
      asignacionId: asignacionId,
    );

    if (result is Success<void>) {
      _clientes =
          _clientes.where((c) => c['id'] != asignacionId).toList();
      emit(AsignarClientesLoaded(clientes: _clientes));
    } else if (result is Error<void>) {
      emit(AsignarClientesError(result.message, errorCode: result.errorCode));
      emit(AsignarClientesLoaded(clientes: _clientes));
    }
  }
}
