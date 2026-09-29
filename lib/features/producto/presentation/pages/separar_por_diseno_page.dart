import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../data/models/producto_variante_model.dart';
import '../../domain/entities/producto_variante.dart';
import '../../domain/entities/stock_por_sede_info.dart';
import '../widgets/archivo_manager_bottom_sheet.dart';

/// Clave del atributo que marca a una variante como UN diseño.
const String kClaveAtributoDiseno = 'diseno';

bool esVarianteDiseno(ProductoVariante v) =>
    v.atributosValores.any((a) => a.atributo.clave == kClaveAtributoDiseno);

/// Separar una variante por diseño: una foto = un diseño = una variante con su
/// propio stock. Paridad con el diálogo de la web.
///
/// El caso que lo pidió: "KITTY" tiene 10 edredones con 8 estampados
/// distintos. Se suben las fotos acá, se dice cuántos hay de cada una, y el
/// backend crea "… / KITTY / D1" … "D8" con su foto, su precio y sus unidades
/// —con el lote de compra de cada una—.
///
/// Devuelve `true` si separó (o si se subieron fotos), para recargar la lista.
class SepararPorDisenoPage extends StatefulWidget {
  final ProductoVariante variante;
  final String empresaId;
  final String? sedeId;

  const SepararPorDisenoPage({
    super.key,
    required this.variante,
    required this.empresaId,
    this.sedeId,
  });

  @override
  State<SepararPorDisenoPage> createState() => _SepararPorDisenoPageState();
}

class _Foto {
  final String id;
  final String url;
  const _Foto(this.id, this.url);
}

