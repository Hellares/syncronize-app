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
import '../../../../core/services/whatsapp_cliente_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/repositories/plantilla_repository.dart';
import '../services/ficha_pdf.dart';
import '../widgets/ficha_compartible.dart';

class CompartirProductoPage extends StatefulWidget {
  /// 🔴 Recibe DATOS ya resueltos, no un `Producto`: la misma pantalla
  /// comparte un producto y una variante, que no comparten tipo. Quien la
  /// abre es el que sabe de qué sede sale el precio.
  /// Para mandar la ficha desde el WhatsApp de la empresa hace falta saber de
  /// qué empresa se trata.
  final String empresaId;

  final String titulo;
  final String? codigo;

  /// La del producto. En una variante es la del padre: la variante no tiene
  /// descripción propia.
  final String? descripcion;
  /// 🔴 TODAS las fotos: cuando hay varias, cada una suele ser un COLOR o un
  /// DIBUJO distinto del mismo artículo. Antes se mandaba la primera sin
  /// preguntar y el resto no existía.
  final List<String> fotos;
  final List<dynamic> atributosValores;
  final List<String> plantillasIds;
  final double precio;
  final double? precioAnterior;

  /// 🔴 El NOMBRE COMERCIAL, el logo y el color salen de la configuración de
  /// documentos (`resolverIdentidadComercial`), no de `Empresa.nombre`, que es
  /// la razón social.
  final String empresaNombre;
  final String? empresaTelefono;
  final String? empresaLogo;
  final Color? empresaColor;
  final String? textoPie;

  const CompartirProductoPage({
    super.key,
    required this.empresaId,
    required this.titulo,
    required this.precio,
    required this.empresaNombre,
    this.codigo,
    this.descripcion,
    this.fotos = const [],
    this.atributosValores = const [],
    this.plantillasIds = const [],
    this.precioAnterior,
    this.empresaTelefono,
    this.empresaLogo,
    this.empresaColor,
    this.textoPie,
  });

  @override
  State<CompartirProductoPage> createState() => _CompartirProductoPageState();
}

class _CompartirProductoPageState extends State<CompartirProductoPage> {
  final GlobalKey _lienzo = GlobalKey();

  bool _incluirPrecio = true;
  bool _incluirCaracteristicas = true;
  bool _incluirCodigo = true;
  bool _incluirOtrasFotos = true;

  /// PNG o PDF: el mismo documento, dos envoltorios. El PDF es la MISMA ficha
  /// en una hoja a su medida, para imprimirla o mandarla como documento.
  bool _comoPdf = false;

  bool _enviando = false;
  List<AtributoPlantilla> _plantillas = const [];
  late String? _foto = widget.fotos.isEmpty ? null : widget.fotos.first;

