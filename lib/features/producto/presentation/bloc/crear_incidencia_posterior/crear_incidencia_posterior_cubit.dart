import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/services/storage_service.dart';
import '../../../../../core/utils/resource.dart';
import '../../../domain/usecases/crear_incidencia_posterior_usecase.dart';
import 'crear_incidencia_posterior_state.dart';

@injectable
class CrearIncidenciaPosteriorCubit extends Cubit<CrearIncidenciaPosteriorState> {
  final CrearIncidenciaPosteriorUseCase _useCase;
  final StorageService _storageService;

  CrearIncidenciaPosteriorCubit(
    this._useCase,
    this._storageService,
  ) : super(const CrearIncidenciaPosteriorInitial());

  /// Crea una incidencia posterior subiendo primero las evidencias
  Future<void> crearIncidencia({
    required String transferenciaId,
    required String empresaId,
    required String itemId,
    required String tipo,
    required int cantidadAfectada,
    required String descripcion,
    String? observaciones,
    List<File>? evidencias,
  }) async {
    emit(const CrearIncidenciaPosteriorProcessing(
      progress: 0.0,
      message: 'Preparando...',
    ));

    try {
      // 1. Subir evidencias si existen
      final evidenciasUrls = <String>[];

      if (evidencias != null && evidencias.isNotEmpty) {
        emit(const CrearIncidenciaPosteriorProcessing(
          progress: 0.1,
          message: 'Subiendo evidencias...',
        ));

        for (int i = 0; i < evidencias.length; i++) {
          try {
            final response = await _storageService.uploadFile(
              file: evidencias[i],
              empresaId: empresaId,
              entidadTipo: 'TRANSFERENCIA_INCIDENCIA',
              entidadId: transferenciaId,
              categoria: 'EVIDENCIA',
            );
            evidenciasUrls.add(response.url);

            // Actualizar progreso
            final progress = 0.1 + (0.5 * (i + 1) / evidencias.length);
            emit(CrearIncidenciaPosteriorProcessing(
              progress: progress,
              message: 'Subiendo evidencias (${i + 1}/${evidencias.length})...',
            ));
          } catch (e) {
            // Si falla una evidencia, continuar con las demás
            // pero no agregar esta URL
            continue;
          }
        }
      }

      // 2. Crear la incidencia
      emit(const CrearIncidenciaPosteriorProcessing(
        progress: 0.7,
        message: 'Creando incidencia...',
      ));

      final result = await _useCase(
        transferenciaId: transferenciaId,
        empresaId: empresaId,
        itemId: itemId,
        tipo: tipo,
        cantidadAfectada: cantidadAfectada,
        descripcion: descripcion,
        evidenciasUrls: evidenciasUrls.isEmpty ? null : evidenciasUrls,
        observaciones: observaciones,
      );

      if (isClosed) return;

      if (result is Success<Map<String, dynamic>>) {
        emit(CrearIncidenciaPosteriorSuccess(
          message: 'Incidencia reportada correctamente',
          evidenciasSubidas: evidenciasUrls.length,
        ));
      } else if (result is Error<Map<String, dynamic>>) {
        emit(CrearIncidenciaPosteriorError(result.message));
      }
    } catch (e) {
      if (isClosed) return;
      emit(CrearIncidenciaPosteriorError(
        'Error inesperado al crear incidencia: ${e.toString()}',
      ));
    }
  }
}
