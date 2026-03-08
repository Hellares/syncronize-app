import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/entities/configuracion_campo.dart';
import '../../../domain/usecases/get_configuracion_campos_usecase.dart';
import '../../../domain/usecases/create_configuracion_campo_usecase.dart';
import '../../../domain/usecases/update_configuracion_campo_usecase.dart';
import '../../../domain/usecases/delete_configuracion_campo_usecase.dart';
import '../../../domain/usecases/reorder_configuracion_campos_usecase.dart';
import 'configuracion_campos_state.dart';

@injectable
class ConfiguracionCamposCubit extends Cubit<ConfiguracionCamposState> {
  final GetConfiguracionCamposUseCase _getCampos;
  final CreateConfiguracionCampoUseCase _createCampo;
  final UpdateConfiguracionCampoUseCase _updateCampo;
  final DeleteConfiguracionCampoUseCase _deleteCampo;
  final ReorderConfiguracionCamposUseCase _reorderCampos;

  ConfiguracionCamposCubit(
    this._getCampos,
    this._createCampo,
    this._updateCampo,
    this._deleteCampo,
    this._reorderCampos,
  ) : super(const ConfiguracionCamposInitial());

  Future<void> load({String? categoria}) async {
    emit(const ConfiguracionCamposLoading());
    final result = await _getCampos(categoria: categoria, activo: true);
    if (isClosed) return;
    if (result is Success<List<ConfiguracionCampo>>) {
      emit(ConfiguracionCamposLoaded(result.data));
    } else if (result is Error) {
      emit(ConfiguracionCamposError((result as Error).message));
    }
  }

  Future<void> create({
    required String nombre,
    required String tipoCampo,
    String? categoria,
    String? descripcion,
    String? placeholder,
    bool? esRequerido,
    String? defaultValue,
    dynamic opciones,
    bool? permiteOtro,
  }) async {
    emit(const ConfiguracionCamposLoading());
    final result = await _createCampo(
      nombre: nombre,
      tipoCampo: tipoCampo,
      categoria: categoria,
      descripcion: descripcion,
      placeholder: placeholder,
      esRequerido: esRequerido,
      defaultValue: defaultValue,
      opciones: opciones,
      permiteOtro: permiteOtro,
    );
    if (isClosed) return;
    if (result is Success<ConfiguracionCampo>) {
      await load();
    } else if (result is Error) {
      emit(ConfiguracionCamposError((result as Error).message));
    }
  }

  Future<void> update({
    required String id,
    String? nombre,
    String? tipoCampo,
    String? categoria,
    String? descripcion,
    String? placeholder,
    bool? esRequerido,
    String? defaultValue,
    dynamic opciones,
    bool? permiteOtro,
  }) async {
    emit(const ConfiguracionCamposLoading());
    final result = await _updateCampo(
      id: id,
      nombre: nombre,
      tipoCampo: tipoCampo,
      categoria: categoria,
      descripcion: descripcion,
      placeholder: placeholder,
      esRequerido: esRequerido,
      defaultValue: defaultValue,
      opciones: opciones,
      permiteOtro: permiteOtro,
    );
    if (isClosed) return;
    if (result is Success<ConfiguracionCampo>) {
      await load();
    } else if (result is Error) {
      emit(ConfiguracionCamposError((result as Error).message));
    }
  }

  Future<void> delete(String id) async {
    emit(const ConfiguracionCamposLoading());
    final result = await _deleteCampo(id);
    if (isClosed) return;
    if (result is Success<void>) {
      await load();
    } else if (result is Error) {
      emit(ConfiguracionCamposError((result).message));
    }
  }

  Future<void> reorder(List<String> orderedIds) async {
    final result = await _reorderCampos(orderedIds);
    if (isClosed) return;
    if (result is Success<List<ConfiguracionCampo>>) {
      emit(ConfiguracionCamposLoaded(result.data));
    } else if (result is Error) {
      emit(ConfiguracionCamposError((result as Error).message));
    }
  }
}
