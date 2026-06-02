import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/network/dio_client.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/utils/date_formatter.dart' as date_utils;
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/currency/currency_formatter.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/date/custom_date.dart';
import '../../domain/entities/precio_nivel.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/repositories/precio_nivel_repository.dart';
import '../../domain/services/precio_nivel_cache_service.dart';
import 'precio_nivel_form_dialog.dart';
import 'gestionar_liquidacion_dialog.dart';
import '../pages/historial_precios_producto_page.dart';
import '../bloc/configurar_precios/configurar_precios_cubit.dart';
import '../bloc/configurar_precios/configurar_precios_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';

/// Dialog para configurar precios de un producto en una sede
class ConfigurarPreciosDialog extends StatefulWidget {
  final ProductoStock stock;
  final String empresaId;

  const ConfigurarPreciosDialog({
    super.key,
    required this.stock,
    required this.empresaId,
  });

  @override
  State<ConfigurarPreciosDialog> createState() =>
      _ConfigurarPreciosDialogState();
}

class _ConfigurarPreciosDialogState extends State<ConfigurarPreciosDialog> {
  final _formKey = GlobalKey<FormState>();
  final _precioController = TextEditingController();
  final _precioCostoController = TextEditingController();
  final _precioOfertaController = TextEditingController();

  bool _enOferta = false;
  DateTime? _fechaInicioOferta;
  DateTime? _fechaFinOferta;

  bool _precioIncluyeIGV = false;
  bool _desgloseVisible = false;
  double _porcentajeIGV = 18.0;
  String _nombreImpuesto = 'IGV';
  String _simboloMoneda = 'S/';

  // ── Niveles de precio (PRECIO_FIJO + PORCENTAJE_DESCUENTO) ──
  late final PrecioNivelRepository _precioNivelRepo;
  late final PrecioNivelCacheService _nivelCacheService;
  bool _cargandoNiveles = false;
  /// Todos los niveles activos del producto/variante. Los fijos se editan/
  /// agregan desde aquí; los porcentuales solo se visualizan/eliminan
  /// (para crearlos/editarlos hay que ir al form completo del producto).
  List<PrecioNivel> _nivelesExistentes = const [];
  /// IDs de niveles que están siendo eliminados (para deshabilitar el
  /// botón papelera mientras la request está en vuelo).
  final Set<String> _eliminandoNiveles = {};

  // Info de unidad de compra del insumo (para mostrar el costo por kg/m/caja).
  // Se carga con un GET /productos/{id} solo si el producto es insumo.
  double? _factorCompra;
  String? _simboloCompra;
  String? _simboloBase;

  /// Insumo: no se vende directamente (bloqueado en POS/marketplace/carrito/
  /// combo), así que oferta, liquidación y precios por volumen no aplican.
  bool get _esInsumo => widget.stock.producto?.esInsumo == true;

  @override
  void initState() {
    super.initState();

    // Inicializar controladores con valores actuales
    if (widget.stock.precio != null && widget.stock.precio! > 0) {
      _precioController.text = widget.stock.precio!.toStringAsFixed(2);
    }
    if (widget.stock.precioCosto != null && widget.stock.precioCosto! > 0) {
      _precioCostoController.text = widget.stock.precioCosto!.toStringAsFixed(
        2,
      );
    }
    if (widget.stock.precioOferta != null && widget.stock.precioOferta! > 0) {
      _precioOfertaController.text = widget.stock.precioOferta!.toStringAsFixed(
        2,
      );
    }
    _enOferta = widget.stock.enOferta;
    // Backend devuelve UTC (ej. "2026-05-09T04:59:59Z"). Convertir a local
    // para que CustomDate muestre el día correcto en hora Perú.
    _fechaInicioOferta = widget.stock.fechaInicioOferta?.toLocal();
    _fechaFinOferta = widget.stock.fechaFinOferta?.toLocal();
    _precioIncluyeIGV = widget.stock.precioIncluyeIgv;

    // Leer configuración de empresa para IGV
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      _porcentajeIGV = configState.configuracion.impuestoDefaultPorcentaje;
      _nombreImpuesto = configState.configuracion.nombreImpuesto;
      _simboloMoneda = configState.configuracion.simboloMoneda;
    }

    // Cargar niveles de precio existentes (precio por mayor)
    _precioNivelRepo = locator<PrecioNivelRepository>();
    _nivelCacheService = locator<PrecioNivelCacheService>();
    _cargarNivelesExistentes();

