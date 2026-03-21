import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/rendicion_caja_chica.dart';
import '../../domain/usecases/crear_rendicion_usecase.dart';
import '../../domain/usecases/get_rendicion_usecase.dart';
import '../../domain/usecases/aprobar_rendicion_usecase.dart';
import '../../domain/usecases/rechazar_rendicion_usecase.dart';
import 'rendicion_state.dart';

@injectable
class RendicionCubit extends Cubit<RendicionState> {
  final CrearRendicionUseCase _crearRendicionUseCase;
  final GetRendicionUseCase _getRendicionUseCase;
  final AprobarRendicionUseCase _aprobarRendicionUseCase;
  final RechazarRendicionUseCase _rechazarRendicionUseCase;

  RendicionCubit(
    this._crearRendicionUseCase,
    this._getRendicionUseCase,
    this._aprobarRendicionUseCase,
    this._rechazarRendicionUseCase,
  ) : super(const RendicionInitial());

  Future<void> loadRendicion(String rendicionId) async {
    emit(const RendicionLoading());

    final result = await _getRendicionUseCase(rendicionId: rendicionId);
    if (isClosed) return;

    if (result is Success<RendicionCajaChica>) {
      emit(RendicionDetailLoaded(result.data));
    } else if (result is Error<RendicionCajaChica>) {
      emit(RendicionError(result.message));
    }
  }

  Future<void> crearRendicion({
    required String cajaChicaId,
    required List<String> gastoIds,
    String? observaciones,
  }) async {
    emit(const RendicionLoading());

    final result = await _crearRendicionUseCase(
      cajaChicaId: cajaChicaId,
      gastoIds: gastoIds,
      observaciones: observaciones,
    );
    if (isClosed) return;

    if (result is Success<RendicionCajaChica>) {
      emit(RendicionCreated(result.data));
    } else if (result is Error<RendicionCajaChica>) {
      emit(RendicionError(result.message));
    }
  }

  Future<void> aprobarRendicion({
    required String rendicionId,
    String? observaciones,
  }) async {
    emit(const RendicionLoading());

    final result = await _aprobarRendicionUseCase(
      rendicionId: rendicionId,
      observaciones: observaciones,
    );
    if (isClosed) return;

    if (result is Success<void>) {
      emit(const RendicionApproved());
    } else if (result is Error<void>) {
      emit(RendicionError(result.message));
    }
  }

  Future<void> rechazarRendicion({
    required String rendicionId,
    required String observaciones,
  }) async {
    emit(const RendicionLoading());

    final result = await _rechazarRendicionUseCase(
      rendicionId: rendicionId,
      observaciones: observaciones,
    );
    if (isClosed) return;

    if (result is Success<void>) {
      emit(const RendicionRejected());
    } else if (result is Error<void>) {
      emit(RendicionError(result.message));
    }
  }
}
