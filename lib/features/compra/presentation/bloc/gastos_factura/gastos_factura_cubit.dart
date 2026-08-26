import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/compra_analytics.dart';
import '../../../domain/usecases/get_gastos_factura_usecase.dart';
import 'gastos_factura_state.dart';

@injectable
class GastosFacturaCubit extends Cubit<GastosFacturaState> {
  final GetGastosFacturaUseCase _getGastosFactura;

  GastosFacturaCubit(this._getGastosFactura)
      : super(const GastosFacturaInitial());

  String? _empresaId;
  String? _sedeId;
  String? _fechaInicio;
  String? _fechaFin;
  String? _proveedorId;
  String? _categoriaGastoId;
  String _periodo = 'mensual';

  String get periodo => _periodo;
  String? get proveedorId => _proveedorId;
  String? get categoriaGastoId => _categoriaGastoId;

  Future<void> cargar({
    required String empresaId,
    String? sedeId,
    String? fechaInicio,
    String? fechaFin,
    String? proveedorId,
    String? categoriaGastoId,
    String? periodo,
    // Los filtros que se limpian necesitan poder mandar null: sin esto,
    // "quitar el proveedor" no se distinguiría de "no lo toqué".
    bool limpiarProveedor = false,
    bool limpiarCategoria = false,
  }) async {
    if (empresaId.isEmpty) {
      emit(const GastosFacturaError('ID de empresa no válido'));
      return;
    }

    _empresaId = empresaId;
    _sedeId = sedeId ?? _sedeId;
    _fechaInicio = fechaInicio ?? _fechaInicio;
    _fechaFin = fechaFin ?? _fechaFin;
    _periodo = periodo ?? _periodo;
    if (limpiarProveedor) {
      _proveedorId = null;
    } else if (proveedorId != null) {
      _proveedorId = proveedorId;
    }
    if (limpiarCategoria) {
      _categoriaGastoId = null;
    } else if (categoriaGastoId != null) {
      _categoriaGastoId = categoriaGastoId;
    }

    emit(const GastosFacturaLoading());

    final result = await _getGastosFactura(
      empresaId: empresaId,
      sedeId: _sedeId,
      fechaInicio: _fechaInicio,
      fechaFin: _fechaFin,
      proveedorId: _proveedorId,
      categoriaGastoId: _categoriaGastoId,
      periodo: _periodo,
    );

    if (isClosed) return;

    if (result is Success<GastosFacturaReporte>) {
      emit(GastosFacturaLoaded(result.data));
    } else if (result is Error<GastosFacturaReporte>) {
      emit(GastosFacturaError(result.message));
    }
  }

  Future<void> recargar() async {
    final id = _empresaId;
    if (id != null) await cargar(empresaId: id);
  }
}
