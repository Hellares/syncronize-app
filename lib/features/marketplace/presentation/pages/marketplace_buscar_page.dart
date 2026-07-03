import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/widgets/custom_search_field.dart';

/// Ítem de búsqueda reciente: puede ser un término de texto o un producto
/// concreto (con su imagen) que el usuario abrió desde las sugerencias.
class BusquedaReciente {
  final String tipo; // 'texto' | 'producto'
  final String? texto;
  final String? id;
  final String? nombre;
  final String? imagen;

  const BusquedaReciente({
    required this.tipo,
    this.texto,
    this.id,
    this.nombre,
    this.imagen,
  });

  /// Clave de deduplicación (por término o por producto).
  String get clave =>
      tipo == 'producto' ? 'p:$id' : 't:${(texto ?? '').toLowerCase()}';

  Map<String, dynamic> toJson() =>
      {'tipo': tipo, 'texto': texto, 'id': id, 'nombre': nombre, 'imagen': imagen};

  factory BusquedaReciente.fromJson(Map<String, dynamic> j) => BusquedaReciente(
        tipo: j['tipo'] as String? ?? 'texto',
        texto: j['texto'] as String?,
        id: j['id'] as String?,
        nombre: j['nombre'] as String?,
        imagen: j['imagen'] as String?,
      );
}

/// Página de búsqueda del marketplace con autocomplete.
///
/// Se abre al tocar la barra del home. Mientras el usuario escribe consulta
/// `GET /marketplace/sugerencias` (debounced) y muestra categorías y productos
/// que matchean. Al elegir:
/// - categoría → vuelve al home con `{categoriaId, categoriaNombre}` (filtra)
/// - producto  → navega directo al detalle
/// - texto libre (submit o fila "Buscar X") → vuelve con `{search}` (busca)
class MarketplaceBuscarPage extends StatefulWidget {
  /// Texto inicial (la búsqueda activa en el home, si la hay).
  final String? queryInicial;

  const MarketplaceBuscarPage({super.key, this.queryInicial});

  @override
  State<MarketplaceBuscarPage> createState() => _MarketplaceBuscarPageState();
}

