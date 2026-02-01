import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/ajuste_masivo_precios_usecase.dart';
import 'ajuste_masivo_state.dart';

@injectable
class AjusteMasivoCubit extends Cubit<AjusteMasivoState> {
  final AjusteMasivoPreciosUseCase _ajusteMasivoPreciosUseCase;

  AjusteMasivoCubit(
    this._ajusteMasivoPreciosUseCase,
  ) : super(const AjusteMasivoInitial());

  /// Generar preview de cambios con productos ya cargados
  /// Calcula el nuevo precio para cada producto en el frontend
  void generarPreviewConProductos({
    required String alcance,
    required List<dynamic> productos,
    required String? sedeId,
    required double porcentaje,
    required String operacion,
  }) {
    final cambios = <Map<String, dynamic>>[];

    // Calcular cambios para cada producto
    for (final producto in productos) {
      double? precioActual;

      // Obtener precio actual según la sede
      if (sedeId != null) {
        precioActual = producto.precioEnSede(sedeId);
      } else {
        precioActual = producto.precio;
      }

      // Si no tiene precio configurado, omitir
      if (precioActual == null || precioActual == 0) continue;

      // Calcular nuevo precio
      final factor = operacion == 'INCREMENTO' ? (1 + porcentaje / 100) : (1 - porcentaje / 100);
      final precioNuevo = precioActual * factor;
      final diferencia = precioNuevo - precioActual;
      final diferenciaPercentual = ((diferencia / precioActual) * 100);

      cambios.add({
        'nombre': producto.nombre,
        'varianteNombre': null, // ProductoListItem no tiene info de variante específica
        'precioAnterior': precioActual,
        'precioNuevo': precioNuevo,
        'diferencia': diferencia,
        'diferenciaPercentual': diferenciaPercentual,
      });
    }

    final resumen = {
      'resumen': {
        'totalProductosAfectados': cambios.length,
        'totalVariantesAfectadas': 0,
        'ajustePromedio': porcentaje,
        'operacion': operacion,
      },
      'cambios': cambios,
      'advertencias': cambios.isEmpty
          ? ['⚠️ No hay productos con precios configurados en esta sede']
          : [
              'Los cambios se aplicarán al confirmar',
              'Total a actualizar: ${cambios.length} producto(s)',
            ],
    };

    emit(AjusteMasivoPreviewLoaded(resumen));
  }

  /// Aplicar cambios de forma definitiva
  Future<void> aplicarAjuste({
    required String sedeId,
    required String empresaId,
    required Map<String, dynamic> dto,
  }) async {
    emit(const AjusteMasivoLoading());

    final result = await _ajusteMasivoPreciosUseCase(
      sedeId: sedeId,
      empresaId: empresaId,
      dto: dto,
    );

    if (result is Success<Map<String, dynamic>>) {
      emit(AjusteMasivoSuccess(result.data));
    } else if (result is Error<Map<String, dynamic>>) {
      emit(AjusteMasivoError(result.message, errorCode: result.errorCode));
    }
  }

  /// Resetear el estado
  void reset() {
    emit(const AjusteMasivoInitial());
  }
}
