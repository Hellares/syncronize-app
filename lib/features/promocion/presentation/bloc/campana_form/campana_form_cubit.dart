import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/campana.dart';
import '../../../domain/repositories/promocion_repository.dart';
import 'campana_form_state.dart';

@injectable
class CampanaFormCubit extends Cubit<CampanaFormState> {
  final PromocionRepository _repository;

  CampanaFormCubit(this._repository) : super(const CampanaFormInitial());

  List<ProductoEnOferta> _productos = [];
  List<ProductoEnOferta> get productos => _productos;

  Future<void> loadProductosEnOferta() async {
    emit(const CampanaFormLoading());

    final result = await _repository.getProductosEnOferta();
    if (isClosed) return;

    if (result is Success<List<ProductoEnOferta>>) {
      _productos = result.data;
      emit(CampanaFormProductosLoaded(productos: result.data));
    } else if (result is Error<List<ProductoEnOferta>>) {
      emit(CampanaFormError(result.message));
    }
  }

  Future<void> enviarCampana({
    required String titulo,
    required String mensaje,
    List<String>? productosIds,
  }) async {
    emit(const CampanaFormSending());

    final result = await _repository.crearCampana(
      titulo: titulo,
      mensaje: mensaje,
      productosIds: productosIds,
    );
    if (isClosed) return;

    if (result is Success<Campana>) {
      emit(CampanaFormSuccess(campana: result.data));
    } else if (result is Error<Campana>) {
      emit(CampanaFormError(result.message));
    }
  }
}
