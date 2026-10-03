import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../widgets/archivo_manager_bottom_sheet.dart';

/// Agregar diseños NUEVOS a una colección que ya tiene: a CRISTAL (D1–D3) le
/// llegan dos estampados más y se crean D4 y D5 con su foto.
///
/// Las unidades no salen de ninguna variante. Por defecto los diseños se
/// crean en 0 y entran con la COMPRA (proveedor, factura, costo real); la
/// otra opción es ingresarlas ya, con su costo (queda como entrada de
/// inventario en el kardex, con su lote).
///
/// Las fotos se suben a la variante base de la colección (la original de la
/// que salieron D1–D3, que suele quedar desactivada): es la misma bandeja que
/// usa separar, y si se cancela quedan ahí, sin ensuciar ningún diseño.
///
/// Devuelve `true` si creó diseños (o se subieron fotos), para recargar.
class AgregarDisenosPage extends StatefulWidget {
  /// Cualquier variante de la colección (un diseño o la base).
  final String varianteId;
  final String empresaId;
  final String titulo;

  const AgregarDisenosPage({
    super.key,
    required this.varianteId,
    required this.empresaId,
    required this.titulo,
  });

  @override
  State<AgregarDisenosPage> createState() => _AgregarDisenosPageState();
}

class _Foto {
  final String id;
  final String url;
  const _Foto(this.id, this.url);
}

class _Sede {
  final String id;
  final String nombre;
  final double? costo;
  final double? precio;
  const _Sede(this.id, this.nombre, this.costo, this.precio);
}

class _AgregarDisenosPageState extends State<AgregarDisenosPage> {
  String? _baseId;
  String _baseNombre = '';
  bool _baseActiva = false;
  String _siguiente = 'D1';
  List<_Foto> _fotos = const [];
  List<_Sede> _sedes = const [];
  String? _sedeId;

  /// Fotos elegidas como diseño nuevo.
  final Set<String> _elegidas = {};

  /// Solo con "Ingresar stock ahora".
  final Map<String, int> _cantidades = {};
  bool _ingresarAhora = false;
  final _costoCtrl = TextEditingController();

  /// Precio de venta del diseño: arranca con el de la colección y se puede
  /// cambiar (un diseño exclusivo puede venderse más caro).
  final _precioCtrl = TextEditingController();