  @override
  void initState() {
    super.initState();
    _cargarPlantillas();
    // 🔴 Las fotos se precargan ANTES de capturar: `toImage` dibuja lo que hay
    // en ese instante, y una imagen a medio bajar sale en blanco en el PNG.
    WidgetsBinding.instance.addPostFrameCallback((_) => _precargarFotos());
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

  /// 🔴 TODAS las que se dibujan, no solo la grande: la tira de abajo también
  /// se captura, y una miniatura a medio bajar sale en blanco en el PNG.
  Future<void> _precargarFotos() async {
    for (final url in <String>{if (_foto != null) _foto!, ...widget.fotos}) {
      if (url.trim().isEmpty) continue;
      if (!mounted) return;
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (_) {
        // La ficha ya dibuja un bloque neutro si una foto falla.
      }
    }
  }

  double get _precio => widget.precio;

  /// El color de la marca, o el del sistema si la empresa no configuró uno.
  Color get _marca => widget.empresaColor ?? AppColors.blue1;

  /// Captura el lienzo y lo deja en un archivo temporal, PNG o PDF según el
  /// formato elegido. null si algo falló.
  Future<File?> _capturarFicha() async {
    setState(() => _enviando = true);
    try {
      final limite = _lienzo.currentContext?.findRenderObject();
      if (limite is! RenderRepaintBoundary) return null;

      // pixelRatio 3: el lienzo son 360 px logicos, asi que el PNG sale de
      // ~1080, que es lo que WhatsApp muestra sin recomprimir feo.
      final imagen = await limite.toImage(pixelRatio: 3);
      final bytes = await imagen.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      final png = bytes.buffer.asUint8List();

      final dir = await getTemporaryDirectory();
      final sello = DateTime.now().millisecondsSinceEpoch;

      if (_comoPdf) {
        // El PDF sale de la MISMA captura: lo que se ve es lo que se manda,
        // en los dos formatos.
        final pdf = await fichaAPdf(png);
        if (pdf == null) return null;
        final archivo = File('${dir.path}/ficha_$sello.pdf');
        await archivo.writeAsBytes(pdf);
        return archivo;
      }

      final archivo = File('${dir.path}/ficha_$sello.png');
      await archivo.writeAsBytes(png);
      return archivo;
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo armar la ficha: $e'), backgroundColor: Colors.red),
      );
      return null;
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  String get _textoMensaje => _incluirPrecio && _precio > 0
      ? '${widget.titulo} — S/ ${_precio.toStringAsFixed(2)}'
      : widget.titulo;

  Future<void> _compartir() async {
    final archivo = await _capturarFicha();
    if (archivo == null) return;
    // El menu nativo: ahi el usuario elige la app y el contacto, y la imagen
    // va como ADJUNTO. Un `wa.me` abre el chat pero no puede mandar archivos.
    await Share.shareXFiles([XFile(archivo.path)], text: _textoMensaje);
  }

  /// A un número puntual. Con la línea de la empresa vinculada la ficha sale
  /// sin salir de la app; si no, se abre WhatsApp con el texto.
  Future<void> _enviarPorWhatsapp() async {
    final archivo = await _capturarFicha();
    if (archivo == null || !mounted) return;

    await WhatsappClienteService.compartirArchivo(
      context,
      empresaId: widget.empresaId,
      archivo: archivo,
      // 🔴 El PDF va por el endpoint de DOCUMENTO y la imagen por el de
      // imagen: mandar un PDF como imagen no lo abre nadie.
      nombreArchivo: _comoPdf ? 'ficha.pdf' : 'ficha.png',
      esPdf: _comoPdf,
      detalleAdjunto: 'La ficha se envía con el mensaje',
      textoInicial: _incluirPrecio && _precio > 0
          ? 'Hola, te comparto *${widget.titulo}*.\nPrecio: S/ ${_precio.toStringAsFixed(2)}'
          : 'Hola, te comparto *${widget.titulo}*.',
      compartirNativo: () =>
          Share.shareXFiles([XFile(archivo.path)], text: _textoMensaje),
    );
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
                    descripcion: widget.descripcion,
                    fotoUrl: _foto,
                    // Las otras salen de la lista completa, sin la principal:
                    // cambiar cuál va grande reacomoda la tira sola.
                    fotosExtra: widget.fotos.where((f) => f != _foto).toList(),
                    atributosValores: widget.atributosValores,
                    plantillasIds: widget.plantillasIds,
                    plantillas: _plantillas,
                    precio: _precio,
                    precioAnterior: widget.precioAnterior,
                    empresaNombre: widget.empresaNombre,
                    empresaTelefono: widget.empresaTelefono,
                    empresaLogo: widget.empresaLogo,
                    color: _marca,
                    textoPie: widget.textoPie,
                    incluirPrecio: _incluirPrecio,
                    incluirCaracteristicas: _incluirCaracteristicas,
                    incluirCodigo: _incluirCodigo,
                    incluirOtrasFotos: _incluirOtrasFotos,
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
                  // 🔴 Con varias fotos se elige cuál va GRANDE: las demás van
                  // en la tira de abajo, en la misma ficha. Cada una suele ser
                  // un color o un dibujo distinto del mismo artículo.
                  if (widget.fotos.length > 1) ...[
                    SizedBox(
                      height: 46,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: widget.fotos.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 6),
                        itemBuilder: (_, i) {
                          final url = widget.fotos[i];
                          final elegida = url == _foto;
                          return GestureDetector(
                            onTap: _enviando
                                ? null
                                : () {
                                    setState(() => _foto = url);
                                    _precargarFotos();
                                  },
                            child: Opacity(
                              opacity: elegida ? 1 : .45,
                              child: Container(
                                width: 46,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: elegida ? _marca : Colors.grey.shade300,
                                    width: elegida ? 2 : 1,
                                  ),
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.network(url, fit: BoxFit.cover),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Wrap(
                    spacing: 6,
                    children: [
                      _interruptor('Precio', _incluirPrecio, (v) => setState(() => _incluirPrecio = v)),
                      _interruptor('Características', _incluirCaracteristicas,
                          (v) => setState(() => _incluirCaracteristicas = v)),
                      _interruptor('Código', _incluirCodigo, (v) => setState(() => _incluirCodigo = v)),
                      // Con una sola foto no hay tira que prender ni apagar.
                      if (widget.fotos.length > 1)
                        _interruptor('Otras fotos', _incluirOtrasFotos,
                            (v) => setState(() => _incluirOtrasFotos = v)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // El formato vale para los DOS botones: se comparte y se
                  // manda por WhatsApp lo mismo que se ve, envuelto en PNG o
                  // en PDF.
                  Row(
                    children: [
                      Text(
                        'Formato',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(width: 8),
                      _formato('PNG', !_comoPdf, () => setState(() => _comoPdf = false)),
                      const SizedBox(width: 6),
                      _formato('PDF', _comoPdf, () => setState(() => _comoPdf = true)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _enviando ? null : _compartir,
                          icon: _enviando
                              ? const SizedBox(
                                  width: 14, height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.share_outlined, size: 16),
                          label: Text(_enviando ? 'Preparando…' : 'Compartir',
                              style: const TextStyle(fontSize: 12)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.blue1,
                            side: const BorderSide(color: AppColors.blue1),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _enviando ? null : _enviarPorWhatsapp,
                          icon: const Icon(Icons.send, size: 16),
                          label: const Text('WhatsApp',
                              style: TextStyle(fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF25D366),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// PNG o PDF. Es una elección entre dos, no un interruptor: un chip de
  /// formato apagado no significa nada.
  Widget _formato(String texto, bool elegido, VoidCallback onTap) {
    return ChoiceChip(
      label: Text(texto, style: const TextStyle(fontSize: 11)),
      selected: elegido,
      onSelected: _enviando ? null : (_) => onTap(),
      showCheckmark: false,
      selectedColor: AppColors.blue1.withValues(alpha: .12),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: elegido ? FontWeight.w700 : FontWeight.w400,
        color: elegido ? AppColors.blue1 : Colors.grey.shade600,
      ),
      side: BorderSide(color: elegido ? AppColors.blue1 : Colors.grey.shade300),
      visualDensity: VisualDensity.compact,
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
