import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/agente_bancario.dart';
import '../../domain/usecases/get_resumen_agentes_usecase.dart';
import '../../domain/usecases/get_agentes_usecase.dart';
import '../../domain/usecases/registrar_operacion_usecase.dart';
import '../../domain/usecases/crear_agente_usecase.dart';
import '../../domain/repositories/agente_bancario_repository.dart';
import 'agente_bancario_state.dart';

@injectable
class AgenteBancarioCubit extends Cubit<AgenteBancarioState> {
  final GetResumenAgentesUseCase _getResumenUseCase;
  final GetAgentesUseCase _getAgentesUseCase;
  final RegistrarOperacionUseCase _registrarOperacionUseCase;
  final CrearAgenteUseCase _crearAgenteUseCase;
  final AgenteBancarioRepository _repository;

  String? _lastSedeId;
  String? _lastDetalleId;

  AgenteBancarioCubit(
    this._getResumenUseCase,
    this._getAgentesUseCase,
    this._registrarOperacionUseCase,
    this._crearAgenteUseCase,
    this._repository,
  ) : super(const AgenteBancarioInitial());

  Future<void> loadResumen({String? sedeId}) async {
    _lastSedeId = sedeId;
    emit(const AgenteBancarioLoading());

    final results = await Future.wait([
      _getResumenUseCase(sedeId: sedeId),
      _getAgentesUseCase(sedeId: sedeId),
    ]);
    if (isClosed) return;

    final resumenResult = results[0] as Resource<ResumenAgentes>;
    final agentesResult = results[1] as Resource<List<AgenteBancario>>;

    if (resumenResult is Success<ResumenAgentes> &&
        agentesResult is Success<List<AgenteBancario>>) {
      emit(AgenteBancarioLoaded(
        resumen: resumenResult.data,
        agentes: agentesResult.data,
      ));
    } else if (resumenResult is Error<ResumenAgentes>) {
      emit(AgenteBancarioError(resumenResult.message));
    } else if (agentesResult is Error<List<AgenteBancario>>) {
      emit(AgenteBancarioError(agentesResult.message));
    }
  }

  Future<void> loadDetalle(String id) async {
    _lastDetalleId = id;
    emit(const AgenteBancarioLoading());

    final results = await Future.wait([
      _repository.getDetalle(id),
      _repository.getOperaciones(id, limit: 50),
    ]);
    if (isClosed) return;

    final detalleResult = results[0] as Resource<AgenteBancario>;
    final operacionesResult = results[1] as Resource<List<OperacionAgente>>;

    if (detalleResult is Success<AgenteBancario> &&
        operacionesResult is Success<List<OperacionAgente>>) {
      emit(AgenteBancarioDetalleLoaded(
        agente: detalleResult.data,
        operaciones: operacionesResult.data,
      ));
    } else if (detalleResult is Error<AgenteBancario>) {
      emit(AgenteBancarioError(detalleResult.message));
    } else if (operacionesResult is Error<List<OperacionAgente>>) {
      emit(AgenteBancarioError(operacionesResult.message));
    }
  }

  Future<bool> crearAgente(String sedeId, Map<String, dynamic> data) async {
    final result = await _crearAgenteUseCase(sedeId, data);
    if (result is Success) {
      await loadResumen(sedeId: _lastSedeId);
      return true;
    }
    return false;
  }

  Future<bool> registrarOperacion(
      String agenteId, Map<String, dynamic> data) async {
    final result = await _registrarOperacionUseCase(agenteId, data);
    if (result is Success) {
      await loadDetalle(agenteId);
      return true;
    }
    return false;
  }

  Future<bool> anularOperacion(
      String agenteId, String operacionId, String motivo) async {
    final result =
        await _repository.anularOperacion(agenteId, operacionId, motivo);
    if (result is Success) {
      await loadDetalle(agenteId);
      return true;
    }
    return false;
  }

  Future<void> refresh() async {
    if (_lastDetalleId != null) {
      await loadDetalle(_lastDetalleId!);
    } else {
      await loadResumen(sedeId: _lastSedeId);
    }
  }
}
