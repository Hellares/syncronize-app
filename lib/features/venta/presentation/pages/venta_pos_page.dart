import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import '../../../../core/widgets/items_table_widget.dart';
import '../../../../core/widgets/cuotas_dial_selector.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_search_cubit.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../bloc/venta_form/venta_form_cubit.dart';
import '../bloc/venta_form/venta_form_state.dart';
import '../../domain/entities/venta_detalle_input.dart';
import '../widgets/resumen_venta_widget.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../cotizacion/presentation/widgets/cotizacion_item_selector.dart';
import '../../../../core/widgets/comprobante_condicion_card.dart';
import '../../../../core/widgets/pagos_section_widget.dart';

class VentaPOSPage extends StatefulWidget {
  const VentaPOSPage({super.key});

  @override
  State<VentaPOSPage> createState() => _VentaPOSPageState();
}

class _VentaPOSPageState extends State<VentaPOSPage> {
  final _formKey = GlobalKey<FormState>();

  // Cliente
  final _nombreClienteController = TextEditingController();
  final _documentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  String? _clienteId;
  String? _clienteEmpresaId;

  // Contexto empresa/sede/vendedor
  String? _sedeId;
  String? _vendedorId;
  String? _empresaId;

  // Items
  final List<VentaDetalleInput> _items = [];

  // Comprobante
  String _tipoComprobante = 'TICKET';

  // Pagos múltiples
  final List<Map<String, dynamic>> _pagos = [];
  String _metodoActual = 'EFECTIVO';
  String _monedaActual = 'PEN';
  double? _tipoCambioVenta;
  final _montoAgregarController = TextEditingController();
  final _referenciaAgregarController = TextEditingController();
  String _condicionPago = 'CONTADO'; // CONTADO, CREDITO, MIXTO
  bool get _esCredito => _condicionPago == 'CREDITO' || _condicionPago == 'MIXTO';
  int _numeroCuotas = 1;
  final _montoCreditoController = TextEditingController();
  final _numeroCuotasController = TextEditingController(text: '1');

  // Observaciones
  final _observacionesController = TextEditingController();

