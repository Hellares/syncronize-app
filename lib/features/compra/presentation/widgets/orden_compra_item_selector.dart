import 'package:flutter/material.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector_exports.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/entities/producto_variante.dart';
import 'historial_compras_producto_panel.dart';
import 'quick_create_producto_dialog.dart';

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
  // Empaque (unidades por paquete/saco) para ESTA compra. Arranca con el
  // factor configurado del producto, pero el usuario puede ajustarlo si el
  // lote vino con otra cantidad (override puntual, no toca la config).
  final _factorController = TextEditingController();
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
  // Se incrementa para forzar un buscador de productos FRESCO (limpia el
  // mensaje "no encontrados" y re-carga la lista) tras crear un producto.
  int _selectorReset = 0;

  @override
  void dispose() {
    _descripcionController.dispose();
    _cantidadController.dispose();
    _precioController.dispose();
    _descuentoController.dispose();
    _nuevoPrecioVentaController.dispose();
    _factorController.dispose();
    super.dispose();
  }

  void _limpiarSeleccion() {
    _descripcionController.clear();
    _cantidadController.text = '1';
    _precioController.clear();
    _descuentoController.text = '0';
    _nuevoPrecioVentaController.clear();
    _factorController.clear();
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
        // Precargar el precio de la línea con el COSTO actual (solo si el
        // usuario no escribió nada todavía).
        if (_costoActualSede != null &&
            _costoActualSede! > 0 &&
            _precioController.text.trim().isEmpty) {
          _precioController.text = _fmtPrecio(_costoActualSede!);
        }
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
      final factor = _factorEfectivo;
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
      final factor = _factorEfectivo;
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

  /// Sugerencia: costo NUEVO + 10% (margen fijo del 10% sobre el costo
  /// proyectado). Siempre cubre el costo, a diferencia de basarlo en la venta
  /// vieja (que en un salto de costo se quedaba por debajo).
  double? get _precioMas10 {
    final costoNuevo = _nuevoCostoProyectado;
    if (costoNuevo == null || costoNuevo <= 0) return null;
    return double.parse((costoNuevo * 1.1).toStringAsFixed(2));
  }

  /// Precio de venta que quedaría tras esta compra: el nuevo (si se escribió)
  /// o, si no, el actual.
  double? get _precioVentaEfectivo {
    final txt = _nuevoPrecioVentaController.text.trim().replaceAll(',', '.');
    final nuevo = double.tryParse(txt);
    if (nuevo != null && nuevo > 0) return nuevo;
    return _precioVentaActualSede;
  }

  /// True si el costo (el de ESTA compra / el proyectado del producto) supera
  /// al precio de venta efectivo → se vendería con pérdida.
  bool get _costoSuperaVenta {
    final precioCompra = _precioCompraAtomico;
    if (precioCompra <= 0) return false; // aún no hay precio de compra
    final costo = _nuevoCostoProyectado ?? precioCompra;
    final venta = _precioVentaEfectivo;
    if (venta == null || venta <= 0) return false;
    return costo > venta;
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

  /// Factor de compra EFECTIVO para esta línea: el que el usuario escribió en
  /// el campo de empaque (override puntual) o, si está vacío/ inválido, el
  /// configurado en el producto.
  double get _factorEfectivo {
    final base = _productoSeleccionado?.factorCompra ?? 1;
    final parsed =
        double.tryParse(_factorController.text.replaceAll(',', '.').trim());
    if (parsed != null && parsed > 0) return parsed;
    return base > 0 ? base : 1;
  }

  /// True si el empaque de esta compra difiere del configurado en el producto.
  bool get _factorDifiereDelProducto {
    final base = _productoSeleccionado?.factorCompra;
    if (base == null) return false;
    return (_factorEfectivo - base).abs() > 1e-9;
  }

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
    final factor = _factorEfectivo;
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

  Future<void> _agregarItem() async {
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
    final factor = _factorEfectivo;
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
        // Factor EFECTIVO (override puntual o el del producto). Se usa para el
        // snapshot dual-view y se envía al backend como override de la línea.
        item['factorCompra'] = _factorEfectivo;
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

    // Bloqueo: si el costo nuevo supera el precio de venta, NO se agrega
    // hasta que el usuario actualice el precio de venta para cubrirlo.
    if (_costoSuperaVenta) {
      await _avisarCostoSupera();
      return;
    }

    widget.onItemAdded(item);
    setState(() => _limpiarSeleccion());
  }

  /// Aviso BLOQUEANTE: el costo supera el precio de venta. No deja agregar el
  /// ítem; el usuario debe actualizar el precio de venta en la card de abajo.
  Future<void> _avisarCostoSupera() async {
    final costo = _nuevoCostoProyectado ?? _precioCompraAtomico;
    final venta = _precioVentaEfectivo;
    await StyledDialog.show<void>(
      context,
      accentColor: Colors.red.shade700,
      icon: Icons.block,
      titulo: 'Actualiza el precio de venta',
      backgroundColor: Colors.white,
      content: [
        Text(
          'El nuevo costo (S/ ${costo.toStringAsFixed(2)}) supera el precio de '
          'venta (S/ ${venta?.toStringAsFixed(2) ?? '—'}).',
          style: const TextStyle(
              fontSize: 12.5, height: 1.35, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Text(
          'Para agregar este producto, primero sube el precio de venta por '
          'encima del costo en la card "Ajustar precio venta" de abajo '
          '(puedes usar "Mantener margen" o "+10%").',
          style: TextStyle(
              fontSize: 11.5, height: 1.35, color: Colors.grey.shade700),
        ),
      ],
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Entendido',
            backgroundColor: AppColors.blue1,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
      ],
    );
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

    // La card se muestra aunque el producto aún no tenga costo/venta (ej. un
    // producto recién creado), para poder fijar el precio de venta aquí mismo.
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
            // Aviso fuerte: el costo nuevo supera el precio de venta.
            if (_costoSuperaVenta) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: Colors.red.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'El costo nuevo supera el precio de venta. '
                        'Actualiza el precio de venta para no vender con pérdida.',
                        style: TextStyle(
                          fontSize: 10,
                          height: 1.3,
                          color: Colors.red.shade800,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
                        'Mantener margen${margenActual != null ? ' ${margenActual.toStringAsFixed(0)}%' : ''} → S/${mantenerMargen.toStringAsFixed(2)}',
                    onTap: () => _aplicarSugerencia(mantenerMargen),
                  ),
                if (mas10 != null)
                  _SugerenciaChip(
                    label: 'Costo +10% → S/${mas10.toStringAsFixed(2)}',
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
                empresaId: widget.empresaId,
                productoId: _productoSeleccionado!.id,
                varianteId: _varianteSeleccionada?.id,
                precioCompra: _precioCompraAtomico,
                precioVenta: _precioVentaActualSede,
              ),
            if (_tipoItem == 'producto' &&
                _productoSeleccionado != null &&
                _varianteSeleccionada == null)
              _buildAjustePrecioVentaCard(),
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
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: AppColors.blue1.withValues(alpha: 0.08),
          selectedBackgroundColor: AppColors.blue1,
          foregroundColor: AppColors.blue3,
          selectedForegroundColor: Colors.white,
          side: BorderSide(color: AppColors.blue1, width: 0.6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 10,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Indicador claro del producto activo (el buscador no muestra la
        // selección hecha por código, ej. tras crear un producto).
        if (_productoSeleccionado != null) _buildProductoSeleccionadoBanner(),
        ProductoSedeSelector(
          key: ValueKey('${widget.sedeId}_$_selectorReset'),
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
            _aplicarSeleccionProducto(
              producto: producto,
              variante: variante,
              sedeId: sedeId,
            );
          },
        ),
        // const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: _crearProductoNuevo,
            icon: const Icon(Icons.add_box_outlined, size: 16),
            label: const Text('¿No existe? Crear producto nuevo'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.blue1,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              textStyle: const TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }

  /// Aplica la selección de un producto (desde el buscador o recién creado):
  /// setea descripción, empaque (factor) y precio por defecto (= costo) y
  /// dispara la carga de costo/stock de la sede.
  void _aplicarSeleccionProducto({
    required ProductoListItem producto,
    ProductoVariante? variante,
    required String sedeId,
  }) {
    setState(() {
      _productoSeleccionado = producto;
      _varianteSeleccionada = variante;
      // Pre-cargar el empaque con el factor configurado del producto.
      final f = producto.factorCompra;
      _factorController.text = (f != null && f > 0) ? _fmtPrecio(f) : '';

      if (variante != null) {
        _descripcionController.text =
            '${producto.nombre} - ${variante.nombre}';
        final precio = variante.precioEnSede(sedeId) ?? 0.0;
        _precioController.text = precio.toStringAsFixed(2);
      } else {
        _descripcionController.text = producto.nombre;
        // En una COMPRA el precio por defecto es el COSTO actual, no el de
        // venta. Si ya está cargado para este producto, lo ponemos; si no,
        // queda vacío y _cargarStockSede lo completa al traer el costo.
        if (_productoIdInfoCargada == producto.id &&
            _costoActualSede != null &&
            _costoActualSede! > 0) {
          _precioController.text = _fmtPrecio(_costoActualSede!);
        } else {
          _precioController.clear();
        }
      }
    });
    // Cargar precio venta + costo + stock actual en la sede para mostrar el
    // card "ajustar precio venta al confirmar". Solo producto base sin variante.
    if (variante == null) {
      _cargarStockSede(producto.id);
    }
  }

  /// Abre el diálogo de creación rápida y, si se crea, lo deja seleccionado.
  Future<void> _crearProductoNuevo() async {
    final sedeId = widget.sedeId;
    if (sedeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona una sede primero'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    final res = await showQuickCreateProductoDialog(
      context,
      empresaId: widget.empresaId,
      sedeId: sedeId,
    );
    if (res == null || !mounted) return;
    // Producto nuevo: forzamos recarga de costo/stock (cache por id) y
    // reseteamos el buscador (limpia "no encontrados" + re-carga la lista).
    _productoIdInfoCargada = null;
    setState(() => _selectorReset++);
    _aplicarSeleccionProducto(producto: res.producto, sedeId: sedeId);
    // Precio de venta opcional → se aplica al confirmar la compra (mismo
    // mecanismo que con productos existentes).
    if (res.precioVenta != null) {
      _nuevoPrecioVentaController.text = res.precioVenta!.toStringAsFixed(2);
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Producto "${res.producto.nombre}" creado. Completa cantidad y precio de compra.'),
        backgroundColor: Colors.green,
      ),
    );
  }

  /// Banner verde que confirma cuál es el producto activo. El buscador no
  /// muestra la selección hecha por código, así que este indicador evita la
  /// confusión de "parece que no se agregó".
  Widget _buildProductoSeleccionadoBanner() {
    final p = _productoSeleccionado!;
    final nombre = _varianteSeleccionada != null
        ? '${p.nombre} - ${_varianteSeleccionada!.nombre}'
        : p.nombre;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.green.shade300, width: 0.8),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green.shade600, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Producto seleccionado',
                  style: TextStyle(
                      fontSize: 9,
                      color: Colors.green.shade800,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  nombre,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w700),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _limpiarSeleccion()),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Icon(Icons.close, size: 16, color: Colors.grey.shade600),
            ),
          ),
        ],
      ),
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
    // Factor efectivo (override puntual o config del producto).
    final factor = _factorEfectivo;
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
            if (_usaUnidadCompra) _buildFactorEditable(simbolo, base),
            _buildCostoEquivalente(base, simbolo, factor),
          ],
        ),
      ),
    );
  }

  /// Campo editable del empaque para ESTA compra: cuántas unidades base trae
  /// el paquete/saco. Default = factor del producto; el usuario lo ajusta si
  /// el lote vino con otra cantidad (no toca la config del producto).
  Widget _buildFactorEditable(String simboloCompra, String base) {
    final configurado = _productoSeleccionado?.factorCompra ?? 1;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '1 $simboloCompra =',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              // SizedBox(
              //   width: 60,
              //   height: 32,
                // child: TextField(
                //   controller: _factorController,
                //   keyboardType:
                //       const TextInputType.numberWithOptions(decimal: true),
                //   textAlign: TextAlign.center,
                //   style: const TextStyle(
                //       fontSize: 12, fontWeight: FontWeight.w600),
                //   decoration: InputDecoration(
                //     isDense: true,
                //     contentPadding:
                //         const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                //     border: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(6),
                //     ),
                //     enabledBorder: OutlineInputBorder(
                //       borderRadius: BorderRadius.circular(6),
                //       borderSide: BorderSide(
                //           color: AppColors.blue1.withValues(alpha: 0.4)),
                //     ),
                //   ),
                //   onChanged: (_) => setState(() {}),
                // ),
              // ),
              SizedBox(
                width: 70,
                child: CustomText(
                  controller: _factorController,
                  keyboardType: TextInputType.numberWithOptions(),
                  onChanged: (_) => setState((){}),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                base,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_factorDifiereDelProducto)
                InkWell(
                  onTap: () => setState(
                      () => _factorController.text = _fmtPrecio(configurado)),
                  borderRadius: BorderRadius.circular(4),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 4, vertical: 2),
                    child: Text(
                      'Restablecer (${_formatFactor(configurado)})',
                      style: const TextStyle(
                          fontSize: 10,
                          color: AppColors.blue1,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              _factorDifiereDelProducto
                  ? 'Empaque solo para esta compra (no cambia la config del producto)'
                  : 'Unidades por $simboloCompra en esta compra',
              style: TextStyle(
                fontSize: 8.5,
                color: _factorDifiereDelProducto
                    ? Colors.orange.shade800
                    : Colors.grey.shade500,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
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
    final factor = _factorEfectivo;
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
      // Alinea al fondo para que las cajas (33px) y el botón "+" queden
      // a la misma altura, sin importar si algún label ocupa 2 líneas.
      crossAxisAlignment: CrossAxisAlignment.end,
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
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
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
        const SizedBox(width: 8),
        // Botón "+" a la misma altura que las cajas (33px).
        _buildAddButton(),
      ],
    );
  }

  /// Botón compacto "+" para agregar el ítem, alineado con la altura de
  /// las cajas de Cantidad/Precio/Descuento (33px).
  Widget _buildAddButton() {
    return SizedBox(
      height: CustomTextFieldConstants.defaultHeight,
      width: 42,
      child: Material(
        color: AppColors.blue1,
        borderRadius: BorderRadius.circular(6),
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: _agregarItem,
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 22),
          ),
        ),
      ),
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