    // Para insumos con unidad de compra: refrescar el costo equivalente al
    // editar el costo, y traer factor + símbolos del producto.
    _precioCostoController.addListener(_onCostoChanged);
    if (widget.stock.producto?.esInsumo == true &&
        widget.stock.productoId != null) {
      _cargarInfoCompra();
    }
  }

  void _onCostoChanged() {
    if (mounted) setState(() {});
  }

  /// GET /productos/{id} para obtener factorCompra + símbolos de unidad de
  /// compra y base (informativo; si falla, no se muestra el label).
  Future<void> _cargarInfoCompra() async {
    try {
      final resp =
          await locator<DioClient>().get('/productos/${widget.stock.productoId}');
      final det = resp.data as Map<String, dynamic>?;
      if (!mounted || det == null) return;
      final fc = det['factorCompra'];
      setState(() {
        _factorCompra = fc is num
            ? fc.toDouble()
            : (fc is String ? double.tryParse(fc) : null);
        _simboloCompra = _simboloDeUnidad(det['unidadCompra']);
        _simboloBase = _simboloDeUnidad(det['unidadMedida']);
      });
    } catch (_) {
      // Silencioso: el costo por unidad de compra es solo informativo.
    }
  }

  String? _simboloDeUnidad(dynamic um) {
    if (um is! Map) return null;
    final maestra = um['unidadMaestra'];
    return (um['simboloLocal'] ??
        um['simboloPersonalizado'] ??
        (maestra is Map ? maestra['simbolo'] : null)) as String?;
  }

  /// Label informativo: costo por unidad de COMPRA (kg, m, caja…) = costo
  /// por unidad base × factorCompra. Solo para insumos con unidad de compra
  /// configurada. Se actualiza en vivo al editar el precio de costo.
  Widget _buildCostoUnidadCompra() {
    final factor = _factorCompra;
    final simbolo = _simboloCompra;
    if (factor == null ||
        factor <= 1 ||
        simbolo == null ||
        simbolo.isEmpty) {
      return const SizedBox.shrink();
    }
    final cv = _precioCostoController.currencyValue;
    final costoBase = cv > 0 ? cv : (widget.stock.precioCosto ?? 0);
    if (costoBase <= 0) return const SizedBox.shrink();
    final costoCompra = costoBase * factor;
    final base = _simboloBase ?? 'u';
    final factorTxt = factor == factor.truncateToDouble()
        ? factor.toStringAsFixed(0)
        : factor.toStringAsFixed(2);
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        children: [
          Icon(Icons.sell_outlined, size: 12, color: AppColors.blue1),
          const SizedBox(width: 4),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                children: [
                  TextSpan(text: 'Costo por $simbolo: '),
                  TextSpan(
                    text: '$_simboloMoneda ${costoCompra.toStringAsFixed(2)}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.blue1),
                  ),
                  TextSpan(
                    text:
                        '  ($_simboloMoneda ${costoBase.toStringAsFixed(2)}/$base × $factorTxt)',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarNivelesExistentes() async {
    setState(() => _cargandoNiveles = true);
    final result = widget.stock.varianteId != null
        ? await _precioNivelRepo.getPreciosNivelVariante(
            varianteId: widget.stock.varianteId!,
          )
        : widget.stock.productoId != null
            ? await _precioNivelRepo.getPreciosNivelProducto(
                productoId: widget.stock.productoId!,
              )
            : null;

    if (!mounted) return;

    if (result is Success<List<PrecioNivel>>) {
      final activos = result.data.where((n) => n.isActive).toList()
        ..sort((a, b) => a.cantidadMinima.compareTo(b.cantidadMinima));
      setState(() {
        _cargandoNiveles = false;
        _nivelesExistentes = activos;
      });
    } else {
      setState(() => _cargandoNiveles = false);
    }
  }

  @override
  void dispose() {
    _precioCostoController.removeListener(_onCostoChanged);
    _precioController.dispose();
    _precioCostoController.dispose();
    _precioOfertaController.dispose();
    super.dispose();
  }

  // Helper para obtener el valor numérico del controlador. Usa el parser de
  // currency para que funcione con texto formateado (ej. "1,234.56") que es
  // lo que produce CurrencyTextField al perder foco.
  double _getControllerValue(TextEditingController controller) {
    return CurrencyUtilsImproved.parseToDouble(controller.text);
  }

  double _calcularPrecioBase(double precioConIGV) =>
      precioConIGV / (1 + _porcentajeIGV / 100);

  double _calcularMontoIGV(double precioBase) =>
      precioBase * (_porcentajeIGV / 100);

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConfigurarPreciosCubit, ConfigurarPreciosState>(
      listener: (context, state) {
        if (state is ConfigurarPreciosSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Retorna true para indicar éxito
        } else if (state is ConfigurarPreciosError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message), backgroundColor: Colors.red),
          );
        }
      },
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 30),
        child: GradientContainer(
          gradient: AppGradients.blueWhiteDialog(),
          padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
          borderRadius: BorderRadius.circular(10.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Título
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.bluechip,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.attach_money,
                        color: AppColors.blue1,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppTitle('Configurar Precios'),
                          AppSubtitle(
                            widget.stock.sede?.nombre ?? 'Sede',
                            fontSize: 10,
                            color: AppColors.blue1,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Ver historial de precios',
                      icon: Icon(Icons.history, color: AppColors.blue1, size: 22),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => HistorialPreciosProductoPage(
                              productoStockId: widget.stock.id,
                              productoNombre:
                                  widget.stock.producto?.nombre ??
                                      widget.stock.variante?.nombre ??
                                      'Producto',
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Divider(),
                const SizedBox(height: 12),

                // Información del producto
                _buildProductoInfo(),
                const SizedBox(height: 10),

                // Formulario
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Si el producto es un INSUMO, no se vende directo.
                      // Ocultamos completamente el bloque Precio Venta + IGV
                      // y mostramos solo un banner explicativo. El costo se
                      // gestiona desde el bloque Precio Costo más abajo y
                      // se actualiza al registrar compras.
                      if (widget.stock.producto?.esInsumo == true) ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.inventory_2_outlined,
                                  color: Colors.amber.shade800, size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Producto INSUMO. No se vende directo — el Precio Venta no aplica. Solo importa el Costo, que se actualiza al registrar compras.',
                                  style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.amber.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Precio de Venta + toggle IGV en una sola fila.
                        // Si el producto está en liquidación activa, el precio
                        // base no aplica (gana la liquidación en el cálculo
                        // del precioEfectivo). Bloqueamos la edición para
                        // evitar confusiones y posibles inconsistencias.
                        if (_stockEfectivo.isLiquidacionActiva) ...[
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Icon(Icons.lock_outline,
                                    size: 12,
                                    color: Colors.deepOrange.shade700),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Precio venta bloqueado: el producto está en liquidación. Desactivá la liquidación para editarlo.',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.deepOrange.shade700,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 1,
                              child: CurrencyTextField(
                                label: 'Precio de Venta',
                                controller: _precioController,
                                borderColor: AppColors.blue1,
                                enabled: !_stockEfectivo.isLiquidacionActiva,
                                onChanged: (_) {
                                  if (_precioIncluyeIGV) setState(() {});
                                },
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'El precio es requerido';
                                  }
                                  final precio = CurrencyUtilsImproved.parseToDouble(value);
                                  if (precio <= 0) {
                                    return 'El precio debe ser mayor a 0';
                                  }
                                  // Validar precio >= costo
                                  final costo = _precioCostoController.currencyValue;
                                  if (costo > 0 && precio < costo) {
                                    return 'El precio debe ser ≥ al costo';
                                  }
                                  // Si por algun motivo se intenta guardar
                                  // un precio venta < precio liquidacion
                                  // activa, rechazar (sino la liquidacion
                                  // ya no es "bajo el precio base").
                                  final liq = _stockEfectivo.precioLiquidacion;
                                  if (_stockEfectivo.isLiquidacionActiva &&
                                      liq != null &&
                                      precio < liq) {
                                    return 'Precio debe ser ≥ liquidación (S/${liq.toStringAsFixed(2)})';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 1,
                              child: InkWell(
                                onTap: () => setState(() =>
                                    _precioIncluyeIGV = !_precioIncluyeIGV),
                                borderRadius: BorderRadius.circular(6),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: Checkbox(
                                          value: _precioIncluyeIGV,
                                          onChanged: (value) {
                                            setState(() {
                                              _precioIncluyeIGV = value ?? false;
                                            });
                                          },
                                          activeColor: AppColors.blue1,
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          visualDensity: VisualDensity.compact,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      Icon(Icons.receipt_long,
                                          size: 13, color: AppColors.blue1),
                                      const SizedBox(width: 4),
                                      Flexible(
                                        child: AppSubtitle(
                                          'Incluye $_nombreImpuesto (${_porcentajeIGV.toStringAsFixed(_porcentajeIGV.truncateToDouble() == _porcentajeIGV ? 0 : 1)}%)',
                                          fontSize: 10,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Desglose de precio colapsable
                      if (_precioIncluyeIGV &&
                          CurrencyUtilsImproved.parseToDouble(_precioController.text) > 0)
                        InkWell(
                          onTap: () => setState(() => _desgloseVisible = !_desgloseVisible),
                          borderRadius: BorderRadius.circular(6),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _desgloseVisible
                                      ? Icons.expand_less
                                      : Icons.expand_more,
                                  size: 16,
                                  color: AppColors.blue1,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Ver desglose $_nombreImpuesto',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.blue1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_precioIncluyeIGV && _desgloseVisible) _buildDesgloseIGV(),

                      const SizedBox(height: 12),

                      // Precio de Costo + toggle "Producto en oferta" en una sola fila
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 1,
                            child: CurrencyTextField(
                              label: 'Precio de Costo (por unidad)',
                              controller: _precioCostoController,
                              borderColor: AppColors.blue1,
                              allowZero: false,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return null;
                                }
                                final nuevoCosto = CurrencyUtilsImproved
                                    .parseToDouble(value);
                                final liq =
                                    _stockEfectivo.precioLiquidacion;
                                if (_stockEfectivo.isLiquidacionActiva &&
                                    liq != null &&
                                    nuevoCosto > 0 &&
                                    nuevoCosto <= liq) {
                                  return 'Costo ≤ liquidación (S/${liq.toStringAsFixed(2)}). Desactivá la liquidación primero.';
                                }
                                return null;
                              },
                            ),
                          ),
                          if (!_esInsumo) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _enOferta = !_enOferta),
                              borderRadius: BorderRadius.circular(6),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: Checkbox(
                                        value: _enOferta,
                                        onChanged: (value) {
                                          setState(() {
                                            _enOferta = value ?? false;
                                          });
                                        },
                                        activeColor: AppColors.blue1,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.local_offer_outlined,
                                        size: 13, color: AppColors.blue1),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: AppSubtitle(
                                        'Producto en oferta',
                                        fontSize: 10,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          ],
                        ],
                      ),
                      _buildCostoUnidadCompra(),
                      InkWell(
                        onTap: _abrirCalculadoraLote,
                        borderRadius: BorderRadius.circular(4),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 4, horizontal: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calculate_outlined,
                                  size: 12, color: AppColors.blue1),
                              const SizedBox(width: 4),
                              Text(
                                'Calcular desde compra',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: AppColors.blue1,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      if (!_esInsumo && _enOferta) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              flex: 2,
                              child: CurrencyTextField(
                                label: 'Precio de Oferta',
                                controller: _precioOfertaController,
                                borderColor: AppColors.blue1,
                                allowZero: false,
                                validator: (value) {
                                  if (!_enOferta) return null;
                                  final oferta = CurrencyUtilsImproved
                                      .parseToDouble(value ?? '');
                                  if (oferta <= 0) {
                                    return 'El precio de oferta debe ser mayor a 0';
                                  }
                                  final venta =
                                      _precioController.currencyValue;
                                  if (venta > 0 && oferta >= venta) {
                                    return 'Debe ser < precio normal';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 3,
                              child: CustomDate(
                          label: 'Vigencia de la oferta',
                          dateType: DateFieldType.dateRange,
                          borderColor: AppColors.blue1,
                          hintText: 'Seleccionar rango de fechas',
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                          showDaysSelectedLabel: false,
                          initialDateRange: _fechaInicioOferta != null || _fechaFinOferta != null
                              ? DateRange(
                                  startDate: _fechaInicioOferta,
                                  endDate: _fechaFinOferta,
                                )
                              : null,
                          onDateRangeSelected: (range) {
                            setState(() {
                              _fechaInicioOferta = range?.startDate != null
                                  ? date_utils.DateFormatter.startOfDay(range!.startDate!)
                                  : null;
                              _fechaFinOferta = range?.endDate != null
                                  ? date_utils.DateFormatter.endOfDay(range!.endDate!)
                                  : null;
                            });
                          },
                          rangeValidator: (_) => null,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Liquidación y Precios por Volumen no aplican a insumos
                      // (no se venden directamente).
                      if (!_esInsumo) ...[
                        // ── Sección Liquidación (remate bajo costo) ──
                        const SizedBox(height: 8),
                        const Divider(),
                        _buildSeccionLiquidacion(),

                        // ── Sección Precios por Volumen (gestión de niveles) ──
                        const SizedBox(height: 8),
                        const Divider(),
                        _buildSeccionNiveles(),
                      ],
                    ],
                  ),
                ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Botones de acción (fijos al fondo, fuera del scroll)
              BlocBuilder<ConfigurarPreciosCubit, ConfigurarPreciosState>(
                builder: (context, state) {
                  final isLoading = state is ConfigurarPreciosLoading;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: AppSubtitle(
                          'Cancelar',
                          fontSize: 12,
                          color: AppColors.blue1,
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : AppSubtitle(
                                'Guardar',
                                fontSize: 12,
                                color: Colors.white,
                              ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductoInfo() {
    final producto = widget.stock.producto;
    return GradientContainer(
      gradient: AppGradients.blue(),
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            producto?.nombre ?? 'Producto',
            fontSize: 12,
            color: AppColors.textPrimary,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.inventory_2, size: 12, color: AppColors.blue1),
              const SizedBox(width: 4),
              AppSubtitle(
                'Stock actual: ${widget.stock.stockActual}',
                fontSize: 10,
                color: AppColors.blue1,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesgloseIGV() {
    final precioIngresado = CurrencyUtilsImproved.parseToDouble(
      _precioController.text,
    );
    if (precioIngresado <= 0) return const SizedBox.shrink();

    final precioBase = _calcularPrecioBase(precioIngresado);
    final montoIGV = _calcularMontoIGV(precioBase);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            'Desglose de precio',
            fontSize: 10,
            color: AppColors.blue1,
          ),
          const SizedBox(height: 6),
          _buildDesgloseRow(
            'Precio base (sin $_nombreImpuesto)',
            '$_simboloMoneda ${precioBase.toStringAsFixed(2)}',
          ),
          const SizedBox(height: 4),
          _buildDesgloseRow(
            '$_nombreImpuesto (${_porcentajeIGV.toStringAsFixed(_porcentajeIGV.truncateToDouble() == _porcentajeIGV ? 0 : 1)}%)',
            '$_simboloMoneda ${montoIGV.toStringAsFixed(2)}',
          ),
          const Divider(height: 12),
          _buildDesgloseRow(
            'Total (precio ingresado)',
            '$_simboloMoneda ${precioIngresado.toStringAsFixed(2)}',
            bold: true,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline, size: 12, color: AppColors.blue1),
              const SizedBox(width: 4),
              Expanded(
                child: AppSubtitle(
                  'Se guardará $_simboloMoneda ${precioIngresado.toStringAsFixed(2)} como precio de venta (incluye $_nombreImpuesto)',
                  fontSize: 9,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDesgloseRow(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppSubtitle(
          label,
          fontSize: 10,
          color: bold ? AppColors.textPrimary : Colors.grey[700]!,
        ),
        AppSubtitle(
          value,
          fontSize: 10,
          color: bold ? AppColors.textPrimary : Colors.grey[700]!,
        ),
      ],
    );
  }

  Widget _buildNivelesExistentesCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.list_alt, size: 13, color: Colors.blueGrey.shade700),
              const SizedBox(width: 4),
              Text(
                'Niveles ya configurados',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.blueGrey.shade800,
                ),
              ),
              const Spacer(),
              Text(
                '${_nivelesExistentes.length}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.blueGrey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ..._nivelesExistentes.map(_buildNivelExistenteRow),
          const SizedBox(height: 4),
          Text(
            'Los porcentuales se crean/editan desde el formulario completo del producto.',
            style: TextStyle(
              fontSize: 9,
              color: Colors.blueGrey.shade600,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNivelesEmptyCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blueGrey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.discount_outlined,
              size: 18, color: Colors.blueGrey.shade400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Aún no hay precios por volumen. Agrega un nivel fijo abajo '
              '(ej. "Por Mayor" desde 6 uds., "Por Cientos" desde 100 uds.).',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blueGrey.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNivelExistenteRow(PrecioNivel n) {
    final esFijo = n.tipoPrecio == TipoPrecioNivel.precioFijo;
    final precioVenta = _precioController.currencyValue;
    final descripcionPrecio = esFijo
        ? '$_simboloMoneda ${(n.precio ?? 0).toStringAsFixed(2)}'
        : '−${(n.porcentajeDesc ?? 0).toStringAsFixed(0)}%'
            '${precioVenta > 0 ? "  ($_simboloMoneda ${n.calcularPrecioFinal(precioVenta).toStringAsFixed(2)})" : ""}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          // Chip de tipo
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
            decoration: BoxDecoration(
              color:
                  esFijo ? Colors.blue.shade100 : Colors.orange.shade100,
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(
              esFijo ? Icons.attach_money : Icons.percent,
              size: 9,
              color: esFijo
                  ? Colors.blue.shade800
                  : Colors.orange.shade800,
            ),
          ),
          const SizedBox(width: 6),
          // Nombre + rango
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  n.nombre,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  n.rangoString,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          // Precio / descuento
          Text(
            descripcionPrecio,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: esFijo ? Colors.blue.shade800 : Colors.orange.shade800,
            ),
          ),
          // Botón editar (solo fijos — los porcentuales se editan en form completo)
          if (esFijo) ...[
            const SizedBox(width: 4),
            SizedBox(
              width: 26,
              height: 26,
              child: IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 15, color: Colors.blue.shade600),
                padding: EdgeInsets.zero,
                tooltip: 'Editar nivel',
                onPressed: () => _abrirNivelDialog(nivelToEdit: n),
              ),
            ),
          ],
          // Botón eliminar nivel
          const SizedBox(width: 4),
          SizedBox(
            width: 26,
            height: 26,
            child: _eliminandoNiveles.contains(n.id)
                ? const Center(
                    child: SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  )
                : IconButton(
                    icon: Icon(Icons.delete_outline,
                        size: 16, color: Colors.red.shade400),
                    padding: EdgeInsets.zero,
                    tooltip: 'Eliminar nivel',
                    onPressed: () => _confirmarYEliminarNivel(n),
                  ),
          ),
        ],
      ),
    );
  }

  /// Pide confirmación al usuario y, si acepta, hace soft-delete del nivel
  /// vía repository, refrescando la lista al final.
  Future<void> _confirmarYEliminarNivel(PrecioNivel n) async {
    final esFijo = n.tipoPrecio == TipoPrecioNivel.precioFijo;
    final tipoLabel = esFijo ? 'fijo' : 'porcentual';
    final confirm = await StyledDialog.show<bool>(
      context,
      accentColor: Colors.red,
      icon: Icons.delete_outline,
      titulo: 'Eliminar nivel de precio',
      content: [
        Text(
          '¿Eliminar el nivel $tipoLabel "${n.nombre}" (${n.rangoString})?',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          'Puede reconfigurarse después.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
      actions: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: 'Eliminar',
            icon: const Icon(Icons.delete, size: 14, color: Colors.white),
            backgroundColor: Colors.red,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context, true),
          ),
        ),
      ],
    );
    if (confirm != true || !mounted) return;

    setState(() => _eliminandoNiveles.add(n.id));
    final result = await _precioNivelRepo.eliminarPrecioNivel(nivelId: n.id);
    if (!mounted) return;

    setState(() => _eliminandoNiveles.remove(n.id));

    if (result is Error<void>) {
      _showError('No se pudo eliminar: ${result.message}');
      return;
    }

    // Invalida cache compartido para que VR/Cot Rápida re-fetch al
    // próximo agregar de este producto/variante.
    final pid = widget.stock.productoId;
    final vid = widget.stock.varianteId;
    if (pid != null) _nivelCacheService.invalidate(pid);
    if (vid != null) _nivelCacheService.invalidateVariante(vid);

    // Refrescar la lista de niveles desde el backend.
    await _cargarNivelesExistentes();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Nivel "${n.nombre}" eliminado'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Abre el form dialog (forzado a PRECIO_FIJO) para crear un nivel nuevo
  /// o editar uno existente, persiste y refresca la lista.
  Future<void> _abrirNivelDialog({PrecioNivel? nivelToEdit}) async {
    final productoId = widget.stock.productoId;
    final varianteId = widget.stock.varianteId;
    if (productoId == null && varianteId == null) {
      _showError('Producto sin ID; no se puede configurar niveles.');
      return;
    }

    final precioBase = _precioController.currencyValue;
    final precioCosto = _precioCostoController.currencyValue;

    await showDialog<void>(
      context: context,
      builder: (ctx) => PrecioNivelFormDialog(
        precioBase: precioBase > 0 ? precioBase : null,
        precioCosto: precioCosto > 0 ? precioCosto : null,
        nivelToEdit: nivelToEdit,
        nivelesExistentes: _nivelesExistentes,
        lockTipoPrecio: TipoPrecioNivel.precioFijo,
        onSave: (dto) async {
          // El form dialog ya cerró; persistimos en background.
          if (nivelToEdit != null) {
            final r = await _precioNivelRepo.actualizarPrecioNivel(
              nivelId: nivelToEdit.id,
              data: {
                'nombre': dto.nombre,
                'cantidadMinima': dto.cantidadMinima,
                if (dto.cantidadMaxima != null)
                  'cantidadMaxima': dto.cantidadMaxima,
                'tipoPrecio': dto.tipoPrecio.value,
                if (dto.precio != null) 'precio': dto.precio,
                if (dto.descripcion != null) 'descripcion': dto.descripcion,
              },
            );
            if (!mounted) return;
            if (r is Error<PrecioNivel>) {
              _showError('No se pudo actualizar: ${r.message}');
              return;
            }
          } else {
            final r = varianteId != null
                ? await _precioNivelRepo.crearPrecioNivelVariante(
                    varianteId: varianteId,
                    dto: dto,
                  )
                : await _precioNivelRepo.crearPrecioNivelProducto(
                    productoId: productoId!,
                    dto: dto,
                  );
            if (!mounted) return;
            if (r is Error<PrecioNivel>) {
              final msg = r.message.toLowerCase().contains('solapa')
                  ? 'El rango se solapa con un nivel existente.'
                  : 'No se pudo crear: ${r.message}';
              _showError(msg);
              return;
            }
          }
          // Invalida cache compartido tras crear/actualizar.
          if (productoId != null) _nivelCacheService.invalidate(productoId);
          if (varianteId != null) _nivelCacheService.invalidateVariante(varianteId);
          await _cargarNivelesExistentes();
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(nivelToEdit != null
                  ? 'Nivel "${dto.nombre}" actualizado'
                  : 'Nivel "${dto.nombre}" creado'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        },
      ),
    );
  }

  /// Estado local del stock que refleja los cambios de liquidación tras
  /// abrir el dialog. Si es null se usa widget.stock.
  ProductoStock? _liquidacionStockOverride;
  ProductoStock get _stockEfectivo => _liquidacionStockOverride ?? widget.stock;

  Widget _buildSeccionLiquidacion() {
    final stock = _stockEfectivo;
    final activa = stock.isLiquidacionActiva;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.local_fire_department,
                size: 16, color: Colors.deepOrange.shade700),
            const SizedBox(width: 6),
            AppSubtitle('Liquidación', fontSize: 13, color: AppColors.red),
            const Spacer(),
            if (activa)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.deepOrange.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'ACTIVA',
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.deepOrange.shade900),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        activa
            ? RichText(
                text: TextSpan(
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                  children: [
                    const TextSpan(text: 'Liquidación activa: '),
                    TextSpan(
                      text: 'S/ ${stock.precioLiquidacion!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Colors.red.shade700,
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(text: ' (${stock.motivoLiquidacion?.label ?? '—'})'),
                  ],
                ),
              )
            : Text(
                'Remate por debajo de costo con motivo justificado y autorización gerencial.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
              ),
        const SizedBox(height: 8),
        CustomButton(
          text: activa ? 'Gestionar liquidación' : 'Activar liquidación',
          width: double.infinity,
          icon: Icon(
            activa ? Icons.settings : Icons.local_fire_department,
            size: 16,
            color: Colors.deepOrange.shade700,
          ),
          isOutlined: true,
          textColor: Colors.deepOrange.shade700,
          borderColor: Colors.deepOrange.shade200,
          // Las sombras default del CustomButton (offset 3,3 blur 6) se
          // cortan visualmente cuando el botón está dentro del
          // GradientContainer del dialog (sin padding extra alrededor).
          // Outlined + flat es lo estándar visualmente y armoniza con el
          // resto de la sección de liquidación.
          enableShadows: false,
          onPressed: () async {
            final result = await showDialog<ProductoStock>(
              context: context,
              builder: (_) => GestionarLiquidacionDialog(stock: stock),
            );
            if (result != null && mounted) {
              // Cerrar el dialog de precios y notificar al productos_page
              // para que recargue la lista (mismo flujo que al guardar
              // precios). Sin esto el usuario veria el estado viejo en
              // la card del producto hasta el proximo refresh manual.
              Navigator.of(context).pop(true);
            }
          },
        ),
      ],
    );
  }

  Widget _buildSeccionNiveles() {
    if (_cargandoNiveles) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header de la sección
        Row(
          children: [
            Icon(Icons.auto_graph, size: 14, color: AppColors.blue1),
            const SizedBox(width: 4),
            AppSubtitle(
              'Precios por Volumen',
              fontSize: 12,
              color: AppColors.textPrimary,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Card con la lista de niveles (o estado vacío)
        if (_nivelesExistentes.isEmpty)
          _buildNivelesEmptyCard()
        else
          _buildNivelesExistentesCard(),

        const SizedBox(height: 10),

        // Botón para agregar un nuevo nivel fijo
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _abrirNivelDialog(),
            icon: const Icon(Icons.add, size: 16),
            label: AppSubtitle(
              'Agregar nivel fijo',
              fontSize: 11,
              color: AppColors.blue1,
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(double.infinity, 34),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(color: AppColors.blue1.withValues(alpha: 0.4)),
            ),
          ),
        ),
      ],
    );
  }

  /// Calculadora rápida: el usuario ingresa cantidad + total pagado en
  /// una compra y el dialog calcula el costo unitario (total ÷ cantidad)
  /// y lo pone en el campo Precio Costo. Resuelve el error típico de
  /// tipear el TOTAL en el campo (que es por unidad).
  Future<void> _abrirCalculadoraLote() async {
    final aplicar = await showDialog<double>(
      context: context,
      builder: (_) => const _CalculadoraLoteDialog(),
    );
    if (aplicar != null && mounted) {
      setState(() {
        _precioCostoController.text = aplicar.toStringAsFixed(2);
      });
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Los niveles de precio se persisten en su propio flujo (al crear/editar/
    // eliminar desde la card). Aquí solo guardamos los precios del stock.
    final precio = _getControllerValue(_precioController);
    final precioCosto = _getControllerValue(_precioCostoController);
    final precioOferta = _getControllerValue(_precioOfertaController);

    // Auditoria: si cambió el precio costo (modificación de un dato sensible
    // que afecta margen y valorización del inventario), pedir motivo +
    // tipoCambio. Se guarda en ProductoPrecioHistorialSede para trazabilidad.
    String? tipoCambioAuditoria;
    String? razonAuditoria;
    final costoOriginal = widget.stock.precioCosto ?? 0;
    final cambioCosto = precioCosto > 0 && (precioCosto - costoOriginal).abs() > 0.001;
    if (cambioCosto) {
      final result = await _pedirMotivoCambioCosto(costoOriginal, precioCosto);
      if (result == null) return; // canceló
      tipoCambioAuditoria = result.tipoCambio;
      razonAuditoria = result.razon;
    }

    if (!mounted) return;
    // Si el producto es INSUMO, no enviamos precio de venta ni nada
    // relacionado a oferta (no se vende directo). Solo el precioCosto
    // que es lo único que tiene sentido para un insumo.
    final esInsumo = widget.stock.producto?.esInsumo == true;
    context.read<ConfigurarPreciosCubit>().configurarPrecios(
      productoStockId: widget.stock.id,
      empresaId: widget.empresaId,
      precio: esInsumo ? 0 : precio,
      precioCosto: precioCosto > 0 ? precioCosto : null,
      precioOferta:
          !esInsumo && _enOferta && precioOferta > 0 ? precioOferta : null,
      enOferta: !esInsumo && _enOferta,
      fechaInicioOferta: !esInsumo && _enOferta ? _fechaInicioOferta : null,
      fechaFinOferta: !esInsumo && _enOferta ? _fechaFinOferta : null,
      precioIncluyeIgv: !esInsumo && _precioIncluyeIGV,
      tipoCambio: tipoCambioAuditoria,
      razon: razonAuditoria,
    );
  }

  /// Dialog que pide motivo + tipo de cambio cuando se edita precioCosto.
  /// Si cancela retorna null. El contenido vive en `_MotivoCambioCostoDialog`
  /// (StatefulWidget) para que el TextEditingController se disponga en el
  /// lifecycle del widget — usar `whenComplete(.dispose)` dispara el dispose
  /// antes de que el rebuild final termine y rompe el frame.
  Future<_MotivoCambioCostoResult?> _pedirMotivoCambioCosto(
    double anterior,
    double nuevo,
  ) {
    return showDialog<_MotivoCambioCostoResult>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _MotivoCambioCostoDialog(
        anterior: anterior,
        nuevo: nuevo,
      ),
    );
  }
}

class _MotivoCambioCostoDialog extends StatefulWidget {
  final double anterior;
  final double nuevo;

  const _MotivoCambioCostoDialog({
    required this.anterior,
    required this.nuevo,
  });

  @override
  State<_MotivoCambioCostoDialog> createState() =>
      _MotivoCambioCostoDialogState();
}

class _MotivoCambioCostoDialogState extends State<_MotivoCambioCostoDialog> {
  String _tipoCambio = 'CORRECCION';
  final _razonCtrl = TextEditingController();

  @override
  void dispose() {
    _razonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final anterior = widget.anterior;
    final nuevo = widget.nuevo;
    final diferencia = nuevo - anterior;
    final esAumento = diferencia > 0;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteDialog(),
        padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.history_edu,
                        color: AppColors.blue1, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTitle('Motivo del cambio'),
                        AppSubtitle(
                          'Auditoría del precio de costo',
                          fontSize: 10,
                          color: AppColors.blue1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Card comparativo de costos
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: AppColors.blueborder.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Costo anterior',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade600),
                        ),
                        Text(
                          'S/ ${anterior.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                            decoration: TextDecoration.lineThrough,
                            decorationColor: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Costo nuevo',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.blue1,
                              fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'S/ ${nuevo.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.blue1,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 14),
                    Row(
                      children: [
                        Icon(
                          esAumento
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 14,
                          color: esAumento
                              ? Colors.red.shade700
                              : Colors.green.shade700,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Diferencia: ${esAumento ? '+' : ''}S/ ${diferencia.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: esAumento
                                ? Colors.red.shade700
                                : Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Aviso de auditoría
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.bluechip.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 12, color: AppColors.blue1),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'El cambio queda en el historial con tu usuario y la fecha.',
                        style: TextStyle(
                            fontSize: 10,
                            color: AppColors.blue1,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Tipo de cambio
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: AppSubtitle(
                  'Tipo de cambio',
                  fontSize: 11,
                  color: AppColors.blue1,
                ),
              ),
              CustomDropdown<String>(
                value: _tipoCambio,
                items: const [
                  DropdownItem(
                      value: 'CORRECCION', label: 'Corrección de error'),
                  DropdownItem(
                      value: 'COSTO',
                      label: 'Actualización de costo (proveedor)'),
                  DropdownItem(
                      value: 'COMPETENCIA', label: 'Ajuste por competencia'),
                  DropdownItem(
                      value: 'AJUSTE_MERCADO', label: 'Ajuste por mercado'),
                  DropdownItem(value: 'MANUAL', label: 'Otro'),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _tipoCambio = v);
                },
              ),
              const SizedBox(height: 12),

              // Motivo (opcional) — el tipoCambio arriba ya documenta
              // el porqué del cambio, este field es solo para detalle
              // adicional opcional.
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 4),
                child: AppSubtitle(
                  'Motivo (opcional)',
                  fontSize: 11,
                  color: AppColors.blue1,
                ),
              ),
              TextField(
                controller: _razonCtrl,
                maxLines: 2,
                style: const TextStyle(fontSize: 13),
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  contentPadding: const EdgeInsets.all(10),
                  hintText:
                      'Ej: proveedor cambió precio, error de carga, etc.',
                  hintStyle:
                      TextStyle(fontSize: 12, color: Colors.grey.shade400),
                ),
              ),
              const SizedBox(height: 16),

              // Botones con CustomButton
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      isOutlined: true,
                      textColor: AppColors.blue1,
                      borderColor: AppColors.blue1.withValues(alpha: 0.4),
                      enableShadows: false,
                      onPressed: () => Navigator.pop(context, null),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Confirmar cambio',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      enableShadows: false,
                      icon: const Icon(Icons.check,
                          color: Colors.white, size: 16),
                      onPressed: () {
                        final razonTrim = _razonCtrl.text.trim();
                        Navigator.pop(
                          context,
                          _MotivoCambioCostoResult(
                            tipoCambio: _tipoCambio,
                            razon: razonTrim.isEmpty ? null : razonTrim,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MotivoCambioCostoResult {
  final String tipoCambio;
  final String? razon;
  const _MotivoCambioCostoResult({required this.tipoCambio, this.razon});
}

/// Dialog separado (no StatefulBuilder) para evitar el bug de
/// "TextEditingController was used after being disposed" que aparece
/// cuando los controllers se disponen en el closure mientras el árbol
/// de widgets sigue intentando rebuildear.
class _CalculadoraLoteDialog extends StatefulWidget {
  const _CalculadoraLoteDialog();

  @override
  State<_CalculadoraLoteDialog> createState() => _CalculadoraLoteDialogState();
}

class _CalculadoraLoteDialogState extends State<_CalculadoraLoteDialog> {
  final _cantidadCtrl = TextEditingController();
  final _totalCtrl = TextEditingController();
  double? _unitario;

  @override
  void dispose() {
    _cantidadCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  void _recalcular() {
    final cant = double.tryParse(_cantidadCtrl.text.replaceAll(',', '.'));
    final tot = double.tryParse(_totalCtrl.text.replaceAll(',', '.'));
    setState(() {
      _unitario = (cant != null && cant > 0 && tot != null && tot > 0)
          ? tot / cant
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Calcular costo por unidad',
          style: TextStyle(fontSize: 14)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Ingresá la cantidad comprada y el total pagado. El sistema calcula el costo por unidad.',
            style: TextStyle(fontSize: 11),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cantidadCtrl,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Cantidad comprada',
              hintText: 'Ej. 50',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _recalcular(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _totalCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Total pagado (S/)',
              hintText: 'Ej. 100',
              isDense: true,
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => _recalcular(),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _unitario != null
                  ? Colors.green.shade50
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: _unitario != null
                    ? Colors.green.shade300
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                Text(
                  'Costo por unidad:',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade700),
                ),
                Text(
                  _unitario != null
                      ? 'S/ ${_unitario!.toStringAsFixed(2)}'
                      : '—',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _unitario != null
                        ? Colors.green.shade800
                        : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _unitario != null
              ? () => Navigator.pop(context, _unitario)
              : null,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
