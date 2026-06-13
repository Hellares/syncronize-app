import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/services/storage_service.dart';
import 'package:syncronize/core/theme/app_colors.dart';

/// Sección de imágenes (evidencia) de un componente dentro de una orden de
/// servicio. Carga las imágenes existentes (Archivo polimórfico
/// entidadTipo='SERVICIO_COMPONENTE'), permite agregar (cámara/galería) y
/// eliminar. Maneja su propio estado.
class ComponenteImagenesSection extends StatefulWidget {
  /// ID del ServicioComponente (la fila componente-en-orden), = OrdenComponente.id.
  final String ordenComponenteId;
  final String empresaId;

  /// Si false, oculta el botón de agregar y de eliminar (solo lectura).
  final bool editable;

  const ComponenteImagenesSection({
    super.key,
    required this.ordenComponenteId,
    required this.empresaId,
    this.editable = true,
  });

  @override
  State<ComponenteImagenesSection> createState() =>
      _ComponenteImagenesSectionState();
}

class _ComponenteImagenesSectionState extends State<ComponenteImagenesSection> {
  static const String _entidadTipo = 'SERVICIO_COMPONENTE';
  final _picker = ImagePicker();

  bool _loading = true;
  bool _uploading = false;
  List<ArchivoResponse> _imagenes = [];

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final imgs = await locator<StorageService>().getFilesByEntity(
        entidadTipo: _entidadTipo,
        entidadId: widget.ordenComponenteId,
        empresaId: widget.empresaId,
      );
      if (!mounted) return;
      setState(() {
        _imagenes = imgs;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  Future<void> _agregar(ImageSource source) async {
    final XFile? picked = await _picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 1600,
    );
    if (picked == null) return;

    setState(() => _uploading = true);
    try {
      final archivo = await locator<StorageService>().uploadFile(
        file: File(picked.path),
        empresaId: widget.empresaId,
        entidadTipo: _entidadTipo,
        entidadId: widget.ordenComponenteId,
        categoria: 'EVIDENCIA',
      );
      if (!mounted) return;
      setState(() {
        _imagenes = [..._imagenes, archivo];
        _uploading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _eliminar(ArchivoResponse img) async {
    try {
      await locator<StorageService>().deleteFile(
        archivoId: img.id,
        empresaId: widget.empresaId,
        entidadTipo: _entidadTipo,
      );
      if (!mounted) return;
      setState(() => _imagenes = _imagenes.where((e) => e.id != img.id).toList());
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _elegirFuente() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.blue1),
              title: const Text('Tomar foto'),
              onTap: () {
                Navigator.pop(ctx);
                _agregar(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.blue1),
              title: const Text('Elegir de la galería'),
              onTap: () {
                Navigator.pop(ctx);
                _agregar(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _verImagen(ArchivoResponse img) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: img.url,
                  placeholder: (_, __) => const Padding(
                    padding: EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (_, __, ___) =>
                      const Icon(Icons.broken_image, color: Colors.white, size: 48),
                ),
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
            if (widget.editable)
              Positioned(
                bottom: 4,
                right: 4,
                child: TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Eliminar',
                      style: TextStyle(color: Colors.red)),
                  onPressed: () {
                    Navigator.pop(ctx);
                    _eliminar(img);
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('IMÁGENES',
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                    letterSpacing: 0.5)),
            const SizedBox(width: 6),
            if (_imagenes.isNotEmpty)
              Text('(${_imagenes.length})',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
        const SizedBox(height: 8),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
            ),
          )
        else
          SizedBox(
            height: 76,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final img in _imagenes) _thumb(img),
                if (widget.editable) _addTile(),
              ],
            ),
          ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _thumb(ArchivoResponse img) {
    return GestureDetector(
      onTap: () => _verImagen(img),
      child: Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300, width: 0.8),
        ),
        clipBehavior: Clip.antiAlias,
        child: CachedNetworkImage(
          imageUrl: img.urlThumbnail ?? img.url,
          fit: BoxFit.cover,
          placeholder: (_, __) => Container(
            color: Colors.grey.shade100,
            child: const Center(
              child: SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              ),
            ),
          ),
          errorWidget: (_, __, ___) =>
              Icon(Icons.broken_image, color: Colors.grey.shade400),
        ),
      ),
    );
  }

  Widget _addTile() {
    return GestureDetector(
      onTap: _uploading ? null : _elegirFuente,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.blue1.withValues(alpha: 0.5),
            width: 1,
          ),
          color: AppColors.blue1.withValues(alpha: 0.05),
        ),
        child: Center(
          child: _uploading
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_a_photo_outlined,
                        size: 20, color: AppColors.blue1),
                    const SizedBox(height: 2),
                    Text('Agregar',
                        style: TextStyle(fontSize: 9, color: AppColors.blue1)),
                  ],
                ),
        ),
      ),
    );
  }
}
