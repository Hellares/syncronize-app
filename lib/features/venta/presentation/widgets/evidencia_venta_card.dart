import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import '../../data/datasources/venta_remote_datasource.dart';

/// Una foto de la venta ya subida.
class EvidenciaVenta {
  final String archivoId;
  final String url;
  final String? urlThumbnail;

  const EvidenciaVenta({
    required this.archivoId,
    required this.url,
    this.urlThumbnail,
  });

  factory EvidenciaVenta.fromJson(Map<String, dynamic> json) => EvidenciaVenta(
        archivoId: json['archivoId'] as String? ?? '',
        url: json['url'] as String? ?? '',
        urlThumbnail: json['urlThumbnail'] as String?,
      );

  /// La miniatura si el media-processor ya la genero; si no, la original.
  String get miniatura =>
      (urlThumbnail != null && urlThumbnail!.isNotEmpty) ? urlThumbnail! : url;
}

/// Elige una foto de la CAMARA o de la GALERIA.
///
/// 🔴 Las dos opciones, no solo la camara: muchas veces la foto ya esta en el
/// telefono (se la mando el repartidor, o se saco antes de empacar).
///
/// `imageQuality: 70` y `maxWidth: 1600` son los mismos de caja chica: en el
/// mostrador se sube por datos moviles y una foto de 4 MB tarda una eternidad.
Future<String?> elegirFotoVenta(BuildContext context) async {
  final origen = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text('Tomar foto'),
            onTap: () => Navigator.pop(ctx, ImageSource.camera),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text('Elegir de galería'),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery),
          ),
        ],
      ),
    ),
  );
  if (origen == null) return null;
  final picked = await ImagePicker()
      .pickImage(source: origen, imageQuality: 70, maxWidth: 1600);
  return picked?.path;
}

/// Fotos de la venta: cómo se vendió el producto y cómo se entrega.
///
/// Sirven de respaldo ante un reclamo. Es evidencia INTERNA: no viaja al
/// comprobante ni al ticket del cliente.
///
/// Dos modos, según haya o no una venta todavía:
///  - [ventaId] null (COBRO): cada foto se sube apenas se elige y su
///    `archivoId` sale por [onIdsChange] para viajar en `evidenciaIds` al
///    cobrar. 🔴 Subirla recién al confirmar dejaría al cliente esperando
///    frente a la caja mientras sale por datos.
///  - [ventaId] con valor (DETALLE): se listan las guardadas y las nuevas se
///    adjuntan directo a esa venta.
class EvidenciaVentaCard extends StatefulWidget {
  /// null mientras la venta no existe (pantalla de cobro).
  final String? ventaId;

  /// Solo en modo cobro: los ids ya subidos.
  final ValueChanged<List<String>>? onIdsChange;

  /// Solo en modo cobro: true mientras haya alguna subida en vuelo. El botón
  /// de cobrar espera con esto para no perder la foto.
  final ValueChanged<bool>? onSubiendoChange;

  final int max;

  const EvidenciaVentaCard({
    super.key,
    this.ventaId,
    this.onIdsChange,
    this.onSubiendoChange,
    this.max = 6,
  });

  @override
  State<EvidenciaVentaCard> createState() => _EvidenciaVentaCardState();
}

class _EvidenciaVentaCardState extends State<EvidenciaVentaCard> {
  final List<EvidenciaVenta> _items = [];
  int _enVuelo = 0;
  bool _cargando = false;
  String? _error;

  bool get _esCobro => widget.ventaId == null;

  @override
  void initState() {
    super.initState();
    if (!_esCobro) _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final filas =
          await locator<VentaRemoteDataSource>().getEvidencias(widget.ventaId!);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(filas.map(EvidenciaVenta.fromJson));
      });
    } catch (_) {
      // Sin fotos o sin red: la tarjeta se muestra vacía y se puede agregar.
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _marcarVuelo(int delta) {
    setState(() => _enVuelo = (_enVuelo + delta).clamp(0, 99));
    widget.onSubiendoChange?.call(_enVuelo > 0);
  }

  void _emitirIds() {
    widget.onIdsChange?.call(_items.map((e) => e.archivoId).toList());
  }

  Future<void> _agregar() async {
    if (_items.length + _enVuelo >= widget.max) {
      setState(() => _error = 'Máximo ${widget.max} fotos.');
      return;
    }
    final path = await elegirFotoVenta(context);
    if (path == null || !mounted) return;

    setState(() => _error = null);
    _marcarVuelo(1);
    try {
      final ds = locator<VentaRemoteDataSource>();
      final json = _esCobro
          ? await ds.subirEvidencia(path)
          : await ds.adjuntarEvidencia(widget.ventaId!, path);
      if (!mounted) return;
      setState(() => _items.add(EvidenciaVenta.fromJson(json)));
      _emitirIds();
    } catch (_) {
      if (mounted) setState(() => _error = 'No se pudo subir la foto.');
    } finally {
      if (mounted) _marcarVuelo(-1);
    }
  }

  Future<void> _quitar(EvidenciaVenta foto) async {
    if (_esCobro) {
      // La venta todavía no existe: sacarla de la lista alcanza. El archivo
      // queda huérfano, igual que si se abandona el cobro.
      setState(() => _items.removeWhere((e) => e.archivoId == foto.archivoId));
      _emitirIds();
      return;
    }
    final antes = List<EvidenciaVenta>.from(_items);
    setState(() => _items.removeWhere((e) => e.archivoId == foto.archivoId));
    try {
      await locator<VentaRemoteDataSource>()
          .eliminarEvidencia(widget.ventaId!, foto.archivoId);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll(antes);
        _error = 'No se pudo quitar la foto.';
      });
    }
  }

  void _verGrande(EvidenciaVenta foto) {
    showDialog<void>(
      context: context,
      builder: (ctx) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: Image.network(foto.url, fit: BoxFit.contain),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.blueborder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Fotos de la venta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue1,
                      ),
                    ),
                    Text(
                      'Cómo se vendió y cómo se entrega. Uso interno.',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: _enVuelo > 0 ? null : _agregar,
                icon: const Icon(Icons.add_a_photo_outlined, size: 16),
                label: const Text('Agregar', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(foregroundColor: AppColors.blue1),
              ),
            ],
          ),
          if (_cargando)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text('Cargando…',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
            )
          else if (_items.isEmpty && _enVuelo == 0)
            Text(
              'Sin fotos. Sirven de respaldo ante un reclamo.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final foto in _items)
                  Stack(
                    children: [
                      GestureDetector(
                        onTap: () => _verGrande(foto),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            foto.miniatura,
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 64,
                              height: 64,
                              color: Colors.grey.shade200,
                              child: Icon(Icons.broken_image_outlined,
                                  size: 18, color: Colors.grey.shade400),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: 2,
                        top: 2,
                        child: GestureDetector(
                          onTap: () => _quitar(foto),
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.55),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.close,
                                size: 11, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                for (var i = 0; i < _enVuelo; i++)
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
              ],
            ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.amber.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _error!,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.amber.shade900),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
