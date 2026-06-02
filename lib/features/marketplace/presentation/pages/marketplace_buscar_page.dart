import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/custom_search_field.dart';

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

  @override
  void initState() {
    super.initState();
    if (widget.queryInicial != null && widget.queryInicial!.isNotEmpty) {
      _controller.text = widget.queryInicial!;
      _query = widget.queryInicial!;
      _fetchSugerencias(_query);
    }
    // Autofocus al entrar.
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
    context.pop({'search': t});
  }

  void _seleccionarCategoria(Map<String, dynamic> categoria) {
    context.pop({
      'categoriaId': categoria['id'],
      'categoriaNombre': categoria['nombre'],
    });
  }

  void _abrirProducto(String id) {
    context.push('/producto-detalle/$id');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: CustomSearchField(
            controller: _controller,
            focusNode: _focusNode,
            hintText: 'Buscar productos, marcas y más...',
            backgroundColor: Colors.white,
            borderRadius: 24,
            height: 38,
            showClearButton: true,
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
      return _hint('Escribe al menos 2 letras para ver sugerencias');
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
      onTap: () => _abrirProducto(p['id'] as String),
    );
  }
}
