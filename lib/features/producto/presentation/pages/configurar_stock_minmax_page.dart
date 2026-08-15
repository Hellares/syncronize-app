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

  /// Número de la búsqueda en curso: una respuesta vieja que llega tarde se
  /// descarta en vez de pisar a la nueva.
  int _reqSeq = 0;

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
    _descartarControllers();
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
        _descartarControllers();
      });
      return;
    }

    // 🔴 Cada búsqueda se numera. Con 400 ms de rebote pueden quedar dos
    // pedidos en vuelo, y el de la palabra CORTA —que trae más filas— suele
    // volver después: sin esto pisaba al bueno y la pantalla terminaba
    // mostrando el resultado de lo que ya no está escrito.
    final miSeq = ++_reqSeq;

    // Ojo: NO se vacía `_productos` acá. Vaciar y repintar en cada tecleo es
    // el parpadeo que se ve; lo viejo se reemplaza recién cuando llega lo
    // nuevo, con una barrita mientras tanto.
    setState(() {
      _loading = true;
      _error = null;
    });

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

      // Llegó tarde: ya hay una búsqueda más nueva. Se descarta sin tocar la
      // pantalla ni los controllers.
      if (!mounted || miSeq != _reqSeq) return;

      // Los controllers nuevos se arman APARTE y recién después se cambian por
      // los viejos, que se liberan ahí. Crearlos sobre el mapa en uso dejaba
      // huérfanos los de las filas que ya no están —fuga— y, peor, si la
      // respuesta llegaba a destiempo pisaba lo que el usuario venía tecleando.
      final nuevosMin = <String, TextEditingController>{};
      final nuevosMax = <String, TextEditingController>{};
      for (final p in productos) {
        final id = (p['id'] ?? p['_id'] ?? '').toString();
        if (id.isEmpty) continue;
        nuevosMin[id] = TextEditingController(text: '${p['stockMinimo'] ?? 0}');
        nuevosMax[id] = TextEditingController(text: '${p['stockMaximo'] ?? 0}');
      }

      setState(() {
        _descartarControllers();
        _minControllers.addAll(nuevosMin);
        _maxControllers.addAll(nuevosMax);
        // Los pendientes de guardar eran de la búsqueda anterior: sus campos
        // ya no están en pantalla, así que no se pueden guardar a ciegas.
        _modified.clear();
        _productos = productos;
        _loading = false;
      });
    } catch (e) {
      if (!mounted || miSeq != _reqSeq) return;
      setState(() {
        _error = 'Error al cargar productos';
        _loading = false;
      });
    }
  }

  /// Libera y vacía los controllers de la tanda anterior.
  void _descartarControllers() {
    for (final c in _minControllers.values) {
      c.dispose();
    }
    for (final c in _maxControllers.values) {
      c.dispose();
    }
    _minControllers.clear();
    _maxControllers.clear();
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

            // Contenido.
            //
            // 🔴 Mientras se busca de nuevo NO se vacía la lista: se deja lo
            // anterior con una barrita arriba. Antes cada tecleo la borraba y
            // volvía a pintarla, y eso era el "se muestra y se barre".
            Expanded(
              child: _error != null
                  ? Center(
                      child: Text(
                        _error!,
                        style: const TextStyle(
                            color: Colors.red, fontSize: 14),
                      ),
                    )
                  : _productos.isEmpty
                      ? (_loading
                          ? const Center(child: CircularProgressIndicator())
                          : _buildEmptyState())
                      : Column(
                          children: [
                            SizedBox(
                              height: 2,
                              child: _loading
                                  ? const LinearProgressIndicator(
                                      minHeight: 2)
                                  : null,
                            ),
                            Expanded(child: _buildProductosList()),
                          ],
                        ),
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

  // Medidas de la grilla, tomadas de la edición masiva para que las dos
  // pantallas se sientan iguales. Acá son TRES columnas, así que entran sin
  // scroll horizontal: no hace falta la columna congelada de allá.
  static const double _hHeader = 28;
  static const double _hCampo = 32;
  static const double _wStock = 52;
  static const double _wCampo = 74;
  static const TextStyle _estiloHeader =
      TextStyle(fontSize: 10, fontWeight: FontWeight.w600);

  Widget _buildProductosList() {
    final bloques = _bloques;
    return Column(
      children: [
        _buildHeaderGrilla(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              if (_selectedSedeId != null) {
                await _loadProductos(_selectedSedeId!);
              }
            },
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: bloques.length,
              itemBuilder: (context, index) => _buildBloque(bloques[index]),
            ),
          ),
        ),
      ],
    );
  }

  /// Encabezado fijo de la grilla. Fuera del scroll: con 28 filas, saber qué
  /// columna es cuál a mitad de camino importa más que ganar 28 píxeles.
  Widget _buildHeaderGrilla() {
    return Container(
      height: _hHeader,
      color: AppColors.blue1.withValues(alpha: 0.08),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(
        children: [
          Expanded(child: Text('Variante', style: _estiloHeader)),
          SizedBox(
            width: _wStock,
            child: Text('Stock',
                style: _estiloHeader, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _wCampo,
            child: Text('Mínimo',
                style: _estiloHeader, textAlign: TextAlign.center),
          ),
          SizedBox(
            width: _wCampo,
            child: Text('Máximo',
                style: _estiloHeader, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }

  /// Fila que separa un producto del siguiente, al estilo de un subtotal de
  /// planilla: ocupa el ancho entero y ahí vive el "aplicar a todas".
  Widget _buildBloque(_BloqueProducto bloque) {
    final varias = bloque.filas.length > 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.05),
            border: Border(
              top: BorderSide(color: AppColors.blue1.withValues(alpha: 0.25)),
              bottom: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.inventory_2, size: 13, color: AppColors.blue1),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bloque.nombre,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Con una sola fila no tiene sentido: "aplicar a todas" es para
              // los 12 graneles de un multi-sabor.
              if (varias)
                InkWell(
                  onTap: () => _aplicarATodas(bloque),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.playlist_add_check,
                            size: 13, color: AppColors.blue1),
                        const SizedBox(width: 3),
                        Text(
                          'Todas (${bloque.filas.length})',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
        for (var i = 0; i < bloque.filas.length; i++)
          _buildFila(bloque.filas[i], i),
      ],
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
  Widget _buildFila(Map<String, dynamic> p, int index) {
    final id = (p['id'] ?? p['_id'] ?? '').toString();
    final variante = p['variante'] is Map ? p['variante'] as Map : null;
    final etiqueta = (variante?['nombre'] as String?)?.trim();
    final stockActual = p['stockActual'] ?? p['stock'] ?? 0;

    final minController = _minControllers[id];
    final maxController = _maxControllers[id];
    if (minController == null || maxController == null) {
      return const SizedBox.shrink();
    }

    // La fila tocada gana sobre la cebra: mientras se edita, lo que importa
    // es ver qué renglones quedaron pendientes de guardar.
    final tocada = _modified.contains(id);
    final fondo = tocada
        ? Colors.amber.withValues(alpha: 0.12)
        : (index.isEven
            ? Colors.transparent
            : Colors.grey.withValues(alpha: 0.05));

    return Container(
      color: fondo,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta == null || etiqueta.isEmpty ? 'Producto base' : etiqueta,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: _wStock,
            child: Text(
              '$stockActual',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.blue1,
              ),
            ),
          ),
          _celda(minController, id),
          _celda(maxController, id),
        ],
      ),
    );
  }

  /// Celda editable de la grilla: compacta y sin `label`, porque el nombre de
  /// la columna ya está en el encabezado. Con label, cada fila repetía
  /// "Mínimo/Máximo" y la tabla dejaba de leerse como tabla.
  Widget _celda(TextEditingController controller, String id) {
    return SizedBox(
      width: _wCampo,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: SizedBox(
          height: _hCampo,
          child: CustomText(
            controller: controller,
            height: _hCampo,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (_) => setState(() => _modified.add(id)),
            borderColor: AppColors.blue1Alpha40,
            borderWidth: 0.6,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            textStyle: const TextStyle(fontSize: 11),
            showValidationIndicator: false,
          ),
        ),
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
