import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector_exports.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import 'historial_compras_producto_panel.dart';

/// Widget para buscar y agregar productos/items al detalle de una Orden de Compra.
///
/// Permite dos modos:
/// - **Producto**: busca productos del catálogo usando [ProductoSedeSelector]
/// - **Personalizado**: permite texto libre para servicios u otros items
class OrdenCompraItemSelector extends StatefulWidget {
  final String empresaId;
  final String? sedeId;
  final void Function(Map<String, dynamic> item) onItemAdded;

  const OrdenCompraItemSelector({
    super.key,
    required this.empresaId,
    this.sedeId,
    required this.onItemAdded,
  });

  @override
  State<OrdenCompraItemSelector> createState() =>
      _OrdenCompraItemSelectorState();
}

class _OrdenCompraItemSelectorState extends State<OrdenCompraItemSelector> {
  final _descripcionController = TextEditingController();
  final _cantidadController = TextEditingController(text: '1');
  final _precioController = TextEditingController();
  final _descuentoController = TextEditingController(text: '0');
  final _nuevoPrecioVentaController = TextEditingController();
  final DioClient _dio = locator<DioClient>();

  String _tipoItem = 'producto';
  ProductoListItem? _productoSeleccionado;
  ProductoVariante? _varianteSeleccionada;

  /// Si el producto seleccionado tiene unidadCompra configurada, el
  /// usuario puede elegir cargar la línea en esa unidad (PAQUETE/KG/...)
  /// en vez de la unidad atómica de venta. true = ingresa por unidad
  /// de COMPRA, el backend convertirá ×factor antes de persistir.
  bool _usaUnidadCompra = false;

  /// Datos actuales del ProductoStock en la sede de la compra. Se cargan
  /// al seleccionar producto para mostrar preview de costo/precio y
  /// permitir al usuario ajustar el precio venta al confirmar.
  double? _costoActualSede;
  double? _precioVentaActualSede;
  int? _stockActualSede;
  bool _loadingStockSede = false;
  String? _productoIdInfoCargada; // Evitar reload si ya tenemos los datos

  @override
  void dispose() {
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _descuentoController.dispose();
    _nuevoPrecioVentaController.dispose();
    super.dispose();
  }

  void _limpiarSeleccion() {
    _descripcionController.clear();
    _cantidadController.text = '1';
    _precioController.clear();
    _descuentoController.text = '0';
    _nuevoPrecioVentaController.clear();
    _productoSeleccionado = null;
    _varianteSeleccionada = null;
    _usaUnidadCompra = false;
    _costoActualSede = null;
    _precioVentaActualSede = null;
    _stockActualSede = null;
    _productoIdInfoCargada = null;
  }

