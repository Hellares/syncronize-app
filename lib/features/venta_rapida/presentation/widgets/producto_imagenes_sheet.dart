import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../producto/domain/entities/producto.dart';
import '../../../producto/domain/repositories/producto_repository.dart';
import '../../../producto/presentation/bloc/producto_images/producto_images_cubit.dart';
import '../../../producto/presentation/bloc/producto_images/producto_images_state.dart';
import '../../../../core/utils/resource.dart';

/// Máximo de imágenes permitidas desde Venta Rápida. Pensado como
/// catálogo rápido (foto frontal + lateral + opcional), no como
/// galería completa del producto.
const int _kMaxImagenesVR = 3;

/// Bottom sheet para gestionar imágenes de un producto desde Venta
/// Rápida (vendedor/cajero). Carga el detalle completo del producto
/// (con sus `archivos`), instancia un `ProductoImagesCubit` aislado, y
/// permite agregar/eliminar/reordenar/marcar principal usando el mismo
/// `ProductoImagesManager` que ya usa la pantalla de edición de producto.
///
/// Al guardar:
///   1. Sube las imágenes locales pendientes (uploadAllPendingImages)
///   2. PATCH al producto con la lista final de `imagenesIds`
///   3. Retorna `true` por Navigator.pop para que el caller refresque catálogo.
Future<bool?> showProductoImagenesSheet(
  BuildContext context, {
  required String productoId,
  required String productoNombre,
  required String empresaId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) {
      return BlocProvider(
        create: (_) => locator<ProductoImagesCubit>(),
        child: _ProductoImagenesSheetView(
          productoId: productoId,
          productoNombre: productoNombre,
          empresaId: empresaId,
        ),
      );
    },
  );
}

class _ProductoImagenesSheetView extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final String empresaId;

  const _ProductoImagenesSheetView({
    required this.productoId,
    required this.productoNombre,
    required this.empresaId,
  });

  @override
  State<_ProductoImagenesSheetView> createState() =>
      _ProductoImagenesSheetViewState();
}

