import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/dashboard_gastos.dart';
import '../../domain/entities/pago_gasto_recurrente.dart';
import '../../domain/repositories/gastos_recurrentes_repository.dart';
import 'pagar_state.dart';

@injectable
class PagarGastoCubit extends Cubit<PagarGastoState> {
  final GastosRecurrentesRepository _repo;
  ComprobanteUploadResult? _comprobante;

  PagarGastoCubit(this._repo) : super(const PagarGastoInitial());

  ComprobanteUploadResult? get comprobante => _comprobante;

  Future<void> subirComprobante(String filePath) async {
    emit(const PagarGastoUploading());
    final r = await _repo.uploadComprobante(filePath: filePath);
    if (isClosed) return;
    if (r is Success<ComprobanteUploadResult>) {
      _comprobante = r.data;
      emit(PagarGastoComprobanteSubido(r.data));
    } else if (r is Error<ComprobanteUploadResult>) {
      emit(PagarGastoError(r.message));
    }
  }

  void quitarComprobante() {
    _comprobante = null;
    emit(const PagarGastoInitial());
  }

  Future<void> pagar({
    required String gastoId,
    required String periodo,
    required double montoReal,
    required FuentePagoGasto fuente,
    required MetodoPagoGasto metodoPago,
    String? cajaId,
    String? bancoId,
    String? notas,
  }) async {
    emit(const PagarGastoEnviando());
    final r = await _repo.pagar(
      gastoId: gastoId,
      periodo: periodo,
      montoReal: montoReal,
      fuente: fuente,
      metodoPago: metodoPago,
      cajaId: cajaId,
      bancoId: bancoId,
      comprobanteUrl: _comprobante?.url,
      notas: notas,
    );
    if (isClosed) return;
    if (r is Success<PagoGastoRecurrente>) {
      emit(PagarGastoOk(r.data));
    } else if (r is Error<PagoGastoRecurrente>) {
      emit(PagarGastoError(r.message));
    }
  }
}
