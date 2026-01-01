import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/politica_descuento.dart';
import '../../../domain/usecases/create_politica.dart';
import '../../../domain/usecases/update_politica.dart';
import '../../../domain/usecases/get_politica_by_id.dart';
import 'politica_form_state.dart';

@injectable
class PoliticaFormCubit extends Cubit<PoliticaFormState> {
  final CreatePolitica _createPolitica;
  final UpdatePolitica _updatePolitica;
  final GetPoliticaById _getPoliticaById;

  PoliticaFormCubit(
    this._createPolitica,
    this._updatePolitica,
    this._getPoliticaById,
  ) : super(const PoliticaFormInitial());

  /// Crea una nueva política de descuento
  Future<void> createPolitica({
    required String nombre,
    String? descripcion,
    required TipoDescuento tipoDescuento,
    required TipoCalculoDescuento tipoCalculo,
    required double valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
  }) async {
    emit(const PoliticaFormLoading());

    final result = await _createPolitica(
      nombre: nombre,
      descripcion: descripcion,
      tipoDescuento: tipoDescuento,
      tipoCalculo: tipoCalculo,
      valorDescuento: valorDescuento,
      descuentoMaximo: descuentoMaximo,
      montoMinCompra: montoMinCompra,
      cantidadMaxUsos: cantidadMaxUsos,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      aplicarATodos: aplicarATodos,
      prioridad: prioridad,
      maxFamiliaresPorTrabajador: maxFamiliaresPorTrabajador,
    );

    if (result is Success<PoliticaDescuento>) {
      emit(PoliticaFormCreateSuccess(result.data));
    } else if (result is Error<PoliticaDescuento>) {
      emit(PoliticaFormError(result.message, errorCode: result.errorCode));
    }
  }

  /// Actualiza una política de descuento existente
  Future<void> updatePolitica({
    required String id,
    String? nombre,
    String? descripcion,
    TipoDescuento? tipoDescuento,
    TipoCalculoDescuento? tipoCalculo,
    double? valorDescuento,
    double? descuentoMaximo,
    double? montoMinCompra,
    int? cantidadMaxUsos,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    bool? aplicarATodos,
    int? prioridad,
    int? maxFamiliaresPorTrabajador,
    bool? isActive,
  }) async {
    emit(const PoliticaFormLoading());

    final result = await _updatePolitica(
      id: id,
      nombre: nombre,
      descripcion: descripcion,
      tipoDescuento: tipoDescuento,
      tipoCalculo: tipoCalculo,
      valorDescuento: valorDescuento,
      descuentoMaximo: descuentoMaximo,
      montoMinCompra: montoMinCompra,
      cantidadMaxUsos: cantidadMaxUsos,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      aplicarATodos: aplicarATodos,
      prioridad: prioridad,
      maxFamiliaresPorTrabajador: maxFamiliaresPorTrabajador,
      isActive: isActive,
    );

    if (result is Success<PoliticaDescuento>) {
      emit(PoliticaFormUpdateSuccess(result.data));
    } else if (result is Error<PoliticaDescuento>) {
      emit(PoliticaFormError(result.message, errorCode: result.errorCode));
    }
  }

  /// Carga una política existente por ID para edición
  Future<void> loadPolitica(String id) async {
    emit(const PoliticaFormLoading());

    final result = await _getPoliticaById(id);

    if (result is Success<PoliticaDescuento>) {
      emit(PoliticaFormLoadSuccess(result.data));
    } else if (result is Error<PoliticaDescuento>) {
      emit(PoliticaFormError(result.message, errorCode: result.errorCode));
    }
  }

  /// Resetea el formulario al estado inicial
  void reset() {
    emit(const PoliticaFormInitial());
  }
}
