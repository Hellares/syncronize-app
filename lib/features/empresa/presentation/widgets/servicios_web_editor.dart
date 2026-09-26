import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';

/// Sube un archivo y devuelve su URL pública.
typedef SubirArchivo = Future<String> Function(File file, {void Function(double progress)? onProgress});

/// Lo que la página de Servicios de la tienda web muestra además de los
/// servicios (`webConfig.serviciosWeb`): título y texto de la portada, foto
/// del taller, trabajos realizados, videos de consejos y galería. La web
/// (`syncronize-web/src/lib/servicios-web.ts`) no dibuja un bloque vacío.
class ServiciosWebEditor extends StatefulWidget {
  final Map<String, dynamic> valor;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final SubirArchivo subir;

  const ServiciosWebEditor({
    super.key,
    required this.valor,
    required this.onChanged,
    required this.subir,
  });

  @override
  State<ServiciosWebEditor> createState() => _ServiciosWebEditorState();
}

class _ServiciosWebEditorState extends State<ServiciosWebEditor> {
  static const _tipos = ['Antes / después', 'Reparación', 'Mantenimiento', 'Armado', 'Instalación'];

  final _picker = ImagePicker();
  late final TextEditingController _titulo;
  late final TextEditingController _descripcion;
  String? _fotoTaller;
  late List<Map<String, String>> _trabajos;
  late List<Map<String, String>> _consejos;
  late List<String> _galeria;
  bool _subiendo = false;
  double _progreso = 0;

  @override
  void initState() {
    super.initState();
    final v = widget.valor;
    _titulo = TextEditingController(text: v['titulo']?.toString() ?? '');
    _descripcion = TextEditingController(text: v['descripcion']?.toString() ?? '');
    final foto = v['fotoTaller']?.toString() ?? '';
    _fotoTaller = foto.isEmpty ? null : foto;
    _trabajos = _lista(v['trabajos'], const ['url', 'titulo', 'tipo']);
    _consejos = _lista(v['consejos'], const ['url', 'titulo']);
    _galeria = _lista(v['galeria'], const ['url']).map((g) => g['url']!).toList();
  }

  @override
  void dispose() {
    _titulo.dispose();
    _descripcion.dispose();
    super.dispose();
  }

