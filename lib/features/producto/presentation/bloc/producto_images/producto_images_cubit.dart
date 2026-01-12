import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../../core/services/storage_service.dart';
import 'producto_images_state.dart';

@injectable
class ProductoImagesCubit extends Cubit<ProductoImagesState> {
  final StorageService _storageService;

  ProductoImagesCubit(this._storageService)
      : super(const ProductoImagesInitial());

  /// Inicializa con imágenes existentes (modo edición)
  void loadExistingImages(List<ProductoImage> images) {
    emit(ProductoImagesLoaded(images: images));
  }

  /// Agrega una nueva imagen LOCAL (NO sube al servidor inmediatamente)
  void addLocalImage(File file) {
    final currentState = state;
    if (currentState is! ProductoImagesLoaded) return;

    // Crear imagen local
    final localImage = ProductoImage(
      id: 'local_${DateTime.now().millisecondsSinceEpoch}',
      file: file,
      isLocal: true, // Marcar como local (no subida)
      isUploading: false,
      uploadProgress: 0.0,
      order: currentState.images.length,
    );

    // Agregar a la lista
    final updatedImages = [...currentState.images, localImage];
    emit(ProductoImagesLoaded(images: updatedImages));
  }

  /// Sube TODAS las imágenes locales al servidor
  /// Retorna lista de IDs de archivos subidos exitosamente
  Future<List<String>> uploadAllPendingImages(String empresaId) async {
    final currentState = state;
    if (currentState is! ProductoImagesLoaded) return [];

    final localImages = currentState.images.where((img) => img.isLocal).toList();
    if (localImages.isEmpty) return [];

    final uploadedIds = <String>[];
    final updatedImages = [...currentState.images];

    for (int i = 0; i < updatedImages.length; i++) {
      final image = updatedImages[i];

      // Solo procesar imágenes locales
      if (!image.isLocal || image.file == null) continue;

      // Marcar como subiendo
      updatedImages[i] = image.copyWith(
        isUploading: true,
        uploadProgress: 0.0,
      );
      if (isClosed) return uploadedIds;
      emit(ProductoImagesLoaded(images: [...updatedImages]));

      try {
        // Subir archivo
        final response = await _storageService.uploadFile(
          file: image.file!,
          empresaId: empresaId,
          entidadTipo: 'PRODUCTO',
          onProgress: (progress) {
            if (isClosed) return;
            updatedImages[i] = updatedImages[i].copyWith(
              uploadProgress: progress,
            );
            emit(ProductoImagesLoaded(images: [...updatedImages]));
          },
        );

        if (isClosed) return uploadedIds;

        // Reemplazar imagen local con la subida
        updatedImages[i] = ProductoImage(
          id: response.id,
          url: response.url,
          urlThumbnail: response.urlThumbnail,
          file: image.file,
          isLocal: false, // Ya no es local
          isUploading: false,
          uploadProgress: 1.0,
          order: image.order,
        );
        emit(ProductoImagesLoaded(images: [...updatedImages]));

        // Agregar ID a la lista de subidos
        uploadedIds.add(response.id);
      } catch (e) {
        if (isClosed) return uploadedIds;
        // Marcar como error pero mantener en la lista
        updatedImages[i] = updatedImages[i].copyWith(
          isUploading: false,
          hasError: true,
          errorMessage: e.toString(),
        );
        emit(ProductoImagesLoaded(images: [...updatedImages]));
      }
    }

    return uploadedIds;
  }