class _MarketplaceBuscarPageState extends State<MarketplaceBuscarPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  List<dynamic> _categorias = [];
  List<dynamic> _productos = [];
  bool _loading = false;
  String _query = '';

  // Búsquedas recientes (persistidas en SharedPreferences como JSON).
  static const _kRecientes = 'marketplace_busquedas_recientes_v2';
  static const _maxRecientes = 12;
  List<BusquedaReciente> _recientes = [];

  @override
  void initState() {
    super.initState();
    _recientes = (locator<LocalStorageService>().getStringList(_kRecientes) ?? [])
        .map((s) {
          try {
            return BusquedaReciente.fromJson(jsonDecode(s) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<BusquedaReciente>()
        .toList();
    if (widget.queryInicial != null && widget.queryInicial!.isNotEmpty) {
      _controller.text = widget.queryInicial!;
      _query = widget.queryInicial!;
      _fetchSugerencias(_query);
    }
    // Autofocus al entrar, pero DESPUÉS de que termine la transición de página
    // (~220ms): si el teclado sube mientras la página aún anima, el body se
    // redimensiona a la vez y se ve como que "se estira y encoge".
    Future.delayed(const Duration(milliseconds: 280), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _fetchSugerencias(String q) async {
    final term = q.trim();
    setState(() => _query = term);
    if (term.length < 2) {
      setState(() {
        _categorias = [];
        _productos = [];
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await locator<DioClient>().get(
        '/marketplace/sugerencias',
        queryParameters: {'q': term, 'limit': '8'},
      );
      if (!mounted) return;
      final data = response.data as Map<String, dynamic>;
      setState(() {
        _categorias = (data['categorias'] as List?) ?? [];
        _productos = (data['productos'] as List?) ?? [];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _buscarTexto(String term) {
    final t = term.trim();
    if (t.isNotEmpty) {
      _guardarReciente(BusquedaReciente(tipo: 'texto', texto: t));
    }
    context.pop({'search': t});
  }

  /// Inserta [item] arriba de las recientes (sin duplicados por clave, tope
  /// [_maxRecientes]) y persiste.
  void _guardarReciente(BusquedaReciente item) {
    _recientes.removeWhere((e) => e.clave == item.clave);
    _recientes.insert(0, item);
    if (_recientes.length > _maxRecientes) {
      _recientes = _recientes.sublist(0, _maxRecientes);
    }
    _persistirRecientes();
  }

  void _eliminarReciente(BusquedaReciente item) {
    setState(() => _recientes.removeWhere((e) => e.clave == item.clave));
    _persistirRecientes();
  }

  void _limpiarRecientes() {
    setState(() => _recientes = []);
    locator<LocalStorageService>().remove(_kRecientes);
  }

  void _persistirRecientes() {
    locator<LocalStorageService>().setStringList(
      _kRecientes,
      _recientes.map((e) => jsonEncode(e.toJson())).toList(),
    );
  }

  void _seleccionarCategoria(Map<String, dynamic> categoria) {
    final nombre = categoria['nombre'] as String?;
    if (nombre != null && nombre.isNotEmpty) {
      _guardarReciente(BusquedaReciente(tipo: 'texto', texto: nombre));
    }
    context.pop({
      'categoriaId': categoria['id'],
      'categoriaNombre': categoria['nombre'],
    });
  }

  void _abrirProducto(Map<String, dynamic> p) {
    // Guardar el PRODUCTO (con su imagen) como búsqueda reciente.
    _guardarReciente(BusquedaReciente(
      tipo: 'producto',
      id: p['id'] as String?,
      nombre: p['nombre'] as String?,
      imagen: p['imagen'] as String?,
    ));
    context.push('/producto-detalle/${p['id']}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        // Mismo alto/espaciado que el AppBar del home (productos) para que la
        // transición entre pages no "salte".
        toolbarHeight: 50,
        titleSpacing: 6,
        title: Padding(
          padding: const EdgeInsets.only(right: 6),
          child: CustomSearchField(
            controller: _controller,
            focusNode: _focusNode,
            hintText: 'Buscar productos, marcas y más...',
            backgroundColor: Colors.white,
            borderRadius: 24,
            height: 33,
            showClearButton: true,
            showShadow: false,
            debounceDelay: const Duration(milliseconds: 300),
            onChanged: _fetchSugerencias,
            onSubmitted: (v) {
              if (v.trim().isNotEmpty) _buscarTexto(v);
            },
            onClear: () {
              setState(() {
                _categorias = [];
                _productos = [];
                _query = '';
              });
            },
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_query.length < 2) {
      // Sin texto: mostrar búsquedas recientes (o un hint si no hay).
      if (_recientes.isEmpty) {
        return _hint('Escribe al menos 2 letras para ver sugerencias');
      }
      return _buildRecientes();
    }
    if (_loading && _categorias.isEmpty && _productos.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.only(top: 40),
          child: CircularProgressIndicator(color: AppColors.blue2),
        ),
      );
    }
    if (_categorias.isEmpty && _productos.isEmpty) {
      return _hint('Sin sugerencias para "$_query"');
    }

    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        // Fila para buscar el texto tal cual.
        _buildBuscarTextoTile(),
        if (_categorias.isNotEmpty) ...[
          _seccionLabel('Categorías'),
          ..._categorias.map((c) => _buildCategoriaTile(c as Map<String, dynamic>)),
        ],
        if (_productos.isNotEmpty) ...[
          _seccionLabel('Productos'),
          ..._productos.map((p) => _buildProductoTile(p as Map<String, dynamic>)),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  /// Lista de búsquedas recientes (estado vacío). Cada fila busca ese término;
  /// la X la quita, y "Borrar todo" limpia el historial.
  Widget _buildRecientes() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'BÚSQUEDAS RECIENTES',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade500,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: _limpiarRecientes,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 32),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Borrar todo',
                    style: TextStyle(fontSize: 11, color: AppColors.blue2, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
        ..._recientes.map(_buildRecienteTile),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildRecienteTile(BusquedaReciente item) {
    final esProducto = item.tipo == 'producto';
    return ListTile(
      dense: true,
      // Acerca el texto al thumbnail del producto (~5px menos que el default 16).
      horizontalTitleGap: esProducto ? 11 : null,
      leading: esProducto
          // Producto: thumbnail con su imagen.
          ? Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade200),
              ),
              clipBehavior: Clip.antiAlias,
              child: item.imagen != null
                  ? CachedNetworkImage(
                      imageUrl: item.imagen!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const SizedBox.shrink(),
                      errorWidget: (_, __, ___) =>
                          Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey.shade300),
                    )
                  : Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey.shade300),
            )
          // Texto: ícono de historial.
          : Icon(Icons.history, size: 20, color: Colors.grey.shade500),
      title: Text(
        esProducto ? (item.nombre ?? '') : (item.texto ?? ''),
        style: TextStyle(fontSize: esProducto ? 10 : 13, color: Colors.black87),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: IconButton(
        icon: Icon(Icons.close, size: 16, color: Colors.grey.shade400),
        splashRadius: 16,
        onPressed: () => _eliminarReciente(item),
      ),
      onTap: () {
        if (esProducto && item.id != null) {
          context.push('/producto-detalle/${item.id}');
        } else if (item.texto != null) {
          _buscarTexto(item.texto!);
        }
      },
    );
  }

  Widget _hint(String texto) => Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Text(
            texto,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
          ),
        ),
      );

  Widget _seccionLabel(String texto) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
        child: Text(
          texto.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade500,
            letterSpacing: 0.5,
          ),
        ),
      );

  Widget _buildBuscarTextoTile() {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.search, color: AppColors.blue2),
      title: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 13, color: Colors.black87),
          children: [
            const TextSpan(text: 'Buscar '),
            TextSpan(
              text: '"$_query"',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
      onTap: () => _buscarTexto(_query),
    );
  }

  Widget _buildCategoriaTile(Map<String, dynamic> c) {
    final nombre = c['nombre'] as String? ?? '';
    final icono = c['icono'] as String?;
    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.blue1.withValues(alpha: 0.1),
        child: icono != null && icono.isNotEmpty && !icono.startsWith('http')
            ? Text(icono, style: const TextStyle(fontSize: 14))
            : const Icon(Icons.category_outlined, size: 16, color: AppColors.blue2),
      ),
      title: Text(nombre, style: const TextStyle(fontSize: 13)),
      trailing: Icon(Icons.north_west, size: 14, color: Colors.grey.shade400),
      onTap: () => _seleccionarCategoria(c),
    );
  }

  Widget _buildProductoTile(Map<String, dynamic> p) {
    final nombre = p['nombre'] as String? ?? '';
    final imagen = p['imagen'] as String?;
    return ListTile(
      dense: true,
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.grey.shade200),
        ),
        clipBehavior: Clip.antiAlias,
        child: imagen != null
            ? CachedNetworkImage(
                imageUrl: imagen,
                fit: BoxFit.contain,
                placeholder: (_, __) => const SizedBox.shrink(),
                errorWidget: (_, __, ___) =>
                    Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey.shade300),
              )
            : Icon(Icons.inventory_2_outlined, size: 18, color: Colors.grey.shade300),
      ),
      title: Text(
        nombre,
        style: const TextStyle(fontSize: 13),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => _abrirProducto(p),
    );
  }
}
