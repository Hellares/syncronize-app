/// Vista previa de la ficha del producto y su envío.
///
/// La vista previa NO es adorno: la imagen se genera capturando exactamente
/// este widget, así que lo que se ve es lo que se manda. Los interruptores
/// dejan sacar el precio, las características o el código sin tocar el diseño.
library;

import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/repositories/plantilla_repository.dart';
import '../widgets/ficha_compartible.dart';

class CompartirProductoPage extends StatefulWidget {
  /// 🔴 Recibe DATOS ya resueltos, no un `Producto`: la misma pantalla
  /// comparte un producto y una variante, que no comparten tipo. Quien la
  /// abre es el que sabe de qué sede sale el precio.
  final String titulo;
  final String? codigo;
  final String? fotoUrl;
  final List<dynamic> atributosValores;
  final List<String> plantillasIds;
  final double precio;
  final double? precioAnterior;

  final String empresaNombre;
  final String? empresaTelefono;
  final String? empresaLogo;

  const CompartirProductoPage({
    super.key,
    required this.titulo,
    required this.precio,
    required this.empresaNombre,
    this.codigo,
    this.fotoUrl,
    this.atributosValores = const [],
    this.plantillasIds = const [],
    this.precioAnterior,
    this.empresaTelefono,
    this.empresaLogo,
  });

  @override
  State<CompartirProductoPage> createState() => _CompartirProductoPageState();
}

class _CompartirProductoPageState extends State<CompartirProductoPage> {
  final GlobalKey _lienzo = GlobalKey();

  bool _incluirPrecio = true;
  bool _incluirCaracteristicas = true;
  bool _incluirCodigo = true;
  bool _enviando = false;
  List<AtributoPlantilla> _plantillas = const [];

  @override
  void initState() {
    super.initState();
    _cargarPlantillas();
    // 🔴 La foto se precarga ANTES de capturar: `toImage` dibuja lo que hay en
    // ese instante, y una imagen a medio bajar sale en blanco en el PNG.
    WidgetsBinding.instance.addPostFrameCallback((_) => _precargarFoto());
  }

  Future<void> _cargarPlantillas() async {
    try {
      final res = await locator<PlantillaRepository>().getPlantillas();
      if (!mounted) return;
      if (res is Success<List<AtributoPlantilla>>) {
        setState(() => _plantillas = res.data);
      }
    } catch (_) {
      // Sin plantillas la ficha sale sin agrupar, que es mejor que no salir.
    }
  }

  Future<void> _precargarFoto() async {
    final url = widget.fotoUrl;
    if (url == null || url.isEmpty) return;
    try {
      await precacheImage(NetworkImage(url), context);
    } catch (_) {
      // La ficha ya dibuja un bloque neutro si la foto falla.
    }
  }

  double get _precio => widget.precio;

  Future<void> _compartir() async {
    setState(() => _enviando = true);
    try {
      final limite = _lienzo.currentContext?.findRenderObject();
      if (limite is! RenderRepaintBoundary) return;

      // pixelRatio 3: el lienzo son 360 px logicos, asi que el PNG sale de
      // ~1080, que es lo que WhatsApp muestra sin recomprimir feo.
      final imagen = await limite.toImage(pixelRatio: 3);
      final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return;

      final dir = await getTemporaryDirectory();
      final archivo = File(
        '${dir.path}/ficha_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await archivo.writeAsBytes(bytes.buffer.asUint8List());

      // El menu nativo: ahi el usuario elige WhatsApp y la imagen va como
      // ADJUNTO. Un `wa.me` abre el chat pero no puede mandar archivos.
      await Share.shareXFiles(
        [XFile(archivo.path)],
        text: _incluirPrecio && _precio > 0
            ? '${widget.titulo} — S/ ${_precio.toStringAsFixed(2)}'
            : widget.titulo,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo compartir: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        title: const Text('Compartir producto', style: TextStyle(fontSize: 15)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                // El RepaintBoundary es lo que se captura: envuelve SOLO la
                // ficha, sin el fondo ni los controles.
                child: RepaintBoundary(
                  key: _lienzo,
                  child: FichaCompartible(
                    titulo: widget.titulo,
                    codigo: widget.codigo,
                    fotoUrl: widget.fotoUrl,
                    atributosValores: widget.atributosValores,
                    plantillasIds: widget.plantillasIds,
                    plantillas: _plantillas,
                    precio: _precio,
                    precioAnterior: widget.precioAnterior,
                    empresaNombre: widget.empresaNombre,
                    empresaTelefono: widget.empresaTelefono,
                    empresaLogo: widget.empresaLogo,
                    incluirPrecio: _incluirPrecio,
                    incluirCaracteristicas: _incluirCaracteristicas,
                    incluirCodigo: _incluirCodigo,
                  ),
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: .06), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      _interruptor('Precio', _incluirPrecio, (v) => setState(() => _incluirPrecio = v)),
                      _interruptor('Características', _incluirCaracteristicas,
                          (v) => setState(() => _incluirCaracteristicas = v)),
                      _interruptor('Código', _incluirCodigo, (v) => setState(() => _incluirCodigo = v)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _enviando ? null : _compartir,
                      icon: _enviando
                          ? const SizedBox(
                              width: 14, height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.share_outlined, size: 16),
                      label: Text(_enviando ? 'Preparando…' : 'Compartir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue1,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _interruptor(String texto, bool valor, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(texto, style: const TextStyle(fontSize: 11)),
      selected: valor,
      onSelected: onChanged,
      showCheckmark: true,
      selectedColor: AppColors.blue1.withValues(alpha: .12),
      checkmarkColor: AppColors.blue1,
      labelStyle: TextStyle(fontSize: 11, color: valor ? AppColors.blue1 : Colors.grey.shade600),
      side: BorderSide(color: valor ? AppColors.blue1 : Colors.grey.shade300),
    );
  }
}
