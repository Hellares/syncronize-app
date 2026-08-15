import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/domain/entities/sede.dart';

/// Page to configure stockMinimo and stockMaximo for all products in a sede.
class ConfigurarStockMinMaxPage extends StatefulWidget {
  const ConfigurarStockMinMaxPage({super.key});

  @override
  State<ConfigurarStockMinMaxPage> createState() =>
      _ConfigurarStockMinMaxPageState();
}

class _ConfigurarStockMinMaxPageState extends State<ConfigurarStockMinMaxPage> {
  final DioClient _dio = locator<DioClient>();

  List<Sede> _sedes = [];
  String? _selectedSedeId;

  List<Map<String, dynamic>> _productos = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  /// Cuánto se pide por vez.
  ///
  /// 🔴 La pantalla NO trae la sede entera: no carga nada hasta que se busca.
  /// Traer las cientos de filas de una sede para después filtrar era lento y
  /// además inútil — se viene acá a tocar un producto puntual, no a leer el
  /// inventario. Con búsqueda, 100 filas sobran: son las variantes de un
  /// producto, no el catálogo.
  static const int _limitePorPagina = 100;

  /// Total en el servidor, para poder avisar cuando quedó gente afuera.
  int? _total;

  /// Lo tecleado en el buscador. Viaja al SERVIDOR: filtrar local solo
  /// revolvería las filas ya traídas.
  String _busqueda = '';
  final TextEditingController _busquedaCtrl = TextEditingController();
  Timer? _debounce;

  /// Controllers for min/max fields indexed by productoStock id
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _maxControllers = {};

  /// Track which items have been modified
  final Set<String> _modified = {};