  /// Elimina una imagen
  Future<void> removeImage({
    required String imageId,
    required String empresaId,
  }) async {
    final currentState = state;
    if (currentState is! ProductoImagesLoaded) return;

    final imageToRemove = currentState.images.firstWhere(
      (img) => img.id == imageId,
      orElse: () => throw Exception('Imagen no encontrada'),
    );

    // Eliminar de la lista inmediatamente (optimistic update)
    final updatedImages = currentState.images
        .where((img) => img.id != imageId)
        .toList();
    emit(ProductoImagesLoaded(images: updatedImages));

    // Si la imagen ya fue subida (no es local), eliminarla del servidor
    if (!imageToRemove.isLocal && !imageToRemove.hasError) {
      try {
        await _storageService.deleteFile(
          archivoId: imageId,
          empresaId: empresaId,
        );
      } catch (e) {
        // Si falla, restaurar la imagen
        if (!isClosed) {
          emit(ProductoImagesLoaded(
            images: [...currentState.images],
          ));
        }
        rethrow;
      }
    }
    // Si es local, simplemente se elimina de la lista (ya hecho arriba)
  }

  /// Reordena imágenes (drag & drop)
  void reorderImages(int oldIndex, int newIndex) {
    final currentState = state;
    if (currentState is! ProductoImagesLoaded) return;

    final images = [...currentState.images];

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final item = images.removeAt(oldIndex);
    images.insert(newIndex, item);

    // Actualizar orden
    for (int i = 0; i < images.length; i++) {
      images[i] = images[i].copyWith(order: i);
    }

    emit(ProductoImagesLoaded(images: images));
  }

  /// Marca una imagen como principal
  void setMainImage(String imageId) {
    final currentState = state;
    if (currentState is! ProductoImagesLoaded) return;

    final images = currentState.images.map((img) {
      if (img.id == imageId) {
        return img.copyWith(isMain: true);
      } else {
        return img.copyWith(isMain: false);
      }
    }).toList();

    emit(ProductoImagesLoaded(images: images));
  }

  /// Reintentar subida de todas las imágenes con error
  Future<List<String>> retryFailedUploads(String empresaId) async {
    final currentState = state;
    if (currentState is! ProductoImagesLoaded) return [];

    final uploadedIds = <String>[];
    final updatedImages = [...currentState.images];

    for (int i = 0; i < updatedImages.length; i++) {
      final image = updatedImages[i];

      // Solo procesar imágenes con error que tengan archivo
      if (!image.hasError || image.file == null) continue;

      // Marcar como subiendo
      updatedImages[i] = image.copyWith(
        isUploading: true,
        hasError: false,
        errorMessage: null,
        uploadProgress: 0.0,
      );
      if (isClosed) return uploadedIds;
      emit(ProductoImagesLoaded(images: [...updatedImages]));

      try {
        final response = await _storageService.uploadFile(
          file: image.file!,
          empresaId: empresaId,
          entidadTipo: 'PRODUCTO',
          onProgress: (progress) {
            if (isClosed) return;
            updatedImages[i] = updatedImages[i].copyWith(
              uploadProgress: progress,
            );
            emit(ProductoImagesLoaded(images: [...updatedImages]));
          },
        );

        if (isClosed) return uploadedIds;

        updatedImages[i] = ProductoImage(
          id: response.id,
          url: response.url,
          urlThumbnail: response.urlThumbnail,
          file: image.file,
          isLocal: false,
          isUploading: false,
          uploadProgress: 1.0,
          order: image.order,
        );
        emit(ProductoImagesLoaded(images: [...updatedImages]));

        uploadedIds.add(response.id);
      } catch (e) {
        if (isClosed) return uploadedIds;
        updatedImages[i] = updatedImages[i].copyWith(
          isUploading: false,
          hasError: true,
          errorMessage: e.toString(),
        );
        emit(ProductoImagesLoaded(images: [...updatedImages]));
      }
    }

    return uploadedIds;
  }

  /// Limpia todas las imágenes
  void clear() {
    emit(const ProductoImagesLoaded(images: []));
  }

  /// Obtiene IDs de imágenes subidas exitosamente (no locales, sin errores)
  List<String> getUploadedImageIds() {
    final currentState = state;
    if (currentState is! ProductoImagesLoaded) return [];

    return currentState.images
        .where((img) => !img.isLocal && !img.hasError)
        .map((img) => img.id)
        .toList();
  }
}
