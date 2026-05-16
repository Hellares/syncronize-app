import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/arqueo_caja.dart';
import '../../domain/usecases/crear_arqueo_usecase.dart';
import '../../domain/usecases/get_arqueos_usecase.dart';
import 'arqueos_caja_state.dart';

@injectable
class ArqueosCajaCubit extends Cubit<ArqueosCajaState> {
  final CrearArqueoUseCase _crearArqueoUseCase;
  final GetArqueosUseCase _getArqueosUseCase;

  ArqueosCajaCubit(this._crearArqueoUseCase, this._getArqueosUseCase)
      : super(const ArqueosCajaInitial());

  Future<void> loadArqueos(String cajaId) async {
    emit(const ArqueosCajaLoading());
    final result = await _getArqueosUseCase(cajaId: cajaId);
    if (isClosed) return;
    if (result is Success<List<ArqueoCaja>>) {
      emit(ArqueosCajaLoaded(result.data));
    } else if (result is Error<List<ArqueoCaja>>) {
      emit(ArqueosCajaError(result.message));
    }
  }

  /// Crea el arqueo. Si exitoso, refresca la lista y deja el
  /// `recienCreado` para que la UI dispare la auto-impresion.
  Future<ArqueoCaja?> crearArqueo({
    required String cajaId,
    required TipoArqueoCaja tipo,
    required List<Map<String, dynamic>> conteos,
    String? observaciones,
    String? autorizadoPorId,
    String? turnoEntregadoAId,
  }) async {
    emit(const ArqueosCajaCreating());
    final result = await _crearArqueoUseCase(
      cajaId: cajaId,
      tipo: tipo,
      conteos: conteos,
      observaciones: observaciones,
      autorizadoPorId: autorizadoPorId,
      turnoEntregadoAId: turnoEntregadoAId,
    );
    if (isClosed) return null;
    if (result is Success<ArqueoCaja>) {
      // Recargamos lista para incluir el nuevo y emitimos con recienCreado.
      final lista = await _getArqueosUseCase(cajaId: cajaId);
      if (isClosed) return null;
      if (lista is Success<List<ArqueoCaja>>) {
        emit(ArqueosCajaLoaded(lista.data, recienCreado: result.data));
      } else {
        emit(ArqueosCajaLoaded([result.data], recienCreado: result.data));
      }
      return result.data;
    }
    if (result is Error<ArqueoCaja>) {
      emit(ArqueosCajaError(result.message));
    }
    return null;
  }
}
