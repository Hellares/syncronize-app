/// Arma un catálogo de varios productos y lo comparte en PDF.
///
/// El caso: el cliente pregunta por edredones. Se busca EDREDONES, entran sus
/// variantes CON STOCK ya tildadas, se destildan las que no van, se agregan
/// otros productos si hace falta y sale un PDF con foto, precio y
/// características de cada uno.
///
/// 🔴 Las variantes SIN stock también se listan, en gris y destildadas: sirven
/// para ofrecer lo que se trae por encargo, pero no entran solas.
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/identidad_comercial.dart';
import '../../../../core/services/whatsapp_cliente_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/domain/entities/empresa_info.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../producto/domain/entities/producto.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/domain/usecases/get_producto_usecase.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_state.dart';
import '../services/catalogo_pdf.dart';

/// Tope duro de ítems. Existe para que un descuido no arme un PDF de mil
/// páginas, no para acotar un catálogo real: un producto con 91 variantes
/// tiene que entrar entero.
///
/// 🔑 Las fotos se descargan SIN REPETIR (`descargarImagenes` deduplica por
/// URL), y las variantes de un mismo producto suelen compartir la del padre:
/// 91 variantes con una sola foto son UNA descarga, no 91.
const int _maxItems = 200;

/// A partir de acá se avisa antes de armar: son muchas páginas y, si cada
/// variante trae su propia foto, unos cuantos MB.
const int _avisarDesde = 60;

class CatalogoCompartirPage extends StatefulWidget {
  final String sedeId;

  const CatalogoCompartirPage({super.key, required this.sedeId});

  static Future<void> show(BuildContext context, {required String sedeId}) {
    return Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CatalogoCompartirPage(sedeId: sedeId)),
    );
  }

  @override
  State<CatalogoCompartirPage> createState() => _CatalogoCompartirPageState();
}

class _CatalogoCompartirPageState extends State<CatalogoCompartirPage> {
  final List<ItemCatalogo> _items = [];
  bool _incluirPrecio = true;
  bool _incluirCaracteristicas = true;
  bool _incluirCodigo = true;

  bool _trabajando = false;
  String _progreso = '';

  /// Lo que de verdad va a salir: un ítem con varias fotos elegidas aporta una
  /// tarjeta por foto. Los topes y los avisos cuentan TARJETAS.
  int get _tarjetas => tarjetasDe(_items).length;

  EmpresaInfo? get _empresa {
    final estado = context.read<EmpresaContextCubit>().state;
    if (estado is! EmpresaContextLoaded) return null;
    return estado.context.empresa;
  }

  /// La sede del catálogo: su nombre y dirección van al membrete, como en la
  /// cotización —la dirección del documento es la de la SEDE, no la fiscal—.
  ({String? nombre, String? direccion}) get _sede {
    final estado = context.read<EmpresaContextCubit>().state;
    if (estado is! EmpresaContextLoaded) return (nombre: null, direccion: null);
    for (final s in estado.context.sedes) {
      if (s.id == widget.sedeId) return (nombre: s.nombre as String?, direccion: s.direccion);
    }
    return (nombre: null, direccion: null);
  }

  // ─────────────────────────── Agregar productos ───────────────────────────