  // Config
  double _impuestoPorcentaje = 18.0;
  String _nombreImpuesto = 'IGV';
  String _moneda = 'PEN';

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      final sedes = empresaState.context.sedes;
      if (sedes.isNotEmpty) {
        _sedeId = empresaState.context.sedePrincipal?.id ?? sedes.first.id;
      }
      context.read<ConfiguracionEmpresaCubit>().cargar(_empresaId!);
    }
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _vendedorId = authState.user.id;
    }
    _leerConfiguracion();
    _montoAgregarController.addListener(() => setState(() {}));
    _montoCreditoController.addListener(() => setState(() {}));
    _numeroCuotasController.addListener(() {
      setState(() => _numeroCuotas = int.tryParse(_numeroCuotasController.text) ?? 1);
    });
    _cargarTipoCambio();
  }

  Future<void> _cargarTipoCambio() async {
    try {
      final dio = locator<DioClient>();
      final response = await dio.get('/consultas/tipo-cambio');
      if (response.data != null && mounted) {
        setState(() {
          _tipoCambioVenta = _toDouble(response.data['venta']);
        });
      }
    } catch (_) {}
  }

  static double _toDouble(dynamic v) {
    if (v == null) return 0;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? 0;
    return 0;
  }

  void _leerConfiguracion() {
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      _impuestoPorcentaje =
          configState.configuracion.impuestoDefaultPorcentaje;
      _nombreImpuesto = configState.configuracion.nombreImpuesto;
      _moneda = configState.configuracion.monedaPrincipal;
    }
  }

  @override
  void dispose() {
    _nombreClienteController.dispose();
    _documentoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _montoAgregarController.dispose();
    _referenciaAgregarController.dispose();
    _montoCreditoController.dispose();
    _numeroCuotasController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  double _calcularSubtotal() {
    return _items.fold(0.0, (sum, i) => sum + i.subtotal);
  }

  double _calcularImpuestos() {
    return _calcularSubtotal() * (_impuestoPorcentaje / 100);
  }

  double _calcularTotal() {
    return _calcularSubtotal() + _calcularImpuestos();
  }

  double get _totalPagado => _pagos.fold(0.0, (sum, p) => sum + (p['monto'] as double));

  /// Monto que va a crédito (MIXTO: lo que ingresa el usuario, CREDITO: el total)
  double get _montoCredito {
    if (_condicionPago == 'CREDITO') return _calcularTotal();
    if (_condicionPago == 'MIXTO') return double.tryParse(_montoCreditoController.text) ?? 0;
    return 0;
  }

  /// Monto que se debe pagar ahora (total - crédito)
  double get _montoPagarAhora {
    final total = _calcularTotal();
    if (_condicionPago == 'CONTADO') return total;
    return (total - _montoCredito).clamp(0, total);
  }

  /// Saldo pendiente de la parte que se paga ahora
  double get _saldoPendiente => _montoPagarAhora - _totalPagado;

  void _agregarPago() {
    final monto = double.tryParse(_montoAgregarController.text);
    if (monto == null || monto <= 0) return;

    if (_monedaActual == 'USD' && _tipoCambioVenta == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tipo de cambio no disponible')),
      );
      return;
    }

    final montoEnSoles = _monedaActual == 'USD'
        ? double.parse((monto * _tipoCambioVenta!).toStringAsFixed(2))
        : monto;

    setState(() {
      _pagos.add({
        'metodo': _metodoActual,
        'monto': montoEnSoles,
        'referencia': _referenciaAgregarController.text.trim(),
        'monedaOriginal': _monedaActual,
        'montoOriginal': monto,
        'tipoCambio': _monedaActual == 'USD' ? _tipoCambioVenta : null,
      });
      _montoAgregarController.clear();
      _referenciaAgregarController.clear();
      _monedaActual = 'PEN';
    });
  }

  void _removerPago(int index) {
    setState(() => _pagos.removeAt(index));
  }


  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<VentaFormCubit>(),
      child: BlocListener<VentaFormCubit, VentaFormState>(
        listener: (context, state) {
          if (state is VentaFormSuccess) {
            try {
              context.read<ProductoListCubit>().invalidateCache();
            } catch (_) {}
            try {
              context.read<ProductoSedeSearchCubit>().clearCache();
            } catch (_) {}
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.of(context).pop(true);
          }
          if (state is VentaFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Builder(
          builder: (context) => GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: Scaffold(
            appBar: SmartAppBar(
              title: 'Venta Rapida (POS)',
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
            body: Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ─── 1. CLIENTE ───
                    _buildSectionHeader('Cliente', Icons.person),
                    _buildClienteSection(),
                    const SizedBox(height: 20),

                    // ─── 2. ITEMS ───
                    _buildSectionHeader('Items', Icons.shopping_cart),
                    _buildItemsSection(),
                    const SizedBox(height: 20),

                    // ─── 3. COMPROBANTE ───
                    _buildSectionHeader('Comprobante', Icons.receipt_long),
                    _buildComprobanteSection(),
                    const SizedBox(height: 20),

                    // ─── 4. PAGO ───
                    _buildSectionHeader('Pago', Icons.payments),
                    _buildPagoSection(),
                    const SizedBox(height: 20),

                    // ─── 5. RESUMEN ───
                    _buildSectionHeader('Resumen', Icons.summarize),
                    _buildResumenSection(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: _buildActionButtons(context),
          ),
          ),
        ),
      ),
    );
  }

  // ─── Section Header ───

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.blue1),
        const SizedBox(width: 8),
        AppSubtitle(title, fontSize: 11, color: AppColors.blue1),
      ],
    );
  }

  // ─── 1. CLIENTE Section ───

  Widget _buildClienteSection() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _documentoController,
                    borderColor: AppColors.blue1,
                    label: 'DNI / RUC',
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: CustomButton(
                    borderRadius: 6,
                    onPressed: () async {
                      if (_empresaId == null) return;
                      final result = await ClienteUnificadoSelector.show(
                        context: context,
                        empresaId: _empresaId!,
                      );
                      if (result != null && mounted) {
                        setState(() {
                          if (result.tipo == TipoClienteSeleccion.persona) {
                            _clienteId = result.clienteId;
                            _clienteEmpresaId = null;
                            _nombreClienteController.text =
                                result.nombreCompleto ?? '';
                            _documentoController.text = result.dni ?? '';
                            _emailController.text = result.email ?? '';
                            _telefonoController.text = result.telefono ?? '';
                            _direccionController.text = '';
                          } else {
                            _clienteId = null;
                            _clienteEmpresaId = result.clienteEmpresaId;
                            _nombreClienteController.text =
                                result.razonSocial ?? result.nombreComercial ?? '';
                            _documentoController.text = result.ruc ?? '';
                            _emailController.text = '';
                            _telefonoController.text = result.telefono ?? '';
                            _direccionController.text = '';
                          }
                        });
                      }
                    },
                    text: 'Buscar',
                    icon: const Icon(Icons.person_search, size: 16, color: AppColors.white,),
                    backgroundColor: AppColors.blue1,
                    height: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: _nombreClienteController,
              label: 'Nombre del cliente *',
              borderColor: AppColors.blue1,
            ),
          ],
        ),
      ),
    );
  }

  // ─── 2. ITEMS Section ───

  Widget _buildItemsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CotizacionItemSelector(
          showModeSelector: false,
          onItemSelected: (item) {
            setState(() {
              // Buscar si ya existe un item con el mismo producto/variante/servicio
              final existingIndex = _items.indexWhere((existing) {
                if (item.productoId != null && existing.productoId == item.productoId && existing.varianteId == item.varianteId) return true;
                if (item.servicioId != null && existing.servicioId == item.servicioId) return true;
                return false;
              });

              if (existingIndex >= 0) {
                // Sumar cantidad al item existente
                final existing = _items[existingIndex];
                _items[existingIndex] = VentaDetalleInput(
                  productoId: existing.productoId,
                  varianteId: existing.varianteId,
                  servicioId: existing.servicioId,
                  descripcion: existing.descripcion,
                  cantidad: existing.cantidad + item.cantidad,
                  precioUnitario: existing.precioUnitario,
                  descuento: existing.descuento,
                  porcentajeIGV: existing.porcentajeIGV,
                );
              } else {
                _items.add(VentaDetalleInput(
                  productoId: item.productoId,
                  varianteId: item.varianteId,
                  servicioId: item.servicioId,
                  descripcion: item.descripcion,
                  cantidad: item.cantidad,
                  precioUnitario: item.precioUnitario,
                  descuento: item.descuento,
                  porcentajeIGV: item.porcentajeIGV,
                ));
              }
            });
          },
        ),
        const SizedBox(height: 12),
        if (_items.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Agrega items a la venta',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          ItemsTableWidget(
            items: _items.map((item) => ItemTableRow(
              descripcion: item.descripcion,
              cantidad: item.cantidad,
              precioUnitario: item.precioUnitario,
              subtotal: item.subtotal,
            )).toList(),
            onRemove: (i) => setState(() => _items.removeAt(i)),
          ),
      ],
    );
  }

  // ─── 3. COMPROBANTE Section ───

  Widget _buildComprobanteSection() {
    return ComprobanteCondicionCard(
      tipoComprobante: _tipoComprobante,
      onComprobanteChanged: (v) => setState(() => _tipoComprobante = v),
      condicionPago: _condicionPago,
      onCondicionChanged: (v) => setState(() {
        _condicionPago = v;
        if (v == 'CREDITO') _pagos.clear();
      }),
    );
  }

  // ─── 4. PAGO Section ───

  Widget _buildPagoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ─── MIXTO: Monto a crédito + Cuotas ───
        if (_condicionPago == 'MIXTO') ...[
          GradientContainer(
            borderColor: Colors.orange.shade300,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_score, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      // Text('Parte a Credito', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                      AppSubtitle('Parte a Credito', color: Colors.orange[700]!)
                    ],
                  ),
                  const SizedBox(height: 5),
                  
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: CurrencyTextField(
                          controller: _montoCreditoController,
                          enableRealTimeValidation: false,
                          borderColor: Colors.orange[700]!,
                          label: 'Monto a credito',
                          hintText: '0.00',
                        ),
                      ),
                      const SizedBox(width: 10),
                      CuotasDialSelector(
                        label: 'Cuotas',
                        value: _numeroCuotas,
                        activeColor: Colors.orange[700],
                        onChanged: (v) => setState(() {
                          _numeroCuotas = v;
                          _numeroCuotasController.text = v.toString();
                        }),
                      ),
                    ],
                  ),
                  if (_montoCredito > 0 && _numeroCuotas > 0) ...[
                    const SizedBox(height: 10),
                    _buildCuotasPreview(),
                  ],
                  if (_montoPagarAhora > 0) ...[
                    const SizedBox(height: 10),
                    GradientContainer(
                      borderColor: Colors.green.shade300,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Pagar ahora:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.green[700])),
                            Text('S/ ${_montoPagarAhora.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Colors.green[700])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ─── CREDITO: Solo cuotas ───
        if (_condicionPago == 'CREDITO') ...[
          GradientContainer(
            borderColor: Colors.orange.shade300,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.credit_score, size: 16, color: Colors.orange[700]),
                      const SizedBox(width: 6),
                      Text('Credito Total', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.orange[700])),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CuotasDialSelector(
                    label: 'Cuotas',
                    value: _numeroCuotas,
                    activeColor: Colors.orange[700],
                    onChanged: (v) => setState(() {
                      _numeroCuotas = v;
                      _numeroCuotasController.text = v.toString();
                    }),
                  ),
                  if (_numeroCuotas > 0 && _items.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    _buildCuotasPreview(),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],

        // ─── Pagos inmediatos (CONTADO y MIXTO) ───
        if (_condicionPago != 'CREDITO') ...[
          PagosSectionWidget(
            pagos: _pagos,
            metodoActual: _metodoActual,
            onMetodoChanged: (v) => setState(() => _metodoActual = v),
            monedaActual: _monedaActual,
            onMonedaChanged: (v) => setState(() => _monedaActual = v),
            tipoCambioVenta: _tipoCambioVenta,
            saldoPendiente: _saldoPendiente,
            totalPagado: _totalPagado,
            montoController: _montoAgregarController,
            referenciaController: _referenciaAgregarController,
            onAgregarPago: _agregarPago,
            onRemoverPago: _removerPago,
          ),
          const SizedBox(height: 12),
        ],

        // Observaciones
        GradientContainer(
          borderColor: AppColors.blueborder,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: CustomText(
              controller: _observacionesController,
              borderColor: AppColors.blue1,
              label: 'Observaciones (opcional)',
              enableVoiceInput: true,
              maxLines: 3,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Cuotas Preview ───

  Widget _buildCuotasPreview() {
    final mc = _montoCredito;
    if (mc <= 0 || _numeroCuotas <= 0) return const SizedBox.shrink();

    final montoCuota = (mc / _numeroCuotas * 100).floor() / 100;
    final resto = double.parse((mc - montoCuota * _numeroCuotas).toStringAsFixed(2));
    final now = DateTime.now();

    return GradientContainer(
      borderColor: Colors.blue.shade200,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_month, size: 14, color: Colors.blue[700]),
                const SizedBox(width: 6),
                Text('Cronograma de cuotas', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.blue[700])),
                const Spacer(),
                Text('Total: S/ ${mc.toStringAsFixed(2)}', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.blue[700])),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(_numeroCuotas, (i) {
              final numero = i + 1;
              final esUltima = numero == _numeroCuotas;
              final monto = esUltima ? montoCuota + resto : montoCuota;
              // Cada cuota vence el 1ro del mes siguiente
              final fecha = DateTime(now.year, now.month + numero + 1, 1);
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Center(child: Text('$numero', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.blue[700]))),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text('S/ ${monto.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                    Text('01/${fecha.month.toString().padLeft(2, '0')}/${fecha.year}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─── 5. RESUMEN Section ───

  Widget _buildResumenSection() {
    final totalVenta = _calcularTotal();
    final cambio = _condicionPago == 'CONTADO' && _totalPagado > totalVenta
        ? _totalPagado - totalVenta
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ResumenVentaWidget(
          items: _items,
          moneda: _moneda,
          nombreImpuesto: _nombreImpuesto,
          porcentajeImpuesto: _impuestoPorcentaje,
        ),
        if (_items.isNotEmpty) ...[
          const SizedBox(height: 8),
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Total de la compra
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Compra',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Text(
                        'S/ ${totalVenta.toStringAsFixed(2)}',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.blue1),
                      ),
                    ],
                  ),
                  // Pagado al contado
                  if (_pagos.isNotEmpty) ...[
                    const Divider(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Pagado al contado',
                            style: TextStyle(fontSize: 11, color: Colors.green[700])),
                        Text(
                          'S/ ${_totalPagado.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.green[700]),
                        ),
                      ],
                    ),
                  ],
                  // Saldo a crédito
                  if (_esCredito && _montoCredito > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saldo a credito ($_numeroCuotas cuota${_numeroCuotas > 1 ? 's' : ''})',
                            style: TextStyle(fontSize: 12, color: Colors.orange[700])),
                        Text(
                          'S/ ${_montoCredito.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.orange[700]),
                        ),
                      ],
                    ),
                  ],
                  // Cambio (solo contado)
                  if (cambio > 0) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Cambio',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                        Text(
                          'S/ ${cambio.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.green.shade700),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ─── 6. ACTION BUTTONS ───

  Widget _buildActionButtons(BuildContext context) {
    return BlocBuilder<VentaFormCubit, VentaFormState>(
      builder: (context, state) {
        final isLoading = state is VentaFormLoading;
        return Container(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Row(
            children: [
              // Guardar Borrador
              Expanded(
                child: CustomButton(
                  text: 'Borrador',
                  isLoading: isLoading,
                  backgroundColor: AppColors.blue1,
                  onPressed:
                      isLoading ? null : () => _submitBorrador(context),
                  icon: const Icon(Icons.save_outlined, size: 16),
                ),
              ),
              const SizedBox(width: 12),
              // Cobrar
              Expanded(
                flex: 2,
                child: CustomButton(
                  text: 'Cobrar',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : () => _submitCobrar(context),
                  backgroundColor: Colors.green.shade600,
                  icon: const Icon(Icons.point_of_sale, size: 16),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Submit: Cobrar (crear + confirmar + pagar) ───

  void _submitCobrar(BuildContext context) {
    if (_nombreClienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del cliente es requerido')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un item')),
      );
      return;
    }
    // Validar pagos para CONTADO y MIXTO
    if (_condicionPago == 'CONTADO' && _pagos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un pago')),
      );
      return;
    }
    if (_condicionPago == 'MIXTO' && _montoPagarAhora > 0 && _pagos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega el pago de la parte al contado')),
      );
      return;
    }
    if (_esCredito && _numeroCuotas <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingresa el numero de cuotas')),
      );
      return;
    }

    final now = DateTime.now();
    // Plazo = cuotas * 30 días (1 cuota = 1 mes)
    final plazoDias = _numeroCuotas * 30;
    // Última cuota vence el 1ro del mes correspondiente
    final fechaUltimaCuota = DateTime(now.year, now.month + _numeroCuotas + 1, 1);

    final data = <String, dynamic>{
      'sedeId': _sedeId,
      'vendedorId': _vendedorId,
      if (_clienteId != null) 'clienteId': _clienteId,
      if (_clienteEmpresaId != null) 'clienteEmpresaId': _clienteEmpresaId,
      'nombreCliente': _nombreClienteController.text,
      if (_documentoController.text.isNotEmpty)
        'documentoCliente': _documentoController.text,
      if (_emailController.text.isNotEmpty)
        'emailCliente': _emailController.text,
      if (_telefonoController.text.isNotEmpty)
        'telefonoCliente': _telefonoController.text,
      if (_direccionController.text.isNotEmpty)
        'direccionCliente': _direccionController.text,
      'moneda': _moneda,
      'tipoComprobante': _tipoComprobante,
      'esCredito': _esCredito,
      // Pagos inmediatos (CONTADO: todo, MIXTO: la parte al contado)
      if (_pagos.isNotEmpty) ...{
        'metodoPago': _pagos.first['metodo'],
        'montoRecibido': _totalPagado,
        'pagos': _pagos.map((p) => {
          'metodoPago': p['metodo'],
          'monto': p['monto'],
          if ((p['referencia'] as String).isNotEmpty)
            'referencia': p['referencia'],
          if (p['monedaOriginal'] == 'USD') ...{
            'monedaOriginal': 'USD',
            'montoOriginal': p['montoOriginal'],
            'tipoCambio': p['tipoCambio'],
          },
        }).toList(),
      },
      // Datos de crédito/cuotas
      if (_esCredito) ...{
        'plazoCredito': plazoDias,
        'numeroCuotas': _numeroCuotas,
        'fechaVencimientoPago': fechaUltimaCuota.toIso8601String(),
      },
      if (_observacionesController.text.isNotEmpty)
        'observaciones': _observacionesController.text,
      'detalles': _items.map((item) => item.toMap()).toList(),
    };

    context.read<VentaFormCubit>().crearYCobrar(data);
  }

  // ─── Submit: Guardar Borrador ───

  void _submitBorrador(BuildContext context) {
    if (_nombreClienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre del cliente es requerido')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Agrega al menos un item')),
      );
      return;
    }

    final data = <String, dynamic>{
      'sedeId': _sedeId,
      'vendedorId': _vendedorId,
      if (_clienteId != null) 'clienteId': _clienteId,
      if (_clienteEmpresaId != null) 'clienteEmpresaId': _clienteEmpresaId,
      'nombreCliente': _nombreClienteController.text,
      if (_documentoController.text.isNotEmpty)
        'documentoCliente': _documentoController.text,
      if (_emailController.text.isNotEmpty)
        'emailCliente': _emailController.text,
      if (_telefonoController.text.isNotEmpty)
        'telefonoCliente': _telefonoController.text,
      if (_direccionController.text.isNotEmpty)
        'direccionCliente': _direccionController.text,
      'moneda': _moneda,
      'tipoComprobante': _tipoComprobante,
      if (_observacionesController.text.isNotEmpty)
        'observaciones': _observacionesController.text,
      'detalles': _items.map((item) => item.toMap()).toList(),
    };

    context.read<VentaFormCubit>().crearVenta(data);
  }
}
