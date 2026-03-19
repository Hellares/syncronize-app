import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
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
import '../../domain/entities/venta.dart';
import '../../domain/entities/venta_detalle_input.dart';
import '../widgets/metodo_pago_selector.dart';
import '../widgets/resumen_venta_widget.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
import '../../../cotizacion/presentation/widgets/cotizacion_item_selector.dart';

class VentaFormPage extends StatefulWidget {
  final String? cotizacionId;

  const VentaFormPage({super.key, this.cotizacionId});

  @override
  State<VentaFormPage> createState() => _VentaFormPageState();
}

class _VentaFormPageState extends State<VentaFormPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Paso 1: Cliente
  final _nombreClienteController = TextEditingController();
  final _documentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  String? _clienteId;
  String? _clienteEmpresaId;
  String? _sedeId;
  String? _vendedorId;
  String? _empresaId;

  // Paso 2: Items
  final List<VentaDetalleInput> _items = [];

  // Paso 3: Pago
  MetodoPago? _metodoPago;
  final _montoRecibidoController = TextEditingController();
  bool _esCredito = false;
  final _plazoCreditoController = TextEditingController();

  // Paso 4: Observaciones
  final _observacionesController = TextEditingController();

  // Config
  double _impuestoPorcentaje = 18.0;
  String _nombreImpuesto = 'IGV';
  String _moneda = 'PEN';

  bool get _desdeCotizacion => widget.cotizacionId != null;
  bool _cotizacionCargada = false;

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

    // Si viene de cotización, cargar datos y saltar al paso de pago
    if (_desdeCotizacion) {
      _cargarDatosCotizacion();
    }
  }

  Future<void> _cargarDatosCotizacion() async {
    if (_empresaId == null || widget.cotizacionId == null) return;
    try {
      final dio = locator<DioClient>();
      final response = await dio.get('/cotizaciones/${widget.cotizacionId}');
      final data = response.data as Map<String, dynamic>;

      if (!mounted) return;
      setState(() {
        // Cliente
        _nombreClienteController.text = data['nombreCliente']?.toString() ?? '';
        _documentoController.text = data['documentoCliente']?.toString() ?? '';
        _emailController.text = data['emailCliente']?.toString() ?? '';
        _telefonoController.text = data['telefonoCliente']?.toString() ?? '';
        _direccionController.text = data['direccionCliente']?.toString() ?? '';
        _clienteId = data['clienteId'] as String?;
        if (data['sedeId'] != null) _sedeId = data['sedeId'] as String;

        // Items de la cotización
        final detalles = data['detalles'] as List? ?? [];
        _items.clear();
        for (final d in detalles) {
          final dm = d as Map<String, dynamic>;
          _items.add(VentaDetalleInput(
            productoId: dm['productoId'] as String?,
            varianteId: dm['varianteId'] as String?,
            descripcion: dm['descripcion']?.toString() ?? dm['producto']?['nombre']?.toString() ?? 'Producto',
            cantidad: (dm['cantidad'] as num?)?.toDouble() ?? 1,
            precioUnitario: (dm['precioUnitario'] as num?)?.toDouble() ?? 0,
            descuento: (dm['descuento'] as num?)?.toDouble() ?? 0,
            porcentajeIGV: _impuestoPorcentaje,
          ));
        }

        // Saltar al paso de items para que el cajero verifique
        _currentStep = 1;
        _cotizacionCargada = true;
      });
    } catch (e) {
      // Si falla, dejar el formulario normal
    }
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
    _montoRecibidoController.dispose();
    _plazoCreditoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<VentaFormCubit>(),
      child: BlocListener<VentaFormCubit, VentaFormState>(
        listener: (context, state) {
          if (state is VentaFormSuccess) {
            // Invalidate product/stock caches so lists refresh
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
          builder: (context) => Scaffold(
            appBar: SmartAppBar(
              title: _desdeCotizacion
                  ? 'Venta desde Cotizacion'
                  : 'Nueva Venta',
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
            body: Form(
              key: _formKey,
              child: Stepper(
                currentStep: _currentStep,
                onStepContinue: _onStepContinue,
                onStepCancel: _onStepCancel,
                onStepTapped: (step) {
                  if (step <= _currentStep) {
                    setState(() => _currentStep = step);
                  }
                },
                controlsBuilder: _buildControls,
                steps: [
                  _buildClienteStep(),
                  _buildItemsStep(),
                  _buildPagoStep(),
                  _buildResumenStep(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Steps ───

  Step _buildClienteStep() {
    return Step(
      title: const Text('Cliente'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ElevatedButton.icon(
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
            icon: const Icon(Icons.person_search, size: 18),
            label: const Text('Buscar Cliente'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          CustomText(
            controller: _nombreClienteController,
            label: 'Nombre del cliente *',
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: _documentoController,
            label: 'Documento (DNI/RUC)',
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: _emailController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: _telefonoController,
            label: 'Telefono',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: _direccionController,
            label: 'Direccion',
          ),
        ],
      ),
    );
  }

  Step _buildItemsStep() {
    return Step(
      title: const Text('Items'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CotizacionItemSelector(
            onItemSelected: (item) {
              setState(() {
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
            ..._items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              return GradientContainer(
                borderColor: AppColors.blueborder,
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  dense: true,
                  title: Text(
                    item.descripcion,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${item.cantidad} x $_moneda ${item.precioUnitario.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$_moneda ${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            size: 18, color: Colors.red),
                        onPressed: () {
                          setState(() => _items.removeAt(i));
                        },
                      ),
                    ],
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Step _buildPagoStep() {
    return Step(
      title: const Text('Pago'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppSubtitle('Metodo de Pago', fontSize: 13),
          const SizedBox(height: 8),
          MetodoPagoSelector(
            selected: _metodoPago,
            onChanged: (metodo) {
              setState(() {
                _metodoPago = metodo;
                _esCredito = metodo == MetodoPago.credito;
              });
            },
          ),
          const SizedBox(height: 16),
          if (_metodoPago == MetodoPago.efectivo) ...[
            CustomText(
              controller: _montoRecibidoController,
              label: 'Monto recibido',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 8),
            Builder(builder: (context) {
              final totalVenta = _calcularTotal();
              final recibido = double.tryParse(
                      _montoRecibidoController.text) ??
                  0;
              final cambio =
                  recibido > totalVenta ? recibido - totalVenta : 0.0;
              return GradientContainer(
                borderColor: Colors.green.shade200,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Cambio:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        '$_moneda ${cambio.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.green.shade700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (_esCredito) ...[
            const SizedBox(height: 12),
            CustomText(
              controller: _plazoCreditoController,
              label: 'Plazo de credito (dias)',
              keyboardType: TextInputType.number,
            ),
          ],
          const SizedBox(height: 12),
          CustomText(
            controller: _observacionesController,
            label: 'Observaciones',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Step _buildResumenStep(BuildContext context) {
    return Step(
      title: const Text('Resumen'),
      isActive: _currentStep >= 3,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_desdeCotizacion)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Venta generada desde cotizacion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          GradientContainer(
            borderColor: AppColors.blueborder,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildResumenRow('Cliente', _nombreClienteController.text),
                  if (_documentoController.text.isNotEmpty)
                    _buildResumenRow('Documento', _documentoController.text),
                  if (_metodoPago != null)
                    _buildResumenRow('Metodo Pago', _metodoPago!.label),
                  if (_esCredito &&
                      _plazoCreditoController.text.isNotEmpty)
                    _buildResumenRow(
                        'Plazo Credito', '${_plazoCreditoController.text} dias'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ResumenVentaWidget(
            items: _items,
            moneda: _moneda,
            nombreImpuesto: _nombreImpuesto,
            porcentajeImpuesto: _impuestoPorcentaje,
          ),
          const SizedBox(height: 16),
          BlocBuilder<VentaFormCubit, VentaFormState>(
            builder: (context, state) {
              final isLoading = state is VentaFormLoading;
              return SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Registrar Venta',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : () => _submitVenta(context),
                  icon: const Icon(Icons.check, size: 18),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResumenRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
          Expanded(
            child: Text(value,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  // ─── Controls ───

  Widget _buildControls(BuildContext context, ControlsDetails details) {
    if (_currentStep == 3) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          ElevatedButton(
            onPressed: details.onStepContinue,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
          if (_currentStep > 0) ...[
            const SizedBox(width: 8),
            TextButton(
              onPressed: details.onStepCancel,
              child: const Text('Atras'),
            ),
          ],
        ],
      ),
    );
  }

  void _onStepContinue() {
    if (_currentStep == 0) {
      if (_nombreClienteController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El nombre del cliente es requerido')),
        );
        return;
      }
    }
    if (_currentStep == 1) {
      if (_items.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Agrega al menos un item')),
        );
        return;
      }
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  double _calcularTotal() {
    final subtotal = _items.fold(0.0, (sum, i) => sum + i.subtotal);
    return subtotal + (subtotal * _impuestoPorcentaje / 100);
  }

  void _submitVenta(BuildContext context) {
    if (_desdeCotizacion) {
      final data = <String, dynamic>{};
      if (_metodoPago != null) data['metodoPago'] = _metodoPago!.apiValue;
      if (_montoRecibidoController.text.isNotEmpty) {
        data['montoRecibido'] = double.tryParse(_montoRecibidoController.text);
      }
      data['esCredito'] = _esCredito;
      if (_esCredito && _plazoCreditoController.text.isNotEmpty) {
        data['plazoCredito'] = int.tryParse(_plazoCreditoController.text);
      }
      if (_observacionesController.text.isNotEmpty) {
        data['observaciones'] = _observacionesController.text;
      }
      context.read<VentaFormCubit>().crearDesdeCotizacion(
            widget.cotizacionId!,
            data,
          );
    } else {
      final data = {
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
        if (_metodoPago != null) 'metodoPago': _metodoPago!.apiValue,
        if (_montoRecibidoController.text.isNotEmpty)
          'montoRecibido': double.tryParse(_montoRecibidoController.text),
        'esCredito': _esCredito,
        if (_esCredito && _plazoCreditoController.text.isNotEmpty)
          'plazoCredito': int.tryParse(_plazoCreditoController.text),
        if (_observacionesController.text.isNotEmpty)
          'observaciones': _observacionesController.text,
        'detalles': _items.map((item) => item.toMap()).toList(),
      };
      context.read<VentaFormCubit>().crearVenta(data);
    }
  }
}
