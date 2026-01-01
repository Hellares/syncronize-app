import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../data/datasources/producto_remote_datasource.dart';
import '../../../domain/entities/atributo_valor.dart';
import '../../../domain/entities/producto_atributo.dart';
import 'variante_atributo_state.dart';

@injectable
class VarianteAtributoCubit extends Cubit<VarianteAtributoState> {
  final ProductoRemoteDataSource _remoteDataSource;

  VarianteAtributoCubit(this._remoteDataSource)
      : super(const VarianteAtributoInitial());

  /// Inicializa con atributos vacíos (para modo creación)
  void initialize() {
    emit(const VarianteAtributoLoaded(atributoValores: []));
  }

  /// Inicializa con atributos desde una plantilla
  void initializeFromPlantilla(List<Map<String, dynamic>> atributosPlantilla) {
    final atributoValores = atributosPlantilla.map((item) {
      final atributoData = item['atributo'] as Map<String, dynamic>?;
      final atributoId = item['atributoId']?.toString() ?? '';

      return AtributoValor(
        id: 'temp_${DateTime.now().millisecondsSinceEpoch}_$atributoId',
        atributoId: atributoId,
        valor: item['valor']?.toString() ?? '',
        atributo: AtributoInfo(
          id: atributoData?['id']?.toString() ?? '',
          nombre: atributoData?['nombre']?.toString() ?? '',
          clave: atributoData?['clave']?.toString() ?? '',
          tipo: atributoData?['tipo']?.toString() ?? 'TEXTO',
          unidad: atributoData?['unidad']?.toString(),
        ),
      );
    }).toList();

    emit(VarianteAtributoLoaded(atributoValores: atributoValores));
  }

  /// Carga los atributos de una variante desde el backend
  Future<void> loadVarianteAtributos({
    required String varianteId,
    required String empresaId,
  }) async {
    try {
      emit(const VarianteAtributoLoading());

      final data = await _remoteDataSource.getVarianteAtributos(
        varianteId: varianteId,
        empresaId: empresaId,
      );

      // Parsear los datos a entidades AtributoValor
      final atributoValores = data.map((item) {
        final atributoData = item['atributo'] as Map<String, dynamic>?;

        return AtributoValor(
          id: item['id']?.toString() ?? '',
          atributoId: item['atributoId']?.toString() ?? '',
          valor: item['valor']?.toString() ?? '',
          atributo: AtributoInfo(
            id: atributoData?['id']?.toString() ?? '',
            nombre: atributoData?['nombre']?.toString() ?? '',
            clave: atributoData?['clave']?.toString() ?? '',
            tipo: atributoData?['tipo']?.toString() ?? 'TEXTO',
            unidad: atributoData?['unidad']?.toString(),
          ),
        );
      }).toList();

      emit(VarianteAtributoLoaded(atributoValores: atributoValores));
    } catch (e) {
      emit(VarianteAtributoError(_getErrorMessage(e)));
    }
  }

  /// Añade un nuevo atributo a la lista local (no lo guarda en el backend aún)
  void addAtributo({
    required ProductoAtributo atributo,
    required String valor,
  }) {
    final currentState = state;
    if (currentState is! VarianteAtributoLoaded) return;

    // Verificar que no exista ya este atributo
    final existe = currentState.atributoValores.any(
      (av) => av.atributoId == atributo.id,
    );

    if (existe) {
      emit(currentState.copyWith(
        errorMessage: 'Este atributo ya ha sido agregado',
      ));
      return;
    }

    // Crear un nuevo AtributoValor temporal (sin ID aún)
    final nuevoAtributoValor = AtributoValor(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      atributoId: atributo.id,
      valor: valor,
      atributo: AtributoInfo(
        id: atributo.id,
        nombre: atributo.nombre,
        clave: atributo.clave,
        tipo: atributo.tipo.name.toUpperCase(),
        unidad: atributo.unidad,
      ),
    );

    final updatedList = [...currentState.atributoValores, nuevoAtributoValor];
    emit(VarianteAtributoLoaded(atributoValores: updatedList));
  }

  /// Actualiza un atributo existente en la lista local
  void updateAtributo({
    required String atributoValorId,
    required String nuevoValor,
  }) {
    final currentState = state;
    if (currentState is! VarianteAtributoLoaded) return;

    final updatedList = currentState.atributoValores.map((av) {
      if (av.id == atributoValorId) {
        return AtributoValor(
          id: av.id,
          atributoId: av.atributoId,
          valor: nuevoValor,
          atributo: av.atributo,
        );
      }
      return av;
    }).toList();

    emit(VarianteAtributoLoaded(atributoValores: updatedList));
  }

  /// Elimina un atributo de la lista local
  void removeAtributo(String atributoValorId) {
    final currentState = state;
    if (currentState is! VarianteAtributoLoaded) return;

    final updatedList = currentState.atributoValores
        .where((av) => av.id != atributoValorId)
        .toList();

    emit(VarianteAtributoLoaded(atributoValores: updatedList));
  }

  /// Guarda todos los atributos en el backend
  Future<void> saveAtributos({
    required String varianteId,
    required String empresaId,
  }) async {
    final currentState = state;
    if (currentState is! VarianteAtributoLoaded) return;

    try {
      emit(currentState.copyWith(isLoading: true));

      // Preparar datos en el formato esperado por el backend
      final data = {
        'atributos': currentState.atributoValores.map((av) {
          return {
            'atributoId': av.atributoId,
            'valor': av.valor,
          };
        }).toList(),
      };

      await _remoteDataSource.setVarianteAtributos(
        varianteId: varianteId,
        empresaId: empresaId,
        data: data,
      );

      // Recargar desde el backend para obtener los IDs reales
      await loadVarianteAtributos(
        varianteId: varianteId,
        empresaId: empresaId,
      );

      final updatedState = state;
      if (updatedState is VarianteAtributoLoaded) {
        emit(VarianteAtributoSaved(
          message: 'Atributos guardados exitosamente',
          atributoValores: updatedState.atributoValores,
        ));
      }
    } catch (e) {
      emit(currentState.copyWith(
        isLoading: false,
        errorMessage: _getErrorMessage(e),
      ));
    }
  }

  /// Limpia el estado de error
  void clearError() {
    final currentState = state;
    if (currentState is VarianteAtributoLoaded) {
      emit(currentState.copyWith(errorMessage: null));
    }
  }

  /// Limpia todos los atributos
  void clear() {
    emit(const VarianteAtributoLoaded(atributoValores: []));
  }

  /// Obtiene los atributos en formato DTO para enviar al backend
  List<Map<String, dynamic>> getAtributosAsDto() {
    final currentState = state;
    if (currentState is! VarianteAtributoLoaded) return [];

    return currentState.atributoValores
        .where((av) => av.valor.isNotEmpty)
        .map((av) => {
              'atributoId': av.atributoId,
              'valor': av.valor,
            })
        .toList();
  }

  /// Obtener mensaje de error legible
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();
    if (errorStr.contains('Exception:')) {
      return errorStr.replaceFirst('Exception:', '').trim();
    }
    return 'Error inesperado: $errorStr';
  }
}
