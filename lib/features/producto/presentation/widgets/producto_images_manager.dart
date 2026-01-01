import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../bloc/producto_images/producto_images_cubit.dart';
import '../bloc/producto_images/producto_images_state.dart';

/// Widget profesional para gestionar imágenes de producto
///
/// Features:
/// - Selección múltiple de imágenes
/// - Preview con thumbnails
/// - Reordenamiento (drag & drop)
/// - Marcar imagen principal
/// - Progreso de subida
/// - Manejo de errores con retry
class ProductoImagesManager extends StatelessWidget {
  final String empresaId;
  final int maxImages;

  const ProductoImagesManager({
    super.key,
    required this.empresaId,
    this.maxImages = 10,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductoImagesCubit, ProductoImagesState>(
      builder: (context, state) {
        if (state is! ProductoImagesLoaded) {
          return const SizedBox.shrink();
        }

        return GradientContainer(
          shadowStyle: ShadowStyle.neumorphic,
          borderColor: AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 10, right: 16, left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, state),
                // const SizedBox(height: 4),
                _buildImageGrid(context, state),
                if (state.hasErrors) ...[
                  const SizedBox(height: 8),
                  _buildErrorBanner(context),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context, ProductoImagesLoaded state) {
    final canAddMore = state.images.length < maxImages;

    return Row(
      children: [
        const Icon(Icons.image, color: AppColors.blue1, size: 16),
        const SizedBox(width: 6),
        AppSubtitle('Imágenes', fontSize: 11),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: state.images.isEmpty
                ? Colors.grey[200]
                : AppColors.blue1.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${state.images.length}/$maxImages',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: state.images.isEmpty ? Colors.grey[600] : AppColors.blue1,
            ),
          ),
        ),
        const Spacer(),
        // Mostrar badge si hay imágenes pendientes (locales)
        if (state.hasPendingImages && !canAddMore)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.cloud_upload, size: 10, color: Colors.orange[700]),
                const SizedBox(width: 4),
                Text(
                  '${state.pendingImagesCount} pendiente${state.pendingImagesCount > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
        if (state.hasPendingImages && canAddMore) const SizedBox(width: 8),
        if (canAddMore)
          IconButton.filled(
            onPressed: () => _pickImages(context),
            icon: const Icon(Icons.add_photo_alternate, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(30, 30),
            ),
            tooltip: 'Agregar imágenes',
          ),
      ],
    );
  }

  Widget _buildImageGrid(BuildContext context, ProductoImagesLoaded state) {
    if (state.images.isEmpty) {
      return _buildEmptyState(context);
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.0,
      ),
      itemCount: state.images.length,
      itemBuilder: (context, index) {
        return _buildImageItem(
          context,
          state.images[index],
          index,
          index == 0, // Primera imagen es la principal
        );
      },
    );
  }

  Widget _buildImageItem(
    BuildContext context,
    ProductoImage image,
    int index,
    bool isFirst,
  ) {
    return Stack(
      key: ValueKey(image.id),
      fit: StackFit.expand,
      children: [
          // Thumbnail con sombra neumórfica
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 4,
                    offset: const Offset(2, 2),
                  ),
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.9),
                    blurRadius: 4,
                    offset: const Offset(-2, -2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: _buildThumbnail(image),
              ),
            ),
          ),

          // Badge de imagen local (pendiente de subir)
          if (image.isLocal && !image.isUploading && !image.hasError)
            Positioned(
              bottom: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_upload, color: Colors.white, size: 8),
                    const SizedBox(width: 2),
                    const Text(
                      'Local',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Loading overlay (durante la subida)
          if (image.isUploading)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: image.uploadProgress,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${(image.uploadProgress * 100).toInt()}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Error overlay
          if (image.hasError)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error, color: Colors.white, size: 32),
                    SizedBox(height: 4),
                    Text(
                      'Error',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Se reintentará\nal guardar',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 9),
                    ),
                  ],
                ),
              ),
            ),

          // Badge de imagen principal con gradiente
          if (isFirst && !image.hasError)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade400, Colors.green.shade600],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, color: Colors.white, size: 8),
                    SizedBox(width: 2),
                    Text(
                      'Principal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Botón de eliminar más sutil
          if (!image.isUploading)
            Positioned(
              top: 4,
              right: 4,
              child: GestureDetector(
                onTap: () => _confirmDelete(context, image),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ),

          // Orden más discreto
          Positioned(
            bottom: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      
    );
  }

  Widget _buildThumbnail(ProductoImage image) {
    // Si hay URL (imagen ya subida)
    if (image.urlThumbnail != null || image.url != null) {
      return Image.network(
        image.urlThumbnail ?? image.url!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(Colors.red[100]!);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return _buildPlaceholder(Colors.grey[300]!);
        },
      );
    }

    // Si hay archivo local
    if (image.file != null) {
      return Image.file(
        image.file!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder(Colors.red[100]!);
        },
      );
    }

    return _buildPlaceholder(Colors.grey[300]!);
  }

  Widget _buildPlaceholder(Color color) {
    return Container(
      color: color,
      child: const Center(
        child: Icon(Icons.image, size: 30, color: Colors.grey),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate,
              size: 28,
              color: AppColors.blue1.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin imágenes',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega fotos de tu\n producto',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          ),
          const SizedBox(height: 5),
          // IconButton.filled(
          //   onPressed: () => _pickImages(context),
          //   icon: const Icon(Icons.add_photo_alternate, size: 20),
          //   style: IconButton.styleFrom(
          //     backgroundColor: AppColors.blue1,
          //     foregroundColor: Colors.white,
          //     padding: const EdgeInsets.all(12),
          //   ),
          //   tooltip: 'Agregar imágenes',
          // ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700]),
          const SizedBox(width: 12, height: 1),
          Expanded(
            child: Text(
              'Algunas imágenes tuvieron error. Se reintentará al guardar el producto.',
              style: TextStyle(color: Colors.red[900], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImages(BuildContext context) async {
    final picker = ImagePicker();
    final cubit = context.read<ProductoImagesCubit>();
    final currentState = cubit.state;

    if (currentState is! ProductoImagesLoaded) return;

    final availableSlots = maxImages - currentState.images.length;
    if (availableSlots <= 0) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Máximo $maxImages imágenes permitidas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final List<XFile> pickedFiles = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) return;
      if (!context.mounted) return;

      // Limitar al número de espacios disponibles
      final filesToUpload = pickedFiles.take(availableSlots).toList();

      if (filesToUpload.length < pickedFiles.length) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Solo se pueden agregar ${filesToUpload.length} imágenes más',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }

      // Agregar cada imagen LOCALMENTE (sin subir todavía)
      for (final xFile in filesToUpload) {
        final file = File(xFile.path);
        cubit.addLocalImage(file);
      }
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar imágenes: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _confirmDelete(BuildContext context, ProductoImage image) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar imagen'),
        content: const Text('¿Estás seguro de eliminar esta imagen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!context.mounted) return;

      try {
        await context.read<ProductoImagesCubit>().removeImage(
              imageId: image.id,
              empresaId: empresaId,
            );
      } catch (e) {
        if (!context.mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al eliminar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