  @override
  void initState() {
    super.initState();
    _loadSedes();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _busquedaCtrl.dispose();
    for (final c in _minControllers.values) {
      c.dispose();
    }
    for (final c in _maxControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadSedes() {
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      setState(() {
        _sedes = state.context.sedes;
        if (_sedes.length == 1) {
          _selectedSedeId = _sedes.first.id;
          _loadProductos(_selectedSedeId!);
        }
      });
    }
  }

  Future<void> _loadProductos(String sedeId) async {
    // Sin término no se pide nada: la pantalla arranca vacía invitando a
    // buscar. Es la diferencia entre una consulta de 100 filas y una de la
    // sede entera cada vez que se elige sede.
    if (_busqueda.isEmpty) {
      setState(() {
        _productos = [];
        _total = null;
        _loading = false;
        _error = null;
        _modified.clear();
      });
      return;
    }

    setState(() {
      _loading = true;
      _productos = [];
      _error = null;
      _modified.clear();
    });

    // Dispose old controllers
    for (final c in _minControllers.values) {
      c.dispose();
    }
    for (final c in _maxControllers.values) {
      c.dispose();
    }
    _minControllers.clear();
    _maxControllers.clear();

    try {
      // 🔴 El `limit` va EXPLÍCITO: sin él el backend manda 50, y una sede con
      // 687 filas de stock mostraba las primeras 50 nada más. Los graneles de
      // un producto con variantes caen mucho más abajo, así que no aparecían
      // nunca y parecía que la pantalla filtraba las variantes.
      //
      // El resto se alcanza con el buscador, que pregunta al SERVIDOR: filtrar
      // local solo revolvería las que ya se trajeron.
      final response = await _dio.get(
        '/producto-stock/sede/$sedeId',
        queryParameters: {
          'limit': _limitePorPagina,
          if (_busqueda.isNotEmpty) 'search': _busqueda,
        },
      );
      final data = response.data;
      final meta = data is Map ? data['meta'] : null;
      _total = meta is Map ? meta['total'] as int? : null;
      final List<Map<String, dynamic>> productos;
      if (data is List) {
        productos = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data['data'] is List) {
        productos = (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        productos = [];
      }

      // Initialize controllers
      for (final p in productos) {
        final id = (p['id'] ?? p['_id'] ?? '').toString();
        if (id.isEmpty) continue;
        final minVal = p['stockMinimo'] ?? 0;
        final maxVal = p['stockMaximo'] ?? 0;
        _minControllers[id] = TextEditingController(text: '$minVal');
        _maxControllers[id] = TextEditingController(text: '$maxVal');
      }

      if (mounted) {
        setState(() {
          _productos = productos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar productos';
          _loading = false;
        });
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (_selectedSedeId == null || _modified.isEmpty) return;

    setState(() => _saving = true);

    try {
      final List<Map<String, dynamic>> updates = [];

      for (final id in _modified) {
        final minText = _minControllers[id]?.text ?? '0';
        final maxText = _maxControllers[id]?.text ?? '0';
        updates.add({
          'productoStockId': id,
          'stockMinimo': int.tryParse(minText) ?? 0,
          'stockMaximo': int.tryParse(maxText) ?? 0,
        });
      }

      await _dio.patch(
        '/producto-stock/sede/$_selectedSedeId/stock-minmax-bulk',
        data: {'items': updates},
      );

      if (mounted) {
        _modified.clear();
        SnackBarHelper.showSuccess(
            context, 'Stock Min/Max actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al guardar cambios');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Configurar Stock Min/Max'),
        body: Column(
          children: [
            // Sede selector + save button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildSedeSelector(),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14),
                          ),
                        )
                      : _productos.isEmpty && _selectedSedeId != null
                          ? _buildEmptyState()
                          : _buildProductosList(),
            ),

            // Save button
            if (_modified.isNotEmpty)
              Padding(
                // El inset inferior va a mano: este Scaffold no tiene
                // bottomNavigationBar y la barra de navegación del sistema
                // tapaba el botón, que quedaba sin poder tocarse.
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  16 + MediaQuery.of(context).padding.bottom,
                ),
                child: CustomButton(
                  text: 'Guardar Cambios (${_modified.length})',
                  isLoading: _saving,
                  onPressed: _saving ? null : _guardarCambios,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeSelector() {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Sede',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedSedeId,
            decoration: InputDecoration(
              hintText: 'Seleccione una sede',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            isExpanded: true,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: _sedes.map((sede) {
              return DropdownMenuItem<String>(
                value: sede.id,
                child:
                    Text(sede.nombre, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSedeId = val;
                  _productos = [];
                });
                _loadProductos(val);
              }
            },
          ),
          if (_selectedSedeId != null) ...[
            const SizedBox(height: 10),
            CustomText(
              controller: _busquedaCtrl,
              hintText: 'Buscar producto o variante…',
              borderColor: AppColors.blue1,
              prefixIcon: const Icon(Icons.search,
                  size: 16, color: AppColors.blue1),
              onChanged: _onBuscar,
            ),
            if (_total != null && _total! > _productos.length) ...[
              const SizedBox(height: 6),
              Text(
                'Mostrando ${_productos.length} de $_total. Buscá para llegar al resto.',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ],
        ],
      ),
    );
  }

  /// Rebota el tecleo y consulta al SERVIDOR.
  ///
  /// 🔴 Nada de filtrar la lista local: solo tiene las primeras
  /// [_limitePorPagina] filas, así que buscar ahí adentro daría "no hay
  /// resultados" para algo que sí existe en la sede.
  void _onBuscar(String valor) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      final termino = valor.trim();
      if (termino == _busqueda) return;
      _busqueda = termino;
      final sedeId = _selectedSedeId;
      if (sedeId != null) _loadProductos(sedeId);
    });
  }

  /// Las filas de la sede, agrupadas por PRODUCTO.
  ///
  /// 🔴 Una fila de stock es un producto simple O una variante, nunca las dos
  /// (XOR del modelo), y las de variante no traen `productoId`: el dueño llega
  /// por `variante.producto`. Sin agrupar, los 12 graneles de un producto se
  /// leían como 12 items sueltos sin decir de qué producto eran.
  List<_BloqueProducto> get _bloques {
    final porProducto = <String, _BloqueProducto>{};
    for (final fila in _productos) {
      final prod = fila['producto'] is Map ? fila['producto'] as Map : null;
      final variante =
          fila['variante'] is Map ? fila['variante'] as Map : null;
      final duenio =
          variante?['producto'] is Map ? variante!['producto'] as Map : null;

      final id = (prod?['id'] ?? duenio?['id'] ?? 'sin-producto').toString();
      final nombre =
          (prod?['nombre'] ?? duenio?['nombre'] ?? 'Sin nombre').toString();

      porProducto
          .putIfAbsent(id, () => _BloqueProducto(id: id, nombre: nombre))
          .filas
          .add(fila);
    }
    return porProducto.values.toList();
  }

  Widget _buildProductosList() {
    final bloques = _bloques;
    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedSedeId != null) {
          await _loadProductos(_selectedSedeId!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: bloques.length,
        itemBuilder: (context, index) => _buildBloque(bloques[index]),
      ),
    );
  }

  Widget _buildBloque(_BloqueProducto bloque) {
    final varias = bloque.filas.length > 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado del producto
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.06),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.inventory_2, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bloque.nombre,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Con una sola fila no tiene sentido: "aplicar a todas" es
                // para los 12 graneles de un multi-sabor.
                if (varias)
                  TextButton.icon(
                    onPressed: () => _aplicarATodas(bloque),
                    icon: const Icon(Icons.playlist_add_check, size: 14),
                    label: Text('Todas (${bloque.filas.length})',
                        style: const TextStyle(fontSize: 10)),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.blue1,
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
          ),
          ...bloque.filas.map(_buildFila),
        ],
      ),
    );
  }

  /// Escribe el mismo mínimo y máximo en TODAS las filas del producto.
  ///
  /// Es el gesto que justifica agrupar: un multi-sabor tiene 12 graneles que
  /// llevan el mismo mínimo, y cargarlos de a uno es donde la gente abandona.
  ///
  /// Deja los campos en blanco sin tocar, así se puede aplicar solo el mínimo.
  Future<void> _aplicarATodas(_BloqueProducto bloque) async {
    final minCtrl = TextEditingController();
    final maxCtrl = TextEditingController();

    final aplicar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StyledDialog(
        accentColor: AppColors.blue1,
        icon: Icons.playlist_add_check,
        titulo: bloque.nombre,
        content: [
          Text(
            'Se escribe en las ${bloque.filas.length} filas de este producto. '
            'Lo que dejes vacío no se toca.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  label: 'Mínimo',
                  controller: minCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomText(
                  label: 'Máximo',
                  controller: maxCtrl,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
        ],
        actions: [
          Expanded(
            child: CustomButton(
              text: 'Cancelar',
              backgroundColor: AppColors.white,
              borderColor: Colors.grey.shade400,
              textColor: Colors.grey.shade700,
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
          ),
          Expanded(
            flex: 2,
            child: CustomButton(
              text: 'Aplicar',
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ),
        ],
      ),
    );

    final min = minCtrl.text.trim();
    final max = maxCtrl.text.trim();
    minCtrl.dispose();
    maxCtrl.dispose();

    if (aplicar != true || (min.isEmpty && max.isEmpty)) return;

    setState(() {
      for (final fila in bloque.filas) {
        final id = (fila['id'] ?? fila['_id'] ?? '').toString();
        if (id.isEmpty) continue;
        if (min.isNotEmpty) _minControllers[id]?.text = min;
        if (max.isNotEmpty) _maxControllers[id]?.text = max;
        _modified.add(id);
      }
    });
  }

  /// Una fila = un `ProductoStock`: el stock actual y los dos campos.
  ///
  /// En un producto sin variantes la fila ES el producto, así que no tiene
  /// nombre propio que mostrar: alcanza el del encabezado del bloque.
  Widget _buildFila(Map<String, dynamic> p) {
    final id = (p['id'] ?? p['_id'] ?? '').toString();
    final variante = p['variante'] is Map ? p['variante'] as Map : null;
    final etiqueta = (variante?['nombre'] as String?)?.trim();
    final stockActual = p['stockActual'] ?? p['stock'] ?? 0;

    final minController = _minControllers[id];
    final maxController = _maxControllers[id];
    if (minController == null || maxController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: _modified.contains(id)
            ? AppColors.blue1.withValues(alpha: 0.04)
            : null,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  etiqueta == null || etiqueta.isEmpty
                      ? 'Producto base'
                      : etiqueta,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Stock: $stockActual',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  label: 'Mínimo',
                  controller: minController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _modified.add(id)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomText(
                  label: 'Máximo',
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setState(() => _modified.add(id)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  /// Dos vacíos distintos: "todavía no buscaste" y "buscaste y no hay".
  /// Mostrar el mismo cartel para los dos hace pensar que la sede está vacía.
  Widget _buildEmptyState() {
    final sinBuscar = _busqueda.isEmpty;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(sinBuscar ? Icons.search : Icons.search_off,
                size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              sinBuscar
                  ? 'Buscá un producto para configurar su stock mínimo y máximo'
                  : 'Nada que coincida con "$_busqueda" en esta sede',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            if (sinBuscar) ...[
              const SizedBox(height: 6),
              Text(
                'Se cargan solo las filas que busques: la sede entera son cientos.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Un producto y las filas de stock que le pertenecen.
///
/// En un producto simple es una sola fila (la del producto); en uno con
/// variantes, una por variante. Agrupar es lo que permite el "aplicar a
/// todas" y lo que hace legible una sede con cientos de filas.
class _BloqueProducto {
  final String id;
  final String nombre;
  final List<Map<String, dynamic>> filas = [];

  _BloqueProducto({required this.id, required this.nombre});
}