  static List<Map<String, String>> _lista(dynamic raw, List<String> claves) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((m) => {for (final k in claves) k: m[k]?.toString() ?? ''})
        .where((m) => m['url']!.isNotEmpty)
        .toList();
  }

  void _emitir() {
    widget.onChanged({
      'titulo': _titulo.text.trim().isEmpty ? null : _titulo.text.trim(),
      'descripcion': _descripcion.text.trim().isEmpty ? null : _descripcion.text.trim(),
      'fotoTaller': _fotoTaller,
      'trabajos': _trabajos,
      'consejos': _consejos,
      'galeria': [for (final u in _galeria) {'url': u}],
    });
  }

  void _cambiar(VoidCallback f) {
    setState(f);
    _emitir();
  }

  Future<String?> _subir(File file) async {
    setState(() {
      _subiendo = true;
      _progreso = 0;
    });
    try {
      return await widget.subir(file, onProgress: (p) {
        if (mounted) setState(() => _progreso = p);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir: $e'), backgroundColor: Colors.red),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _subiendo = false);
    }
  }

  Future<String?> _elegirFoto() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1920);
    if (picked == null) return null;
    return _subir(File(picked.path));
  }

  Future<void> _agregarTrabajo() async {
    final url = await _elegirFoto();
    if (url == null || !mounted) return;
    final datos = await _dialogoTrabajo(const {'titulo': '', 'tipo': ''});
    _cambiar(() => _trabajos.add({'url': url, ...?datos}));
  }

  Future<Map<String, String>?> _dialogoTrabajo(Map<String, String> actual) {
    final titulo = TextEditingController(text: actual['titulo']);
    String tipo = actual['tipo'] ?? '';
    return showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Trabajo realizado', style: TextStyle(fontSize: 15)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titulo,
                decoration: const InputDecoration(labelText: 'Qué se hizo', hintText: 'Ej: Limpieza de laptop gamer'),
                style: const TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Text('Etiqueta', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final t in ['', ..._tipos])
                    ChoiceChip(
                      label: Text(t.isEmpty ? 'Ninguna' : t, style: const TextStyle(fontSize: 11)),
                      selected: tipo == t,
                      onSelected: (_) => setD(() => tipo = t),
                    ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Omitir')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, {'titulo': titulo.text.trim(), 'tipo': tipo}),
              child: const Text('Listo'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _agregarConsejoArchivo() async {
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    final file = File(picked.path);
    final mb = await file.length() / (1024 * 1024);
    if (mb > 80) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El video pesa ${mb.toStringAsFixed(1)} MB. Máximo 80 MB.'), backgroundColor: Colors.red),
      );
      return;
    }
    final url = await _subir(file);
    if (url == null || !mounted) return;
    final titulo = await _pedirTexto('Título del video', 'Ej: Cómo limpiar el teclado');
    _cambiar(() => _consejos.add({'url': url, 'titulo': titulo ?? ''}));
  }

  Future<void> _agregarConsejoUrl() async {
    final url = await _pedirTexto('Link del video', 'https://www.youtube.com/watch?v=...');
    if (url == null || url.isEmpty || !mounted) return;
    final titulo = await _pedirTexto('Título del video', 'Ej: Cómo limpiar el teclado');
    _cambiar(() => _consejos.add({'url': url, 'titulo': titulo ?? ''}));
  }

  Future<String?> _pedirTexto(String titulo, String hint, [String inicial = '']) {
    final c = TextEditingController(text: inicial);
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(titulo, style: const TextStyle(fontSize: 15)),
        content: TextField(
          controller: c,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, c.text.trim()), child: const Text('Listo')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _titulo,
          onChanged: (_) => _emitir(),
          decoration: const InputDecoration(labelText: 'Título de la página', hintText: 'Nuestros servicios'),
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _descripcion,
          onChanged: (_) => _emitir(),
          minLines: 2,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Texto de presentación',
            hintText: 'Ej: Mantenimiento, reparación y armado de equipos.',
          ),
          style: const TextStyle(fontSize: 13),
        ),

        _encabezado('Foto de la portada', 'El taller, el local o tu equipo de trabajo.'),
        _fotoTaller == null
            ? _botonAgregar('Subir foto', Icons.add_photo_alternate_outlined, () async {
                final url = await _elegirFoto();
                if (url != null) _cambiar(() => _fotoTaller = url);
              })
            : _miniatura(_fotoTaller!, ancho: double.infinity, alto: 120, onQuitar: () => _cambiar(() => _fotoTaller = null)),

        _encabezado('Trabajos realizados', 'Fotos de equipos que atendiste, con lo que se hizo.'),
        if (_trabajos.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _trabajos.length; i++)
                SizedBox(
                  width: 96,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _miniatura(
                        _trabajos[i]['url']!,
                        ancho: 96,
                        alto: 72,
                        onQuitar: () => _cambiar(() => _trabajos.removeAt(i)),
                        onTap: () async {
                          final d = await _dialogoTrabajo(_trabajos[i]);
                          if (d != null) _cambiar(() => _trabajos[i] = {..._trabajos[i], ...d});
                        },
                      ),
                      const SizedBox(height: 2),
                      Text(
                        (_trabajos[i]['titulo'] ?? '').isEmpty ? 'Sin título' : _trabajos[i]['titulo']!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        const SizedBox(height: 6),
        _botonAgregar('Agregar trabajo', Icons.add_photo_alternate_outlined, _agregarTrabajo),

        _encabezado('Consejos en video', 'Videos cortos: limpieza, cuidado de la batería, etc.'),
        for (var i = 0; i < _consejos.length; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.play_arrow_rounded, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final t = await _pedirTexto('Título del video', 'Ej: Cómo limpiar el teclado', _consejos[i]['titulo'] ?? '');
                      if (t != null) _cambiar(() => _consejos[i] = {..._consejos[i], 'titulo': t});
                    },
                    child: Text(
                      (_consejos[i]['titulo'] ?? '').isEmpty ? 'Video ${i + 1} (tocar para poner título)' : _consejos[i]['titulo']!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _cambiar(() => _consejos.removeAt(i)),
                  icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade300),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        Row(
          children: [
            Expanded(child: _botonAgregar('Subir video', Icons.video_camera_back_outlined, _agregarConsejoArchivo)),
            const SizedBox(width: 8),
            Expanded(child: _botonAgregar('Pegar link', Icons.link, _agregarConsejoUrl)),
          ],
        ),

        _encabezado('Galería', 'Fotos del taller y del local. En la web se deslizan.'),
        if (_galeria.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < _galeria.length; i++)
                _miniatura(_galeria[i], ancho: 72, alto: 72, onQuitar: () => _cambiar(() => _galeria.removeAt(i))),
            ],
          ),
        const SizedBox(height: 6),
        _botonAgregar('Agregar foto', Icons.add_photo_alternate_outlined, () async {
          final url = await _elegirFoto();
          if (url != null) _cambiar(() => _galeria.add(url));
        }),

        if (_subiendo) ...[
          const SizedBox(height: 10),
          LinearProgressIndicator(value: _progreso > 0 ? _progreso : null, minHeight: 4),
          const SizedBox(height: 4),
          Text('Subiendo... ${(_progreso * 100).toInt()}%', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ],
    );
  }

  Widget _encabezado(String titulo, String ayuda) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            Text(ayuda, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
          ],
        ),
      );

  Widget _botonAgregar(String texto, IconData icono, VoidCallback onTap) => OutlinedButton.icon(
        onPressed: _subiendo ? null : onTap,
        icon: Icon(icono, size: 16),
        label: Text(texto, style: const TextStyle(fontSize: 11)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

  Widget _miniatura(String url, {required double ancho, required double alto, required VoidCallback onQuitar, VoidCallback? onTap}) {
    return Stack(
      children: [
        GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: url,
              width: ancho,
              height: alto,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(width: ancho, height: alto, color: Colors.grey.shade200),
            ),
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: InkWell(
            onTap: onQuitar,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
              child: const Icon(Icons.close, size: 12, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