class _SepararPorDisenoPageState extends State<SepararPorDisenoPage> {
  List<_Foto> _fotos = const [];
  final Map<String, int> _cantidades = {};
  List<StockPorSedeInfo> _stocks = const [];
  String? _sedeId;
  bool _cargando = true;
  bool _enviando = false;
  bool _huboCambios = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _stocks = widget.variante.stocksPorSede ?? const [];
    _sedeId = widget.sedeId;
    _cargar();
  }

  /// Se recarga la variante: la fila de la lista puede no traer la galería
  /// completa, y separar con media galería dejaría diseños afuera.
  Future<void> _cargar() async {
    setState(() => _cargando = true);
    try {
      final resp = await locator<DioClient>().get(
        '${ApiConstants.productos}/variantes/${widget.variante.id}',
      );
      final v = ProductoVarianteModel.fromJson(
          resp.data as Map<String, dynamic>);
      if (!mounted) return;
      setState(() {
        _fotos = [
          for (final a in v.archivos ?? const <ProductoVarianteArchivo>[])
            _Foto(a.id, a.urlThumbnail ?? a.url),
        ];
        // Las nuevas arrancan en 1; las que ya tenían cantidad la conservan.
        for (final f in _fotos) {
          _cantidades.putIfAbsent(f.id, () => 1);
        }
        _cantidades.removeWhere((id, _) => !_fotos.any((f) => f.id == id));
        _stocks = v.stocksPorSede ?? _stocks;
        if (_stocks.isNotEmpty && !_stocks.any((s) => s.sedeId == _sedeId)) {
          _sedeId = _stocks.first.sedeId;
        }
        _cargando = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cargando = false;
        _error = 'No se pudo cargar la variante';
      });
    }
  }

  /// Subir o quitar fotos con el mismo gestor que el resto del app.
  Future<void> _gestionarFotos() async {
    final storage = locator<StorageService>();
    final existentes = await storage.getFilesByEntity(
      empresaId: widget.empresaId,
      entidadTipo: 'PRODUCTO_VARIANTE',
      entidadId: widget.variante.id,
    );
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ArchivoManagerBottomSheet(
        entidadId: widget.variante.id,
        entidadNombre: widget.variante.nombre,
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

  int get _disponible =>
      _stocks.where((s) => s.sedeId == _sedeId).firstOrNull?.cantidad ?? 0;
  int get _asignadas => _fotos.fold(0, (a, f) => a + (_cantidades[f.id] ?? 0));
  List<_Foto> get _disenos =>
      _fotos.where((f) => (_cantidades[f.id] ?? 0) > 0).toList();

  Future<void> _separar() async {
    final sede = _sedeId;
    if (sede == null) return;
    setState(() {
      _enviando = true;
      _error = null;
    });
    try {
      final resp = await locator<DioClient>().post(
        '${ApiConstants.productos}/variantes/${widget.variante.id}/separar-por-diseno',
        data: {
          'sedeId': sede,
          'disenos': [
            for (final f in _disenos)
              {'archivoId': f.id, 'cantidad': _cantidades[f.id]},
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
        _error = _mensajeDeError(e);
      });
    }
  }

  String _mensajeDeError(Object e) {
    if (e is! DioException) return e.toString();
    final body = e.response?.data;
    if (body is Map<String, dynamic> && body['message'] != null) {
      return body['message'].toString();
    }
    return e.message ?? 'No se pudo separar la variante';
  }

  Future<void> _mostrarResultado(Map<String, dynamic> data) {
    final disenos = (data['disenos'] as List? ?? const [])
        .cast<Map<String, dynamic>>();
    final desactivada = data['origenDesactivada'] == true;
    final restante = (data['stockRestante'] as num?)?.toInt() ?? 0;
    return StyledDialog.show<void>(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.photo_library_outlined,
      titulo:
          '${disenos.length} diseño${disenos.length == 1 ? '' : 's'} creado${disenos.length == 1 ? '' : 's'}',
      subtitulo: widget.variante.nombre,
      backgroundColor: Colors.white,
      barrierDismissible: false,
      content: [
        for (final d in disenos)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Expanded(
                  child: AppSubtitle(
                    '${d['nombre']}',
                    fontSize: 11,
                    color: Colors.grey.shade800,
                  ),
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
          desactivada
              ? 'La variante original quedó sin stock y se desactivó.'
              : 'En la variante original quedan $restante und. sin diseño.',
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
    final excede = _asignadas > _disponible;
    final n = _disenos.length;
    return PopScope(
      canPop: !_enviando,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F8FB),
        appBar: AppBar(
          title: const Text('Separar por diseño', style: TextStyle(fontSize: 16)),
          leading: BackButton(
            onPressed: _enviando
                ? null
                : () => Navigator.pop(context, _huboCambios),
          ),
        ),
        body: _cargando
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  AppSubtitle(
                    widget.variante.nombre,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                  const SizedBox(height: 2),
                  AppSubtitle(
                    'Cada foto es un diseño con su propio stock.',
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  if (_stocks.length > 1) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _sedeId,
                      decoration: const InputDecoration(
                        labelText: 'Sede',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (final s in _stocks)
                          DropdownMenuItem(
                            value: s.sedeId,
                            child: Text('${s.sedeNombre} (${s.cantidad} und.)',
                                style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                      onChanged: (v) => setState(() => _sedeId = v),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: AppSubtitle(
                          '1. FOTOS (UNA POR DISEÑO)',
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _enviando ? null : _gestionarFotos,
                        icon: const Icon(Icons.add_photo_alternate_outlined,
                            size: 18),
                        label: Text(_fotos.isEmpty ? 'Subir fotos' : 'Agregar / quitar'),
                      ),
                    ],
                  ),
                  if (_fotos.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: AppSubtitle(
                          'La variante no tiene fotos. Subí una por cada diseño.',
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                  else ...[
                    const SizedBox(height: 4),
                    AppSubtitle(
                      '2. ¿CUÁNTAS UNIDADES HAY DE CADA DISEÑO?',
                      fontSize: 10,
                      color: Colors.grey.shade700,
                    ),
                    const SizedBox(height: 8),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.72,
                      children: [for (final f in _fotos) _tarjetaFoto(f)],
                    ),
                    const SizedBox(height: 12),
                    AppSubtitle(
                      'Asignadas $_asignadas de $_disponible und. en stock'
                      '${excede ? ' · asignaste más de las que hay' : (_asignadas < _disponible ? ' · ${_disponible - _asignadas} quedan en la original' : '')}',
                      fontSize: 12,
                      fontWeight: excede ? FontWeight.w700 : FontWeight.w500,
                      color: excede ? AppColors.red : AppColors.blue1,
                    ),
                    const SizedBox(height: 4),
                    AppSubtitle(
                      'Con 0 la foto no se separa y queda en la original. Cada '
                      'diseño se llama como la variante más D1, D2… y copia su '
                      'precio y costo.',
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
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
              onPressed: _cargando || _enviando || n == 0 || excede || _sedeId == null
                  ? null
                  : _separar,
              child: Text(
                _enviando
                    ? 'Separando…'
                    : 'Separar en $n diseño${n == 1 ? '' : 's'}',
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tarjetaFoto(_Foto f) {
    final cantidad = _cantidades[f.id] ?? 0;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: cantidad > 0 ? AppColors.blue1 : Colors.grey.shade300,
          width: cantidad > 0 ? 1.4 : 0.6,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: f.url,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: Colors.grey.shade100),
                errorWidget: (_, __, ___) =>
                    Container(color: Colors.grey.shade200),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _boton(Icons.remove, cantidad > 0,
                  () => setState(() => _cantidades[f.id] = cantidad - 1)),
              AppSubtitle(
                '$cantidad',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cantidad > 0 ? AppColors.blue1 : Colors.grey.shade500,
              ),
              _boton(Icons.add, true,
                  () => setState(() => _cantidades[f.id] = cantidad + 1)),
            ],
          ),
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
        child: Icon(
          icono,
          size: 18,
          color: enabled ? AppColors.blue1 : Colors.grey.shade300,
        ),
      ),
    );
  }
}