class _ProductoImagenesSheetViewState
    extends State<_ProductoImagenesSheetView> {
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  /// `true` cuando el producto tenía MÁS de _kMaxImagenesVR imágenes en
  /// la BD y truncamos al cargar — mostramos un warning para que el
  /// admin sepa que las extras se descartarán si guarda.
  bool _truncoImagenesExistentes = false;

  /// Índice del slot cuya imagen se muestra ampliada en la sección
  /// inferior. Por default 0 (primera imagen); si el slot queda vacío,
  /// hacemos fallback al siguiente con imagen.
  int _selectedSlotIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarDetalleProducto();
  }

  /// Carga el detalle completo del producto para obtener `archivos`
  /// (id + url + orden) y precargarlos en el ProductoImagesCubit.
  Future<void> _cargarDetalleProducto() async {
    final repo = locator<ProductoRepository>();
    final result = await repo.getProducto(
      productoId: widget.productoId,
      empresaId: widget.empresaId,
    );
    if (!mounted) return;

    if (result is Success<Producto>) {
      final producto = result.data;
      final archivos = producto.archivos ?? const [];
      final ordenadas = archivos
          .map((a) => ProductoImage(
                id: a.id,
                url: a.url,
                urlThumbnail: a.urlThumbnail,
                isUploading: false,
                uploadProgress: 1.0,
                hasError: false,
                order: a.orden ?? 0,
              ))
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));

      // VR limita a 3 imágenes: si el producto tenía más, mostramos
      // solo las primeras 3 y avisamos al admin. Las extras se
      // mantienen en el backend hasta que guarde (al guardar se
      // recortan).
      final truncado = ordenadas.length > _kMaxImagenesVR;
      final primerasN = ordenadas.take(_kMaxImagenesVR).toList();

      // ignore: use_build_context_synchronously
      context.read<ProductoImagesCubit>().loadExistingImages(primerasN);
      setState(() {
        _truncoImagenesExistentes = truncado;
        _isLoading = false;
      });
    } else if (result is Error<Producto>) {
      setState(() {
        _loadError = result.message;
        _isLoading = false;
      });
    }
  }

  /// Sube imágenes locales pendientes y actualiza el producto con la
  /// lista final de `imagenesIds`. Si todo OK, cierra el sheet con
  /// `true` para que el caller refresque el catálogo.
  Future<void> _guardar() async {
    setState(() => _isSaving = true);
    final imagesCubit = context.read<ProductoImagesCubit>();

    try {
      // 1) Subir locales pendientes (si las hay).
      await imagesCubit.uploadAllPendingImages(widget.empresaId);

      // Si una imagen quedó con error, abortamos.
      final state = imagesCubit.state;
      if (state is ProductoImagesLoaded && state.hasErrors) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        SnackBarHelper.showError(
          context,
          'Alguna imagen no se pudo subir. Revisá e intentá de nuevo.',
        );
        return;
      }

      // 2) PATCH /productos/:id/imagenes (endpoint reducido que solo
      //    requiere VIEW_PRODUCTS, no MANAGE_PRODUCTS — permite a
      //    vendedores/cajeros actualizar sin necesidad de gestión
      //    completa de productos).
      final imagenesIds = imagesCubit.getUploadedImageIds();
      final repo = locator<ProductoRepository>();
      final result = await repo.actualizarImagenesProducto(
        productoId: widget.productoId,
        empresaId: widget.empresaId,
        imagenesIds: imagenesIds,
      );

      if (!mounted) return;
      if (result is Success<void>) {
        SnackBarHelper.showSuccess(context, 'Imágenes actualizadas');
        Navigator.of(context).pop(true);
      } else if (result is Error<void>) {
        setState(() => _isSaving = false);
        SnackBarHelper.showError(context, result.message);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      SnackBarHelper.showError(context, 'Error al guardar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return Padding(
      // Respeta el teclado si se abriera (improbable acá, pero defensivo).
      padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mediaQuery.size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Stack(
          children: [
            SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildHeader(),
                  const Divider(height: 1),
                  Expanded(child: _buildBody()),
                  const Divider(height: 1),
                  _buildFooter(),
                ],
              ),
            ),
            // Overlay de guardado: bloquea interacción y muestra
            // progreso explícito. Se monta SOLO mientras `_isSaving`
            // está activo (subida + PATCH del producto).
            if (_isSaving) _buildSavingOverlay(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.image_outlined, color: AppColors.blue1, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Imágenes del producto',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.productoNombre,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(false),
            icon: const Icon(Icons.close, size: 22),
            splashRadius: 18,
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.red, size: 40),
            const SizedBox(height: 12),
            Text(
              _loadError!,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Reintentar',
              onPressed: () {
                setState(() {
                  _loadError = null;
                  _isLoading = true;
                });
                _cargarDetalleProducto();
              },
            ),
          ],
        ),
      );
    }
    return BlocBuilder<ProductoImagesCubit, ProductoImagesState>(
      builder: (context, state) {
        if (state is! ProductoImagesLoaded) {
          return const SizedBox.shrink();
        }
        final imagenes = state.images;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Toca un espacio vacío para agregar foto. Máximo '
                '$_kMaxImagenesVR imágenes.',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              if (_truncoImagenesExistentes) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          color: Colors.orange, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Este producto tenía más de $_kMaxImagenesVR '
                          'imágenes; las extras se descartarán si guardas.',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              // Grid fijo de _kMaxImagenesVR slots. Cada slot:
              //  - Vacío → tap abre dialog cámara/galería
              //  - Con imagen → tap selecciona para preview grande,
              //    X elimina
              Row(
                children: List.generate(_kMaxImagenesVR, (i) {
                  final hasImage = i < imagenes.length;
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: i < _kMaxImagenesVR - 1 ? 8 : 0,
                      ),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: hasImage
                            ? _buildImageSlot(
                                imagenes[i],
                                index: i,
                                seleccionado: _selectedSlotIndex == i,
                              )
                            : _buildEmptySlot(),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 18),
              // Preview ampliado de la imagen seleccionada. Aprovecha
              // el espacio libre del sheet para que el admin vea bien
              // qué imagen tiene/va a subir antes de guardar.
              _buildPreviewAmpliado(imagenes),
            ],
          ),
        );
      },
    );
  }

  /// Renderiza la imagen actualmente seleccionada en grande. Si no hay
  /// imágenes, muestra un placeholder neutro que invita a agregar.
  Widget _buildPreviewAmpliado(List<ProductoImage> imagenes) {
    // Resolver imagen efectiva: si el slot seleccionado está fuera de
    // rango (porque se eliminó la última), caemos a la primera.
    ProductoImage? seleccionada;
    if (imagenes.isNotEmpty) {
      final idx = _selectedSlotIndex.clamp(0, imagenes.length - 1);
      seleccionada = imagenes[idx];
    }

    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.greyLight.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.blue1.withValues(alpha: 0.15),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: seleccionada == null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 38,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sin imágenes — agregá una arriba',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
            : Stack(
                fit: StackFit.expand,
                children: [
                  if (seleccionada.file != null)
                    Image.file(seleccionada.file!, fit: BoxFit.contain)
                  else if (seleccionada.url != null &&
                      seleccionada.url!.isNotEmpty)
                    CachedNetworkImage(
                      imageUrl: seleccionada.url!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => const Center(
                        child: Icon(Icons.broken_image_outlined),
                      ),
                    )
                  else
                    const Center(child: Icon(Icons.broken_image_outlined)),
                  if (seleccionada.isUploading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.4),
                      child: Center(
                        child: CircularProgressIndicator(
                          value: seleccionada.uploadProgress > 0
                              ? seleccionada.uploadProgress
                              : null,
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptySlot() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _isSaving ? null : _mostrarOpcionesSubida,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.blue1.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_a_photo_outlined,
                color: AppColors.blue1.withValues(alpha: 0.7),
                size: 26,
              ),
              const SizedBox(height: 4),
              Text(
                'Agregar',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSlot(
    ProductoImage img, {
    required int index,
    required bool seleccionado,
  }) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Tap simple sobre el thumbnail → selecciona para preview grande
        // (no abre dialog ni elimina). La eliminación es solo vía el
        // botón X de arriba a la derecha.
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isSaving
                ? null
                : () => setState(() => _selectedSlotIndex = index),
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: img.file != null
                  ? Image.file(img.file!, fit: BoxFit.cover)
                  : (img.url != null && img.url!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: img.url!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppColors.greyLight,
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.greyLight,
                            child: const Icon(Icons.broken_image_outlined),
                          ),
                        )
                      : Container(color: AppColors.greyLight)),
            ),
          ),
        ),
        // Borde: más prominente cuando está seleccionada (para que se
        // vea cuál estás previsualizando abajo).
        Positioned.fill(
          child: IgnorePointer(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: seleccionado
                      ? AppColors.blue1
                      : AppColors.blue1.withValues(alpha: 0.15),
                  width: seleccionado ? 2 : 1,
                ),
              ),
            ),
          ),
        ),
        // Overlay de subida en curso.
        if (img.isUploading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: CircularProgressIndicator(
                  value: img.uploadProgress > 0 ? img.uploadProgress : null,
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        // Badge "Nueva" para locales aún sin subir.
        if (img.isLocal && !img.isUploading)
          Positioned(
            left: 4,
            bottom: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.blue1,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Nueva',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        // Badge "PRINCIPAL" cuando el slot está en índice 0 — esa es
        // la imagen que aparece en la card del catálogo. El admin la
        // ve marcada con estrella llena dorada.
        if (index == 0)
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.amber.shade700,
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 11, color: Colors.white),
                  SizedBox(width: 2),
                  Text(
                    'PRINCIPAL',
                    style: TextStyle(
                      fontSize: 8,
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          // Para slots no-principales, ofrecer botón "Hacer principal"
          // que mueve la imagen al índice 0 vía reorderImages del cubit.
          Positioned(
            bottom: 4,
            right: 4,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: _isSaving
                    ? null
                    : () => _hacerPrincipal(index),
                borderRadius: BorderRadius.circular(14),
                child: Tooltip(
                  message: 'Hacer principal',
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.star_outline_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        // Botón X arriba a la derecha para eliminar.
        Positioned(
          top: 4,
          right: 4,
          child: InkWell(
            onTap: _isSaving ? null : () => _confirmarEliminar(img.id),
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                size: 14,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mueve la imagen del slot `index` al índice 0 (primera posición =
  /// principal). El orden lo persiste el cubit y al guardar se manda
  /// como `imagenesIds` en el orden final.
  void _hacerPrincipal(int index) {
    final cubit = context.read<ProductoImagesCubit>();
    cubit.reorderImages(index, 0);
    // Como el slot seleccionado para preview pudo desplazarse, lo
    // mantenemos sobre la imagen que el admin acaba de promover.
    setState(() => _selectedSlotIndex = 0);
  }

  /// Abre un bottom sheet con dos opciones: Tomar foto / Elegir de
  /// galería. Después llama a image_picker con la fuente elegida.
  Future<void> _mostrarOpcionesSubida() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 4),
            ListTile(
              leading: const Icon(
                Icons.photo_camera_outlined,
                color: AppColors.blue1,
              ),
              title: const Text(
                'Tomar foto con la cámara',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library_outlined,
                color: AppColors.blue1,
              ),
              title: const Text(
                'Elegir de la galería',
                style: TextStyle(fontSize: 14),
              ),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
    );
    if (source == null || !mounted) return;
    await _agregarImagen(source);
  }

  Future<void> _agregarImagen(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? xFile =
          await picker.pickImage(source: source, imageQuality: 85);
      if (xFile == null || !mounted) return;
      context.read<ProductoImagesCubit>().addLocalImage(File(xFile.path));
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error al obtener imagen: $e');
    }
  }

  /// Overlay modal que cubre el sheet mientras se sube imágenes y
  /// se hace PATCH al producto. Bloquea taps en el body/footer y
  /// muestra el estado en vivo desde el ProductoImagesCubit:
  ///   - "Subiendo imagen 2 de 3..."  (mientras hay imágenes locales)
  ///   - "Guardando cambios..."        (cuando ya subió todo y va PATCH)
  Widget _buildSavingOverlay() {
    return Positioned.fill(
      child: BlocBuilder<ProductoImagesCubit, ProductoImagesState>(
        builder: (context, state) {
          int totalALocal = 0;
          int subiendo = 0;
          int subidas = 0;
          if (state is ProductoImagesLoaded) {
            for (final img in state.images) {
              if (img.isLocal) {
                totalALocal++;
                if (img.isUploading) {
                  subiendo++;
                } else if (!img.hasError) {
                  // Local que ya terminó subida sin error =
                  // "promovida" — no la cuento como pendiente.
                }
              }
            }
            // Locales totales recién creadas vs las que ya transicionaron
            // a server (isLocal=false). Como el cubit marca isLocal=false
            // post-subida, las que ya terminaron NO están en `totalALocal`.
            // Usamos el conteo de uploading para mostrar el paso actual.
            subidas = totalALocal - subiendo;
          }
          final hayUpload = totalALocal > 0;
          final mensaje = hayUpload
              ? (subiendo > 0
                  ? 'Subiendo imagen ${subidas + 1} de $totalALocal…'
                  : 'Guardando cambios…')
              : 'Guardando cambios…';

          return Stack(
            children: [
              // Barrier: bloquea toda interacción.
              ModalBarrier(
                color: Colors.black.withValues(alpha: 0.35),
                dismissible: false,
              ),
              // Card central con spinner + mensaje + progreso.
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 42,
                        height: 42,
                        child: CircularProgressIndicator(
                          strokeWidth: 3.2,
                          color: AppColors.blue1,
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        mensaje,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.blue3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'No cierres la app hasta que termine.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (totalALocal > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: totalALocal == 0
                                ? null
                                : (subidas / totalALocal).clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor:
                                AppColors.blue1.withValues(alpha: 0.12),
                            valueColor: const AlwaysStoppedAnimation(
                              AppColors.blue1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmarEliminar(String imageId) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('¿Eliminar imagen?'),
        content: const Text(
          'Esta acción quitará la imagen del producto al guardar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
    if (confirmar != true || !mounted) return;
    try {
      await context.read<ProductoImagesCubit>().removeImage(
            imageId: imageId,
            empresaId: widget.empresaId,
          );
    } catch (e) {
      if (!mounted) return;
      SnackBarHelper.showError(context, 'Error al eliminar: $e');
    }
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving
                  ? null
                  : () => Navigator.of(context).pop(false),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.blue1, width: 1),
                foregroundColor: AppColors.blue1,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Cancelar',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.blue1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: CustomButton(
              borderColor: AppColors.green,
              textColor: Colors.green,
              text: 'Guardar cambios',
              isLoading: _isSaving,
              onPressed: _isSaving || _isLoading ? null : _guardar,
            ),
          ),
        ],
      ),
    );
  }
}