  /// Carga precioCosto + precio venta del producto en la sede actual
  /// para mostrar el preview de "lo que va a cambiar" al confirmar.
  Future<void> _cargarStockSede(String productoId) async {
    if (widget.sedeId == null) return;
    if (_productoIdInfoCargada == productoId) return; // Ya cargado
    setState(() {
      _loadingStockSede = true;
      _costoActualSede = null;
      _precioVentaActualSede = null;
    });
    try {
      final resp = await _dio.get(
        '/producto-stock/producto/$productoId/sede/${widget.sedeId}',
      );
      final data = resp.data as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() {
        final costoRaw = data?['precioCosto'];
        _costoActualSede = costoRaw is num
            ? costoRaw.toDouble()
            : (costoRaw is String ? double.tryParse(costoRaw) : null);
        final precioRaw = data?['precio'];
        _precioVentaActualSede = precioRaw is num
            ? precioRaw.toDouble()
            : (precioRaw is String ? double.tryParse(precioRaw) : null);
        _stockActualSede = (data?['stockActual'] as num?)?.toInt();
        _loadingStockSede = false;
        _productoIdInfoCargada = productoId;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loadingStockSede = false);
      }
    }
  }

  /// Costo unitario de la compra actual en unidad atómica
  /// (después de conversión por factor si aplica).
  double get _precioCompraAtomico {
    final raw = double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0;
    if (raw <= 0) return 0;
    if (_usaUnidadCompra && _productoSoportaUnidadCompra) {
      final factor = _productoSeleccionado!.factorCompra ?? 1;
      return factor > 0 ? raw / factor : raw;
    }
    return raw;
  }

  /// Cantidad en unidad atómica (después de conversión). Tolera decimales
  /// (ej. 1.5 m) y redondea a unidad base entera (cm).
  int get _cantidadAtomica {
    final raw =
        double.tryParse(_cantidadController.text.replaceAll(',', '.')) ?? 0;
    if (raw <= 0) return 0;
    if (_usaUnidadCompra && _productoSoportaUnidadCompra) {
      final factor = _productoSeleccionado!.factorCompra ?? 1;
      return (raw * factor).round();
    }
    return raw.round();
  }

  /// Costo proyectado tras la compra (promedio ponderado con stock previo).
  /// Para preview en card; el backend recalcula igual al confirmar.
  double? get _nuevoCostoProyectado {
    if (_productoSeleccionado == null) return null;
    final precioNuevo = _precioCompraAtomico;
    final cantNueva = _cantidadAtomica;
    if (precioNuevo <= 0 || cantNueva <= 0) return _costoActualSede;
    final stockPrev = _stockActualSede ?? 0;
    final costoPrev = _costoActualSede ?? 0;
    if (stockPrev == 0) return precioNuevo;
    final pond =
        (stockPrev * costoPrev + cantNueva * precioNuevo) /
            (stockPrev + cantNueva);
    return double.parse(pond.toStringAsFixed(4));
  }

  /// % de margen actual (precio venta vs costo actual). Para "Mantener
  /// margen" calculamos el precio venta sugerido sobre el costo nuevo.
  double? get _margenActualPct {
    final precio = _precioVentaActualSede;
    final costo = _costoActualSede;
    if (precio == null || costo == null || costo <= 0) return null;
    return ((precio - costo) / costo) * 100;
  }

  /// Sugerencia: precio que mantiene el mismo margen sobre el nuevo costo.
  double? get _precioMantenerMargen {
    final margen = _margenActualPct;
    final costoNuevo = _nuevoCostoProyectado;
    if (margen == null || costoNuevo == null) return null;
    return double.parse(
      (costoNuevo * (1 + margen / 100)).toStringAsFixed(2),
    );
  }

  /// Sugerencia: precio actual + 10%.
  double? get _precioMas10 {
    final precio = _precioVentaActualSede;
    if (precio == null) return null;
    return double.parse((precio * 1.1).toStringAsFixed(2));
  }

  void _aplicarSugerencia(double v) {
    setState(() {
      _nuevoPrecioVentaController.text = v.toStringAsFixed(2);
    });
  }

  /// Producto seleccionado tiene unidadCompra+factor → mostramos toggle.
  bool get _productoSoportaUnidadCompra =>
      _productoSeleccionado?.factorCompra != null &&
      _productoSeleccionado!.factorCompra! > 0 &&
      (_productoSeleccionado?.unidadCompraSimbolo?.isNotEmpty ?? false);

  /// Símbolo de la unidad actualmente seleccionada en "Comprar por":
  /// la de compra si el toggle está en compra, si no la base.
  String? get _simboloUnidadSel {
    final p = _productoSeleccionado;
    if (p == null) return null;
    final s = _usaUnidadCompra ? p.unidadCompraSimbolo : p.unidadMedidaSimbolo;
    return (s != null && s.isNotEmpty) ? s : null;
  }

  /// Formatea un precio quitando ceros/punto sobrantes (5.0 → "5",
  /// 0.0500 → "0.05").
  String _fmtPrecio(double n) {
    if ((n - n.truncateToDouble()).abs() < 1e-9) return n.toStringAsFixed(0);
    var s = n.toStringAsFixed(4);
    s = s.replaceFirst(RegExp(r'0+$'), '');
    s = s.replaceFirst(RegExp(r'\.$'), '');
    return s;
  }

  /// Opción A: al cambiar la unidad de "Comprar por", reconvierte el PRECIO y
  /// la CANTIDAD que ya escribió el usuario para que la compra real (material
  /// total y costo) se mantenga idéntica al toggear.
  /// - Precio: cm→m ×factor, m→cm ÷factor.
  /// - Cantidad: cm→m ÷factor, m→cm ×factor (inverso al precio).
  /// Nota: cm→m puede dar cantidad fraccionaria (ej. 150 cm = 1.5 m); se
  /// permite y `_agregarItem` la aplana a unidad base al enviar.
  void _cambiarUnidadCompra(bool nuevo) {
    if (nuevo == _usaUnidadCompra) return;
    final factor = _productoSeleccionado?.factorCompra ?? 1;
    final precio = double.tryParse(_precioController.text.replaceAll(',', '.'));
    final cantidad =
        double.tryParse(_cantidadController.text.replaceAll(',', '.'));
    setState(() {
      if (factor > 0) {
        if (precio != null && precio > 0) {
          _precioController.text =
              _fmtPrecio(nuevo ? precio * factor : precio / factor);
        }
        if (cantidad != null && cantidad > 0) {
          _cantidadController.text =
              _fmtPrecio(nuevo ? cantidad / factor : cantidad * factor);
        }
      }
      _usaUnidadCompra = nuevo;
    });
  }

  void _agregarItem() {
    final descripcion = _descripcionController.text.trim();
    if (descripcion.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La descripción es requerida'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final cantidadSel =
        double.tryParse(_cantidadController.text.replaceAll(',', '.')) ?? 0;
    if (cantidadSel <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad debe ser mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final precioSel =
        double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0;
    if (precioSel <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El precio debe ser mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final descuento = double.tryParse(_descuentoController.text) ?? 0;

    // El backend exige `cantidad` ENTERA (@IsInt). Resolución:
    // - unidad de compra + cantidad entera → se envía en esa unidad (conserva
    //   snapshot de unidad de compra).
    // - unidad de compra + cantidad fraccionaria (ej. 1.5 m tras convertir
    //   150 cm) → se "aplana" a unidad base atómica (cm enteros) con el costo
    //   equivalente; el resultado es idéntico.
    // - unidad base → entero directo.
    final usaUC = _tipoItem == 'producto' &&
        _productoSoportaUnidadCompra &&
        _usaUnidadCompra;
    final factor = _productoSeleccionado?.factorCompra ?? 1;
    final esEntera = (cantidadSel - cantidadSel.roundToDouble()).abs() < 1e-9;

    int cantidadEnviar;
    double precioEnviar;
    bool enviarUsaUC;
    if (usaUC && esEntera) {
      cantidadEnviar = cantidadSel.round();
      precioEnviar = precioSel;
      enviarUsaUC = true;
    } else if (usaUC && !esEntera && factor > 0) {
      cantidadEnviar = (cantidadSel * factor).round();
      precioEnviar = double.parse((precioSel / factor).toStringAsFixed(4));
      enviarUsaUC = false;
    } else {
      cantidadEnviar = cantidadSel.round();
      precioEnviar = precioSel;
      enviarUsaUC = false;
    }
    if (cantidadEnviar <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La cantidad debe ser mayor a 0'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final item = <String, dynamic>{
      'descripcion': descripcion,
      'cantidad': cantidadEnviar,
      'precioUnitario': precioEnviar,
      'descuento': descuento,
    };

    if (_tipoItem == 'producto' && _productoSeleccionado != null) {
      item['productoId'] = _productoSeleccionado!.id;
      if (_varianteSeleccionada != null) {
        item['varianteId'] = _varianteSeleccionada!.id;
      }
      // Snapshot para mostrar dual-view en la lista de items
      // antes de enviar al backend.
      if (enviarUsaUC) {
        item['usaUnidadCompra'] = true;
        item['factorCompra'] = _productoSeleccionado!.factorCompra;
        item['unidadCompraSimbolo'] =
            _productoSeleccionado!.unidadCompraSimbolo;
      }

      // Si el usuario seteó un nuevo precio de venta distinto al
      // actual, se aplica al confirmar la compra (mismo tx que el
      // costo). Si el field está vacío o coincide con el actual, no
      // mandamos nada.
      final nuevoPrecioVentaText =
          _nuevoPrecioVentaController.text.trim().replaceAll(',', '.');
      if (nuevoPrecioVentaText.isNotEmpty) {
        final nuevoPrecio = double.tryParse(nuevoPrecioVentaText);
        if (nuevoPrecio != null &&
            nuevoPrecio > 0 &&
            nuevoPrecio != _precioVentaActualSede) {
          item['nuevoPrecioVenta'] = nuevoPrecio;
        }
      }
    }

    widget.onItemAdded(item);
    setState(() => _limpiarSeleccion());
  }

  /// Card debajo de los campos cantidad/precio con:
  /// - Costo actual del producto en sede + costo proyectado tras compra
  /// - Precio venta actual + input para nuevo precio venta
  /// - Botones de sugerencia: "Mantener margen" y "+10%"
  /// - Si se completa el field, se aplicará al confirmar la compra.
  Widget _buildAjustePrecioVentaCard() {
    if (_loadingStockSede) {
      return Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text('Cargando precios actuales…',
                  style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      );
    }

    if (_costoActualSede == null && _precioVentaActualSede == null) {
      // Producto sin stock todavía — nada que mostrar
      return const SizedBox.shrink();
    }

    final costoNuevo = _nuevoCostoProyectado;
    final margenActual = _margenActualPct;
    final mantenerMargen = _precioMantenerMargen;
    final mas10 = _precioMas10;
    final hayLote =
        (double.tryParse(_cantidadController.text.replaceAll(',', '.')) ?? 0) >
                0 &&
            (double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0) >
                0;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.shade200, width: 0.6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.price_change_outlined,
                    size: 14, color: Colors.amber.shade900),
                const SizedBox(width: 6),
                Text(
                  'Ajustar precio venta al confirmar (opcional)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.amber.shade900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Línea costo: actual → proyectado
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Costo: S/${_costoActualSede?.toStringAsFixed(4) ?? '—'}',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade800),
                  ),
                ),
                if (hayLote && costoNuevo != null)
                  Text(
                    '→ S/${costoNuevo.toStringAsFixed(4)} (nuevo)',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: Colors.deepOrange.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 2),
            // Línea precio venta actual + margen
            Row(
              children: [
                Expanded(
                  child: Text(
                    'P. venta actual: S/${_precioVentaActualSede?.toStringAsFixed(2) ?? '—'}',
                    style: TextStyle(
                        fontSize: 10, color: Colors.grey.shade800),
                  ),
                ),
                if (margenActual != null)
                  Text(
                    'margen ${margenActual.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: margenActual >= 0
                          ? Colors.green.shade800
                          : Colors.red.shade700,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Input nuevo precio venta + sugerencias
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _nuevoPrecioVentaController,
                    borderColor: Colors.amber.shade700,
                    label: 'Nuevo precio venta',
                    hintText:
                        _precioVentaActualSede?.toStringAsFixed(2) ?? '0.00',
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                if (mantenerMargen != null)
                  _SugerenciaChip(
                    label:
                        'Mantener margen → S/${mantenerMargen.toStringAsFixed(2)}',
                    onTap: () => _aplicarSugerencia(mantenerMargen),
                  ),
                if (mas10 != null)
                  _SugerenciaChip(
                    label: '+10% → S/${mas10.toStringAsFixed(2)}',
                    onTap: () => _aplicarSugerencia(mas10),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Si dejás vacío, el precio venta NO cambia. Solo se aplica al confirmar la compra.',
                style: TextStyle(
                    fontSize: 9,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSubtitle('Agregar Producto'),
            const SizedBox(height: 6),
            _buildTipoToggle(),
            const SizedBox(height: 12),
            if (_tipoItem == 'producto') _buildProductoSelector(),
            if (_tipoItem == 'personalizado') _buildPersonalizadoForm(),
            if (_tipoItem == 'producto' && _productoSoportaUnidadCompra)
              _buildUnidadCompraToggle(),
            const SizedBox(height: 10),
            _buildCamposComunes(),
            if (_tipoItem == 'producto' &&
                _productoSoportaUnidadCompra &&
                _usaUnidadCompra)
              _buildPreviewConversion(),
            if (_tipoItem == 'producto' && _productoSeleccionado != null)
              _buildAdvertenciaCosto(),
            // Historial de compras del producto (a cuánto te lo dejó cada
            // proveedor) + variación vs último costo + margen.
            if (_tipoItem == 'producto' && _productoSeleccionado != null)
              HistorialComprasProductoPanel(
                productoId: _productoSeleccionado!.id,
                varianteId: _varianteSeleccionada?.id,
                precioCompra: _precioCompraAtomico,
                precioVenta: _precioVentaActualSede,
              ),
            if (_tipoItem == 'producto' &&
                _productoSeleccionado != null &&
                _varianteSeleccionada == null)
              _buildAjustePrecioVentaCard(),
            const SizedBox(height: 12),
            FloatingButtonText(
              width: double.infinity,
              onPressed: _agregarItem,
              label: 'Agregar Item',
              icon: Icons.add,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipoToggle() {
    return Container(
      alignment: AlignmentDirectional.center,
      child: SegmentedButton<String>(
        style: SegmentedButton.styleFrom(
          minimumSize: const Size(0, 30),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          backgroundColor: AppColors.blue1.withValues(alpha: 0.08),
          selectedBackgroundColor: AppColors.blue1,
          foregroundColor: AppColors.blue3,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: AppColors.blue1, width: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            fontFamily: 'Oxygen',
          ),
        ),
        segments: const [
          ButtonSegment(
            value: 'producto',
            label: Text('Producto'),
            icon: Icon(Icons.inventory_2, size: 15),
          ),
          ButtonSegment(
            value: 'personalizado',
            label: Text('Personalizado'),
            icon: Icon(Icons.edit_note, size: 17),
          ),
        ],
        selected: {_tipoItem},
        onSelectionChanged: (value) {
          setState(() {
            _tipoItem = value.first;
            _limpiarSeleccion();
          });
        },
      ),
    );
  }

  Widget _buildProductoSelector() {
    if (widget.sedeId == null) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Selecciona una sede primero para buscar productos',
          style: TextStyle(color: Colors.grey[500], fontSize: 13),
          textAlign: TextAlign.center,
        ),
      );
    }

    return ProductoSedeSelector(
      key: ValueKey(widget.sedeId),
      empresaId: widget.empresaId,
      sedeIdInicial: widget.sedeId,
      mostrarSelectorSede: false,
      soloProductos: true,
      label: 'Selecciona un producto *',
      hintText: 'Buscar producto...',
      labelBuilder: (producto) {
        return '${producto.nombre} | Stock: ${producto.stockTotal}';
      },
      onProductoSeleccionado: ({
        required ProductoListItem producto,
        required String sedeId,
        ProductoVariante? variante,
      }) {
        setState(() {
          _productoSeleccionado = producto;
          _varianteSeleccionada = variante;

          if (variante != null) {
            _descripcionController.text =
                '${producto.nombre} - ${variante.nombre}';
            final precio = variante.precioEnSede(sedeId) ?? 0.0;
            _precioController.text = precio.toStringAsFixed(2);
          } else {
            _descripcionController.text = producto.nombre;
            final precio = producto.precioEnSede(sedeId) ?? 0.0;
            _precioController.text = precio.toStringAsFixed(2);
          }
        });
        // Cargar precio venta + costo + stock actual en la sede para
        // mostrar el card "ajustar precio venta al confirmar".
        // Solo para producto base sin variante (las variantes tienen
        // su propio stock; por ahora soportamos solo el caso base).
        if (variante == null) {
          _cargarStockSede(producto.id);
        }
      },
    );
  }

  Widget _buildPersonalizadoForm() {
    return CustomText(
      controller: _descripcionController,
      borderColor: AppColors.blue1,
      label: 'Descripción *',
      hintText: 'Descripción del item (servicio, otro)',
      keyboardType: TextInputType.text,
    );
  }

  /// Toggle entre "comprar como unidad de COMPRA" (PAQUETE, KG, ...) vs
  /// "comprar como unidad de VENTA" (atómica). El producto debe tener
  /// unidadCompra+factor configurados (`_productoSoportaUnidadCompra`).
  Widget _buildUnidadCompraToggle() {
    final simbolo = _productoSeleccionado!.unidadCompraSimbolo ?? '?';
    final factor = _productoSeleccionado!.factorCompra ?? 1;
    // Unidad base real (ej. "cm"). Si el producto no la tiene, caemos a "UNID".
    final base = _productoSeleccionado!.unidadMedidaSimbolo ?? 'UNID';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
        decoration: BoxDecoration(
          color: AppColors.blue1.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.blue1.withValues(alpha: 0.2),
            width: 0.6,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Comprar por:',
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade700,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _UnidadOpcionChip(
                    label: simbolo,
                    factor: '×${_formatFactor(factor)}',
                    selected: _usaUnidadCompra,
                    onTap: () => _cambiarUnidadCompra(true),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _UnidadOpcionChip(
                    label: base,
                    factor: '×1',
                    selected: !_usaUnidadCompra,
                    onTap: () => _cambiarUnidadCompra(false),
                  ),
                ),
              ],
            ),
            _buildCostoEquivalente(base, simbolo, factor),
          ],
        ),
      ),
    );
  }

  /// Línea informativa: costo actual en unidad base y su equivalente en la
  /// unidad de compra (derivado = costoBase × factor). No se almacena.
  Widget _buildCostoEquivalente(String base, String simboloCompra, double factor) {
    final costoBase = _costoActualSede;
    if (costoBase == null || costoBase <= 0 || factor <= 0) {
      return const SizedBox.shrink();
    }
    final costoCompra = costoBase * factor;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(Icons.sell_outlined, size: 12, color: Colors.grey.shade600),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                children: [
                  const TextSpan(text: 'Costo actual: '),
                  TextSpan(
                    text: 'S/ ${costoBase.toStringAsFixed(2)} / $base',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const TextSpan(text: '  ≈  '),
                  TextSpan(
                    text:
                        'S/ ${costoCompra.toStringAsFixed(2)} / $simboloCompra',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1,
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

  /// Preview en vivo de la conversión que hará el backend cuando se
  /// usa unidad de compra. Lee cantidad+precio del input y muestra
  /// equivalente atómico.
  Widget _buildPreviewConversion() {
    final cantidad =
        double.tryParse(_cantidadController.text.replaceAll(',', '.')) ?? 0;
    final precio =
        double.tryParse(_precioController.text.replaceAll(',', '.')) ?? 0;
    final factor = _productoSeleccionado!.factorCompra ?? 1;
    final cantidadAtomica = cantidad * factor;
    final precioAtomico = factor > 0 ? precio / factor : 0;
    if (cantidad <= 0 && precio <= 0) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.green.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.swap_horiz, size: 14, color: Colors.green.shade800),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '= ${_formatNum(cantidadAtomica)} unidad(es) · '
                'costo S/${precioAtomico.toStringAsFixed(2)}/u',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.green.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Opción B: advertencia cuando el costo atómico resultante diverge mucho
  /// del costo actual (>4× o <1/4×) — típico al equivocar la unidad.
  Widget _buildAdvertenciaCosto() {
    final costoActual = _costoActualSede;
    final atomico = _precioCompraAtomico;
    if (costoActual == null || costoActual <= 0 || atomico <= 0) {
      return const SizedBox.shrink();
    }
    final ratio = atomico / costoActual;
    if (ratio <= 4 && ratio >= 0.25) return const SizedBox.shrink();
    final base = _productoSeleccionado?.unidadMedidaSimbolo ?? 'u';
    final detalle = ratio >= 1
        ? '${_formatNum(ratio)}× más caro'
        : '${_formatNum(1 / ratio)}× más barato';
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.orange.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 15, color: Colors.orange.shade800),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'Costo resultante S/${atomico.toStringAsFixed(2)}/$base — '
                '$detalle que el actual (S/${costoActual.toStringAsFixed(2)}/$base). '
                '¿La unidad es correcta?',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.orange.shade900,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatFactor(double n) {
    if ((n - n.truncateToDouble()).abs() < 1e-6) {
      return n.toStringAsFixed(0);
    }
    return n.toStringAsFixed(2);
  }

  String _formatNum(double n) {
    if ((n - n.truncateToDouble()).abs() < 1e-6) {
      return n.toStringAsFixed(0);
    }
    return n.toStringAsFixed(2);
  }

  Widget _buildCamposComunes() {
    return Row(
      children: [
        Expanded(
          child: CustomText(
            controller: _cantidadController,
            borderColor: AppColors.blue1,
            label: _simboloUnidadSel != null
                ? 'Cantidad en $_simboloUnidadSel'
                : 'Cantidad',
            hintText: 'Cantidad',
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            // Cualquier cambio refresca preview (unidadCompra +
            // card ajuste precio venta).
            onChanged: (_) {
              if (_productoSeleccionado != null) setState(() {});
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomText(
            controller: _precioController,
            borderColor: AppColors.blue1,
            label: _simboloUnidadSel != null
                ? 'P. Unit x $_simboloUnidadSel'
                : 'Precio Unit.',
            hintText: 'Precio Compra',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) {
              if (_productoSeleccionado != null) setState(() {});
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: CustomText(
            controller: _descuentoController,
            borderColor: AppColors.blue1,
            label: 'Descuento',
            hintText: 'Descuento',
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ),
      ],
    );
  }
}

/// Chip selector compacto para alternar entre unidad de compra y unidad
/// de venta. Pintado como chip con borde + factor pequeño debajo del label.
class _UnidadOpcionChip extends StatelessWidget {
  final String label;
  final String factor;
  final bool selected;
  final VoidCallback onTap;

  const _UnidadOpcionChip({
    required this.label,
    required this.factor,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: selected
                ? AppColors.blue1
                : AppColors.blue1.withValues(alpha: 0.3),
            width: 0.8,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColors.blue1,
              ),
            ),
            Text(
              factor,
              style: TextStyle(
                fontSize: 8,
                color: selected
                    ? Colors.white.withValues(alpha: 0.85)
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Chip pequeño tipo "atajo" para aplicar una sugerencia de precio.
class _SugerenciaChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SugerenciaChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.amber.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.amber.shade300, width: 0.6),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: Colors.amber.shade900,
            ),
          ),
        ),
      ),
    );
  }
}
