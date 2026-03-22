import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../data/datasources/solicitud_cotizacion_remote_datasource.dart';
import '../../data/models/solicitud_cotizacion_model.dart';
import '../../domain/entities/solicitud_cotizacion.dart';
import '../../domain/usecases/crear_solicitud_usecase.dart';
import 'solicitud_form_state.dart';

@injectable
class SolicitudFormCubit extends Cubit<SolicitudFormState> {
  final CrearSolicitudUseCase _crearSolicitudUseCase;
  final SolicitudCotizacionRemoteDataSource _remoteDataSource;

  SolicitudFormCubit(this._crearSolicitudUseCase, this._remoteDataSource)
      : super(const SolicitudFormEditing());

  /// Lista actual de items
  List<SolicitudItem> get _currentItems {
    final current = state;
    if (current is SolicitudFormEditing) return current.items;
    if (current is SolicitudFormError) return current.items;
    return [];
  }

  /// Observaciones actuales
  String? get _currentObservaciones {
    final current = state;
    if (current is SolicitudFormEditing) return current.observaciones;
    if (current is SolicitudFormError) return current.observaciones;
    return null;
  }

  /// Agrega un item del catalogo
  void agregarItemCatalogo({
    required String productoId,
    String? varianteId,
    required String descripcion,
    required int cantidad,
    String? imagenUrl,
  }) {
    final items = List<SolicitudItem>.from(_currentItems);
    items.add(SolicitudItem(
      productoId: productoId,
      varianteId: varianteId,
      descripcion: descripcion,
      cantidad: cantidad,
      imagenUrl: imagenUrl,
      esManual: false,
    ));
    emit(SolicitudFormEditing(
      items: items,
      observaciones: _currentObservaciones,
    ));
  }

  /// Agrega un item manual
  void agregarItemManual({
    required String descripcion,
    required int cantidad,
    String? notasItem,
  }) {
    final items = List<SolicitudItem>.from(_currentItems);
    items.add(SolicitudItem(
      descripcion: descripcion,
      cantidad: cantidad,
      notasItem: notasItem,
      esManual: true,
    ));
    emit(SolicitudFormEditing(
      items: items,
      observaciones: _currentObservaciones,
    ));
  }

  /// Elimina un item por indice
  void eliminarItem(int index) {
    final items = List<SolicitudItem>.from(_currentItems);
    if (index >= 0 && index < items.length) {
      items.removeAt(index);
      emit(SolicitudFormEditing(
        items: items,
        observaciones: _currentObservaciones,
      ));
    }
  }

  /// Actualiza las observaciones
  void actualizarObservaciones(String observaciones) {
    emit(SolicitudFormEditing(
      items: _currentItems,
      observaciones: observaciones.isEmpty ? null : observaciones,
    ));
  }

  /// Carga items de la solicitud anterior para pre-popular el formulario
  Future<void> cargarItemsPrevios(String empresaId) async {
    try {
      final itemsData = await _remoteDataSource.getItemsPrevios(empresaId);

      if (itemsData.isEmpty) {
        emit(SolicitudFormError(
          message: 'No se encontraron items de solicitudes anteriores',
          items: _currentItems,
          observaciones: _currentObservaciones,
        ));
        return;
      }

      final items = List<SolicitudItem>.from(_currentItems);
      for (final json in itemsData) {
        final model = SolicitudItemModel.fromJson(json);
        items.add(model.toEntity());
      }

      emit(SolicitudFormEditing(
        items: items,
        observaciones: _currentObservaciones,
      ));
    } catch (e) {
      emit(SolicitudFormError(
        message: 'Error al cargar items previos: ${e.toString()}',
        items: _currentItems,
        observaciones: _currentObservaciones,
      ));
    }
  }

  /// Envia la solicitud al servidor
  Future<void> submit({required String empresaId}) async {
    final items = _currentItems;
    final observaciones = _currentObservaciones;

    if (items.isEmpty) {
      emit(SolicitudFormError(
        message: 'Debes agregar al menos un item',
        items: items,
        observaciones: observaciones,
      ));
      return;
    }

    emit(const SolicitudFormSubmitting());

    final itemsData = items
        .map((item) => <String, dynamic>{
              if (item.productoId != null) 'productoId': item.productoId,
              if (item.varianteId != null) 'varianteId': item.varianteId,
              'descripcion': item.descripcion,
              'cantidad': item.cantidad,
              if (item.imagenUrl != null) 'imagenUrl': item.imagenUrl,
              'esManual': item.esManual,
              if (item.notasItem != null) 'notasItem': item.notasItem,
            })
        .toList();

    final result = await _crearSolicitudUseCase(
      empresaId: empresaId,
      observaciones: observaciones,
      items: itemsData,
    );
    if (isClosed) return;

    if (result is Success<SolicitudCotizacion>) {
      emit(SolicitudFormSuccess(
        solicitud: result.data,
        message: 'Solicitud de cotizacion enviada exitosamente',
      ));
    } else if (result is Error<SolicitudCotizacion>) {
      emit(SolicitudFormError(
        message: result.message,
        items: items,
        observaciones: observaciones,
      ));
    }
  }
}