  bool _cargando = true;
  bool _enviando = false;
  bool _huboCambios = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  @override
  void dispose() {
    _costoCtrl.dispose();
    _precioCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final resp = await locator<DioClient>().get(
        '${ApiConstants.productos}/variantes/${widget.varianteId}/coleccion-diseno',
      );
      final data = resp.data as Map<String, dynamic>;
      final base = data['base'] as Map<String, dynamic>;
      final fotos = [
        for (final a in (base['archivos'] as List? ?? const []).cast<Map<String, dynamic>>())
          _Foto(a['id'] as String, (a['urlThumbnail'] ?? a['url']) as String),
      ];
      final sedes = [
        for (final s in (data['sedes'] as List? ?? const []).cast<Map<String, dynamic>>())
          _Sede(
            s['sedeId'] as String,
            (s['sedeNombre'] as String?) ?? 'Sede',
            (s['precioCosto'] as num?)?.toDouble(),
            (s['precioVenta'] as num?)?.toDouble(),
          ),
      ];
      if (!mounted) return;
      final primeraVez = _baseId == null;
      setState(() {
        _baseId = base['id'] as String;
        _baseNombre = (base['nombre'] as String?) ?? widget.titulo;
        _baseActiva = base['isActive'] == true;
        _siguiente = (data['siguienteDiseno'] as String?) ?? 'D1';
        _fotos = fotos;
        _sedes = sedes;
        if (_sedeId == null || !_sedes.any((s) => s.id == _sedeId)) {
          _sedeId = _sedes.isNotEmpty ? _sedes.first.id : null;
        }
        // Con la base desactivada, sus fotos son justamente los diseños por
        // crear: arrancan elegidas. Si la base sigue activa (le quedan
        // unidades sin separar), sus fotos son las suyas: se eligen a mano.
        for (final f in _fotos) {
          final nueva = !_cantidades.containsKey(f.id);
          _cantidades.putIfAbsent(f.id, () => 1);
          if (nueva && !_baseActiva) _elegidas.add(f.id);
        }
        _elegidas.removeWhere((id) => !_fotos.any((f) => f.id == id));
        _cantidades.removeWhere((id, _) => !_fotos.any((f) => f.id == id));
        if (primeraVez) _sugerirCosto();
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = _mensajeDeError(e, 'No se pudo cargar la colección');
      });
    }
  }

  /// Costo y precio de venta de la colección en la sede: lo sugerido.
  void _sugerirCosto() {
    final sede = _sedes.where((s) => s.id == _sedeId).firstOrNull;
    final costo = sede?.costo;
    final precio = sede?.precio;
    _costoCtrl.text = costo != null && costo > 0 ? costo.toStringAsFixed(2) : '';
    _precioCtrl.text = precio != null && precio > 0 ? precio.toStringAsFixed(2) : '';
  }

  Future<void> _gestionarFotos() async {
    final baseId = _baseId;
    if (baseId == null) return;
    final storage = locator<StorageService>();
    final existentes = await storage.getFilesByEntity(
      empresaId: widget.empresaId,
      entidadTipo: 'PRODUCTO_VARIANTE',
      entidadId: baseId,
    );
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArchivoManagerBottomSheet(
        entidadId: baseId,
        entidadNombre: _baseNombre,
        entidadTipo: 'PRODUCTO_VARIANTE',
        empresaId: widget.empresaId,
        storageService: storage,
        archivosExistentes: [
          for (final a in existentes)
            ArchivoItem(
              id: a.id,
              url: a.url,
              urlThumbnail: a.urlThumbnail,
              nombreOriginal: a.nombreOriginal,
              tipoArchivo: a.mimeType.startsWith('image/')
                  ? TipoArchivo.imagen
                  : TipoArchivo.otro,
            ),
        ],
      ),
    );
    _huboCambios = true;
    await _cargar();
  }

  List<_Foto> get _disenos => _fotos.where((f) => _elegidas.contains(f.id)).toList();

  double? get _costo => double.tryParse(_costoCtrl.text.replaceAll(',', '.'));
  double? get _precio => double.tryParse(_precioCtrl.text.replaceAll(',', '.'));

  /// Cómo se van a llamar: D4, D5… (el backend numera igual).
  String _rango(int n) {
    final base = int.tryParse(_siguiente.replaceAll(RegExp(r'^\D+'), '')) ?? 1;
    final pref = _siguiente.replaceAll(RegExp(r'\d+$'), '');
    return n == 1 ? '$pref$base' : '$pref$base–$pref${base + n - 1}';
  }

  Future<void> _crear() async {
    final sede = _sedeId;
    final baseId = _baseId;
    if (sede == null || baseId == null) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final resp = await locator<DioClient>().post(
        '${ApiConstants.productos}/variantes/$baseId/agregar-disenos',
        data: {
          'sedeId': sede,
          'disenos': [
            for (final f in _disenos)
              {
                'archivoId': f.id,
                'cantidad': _ingresarAhora ? (_cantidades[f.id] ?? 0) : 0,
                if (_ingresarAhora && _costo != null) 'costoUnitario': _costo,
                if (_ingresarAhora && _precio != null) 'precioVenta': _precio,
              },
          ],
        },
      );
      final data = resp.data as Map<String, dynamic>;
      if (!mounted) return;
      await _mostrarResultado(data);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _enviando = false;
        _error = _mensajeDeError(e, 'No se pudieron crear los diseños');
      });
    }
  }

  String _mensajeDeError(Object e, String porDefecto) {
    if (e is! DioException) return e.toString();
    final body = e.response?.data;
    if (body is Map<String, dynamic> && body['message'] != null) {
      return body['message'].toString();
    }
    return e.message ?? porDefecto;
  }

  Future<void> _mostrarResultado(Map<String, dynamic> data) {
    final disenos = (data['disenos'] as List? ?? const []).cast<Map<String, dynamic>>();
    final n = disenos.length;
    return StyledDialog.show<void>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.photo_library_outlined,
      titulo: '$n diseño${n == 1 ? '' : 's'} nuevo${n == 1 ? '' : 's'}',
      subtitulo: widget.titulo,
      backgroundColor: Colors.white,
      barrierDismissible: false,
      content: [
        for (final d in disenos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: AppSubtitle('${d['nombre']}', fontSize: 11, color: Colors.grey.shade800),
                ),
                const SizedBox(width: 8),
                AppSubtitle(
                  '${d['cantidad']} und.',
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        AppSubtitle(
          _ingresarAhora
              ? 'Las unidades entraron como ingreso de inventario.'
              : 'Quedaron en 0: las unidades entran al registrar la compra.',
          fontSize: 10,
          color: Colors.grey.shade600,
        ),
      ],
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Listo',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final n = _disenos.length;
    final faltaCosto = _ingresarAhora && (_costo == null);
    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: const Text('Agregar diseños', style: TextStyle(fontSize: 16)),
          leading: BackButton(
            onPressed: _enviando ? null : () => Navigator.pop(context, _huboCambios),
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  AppSubtitle(widget.titulo,
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.blue1),
                  const SizedBox(height: 2),
                  AppSubtitle(
                    'Una foto = un diseño nuevo. El siguiente es $_siguiente; copian el precio '
                    'y los precios por mayor de la colección.',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  if (_sedes.length > 1) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _sedeId,
                      decoration: const InputDecoration(
                        labelText: 'Sede',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final s in _sedes)
                          DropdownMenuItem(
                            value: s.id,
                            child: Text(s.nombre, style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        _sedeId = v;
                        _sugerirCosto();
                      }),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppSubtitle('1. FOTOS DE LOS DISEÑOS NUEVOS',
                            fontSize: 10, color: Colors.grey.shade700),
                      ),
                      TextButton.icon(
                        onPressed: _enviando ? null : _gestionarFotos,
                        icon: const Icon(Icons.add_photo_alternate_outlined, size: 18),
                        label: Text(_fotos.isEmpty ? 'Subir fotos' : 'Agregar / quitar'),
                      ),
                    ],
                  ),
                  if (_fotos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: AppSubtitle('Subí una foto por cada diseño que llegó.',
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    )
                  else ...[
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: _ingresarAhora ? 0.72 : 0.9,
                      children: [for (final f in _fotos) _tarjetaFoto(f)],
                    ),
                    const SizedBox(height: 16),
                    AppSubtitle('2. ¿CÓMO ENTRAN LAS UNIDADES?',
                        fontSize: 10, color: Colors.grey.shade700),
                    const SizedBox(height: 6),
                    _opcion(
                      valor: false,
                      titulo: 'Crear en 0',
                      detalle: 'Las unidades entran al registrar la compra.',
                    ),
                    _opcion(
                      valor: true,
                      titulo: 'Ingresar stock ahora',
                      detalle: 'Entrada de inventario con su costo (sin compra).',
                    ),
                    if (_ingresarAhora) ...[
                      const SizedBox(height: 10),
                      // Los dos sugeridos con los de la colección; el costo
                      // puede ser igual o mayor, y el precio se sube si el
                      // diseño es exclusivo.
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomText(
                              controller: _costoCtrl,
                              label: 'Costo unitario',
                              prefixText: 'S/ ',
                              hintText: '0.00',
                              borderColor: AppColors.blue1,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: CustomText(
                              controller: _precioCtrl,
                              label: 'Precio de venta',
                              prefixText: 'S/ ',
                              hintText: '0.00',
                              borderColor: AppColors.blue1,
                              keyboardType:
                                  const TextInputType.numberWithOptions(decimal: true),
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                              ],
                              onChanged: (_) => setState(() {}),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      AppSubtitle(
                        'Sugeridos: los de la colección. El precio aplica a los '
                        'diseños de este ingreso.',
                        fontSize: 10,
                        color: Colors.grey.shade600,
                      ),
                    ],
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    AppSubtitle(_error!, fontSize: 12, color: AppColors.red),
                  ],
                ],
              ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blue1,
                minimumSize: const Size.fromHeight(46),
              ),
              onPressed:
                  _cargando || _enviando || n == 0 || _sedeId == null || faltaCosto ? null : _crear,
              child: Text(
                _enviando
                    ? 'Creando…'
                    : n == 0
                        ? 'Elegí al menos una foto'
                        : 'Crear $n diseño${n == 1 ? '' : 's'} (${_rango(n)})',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _opcion({required bool valor, required String titulo, required String detalle}) {
    final elegida = _ingresarAhora == valor;
    return InkWell(
      onTap: _enviando ? null : () => setState(() => _ingresarAhora = valor),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: elegida ? AppColors.blue1.withValues(alpha: 0.06) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: elegida ? AppColors.blue1 : Colors.grey.shade300,
            width: elegida ? 1.2 : 0.6,
          ),
        ),
        child: Row(
          children: [
            Icon(elegida ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 18, color: elegida ? AppColors.blue1 : Colors.grey.shade400),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSubtitle(titulo, fontSize: 12, fontWeight: FontWeight.w700),
                  AppSubtitle(detalle, fontSize: 10, color: Colors.grey.shade600),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tarjetaFoto(_Foto f) {
    final elegida = _elegidas.contains(f.id);
    final cantidad = _cantidades[f.id] ?? 1;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: elegida ? AppColors.blue1 : Colors.grey.shade300,
          width: elegida ? 1.4 : 0.6,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _enviando
                  ? null
                  : () => setState(() => elegida ? _elegidas.remove(f.id) : _elegidas.add(f.id)),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: CachedNetworkImage(
                      imageUrl: f.url,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(color: Colors.grey.shade100),
                      errorWidget: (_, __, ___) => Container(color: Colors.grey.shade200),
                    ),
                  ),
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Icon(
                      elegida ? Icons.check_circle : Icons.radio_button_unchecked,
                      size: 18,
                      color: elegida ? AppColors.blue1 : Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_ingresarAhora && elegida) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _boton(Icons.remove, cantidad > 1,
                    () => setState(() => _cantidades[f.id] = cantidad - 1)),
                AppSubtitle('$cantidad',
                    fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blue1),
                _boton(Icons.add, true, () => setState(() => _cantidades[f.id] = cantidad + 1)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _boton(IconData icono, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled && !_enviando ? onTap : null,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icono, size: 18, color: enabled ? AppColors.blue1 : Colors.grey.shade300),
      ),
    );
  }
}