  Future<void> _buscarYAgregar() async {
    final empresa = _empresa;
    if (empresa == null) return;
    // Devuelve IDS: lo que lista el buscador son `ProductoListItem`, la forma
    // liviana del listado, y la ficha completa se pide aparte por cada uno.
    final ids = await showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BuscadorProductos(empresaId: empresa.id, sedeId: widget.sedeId),
    );
    if (ids == null || ids.isEmpty || !mounted) return;
    for (var i = 0; i < ids.length; i++) {
      if (!mounted) return;
      setState(() => _progreso = 'Cargando ${i + 1} de ${ids.length}…');
      await _agregarProducto(ids[i], empresa.id);
    }
  }

  /// Trae la ficha COMPLETA: la card del buscador no tiene atributos ni
  /// variantes, y sin eso el catálogo saldría sin características.
  Future<void> _agregarProducto(String productoId, String empresaId) async {
    setState(() => _trabajando = true);
    try {
      final res = await locator<GetProductoUseCase>()(
        productoId: productoId,
        empresaId: empresaId,
      );
      if (!mounted || res is! Success<Producto>) return;
      final p = res.data;

      final nuevos = <ItemCatalogo>[];
      final variantes = p.variantes ?? const [];
      if (p.tieneVariantes && variantes.isNotEmpty) {
        for (final v in variantes) {
          // 🔴 Miniaturas: el catálogo las mete en 4 cm y las de tamaño
          // completo solo engordan el PDF.
          final propias = v.fotos(miniaturas: true);
          nuevos.add(ItemCatalogo(
            id: v.id,
            titulo: v.nombre,
            codigo: v.codigoEmpresa,
            // La variante no tiene descripción propia: va la del padre.
            descripcion: p.descripcion,
            // Sin fotos propias hereda las del padre, como en la lista.
            fotos: propias.isNotEmpty ? propias : p.fotos(miniaturas: true),
            precio: v.precioEfectivoEnSede(widget.sedeId) ?? 0,
            stock: (v.stockEnSede(widget.sedeId) ?? 0).toDouble(),
            caracteristicas: _caracteristicas(v.atributosValores),
          ));
        }
      } else {
        nuevos.add(ItemCatalogo(
          id: p.id,
          titulo: p.nombre,
          codigo: p.codigoEmpresa,
          descripcion: p.descripcion,
          fotos: p.fotos(miniaturas: true),
          precio: p.precioEfectivoEnSede(widget.sedeId) ?? 0,
          stock: (p.stockEnSede(widget.sedeId) ?? 0).toDouble(),
          caracteristicas: _caracteristicas(p.atributosValores ?? const []),
        ));
      }

      // Sin repetidos: agregar dos veces el mismo producto no duplica su ficha.
      final yaEstan = _items.map((i) => i.id).toSet();
      final aSumar = nuevos.where((n) => !yaEstan.contains(n.id)).toList();
      final espacio = _maxItems - _items.length;

      setState(() {
        _items.addAll(aSumar.take(espacio < 0 ? 0 : espacio));
      });

      if (!mounted) return;
      if (aSumar.length > espacio) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('El catálogo llega hasta $_maxItems ítems.')),
        );
      }
    } finally {
      if (mounted) setState(() { _trabajando = false; _progreso = ''; });
    }
  }

  List<(String, String)> _caracteristicas(List<dynamic> valores) {
    return [
      for (final av in valores)
        if ((av.valor as String).trim().isNotEmpty)
          (av.atributo.nombre as String, av.valor as String),
    ];
  }

  // ───────────────────────────── Armar y enviar ────────────────────────────

  /// Comparte el catálogo por el menú del sistema: sirve para cualquier app y
  /// para elegir el contacto ahí.
  Future<void> _armarYCompartir() async {
    final armado = await _armarPdf();
    if (armado == null) return;
    await Share.shareXFiles(
      [XFile(armado.archivo.path)],
      text: 'Catálogo de ${armado.marca}',
    );
  }

  /// Lo manda por WhatsApp a un número que se escribe en el momento: quien
  /// pregunta por un producto no siempre es un cliente cargado.
  Future<void> _armarYEnviarPorWhatsapp() async {
    final empresa = _empresa;
    if (empresa == null) return;
    final armado = await _armarPdf();
    if (armado == null || !mounted) return;

    await WhatsappClienteService.compartirArchivo(
      context,
      empresaId: empresa.id,
      archivo: armado.archivo,
      nombreArchivo: 'catalogo_${armado.marca.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_')}.pdf',
      esPdf: true,
      detalleAdjunto:
          '${armado.productos} ${armado.productos == 1 ? 'producto' : 'productos'} · ${armado.peso}',
      textoInicial: 'Hola, te comparto nuestro catálogo de *${armado.marca}*.',
      // El respaldo real del archivo cuando la empresa no tiene su línea
      // vinculada: el enlace de WhatsApp no lleva adjuntos.
      compartirNativo: () => Share.shareXFiles(
        [XFile(armado.archivo.path)],
        text: 'Catálogo de ${armado.marca}',
      ),
    );
  }

  /// Arma el PDF y lo deja en un archivo temporal. null si se canceló o falló.
  Future<({File archivo, String marca, int productos, String peso})?>
      _armarPdf() async {
    final empresa = _empresa;
    if (empresa == null || _tarjetas == 0) return null;

    // Con muchos ítems se avisa y se deja decidir, en vez de recortar en
    // silencio o dejar la pantalla colgada un minuto sin explicación.
    if (_tarjetas >= _avisarDesde) {
      final seguir = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Catálogo grande', style: TextStyle(fontSize: 15)),
          content: Text(
            'Son $_tarjetas tarjetas: unas ${(_tarjetas / 4).ceil()} páginas. '
            'Si cada uno tiene su propia foto puede tardar y pesar bastante.',
            style: const TextStyle(fontSize: 12),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Armar igual')),
          ],
        ),
      );
      if (seguir != true || !mounted) return null;
    }

    setState(() { _trabajando = true; _progreso = 'Descargando imágenes…'; });
    try {
      final elegidos = _items.where((i) => i.elegido).toList();
      // 🔴 El membrete va con el NOMBRE COMERCIAL, el logo y el color que la
      // empresa configuró para sus documentos: `empresa.nombre` es la razón
      // social ("JAYLI FLORES S.A.C." cuando la marca es "JAYLILAND").
      final identidad = await resolverIdentidadComercial(
        empresa: empresa,
        sedeId: widget.sedeId,
      );
      final logoUrl = identidad.logoUrl ?? '';
      final imagenes = await descargarImagenes(
        [
          ...tarjetasDe(_items).map((t) => t.fotoUrl ?? ''),
          // El logo baja con las fotos: en el PDF tampoco puede ser una URL.
          logoUrl,
        ].where((u) => u.isNotEmpty),
        onProgreso: (listas, total) {
          if (mounted) setState(() => _progreso = 'Imágenes $listas de $total…');
        },
      );

      if (!mounted) return null;
      setState(() => _progreso = 'Armando el PDF…');
      final bytes = await construirCatalogoPdf(
        items: elegidos,
        empresaNombre: identidad.nombre,
        empresaTelefono: identidad.telefono,
        empresaRuc: identidad.ruc,
        empresaDireccion: identidad.direccion,
        sedeNombre: _sede.nombre,
        sedeDireccion: _sede.direccion,
        logo: imagenes[logoUrl],
        colorPrimario: identidad.colorPdf,
        textoPie: identidad.textoPie,
        imagenes: imagenes,
        incluirPrecio: _incluirPrecio,
        incluirCaracteristicas: _incluirCaracteristicas,
        incluirCodigo: _incluirCodigo,
      );

      final dir = await getTemporaryDirectory();
      final archivo = File('${dir.path}/catalogo_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await archivo.writeAsBytes(bytes);

      return (
        archivo: archivo,
        marca: identidad.nombre,
        productos: elegidos.length,
        peso: _peso(bytes.length),
      );
    } catch (e) {
      if (!mounted) return null;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo armar el catálogo: $e'), backgroundColor: Colors.red),
      );
      return null;
    } finally {
      if (mounted) setState(() { _trabajando = false; _progreso = ''; });
    }
  }

  static String _peso(int bytes) => bytes < 1024 * 1024
      ? '${(bytes / 1024).round()} KB'
      : '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';

  // ──────────────────────────────── Pantalla ───────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEEF2F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Catálogo para compartir', style: TextStyle(fontSize: 15)),
        actions: [
          if (_items.isNotEmpty)
            TextButton(
              onPressed: _trabajando ? null : () => setState(_items.clear),
              child: const Text('Vaciar', style: TextStyle(fontSize: 12)),
            ),
        ],
      ),
      body: Column(
        children: [
          if (_trabajando)
            LinearProgressIndicator(minHeight: 2, color: AppColors.blue1),
          Expanded(
            child: _items.isEmpty ? _vacio() : _lista(),
          ),
          _barraInferior(),
        ],
      ),
    );
  }

  Widget _vacio() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.collections_bookmark_outlined, size: 44, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text('Todavía no agregaste productos',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
            const SizedBox(height: 4),
            Text(
              'Buscá un producto y, si tiene variantes, entran las que tienen stock.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lista() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      itemCount: _items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (_, i) {
        final it = _items[i];
        final sinStock = it.stock <= 0;
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
          CheckboxListTile(
            dense: true,
            value: it.elegido,
            onChanged: _trabajando ? null : (v) => setState(() => it.elegido = v ?? false),
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: AppColors.blue1,
            title: Text(
              it.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                // 🔴 Lo que no tiene stock se ve distinto ANTES de mandarlo.
                color: sinStock ? Colors.grey.shade500 : Colors.grey.shade900,
              ),
            ),
            subtitle: Text(
              [
                'S/ ${it.precio.toStringAsFixed(2)}',
                sinStock ? 'sin stock' : 'stock ${it.stock.toStringAsFixed(0)}',
                if (it.caracteristicas.isNotEmpty) '${it.caracteristicas.length} caract.',
              ].join('  ·  '),
              style: TextStyle(fontSize: 10, color: sinStock ? Colors.amber.shade800 : Colors.grey.shade600),
            ),
            secondary: SizedBox(
              width: 38, height: 38,
              child: (it.fotoPrincipal ?? '').isEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.image_not_supported_outlined,
                          size: 16, color: Colors.grey.shade400),
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(it.fotoPrincipal!, fit: BoxFit.cover),
                    ),
            ),
          ),
          // 🔴 Con VARIAS fotos, cada una es un color o un dibujo del mismo
          // producto: sale una tarjeta por foto tildada, con los mismos datos.
          // Acá se elige cuáles van.
          if (it.fotos.length > 1) _tiraDeFotos(it),
            ],
          ),
        );
      },
    );
  }

  /// Las fotos del ítem, para elegir cuáles salen.
  Widget _tiraDeFotos(ItemCatalogo it) {
    final elegidas = it.fotos.where((f) => f.elegida).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(52, 0, 10, 8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 44,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: it.fotos.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) {
                  final f = it.fotos[i];
                  return GestureDetector(
                    onTap: _trabajando
                        ? null
                        : () => setState(() => f.elegida = !f.elegida),
                    child: Opacity(
                      opacity: f.elegida ? 1 : .35,
                      child: Container(
                        width: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: f.elegida ? AppColors.blue1 : Colors.grey.shade300,
                            width: f.elegida ? 2 : 1,
                          ),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.network(f.url, fit: BoxFit.cover),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            elegidas > 1 ? '$elegidas tarjetas' : '1 tarjeta',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _barraInferior() {
    return Container(
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
                _chip('Precio', _incluirPrecio, (v) => setState(() => _incluirPrecio = v)),
                _chip('Características', _incluirCaracteristicas, (v) => setState(() => _incluirCaracteristicas = v)),
                _chip('Código', _incluirCodigo, (v) => setState(() => _incluirCodigo = v)),
              ],
            ),
            const SizedBox(height: 8),
            if (_progreso.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(_progreso, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _trabajando ? null : _buscarYAgregar,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Agregar productos', style: TextStyle(fontSize: 12)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.blue1,
                      side: BorderSide(color: AppColors.blue1),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (_trabajando || _tarjetas == 0) ? null : _armarYCompartir,
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 16),
                    label: Text('Compartir ($_tarjetas)', style: const TextStyle(fontSize: 12)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // A un número puntual: con la línea de la empresa vinculada el PDF
            // sale solo; si no, se abre WhatsApp con el texto.
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: (_trabajando || _tarjetas == 0)
                    ? null
                    : _armarYEnviarPorWhatsapp,
                icon: const Icon(Icons.send, size: 16),
                label: const Text('Enviar por WhatsApp',
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
      ),
    );
  }

  Widget _chip(String texto, bool valor, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(texto, style: const TextStyle(fontSize: 11)),
      selected: valor,
      onSelected: _trabajando ? null : onChanged,
      selectedColor: AppColors.blue1.withValues(alpha: .12),
      checkmarkColor: AppColors.blue1,
      labelStyle: TextStyle(fontSize: 11, color: valor ? AppColors.blue1 : Colors.grey.shade600),
      side: BorderSide(color: valor ? AppColors.blue1 : Colors.grey.shade300),
    );
  }
}

/// El MISMO buscador de la calculadora de precios: filtra el catálogo local al
/// instante y, en paralelo, le pregunta al server —el catálogo local se llena
/// por lotes en background y puede no tener todavía lo que se busca—.
///
/// Acá suma selección MÚLTIPLE: se tildan varios y recién al confirmar se
/// cierra devolviendo los ids. Antes cada elección cerraba el sheet y había que
/// volver a abrirlo por cada producto.
class _BuscadorProductos extends StatefulWidget {
  final String empresaId;
  final String sedeId;

  const _BuscadorProductos({required this.empresaId, required this.sedeId});

  @override
  State<_BuscadorProductos> createState() => _BuscadorProductosState();
}

class _BuscadorProductosState extends State<_BuscadorProductos> {
  final _ctrl = TextEditingController();
  late final ProductoListCubit _cubit;
  Timer? _debounceServer;
  String _query = '';
  String? _queryServer;
  final Set<String> _elegidos = {};

  @override
  void initState() {
    super.initState();
    _cubit = locator<ProductoListCubit>();
    _cubit.loadProductos(
      empresaId: widget.empresaId,
      sedeId: widget.sedeId,
      filtros: const ProductoFiltros(isActive: true, esInsumo: false),
    );
  }

  @override
  void dispose() {
    _debounceServer?.cancel();
    _ctrl.dispose();
    _cubit.close();
    super.dispose();
  }

  void _alEscribir(String v) {
    _debounceServer?.cancel();
    final q = v.trim();
    setState(() {
      _query = q;
      _queryServer = null;
    });
    if (q.length < 3) return;
    // Lo local pinta al instante; el server completa lo que el catálogo en
    // memoria todavía no tiene.
    _debounceServer = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || _query != q) return;
      setState(() => _queryServer = q);
      _cubit.loadProductos(
        empresaId: widget.empresaId,
        sedeId: widget.sedeId,
        filtros: ProductoFiltros(search: q, isActive: true, esInsumo: false),
        keepListWhileFiltering: true,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .8,
      minChildSize: .5,
      maxChildSize: .95,
      expand: false,
      builder: (_, scroll) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: CustomSearchField(
                controller: _ctrl,
                borderColor: AppColors.blue1,
                hintText: 'Buscar por nombre o código…',
                debounceDelay: const Duration(milliseconds: 200),
                onChanged: _alEscribir,
                onClear: () => setState(() {
                  _query = '';
                  _queryServer = null;
                }),
              ),
            ),
            Expanded(child: _resultados(scroll)),
            _pie(),
          ],
        ),
      ),
    );
  }

  Widget _resultados(ScrollController scroll) {
    return BlocBuilder<ProductoListCubit, ProductoListState>(
      bloc: _cubit,
      builder: (context, state) {
        if (state is! ProductoListLoaded) {
          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
        }
        final q = _query.toLowerCase();
        final serverListo = _queryServer != null &&
            state.filtros.search == _queryServer &&
            !state.isFiltering;
        final esperandoServer = _queryServer != null && !serverListo;

        // Sin la respuesta del server se filtra LOCAL, que responde al
        // instante. El nombre de la VARIANTE también cuenta: buscar
        // "carnerito" tiene que encontrar el edredón que la tiene.
        final items = (serverListo
                ? state.productos.where((p) => !p.esCombo)
                : state.productos.where((p) =>
                    !p.esCombo &&
                    (q.isEmpty ||
                        p.nombre.toLowerCase().contains(q) ||
                        p.codigoEmpresa.toLowerCase().contains(q) ||
                        (p.variantes ?? [])
                            .any((v) => v.nombre.toLowerCase().contains(q)))))
            .take(40)
            .toList();

        if (items.isEmpty) {
          return Center(
            child: Text(
              // Con el server en vuelo no se afirma "sin resultados": el
              // catálogo local puede no tenerlo todavía.
              esperandoServer ? 'Buscando…' : 'Sin resultados',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          );
        }

        return ListView.builder(
          controller: scroll,
          itemCount: items.length,
          itemBuilder: (_, i) {
            final p = items[i];
            return CheckboxListTile(
              dense: true,
              value: _elegidos.contains(p.id),
              activeColor: AppColors.blue1,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() {
                if (v == true) {
                  _elegidos.add(p.id);
                } else {
                  _elegidos.remove(p.id);
                }
              }),
              secondary: SizedBox(
                width: 34,
                height: 34,
                child: (p.imagenPrincipal ?? '').isEmpty
                    ? Icon(Icons.inventory_2_outlined,
                        size: 18, color: Colors.grey.shade400)
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(5),
                        child: Image.network(p.imagenPrincipal!, fit: BoxFit.cover),
                      ),
              ),
              title: Text(
                p.nombre,
                style: const TextStyle(fontSize: 12),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                p.tieneVariantes
                    ? '${(p.variantes ?? []).length} variantes'
                    : p.codigoEmpresa,
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pie() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Text(
                _elegidos.isEmpty
                    ? 'Tildá los productos que quieras sumar'
                    : '${_elegidos.length} seleccionados',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
            ElevatedButton(
              onPressed: _elegidos.isEmpty
                  ? null
                  : () => Navigator.pop(context, _elegidos.toList()),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
              ),
              child: Text('Agregar (${_elegidos.length})',
                  style: const TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}
