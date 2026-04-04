import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import '../../../../core/widgets/items_table_widget.dart';
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
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../cotizacion/presentation/widgets/cotizacion_item_selector.dart';
import '../../../../core/widgets/comprobante_condicion_card.dart';
import '../../data/datasources/venta_remote_datasource.dart';
import '../../../../core/widgets/pagos_section_widget.dart';
import '../../../../core/widgets/currency/currency_formatter.dart';
import '../widgets/credito_cuotas_section.dart';
import '../widgets/pos_resumen_totales.dart';
import '../widgets/pos_action_bar.dart';
import '../../../../core/utils/caja_guard.dart';

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
  List<EmisorItem> _emisores = [];
  EmisorItem? _emisorSeleccionado;

  // Pagos múltiples
  final List<Map<String, dynamic>> _pagos = [];
  String _metodoActual = 'EFECTIVO';
  String _monedaActual = 'PEN';
  double? _tipoCambioVenta;
  final _montoAgregarController = TextEditingController();
  final _referenciaAgregarController = TextEditingController();
  String _condicionPago = 'CONTADO';
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

  // Mora config
  bool _moraHabilitada = false;
  double _porcentajeMoraDiario = 0;
  double _moraMaximaPorcentaje = 0;
  int _diasGraciaMora = 0;

  // Interés por crédito
  bool _interesHabilitado = false;
  double _porcentajeInteres = 0;
  bool _interesEsEditable = true;
  final _porcentajeInteresController = TextEditingController(text: '0');

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
    _cargarEmisores();
    _montoAgregarController.addListener(() => setState(() {}));
    _montoCreditoController.addListener(() => setState(() {}));
    _numeroCuotasController.addListener(() {
      setState(() => _numeroCuotas = int.tryParse(_numeroCuotasController.text) ?? 1);
    });
    _cargarTipoCambio();
    _verificarCaja();
  }

  Future<void> _verificarCaja() async {
    final tieneCaja = await verificarCajaAbierta(context);
    if (!tieneCaja && mounted) {
      Navigator.of(context).pop();
    }
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

  Future<void> _cargarEmisores() async {
    try {
      final datasource = locator<VentaRemoteDataSource>();
      final response = await datasource.listarEmisores();
      if (mounted) {
        setState(() {
          _emisores = response;
          if (_emisores.isNotEmpty) _emisorSeleccionado = _emisores.first;
        });
      }
    } catch (_) {}
  }

  void _leerConfiguracion() {
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      _impuestoPorcentaje = configState.configuracion.impuestoDefaultPorcentaje;
      _nombreImpuesto = configState.configuracion.nombreImpuesto;
      _moneda = configState.configuracion.monedaPrincipal;
      _moraHabilitada = configState.configuracion.moraHabilitada;
      _porcentajeMoraDiario = configState.configuracion.porcentajeMoraDiario;
      _moraMaximaPorcentaje = configState.configuracion.moraMaximaPorcentaje;
      _diasGraciaMora = configState.configuracion.diasGraciaMora;
      _interesHabilitado = configState.configuracion.interesHabilitado;
      _porcentajeInteres = configState.configuracion.porcentajeInteresDefault;
      _porcentajeInteresController.text = _porcentajeInteres.toStringAsFixed(2);
      _interesEsEditable = configState.configuracion.interesEsEditable;
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
    _porcentajeInteresController.dispose();
    super.dispose();
  }

  // ─── Computed Properties ───

  double _calcularTotal() => _items.fold(0.0, (sum, i) => sum + i.total);
  double get _totalPagado => _pagos.fold(0.0, (sum, p) => sum + (p['monto'] as double));

  double get _montoCredito {
    if (_condicionPago == 'CREDITO') return _calcularTotal();
    if (_condicionPago == 'MIXTO') {
      final ingresado = CurrencyUtilsImproved.parseToDouble(_montoCreditoController.text);
      final total = _calcularTotal();
      return ingresado.clamp(0, total); // No puede exceder el total
    }
    return 0;
  }

  double get _montoPagarAhora {
    final total = _calcularTotal();
    if (_condicionPago == 'CONTADO') return total;
    return (total - _montoCredito).clamp(0, total);
  }

  double get _saldoPendiente => _montoPagarAhora - _totalPagado;

  // ─── Pago Actions ───

  void _agregarPago() {
    final monto = CurrencyUtilsImproved.parseToDouble(_montoAgregarController.text);
    if (monto <= 0) return;

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

  void _removerPago(int index) => setState(() => _pagos.removeAt(index));

  // ─── BUILD ───

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<VentaFormCubit>(),
      child: BlocListener<VentaFormCubit, VentaFormState>(
        listener: (context, state) {
          if (state is VentaFormSuccess) {
            try { context.read<ProductoListCubit>().invalidateCache(); } catch (_) {}
            try { context.read<ProductoSedeSearchCubit>().clearCache(); } catch (_) {}
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message)));
            Navigator.of(context).pop(true);
          }
          if (state is VentaFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          }
        },
        child: BlocListener<ConfiguracionEmpresaCubit, ConfiguracionEmpresaState>(
          listener: (context, state) {
            if (state is ConfiguracionEmpresaLoaded) {
              setState(() {
                _impuestoPorcentaje = state.configuracion.impuestoDefaultPorcentaje;
                _nombreImpuesto = state.configuracion.nombreImpuesto;
                _moneda = state.configuracion.monedaPrincipal;
                _moraHabilitada = state.configuracion.moraHabilitada;
                _porcentajeMoraDiario = state.configuracion.porcentajeMoraDiario;
                _moraMaximaPorcentaje = state.configuracion.moraMaximaPorcentaje;
                _diasGraciaMora = state.configuracion.diasGraciaMora;
                _interesHabilitado = state.configuracion.interesHabilitado;
                _porcentajeInteres = state.configuracion.porcentajeInteresDefault;
                _porcentajeInteresController.text = _porcentajeInteres.toStringAsFixed(2);
                _interesEsEditable = state.configuracion.interesEsEditable;
              });
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
                    _buildSectionHeader('Cliente', Icons.person),
                    _buildClienteSection(),
                    const SizedBox(height: 20),

                    _buildSectionHeader('Items', Icons.shopping_cart),
                    _buildItemsSection(),
                    const SizedBox(height: 20),

                    _buildSectionHeader('Comprobante', Icons.receipt_long),
                    ComprobanteCondicionCard(
                      tipoComprobante: _tipoComprobante,
                      onComprobanteChanged: (v) => setState(() => _tipoComprobante = v),
                      condicionPago: _condicionPago,
                      onCondicionChanged: (v) => setState(() {
                        _condicionPago = v;
                        if (v == 'CREDITO') _pagos.clear();
                      }),
                      emisores: _emisores,
                      emisorSeleccionado: _emisorSeleccionado,
                      onEmisorChanged: (e) => setState(() => _emisorSeleccionado = e),
                    ),
                    const SizedBox(height: 20),

                    _buildSectionHeader('Pago', Icons.payments),
                    _buildPagoSection(),
                    const SizedBox(height: 20),

                    _buildSectionHeader('Resumen', Icons.summarize),
                    PosResumenTotales(
                      items: _items,
                      moneda: _moneda,
                      nombreImpuesto: _nombreImpuesto,
                      porcentajeImpuesto: _impuestoPorcentaje,
                      totalVenta: _calcularTotal(),
                      totalPagado: _totalPagado,
                      montoCredito: _montoCredito,
                      numeroCuotas: _numeroCuotas,
                      esCredito: _esCredito,
                      condicionPago: _condicionPago,
                      interesHabilitado: _interesHabilitado,
                      porcentajeInteres: _porcentajeInteres,
                    ),
                    const SizedBox(height: 12),

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
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: PosActionBar(
              onBorrador: () => _submitBorrador(context),
              onCobrar: () => _submitCobrar(context),
            ),
          ),
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
                            _nombreClienteController.text = result.nombreCompleto ?? '';
                            _documentoController.text = result.dni ?? '';
                            _emailController.text = result.email ?? '';
                            _telefonoController.text = result.telefono ?? '';
                            _direccionController.text = '';
                          } else {
                            _clienteId = null;
                            _clienteEmpresaId = result.clienteEmpresaId;
                            _nombreClienteController.text = result.razonSocial ?? result.nombreComercial ?? '';
                            _documentoController.text = result.ruc ?? '';
                            _emailController.text = result.email ?? '';
                            _telefonoController.text = result.telefono ?? '';
                            _direccionController.text = result.direccion ?? '';
                          }
                        });
                      }
                    },
                    text: 'Buscar',
                    icon: const Icon(Icons.person_search, size: 16, color: AppColors.white),
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
              final existingIndex = _items.indexWhere((existing) {
                if (item.comboId != null && existing.comboId == item.comboId) return true;
                if (item.productoId != null && existing.productoId == item.productoId && existing.varianteId == item.varianteId) return true;
                if (item.servicioId != null && existing.servicioId == item.servicioId) return true;
                return false;
              });

              if (existingIndex >= 0) {
                final existing = _items[existingIndex];
                final nuevaCantidad = existing.cantidad + item.cantidad;
                // Recalcular ICBPER proporcionalmente si aplica
                final icbperPorUnidad = existing.cantidad > 0 ? existing.icbper / existing.cantidad : 0.0;
                _items[existingIndex] = VentaDetalleInput(
                  productoId: existing.productoId,
                  varianteId: existing.varianteId,
                  servicioId: existing.servicioId,
                  comboId: existing.comboId,
                  descripcion: existing.descripcion,
                  cantidad: nuevaCantidad,
                  precioUnitario: existing.precioUnitario,
                  descuento: existing.descuento,
                  porcentajeIGV: existing.porcentajeIGV,
                  precioIncluyeIgv: existing.precioIncluyeIgv,
                  tipoAfectacion: existing.tipoAfectacion,
                  icbper: icbperPorUnidad * nuevaCantidad,
                  stockDisponible: existing.stockDisponible,
                );
              } else {
                _items.add(VentaDetalleInput(
                  productoId: item.productoId,
                  varianteId: item.varianteId,
                  servicioId: item.servicioId,
                  comboId: item.comboId,
                  descripcion: item.descripcion,
                  cantidad: item.cantidad,
                  precioUnitario: item.precioUnitario,
                  descuento: item.descuento,
                  porcentajeIGV: item.porcentajeIGV,
                  precioIncluyeIgv: item.precioIncluyeIgv,
                  tipoAfectacion: item.tipoAfectacion,
                  icbper: item.icbper,
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
              child: Text('Agrega items a la venta', style: TextStyle(color: Colors.grey.shade500)),
            ),
          )
        else
          ItemsTableWidget(
            items: _items.map((item) => ItemTableRow(
              descripcion: item.descripcion,
              cantidad: item.cantidad,
              precioUnitario: item.precioUnitario,
              subtotal: item.total,
              porcentajeIGV: item.porcentajeIGV,
            )).toList(),
            onRemove: (i) => setState(() => _items.removeAt(i)),
          ),
      ],
    );
  }

  // ─── 4. PAGO Section ───

  Widget _buildPagoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sección crédito/cuotas (CREDITO y MIXTO)
        CreditoCuotasSection(
          condicionPago: _condicionPago,
          numeroCuotas: _numeroCuotas,
          onCuotasChanged: (v) => setState(() {
            _numeroCuotas = v;
            _numeroCuotasController.text = v.toString();
          }),
          montoCreditoController: _montoCreditoController,
          montoCredito: _montoCredito,
          montoPagarAhora: _montoPagarAhora,
          interesHabilitado: _interesHabilitado,
          interesEsEditable: _interesEsEditable,
          porcentajeInteres: _porcentajeInteres,
          porcentajeInteresController: _porcentajeInteresController,
          onInteresChanged: (v) => setState(() => _porcentajeInteres = double.tryParse(v) ?? 0),
          moraHabilitada: _moraHabilitada,
          porcentajeMoraDiario: _porcentajeMoraDiario,
          moraMaximaPorcentaje: _moraMaximaPorcentaje,
          diasGraciaMora: _diasGraciaMora,
          hasItems: _items.isNotEmpty,
          totalVenta: _calcularTotal(),
        ),

        // Pagos inmediatos (CONTADO y MIXTO)
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
            montoCredito: _esCredito ? _montoCredito : null,
            numeroCuotas: _esCredito ? _numeroCuotas : null,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  // ─── Submit: Cobrar ───

  void _submitCobrar(BuildContext context) {
    if (_nombreClienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre del cliente es requerido')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un item')));
      return;
    }
    if (_condicionPago == 'CONTADO' && _pagos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un pago')));
      return;
    }
    if (_condicionPago == 'MIXTO') {
      if (_montoCredito <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el monto a credito')));
        return;
      }
      if (_montoCredito >= _calcularTotal()) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El monto a credito debe ser menor al total. Usa "Credito" para credito total.')));
        return;
      }
      if (_montoPagarAhora > 0 && _pagos.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega el pago de la parte al contado')));
        return;
      }
      if (_totalPagado < _montoPagarAhora) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falta pagar S/ ${(_montoPagarAhora - _totalPagado).toStringAsFixed(2)} de la parte al contado')));
        return;
      }
    }
    if (_esCredito && _numeroCuotas <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingresa el numero de cuotas')));
      return;
    }

    final plazoDias = _numeroCuotas * 30;
    final now = DateTime.now();
    final fechaUltimaCuota = DateTime(now.year, now.month + _numeroCuotas + 1, 1);

    final data = <String, dynamic>{
      'canalVenta': 'POS',
      'sedeId': _sedeId,
      'vendedorId': _vendedorId,
      if (_clienteId != null) 'clienteId': _clienteId,
      if (_clienteEmpresaId != null) 'clienteEmpresaId': _clienteEmpresaId,
      'nombreCliente': _nombreClienteController.text,
      if (_documentoController.text.isNotEmpty) 'documentoCliente': _documentoController.text,
      if (_emailController.text.isNotEmpty) 'emailCliente': _emailController.text,
      if (_telefonoController.text.isNotEmpty) 'telefonoCliente': _telefonoController.text,
      if (_direccionController.text.isNotEmpty) 'direccionCliente': _direccionController.text,
      'moneda': _moneda,
      'tipoComprobante': _tipoComprobante,
      if (_emisorSeleccionado?.sedeId != null) 'sedeFacturacionId': _emisorSeleccionado!.sedeId,
      'esCredito': _esCredito,
      if (_pagos.isNotEmpty) ...{
        'metodoPago': _pagos.first['metodo'],
        'montoRecibido': _totalPagado,
        'pagos': _pagos.map((p) => {
          'metodoPago': p['metodo'],
          'monto': p['monto'],
          if ((p['referencia'] as String).isNotEmpty) 'referencia': p['referencia'],
          if (p['monedaOriginal'] == 'USD') ...{
            'monedaOriginal': 'USD',
            'montoOriginal': p['montoOriginal'],
            'tipoCambio': p['tipoCambio'],
          },
        }).toList(),
      },
      if (_esCredito) ...{
        'plazoCredito': plazoDias,
        'numeroCuotas': _numeroCuotas,
        'fechaVencimientoPago': fechaUltimaCuota.toIso8601String(),
      },
      if (_esCredito && _interesHabilitado && _porcentajeInteres > 0) ...{
        'porcentajeInteres': _porcentajeInteres,
      },
      if (_observacionesController.text.isNotEmpty) 'observaciones': _observacionesController.text,
      'detalles': _items.map((item) => item.toMap()).toList(),
    };

    context.read<VentaFormCubit>().crearYCobrar(data);
  }

  // ─── Submit: Borrador ───

  void _submitBorrador(BuildContext context) {
    if (_nombreClienteController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('El nombre del cliente es requerido')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Agrega al menos un item')));
      return;
    }

    final data = <String, dynamic>{
      'canalVenta': 'POS',
      'sedeId': _sedeId,
      'vendedorId': _vendedorId,
      if (_clienteId != null) 'clienteId': _clienteId,
      if (_clienteEmpresaId != null) 'clienteEmpresaId': _clienteEmpresaId,
      'nombreCliente': _nombreClienteController.text,
      if (_documentoController.text.isNotEmpty) 'documentoCliente': _documentoController.text,
      if (_emailController.text.isNotEmpty) 'emailCliente': _emailController.text,
      if (_telefonoController.text.isNotEmpty) 'telefonoCliente': _telefonoController.text,
      if (_direccionController.text.isNotEmpty) 'direccionCliente': _direccionController.text,
      'moneda': _moneda,
      'tipoComprobante': _tipoComprobante,
      if (_observacionesController.text.isNotEmpty) 'observaciones': _observacionesController.text,
      'detalles': _items.map((item) => item.toMap()).toList(),
    };

    context.read<VentaFormCubit>().crearVenta(data);
  }
}
