import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/date_formatter.dart' as df;
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/bloc/auth/auth_bloc.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../bloc/cotizacion_form/cotizacion_form_cubit.dart';
import '../bloc/cotizacion_form/cotizacion_form_state.dart';
import '../../domain/entities/cotizacion.dart';
import '../../domain/entities/cotizacion_detalle_input.dart';
import '../../domain/usecases/get_cotizacion_usecase.dart';
import '../widgets/cotizacion_item_selector.dart';
import '../widgets/cotizacion_compatibilidad_banner.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';

class CotizacionFormPage extends StatefulWidget {
  final String? cotizacionId;

  const CotizacionFormPage({super.key, this.cotizacionId});

  bool get isEditing => cotizacionId != null;

  @override
  State<CotizacionFormPage> createState() => _CotizacionFormPageState();
}

class _CotizacionFormPageState extends State<CotizacionFormPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();

  // Nombre de la cotizacion
  final _nombreCotizacionController = TextEditingController();

  // Paso 1: Datos del cliente
  final _nombreClienteController = TextEditingController();
  final _documentoController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  String? _clienteId; // EmpresaPersona.id cuando hay cliente vinculado
  String? _sedeId;
  String? _vendedorId;

  // Paso 2: Items
  final List<CotizacionDetalleInput> _items = [];

  // Paso 3: Observaciones
  final _observacionesController = TextEditingController();
  final _condicionesController = TextEditingController();
  final _fechaVencimientoController = TextEditingController();
  String _moneda = 'PEN';

  // Compatibilidad
  bool? _compatible;
  List<Map<String, dynamic>> _conflictos = [];

  // Configuración fiscal (defaults si no se ha cargado)
  // ignore: unused_field
  double _impuestoPorcentaje = 18.0; // Mantenido para referencia, el IGV real es per-item
  String _nombreImpuesto = 'IGV';
  int _diasVigencia = 30;

  // Edición
  bool _isLoadingCotizacion = false;

  bool get _isEditing => widget.isEditing;

  @override
  void initState() {
    super.initState();
    // Obtener sedeId desde EmpresaContext
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      final sedes = empresaState.context.sedes;
      if (sedes.isNotEmpty) {
        _sedeId = empresaState.context.sedePrincipal?.id ?? sedes.first.id;
      }
      // Cargar configuración fiscal
      context.read<ConfiguracionEmpresaCubit>().cargar(
        empresaState.context.empresa.id,
      );
    }
    // Obtener vendedorId desde AuthBloc (usuario actual)
    final authState = context.read<AuthBloc>().state;
    if (authState is Authenticated) {
      _vendedorId = authState.user.id;
    }
    // Leer configuración si ya está cargada
    _leerConfiguracion();

    // Si es edición, cargar datos existentes
    if (_isEditing) {
      _loadCotizacion();
    }
  }

  Future<void> _loadCotizacion() async {
    setState(() => _isLoadingCotizacion = true);

    final result = await locator<GetCotizacionUseCase>()(
      cotizacionId: widget.cotizacionId!,
    );

    if (!mounted) return;

    if (result is Success<Cotizacion>) {
      final cot = result.data;
      setState(() {
        // Paso 1: Cliente
        _nombreCotizacionController.text = cot.nombre ?? '';
        _clienteId = cot.clienteId;
        _nombreClienteController.text = cot.nombreCliente;
        _documentoController.text = cot.documentoCliente ?? '';
        _emailController.text = cot.emailCliente ?? '';
        _telefonoController.text = cot.telefonoCliente ?? '';
        _direccionController.text = cot.direccionCliente ?? '';

        // Paso 2: Items
        _items.clear();
        if (cot.detalles != null) {
          for (final d in cot.detalles!) {
            _items.add(CotizacionDetalleInput(
              productoId: d.productoId,
              varianteId: d.varianteId,
              servicioId: d.servicioId,
              descripcion: d.descripcion,
              cantidad: d.cantidad,
              precioUnitario: d.precioUnitario,
              descuento: d.descuento,
              tipoAfectacion: d.tipoAfectacion,
              porcentajeIGV: d.porcentajeIGV,
              icbper: d.icbper,
            ));
          }
        }

        // Paso 3: Condiciones
        _moneda = cot.moneda;
        _observacionesController.text = cot.observaciones ?? '';
        _condicionesController.text = cot.condiciones ?? '';
        if (cot.fechaVencimiento != null) {
          _fechaVencimientoController.text = df.DateFormatter.formatDate(cot.fechaVencimiento!);
        }

        _isLoadingCotizacion = false;
      });
    } else if (result is Error<Cotizacion>) {
      setState(() => _isLoadingCotizacion = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al cargar cotizacion: ${result.message}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _leerConfiguracion() {
    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is ConfiguracionEmpresaLoaded) {
      _impuestoPorcentaje = configState.configuracion.impuestoDefaultPorcentaje;
      _nombreImpuesto = configState.configuracion.nombreImpuesto;
      _diasVigencia = configState.configuracion.diasVigenciaCotizacion;
      _moneda = configState.configuracion.monedaPrincipal;
    }
  }

  @override
  void dispose() {
    _nombreCotizacionController.dispose();
    _nombreClienteController.dispose();
    _documentoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _observacionesController.dispose();
    _condicionesController.dispose();
    _fechaVencimientoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CotizacionFormCubit>(),
      child: BlocListener<ConfiguracionEmpresaCubit, ConfiguracionEmpresaState>(
        listener: (context, configState) {
          if (configState is ConfiguracionEmpresaLoaded) {
            setState(() {
              _impuestoPorcentaje = configState.configuracion.impuestoDefaultPorcentaje;
              _nombreImpuesto = configState.configuracion.nombreImpuesto;
              _diasVigencia = configState.configuracion.diasVigenciaCotizacion;
              _moneda = configState.configuracion.monedaPrincipal;
            });
          }
        },
        child: BlocConsumer<CotizacionFormCubit, CotizacionFormState>(
        listener: (context, state) {
          if (state is CotizacionFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
            Navigator.pop(context, true);
          }
          if (state is CotizacionFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
          if (state is CotizacionCompatibilidadResult) {
            setState(() {
              _compatible = state.compatible;
              _conflictos = state.conflictos;
            });
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: SmartAppBar(
              title: _isEditing ? 'Editar Cotizacion' : 'Nueva Cotizacion',
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
            ),
            body: _isLoadingCotizacion
                ? const Center(child: CircularProgressIndicator())
                : GradientContainer(
              child: Form(
                key: _formKey,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: AppColors.blue1,
                      onPrimary: Colors.white,
                    ),
                  ),
                  child: Stepper(
                    currentStep: _currentStep,
                    margin: const EdgeInsets.only(left: 10, right: 8, bottom: 12),
                    connectorColor: WidgetStatePropertyAll(AppColors.blue1),
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    onStepTapped: _onStepTapped,
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          if (_currentStep < 3)

                            CustomButton(text: 'Siguiente', onPressed: details.onStepContinue, backgroundColor: AppColors.blue1,),
                          if (_currentStep == 3)
                            CustomButton(
                              text: state is CotizacionFormLoading
                                  ? (_isEditing ? 'Guardando...' : 'Creando...')
                                  : (_isEditing ? 'Guardar Cambios' : 'Crear Cotizacion'),
                              onPressed: state is CotizacionFormLoading
                                  ? null
                                  : () => _submitCotizacion(context),
                              backgroundColor: AppColors.green,
                            ),
                          const SizedBox(width: 4),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Anterior', style: TextStyle(fontSize: 10)),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    // Paso 1: Datos del cliente
                    Step(
                      title: AppSubtitle('CLIENTE'),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0
                          ? StepState.complete
                          : StepState.indexed,
                      content: _buildStep1(),
                    ),
              
                    // Paso 2: Items (lazy: solo construye el contenido pesado cuando el usuario llega)
                    Step(
                      title: AppSubtitle('ITEMS'),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1
                          ? StepState.complete
                          : StepState.indexed,
                      content: _currentStep >= 1
                          ? _buildStep2(context)
                          : const SizedBox.shrink(),
                    ),

                    // Paso 3: Condiciones
                    Step(
                      title: AppSubtitle('CONDICIONES'),
                      isActive: _currentStep >= 2,
                      state: _currentStep > 2
                          ? StepState.complete
                          : StepState.indexed,
                      content: _currentStep >= 2
                          ? _buildStep3()
                          : const SizedBox.shrink(),
                    ),

                    // Paso 4: Resumen
                    Step(
                      title: AppSubtitle('RESUMEN'),
                      isActive: _currentStep >= 3,
                      content: _currentStep >= 3
                          ? _buildStep4()
                          : const SizedBox.shrink(),
                    ),
                  ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
      ),
    );
  }

  // Paso 1: Datos del cliente y vendedor
  Widget _buildStep1() {
    final bool linked = _clienteId != null;

    return Column(
      children: [
        _buildClienteSelector(),
        const SizedBox(height: 12),
        CustomText(
          controller: _nombreCotizacionController,
          label: 'Nombre de la cotizacion',
          hintText: 'Ej: PC GAMER PROFESIONAL',
          borderColor: AppColors.blue1,
        ),
        const SizedBox(height: 12),
        if (linked) ...[
          _buildClienteInfoCard(),
          const SizedBox(height: 12),
          CustomText(
            controller: _telefonoController,
            label: 'Telefono',
            borderColor: AppColors.blue1,
            keyboardType: TextInputType.phone,
          ),
        ] else ...[
          CustomText(
            controller: _nombreClienteController,
            label: 'Nombre del cliente',
            borderColor: AppColors.blue1,
            validator: (v) =>
                v == null || v.isEmpty ? 'El nombre es requerido' : null,
          ),
          const SizedBox(height: 12),
          CustomText(
            controller: _documentoController,
            label: 'Documento (DNI/RUC)',
            borderColor: AppColors.blue1,
            validator: (v) =>
                v == null || v.isEmpty ? 'El documento es requerido' : null,
          ),
          const SizedBox(height: 12),
          CustomText(
            controller: _direccionController,
            label: 'Direccion',
            borderColor: AppColors.blue1,
          ),
          const SizedBox(height: 12),
          CustomText(
            controller: _emailController,
            label: 'Email',
            borderColor: AppColors.blue1,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),
          CustomText(
            controller: _telefonoController,
            label: 'Telefono',
            borderColor: AppColors.blue1,
            keyboardType: TextInputType.phone,
          ),
        ],
      ],
    );
  }

  Widget _buildClienteInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bluechip.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.blueborder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(Icons.person_outline, 'Cliente', _nombreClienteController.text),
          if (_documentoController.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.badge_outlined, 'DNI', _documentoController.text),
          ],
          if (_emailController.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.email_outlined, 'Email', _emailController.text),
          ],
          if (_direccionController.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            _buildInfoRow(Icons.location_on_outlined, 'Dirección', _direccionController.text),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.blue1),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildClienteSelector() {
    if (_clienteId != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle, size: 18, color: Colors.green),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cliente vinculado',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _nombreClienteController.text,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green.shade800,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: Colors.red),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              tooltip: 'Desvincular cliente',
              onPressed: _clearLinkedCliente,
            ),
          ],
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _openClienteSelector,
        icon: const Icon(Icons.person_search, size: 18),
        label: const Text('Buscar o registrar cliente'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.blue1,
          side: const BorderSide(color: AppColors.blue1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Future<void> _openClienteSelector() async {
    String? empresaId;
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      empresaId = empresaState.context.empresa.id;
    }
    if (empresaId == null) return;

    final result = await ClienteUnificadoSelector.show(
      context: context,
      empresaId: empresaId,
      tipoPermitido: TipoClienteSeleccion.persona,
    );

    if (result != null && mounted) {
      setState(() {
        _clienteId = result.clienteId;
        _nombreClienteController.text = result.nombreCompleto ?? '';
        _documentoController.text = result.dni ?? '';
        _telefonoController.text = result.telefono ?? '';
        _emailController.text = result.email ?? '';
        _direccionController.text = '';
      });
    }
  }

  void _clearLinkedCliente() {
    setState(() {
      _clienteId = null;
      _nombreClienteController.clear();
      _documentoController.clear();
      _telefonoController.clear();
      _emailController.clear();
      _direccionController.clear();
    });
  }

  // Paso 2: Items
  Widget _buildStep2(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner de compatibilidad
        if (_compatible != null)
          CotizacionCompatibilidadBanner(
            compatible: _compatible!,
            conflictos: _conflictos,
          ),

        // Selector de items
        CotizacionItemSelector(
          onItemSelected: (item) {
            setState(() {
              _items.add(item);
            });
            // Validar compatibilidad si hay 2+ items con productoId
            _checkCompatibilidad(context);
          },
        ),

        const SizedBox(height: 12),

        // Lista de items agregados
        if (_items.isNotEmpty) ...[
          AppSubtitle('Items agregados (${_items.length})'),
          const SizedBox(height: 8),
          ..._items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final cantidad = item.cantidad;
            final precio = item.precioUnitario;
            final subtotal = cantidad * precio;
            final hayIgvMixto = _items.length > 1 && !_items.every((i) => i.porcentajeIGV == _items.first.porcentajeIGV);

            return GradientContainer(
              margin: const EdgeInsets.only(bottom: 6),
              child: ListTile(
                dense: true,
                contentPadding: const EdgeInsets.only(right: 1, left: 10),
                title: Row(
                  children: [
                    Expanded(child: AppSubtitle(item.descripcion)),
                    if (hayIgvMixto)
                      Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: item.porcentajeIGV != _items.first.porcentajeIGV ? Colors.orange.shade50 : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: item.porcentajeIGV != _items.first.porcentajeIGV ? Colors.orange.shade300 : Colors.blue.shade300, width: 0.5),
                        ),
                        child: Text(
                          'IGV ${item.porcentajeIGV.toStringAsFixed(0)}%',
                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: item.porcentajeIGV != _items.first.porcentajeIGV ? Colors.orange.shade700 : Colors.blue.shade700),
                        ),
                      ),
                  ],
                ),
                subtitle: AppSubtitle(
                  '${cantidad.toStringAsFixed(0)} x $_moneda ${precio.toStringAsFixed(2)}',
                  color: Colors.grey.shade600,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppSubtitle(
                      '$_moneda ${subtotal.toStringAsFixed(2)}',
                      color: AppColors.blue1,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,

                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          size: 20, color: Colors.red),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(() => _items.removeAt(index));
                        _checkCompatibilidad(context);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  // Paso 3: Condiciones
  Widget _buildStep3() {
    return Column(
      children: [
        CustomDropdown<String>(
          label: 'Moneda',
          value: _moneda,
          borderColor: AppColors.blue1,
          items: const [
            DropdownItem(value: 'PEN', label: 'PEN - Soles'),
            DropdownItem(value: 'USD', label: 'USD - Dolares'),
          ],
          onChanged: (v) => setState(() => _moneda = v ?? 'PEN'),
        ),
        const SizedBox(height: 12),
        CustomDate(
          label: 'Fecha de vencimiento',
          controller: _fechaVencimientoController,
          borderColor: AppColors.blue1,
          initialDate: DateTime.now().add(Duration(days: _diasVigencia)),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _observacionesController,
          borderColor: AppColors.blue1,
          label: 'Observaciones',
          hintText: 'Notas adicionales para la cotización',
          enableVoiceInput: true,
          maxLines: null,
          minLines: 3,
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _condicionesController,
          borderColor: AppColors.blue1,
          label: 'Condiciones comerciales',
          hintText: 'Condiciones especiales de venta',
          enableVoiceInput: true,
          maxLines: null,
          minLines: 3,
        ),
      ],
    );
  }

  // Paso 4: Resumen
  Widget _buildStep4() {
    final subtotal = _items.fold<double>(0, (sum, item) => sum + item.subtotal);
    final igv = _items.fold<double>(0, (sum, item) => sum + item.igv);
    final total = _items.fold<double>(0, (sum, item) => sum + item.total);

    return GradientContainer(
      width: double.infinity,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_nombreCotizacionController.text.trim().isNotEmpty) ...[
              AppSubtitle('Cotizacion:  ${_nombreCotizacionController.text.trim()}'),
              const SizedBox(height: 8),
            ],

            // Cliente
            AppSubtitle('Cliente: ${_nombreClienteController.text}', color: AppColors.blue1),
            if (_documentoController.text.isNotEmpty)
              Text('Doc: ${_documentoController.text}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),

            Divider(color: AppColors.blueborder, height: 24),

            // Items
            AppSubtitle('Items (${_items.length})'),
            const SizedBox(height: 6),
            ..._items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: AppSubtitle(item.descripcion)
                      ),
                      AppSubtitle(
                        '$_moneda ${(item.cantidad * item.precioUnitario).toStringAsFixed(2)}',
                        color: AppColors.blue1,
                      ),
                    ],
                  ),
                )),

            Divider(color: AppColors.blueborder, height: 24),

            // Totales
            _SummaryRow('Subtotal', '$_moneda ${subtotal.toStringAsFixed(2)}'),
            _SummaryRow('$_nombreImpuesto${_items.isNotEmpty && _items.every((i) => i.porcentajeIGV == _items.first.porcentajeIGV) ? ' (${_items.first.porcentajeIGV.toStringAsFixed(0)}%)' : ''}', '$_moneda ${igv.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            _SummaryRow('Total', '$_moneda ${total.toStringAsFixed(2)}',
                bold: true),
          ],
        ),
      ),
    );
  }

  /// Valida si un paso específico está completo
  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _nombreClienteController.text.trim().isNotEmpty;
      case 1:
        return _items.isNotEmpty;
      default:
        return true;
    }
  }

  /// Muestra error de validación para un paso
  void _showStepError(int step) {
    String message;
    switch (step) {
      case 0:
        message = 'El nombre del cliente es requerido';
        break;
      case 1:
        message = 'Agregue al menos un item';
        break;
      default:
        return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onStepTapped(int step) {
    // Permitir retroceder siempre
    if (step <= _currentStep) {
      setState(() => _currentStep = step);
      return;
    }
    // Para avanzar, validar todos los pasos intermedios
    for (int i = _currentStep; i < step; i++) {
      if (!_isStepValid(i)) {
        _showStepError(i);
        return;
      }
    }
    setState(() => _currentStep = step);
  }

  void _onStepContinue() {
    if (!_isStepValid(_currentStep)) {
      _showStepError(_currentStep);
      return;
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

  void _checkCompatibilidad(BuildContext context) {
    final productItems = _items
        .where((i) => i.productoId != null || i.varianteId != null)
        .toList();
    if (productItems.length >= 2) {
      context.read<CotizacionFormCubit>().validarCompatibilidad(
        productItems.map((i) => i.toMap()).toList(),
      );
    } else {
      setState(() {
        _compatible = null;
        _conflictos = [];
      });
    }
  }

  void _submitCotizacion(BuildContext context) {
    // Construir fecha de vencimiento
    String? fechaVencimiento;
    if (_fechaVencimientoController.text.isNotEmpty) {
      final parts = _fechaVencimientoController.text.split('/');
      if (parts.length == 3) {
        final day = int.tryParse(parts[0]) ?? 1;
        final month = int.tryParse(parts[1]) ?? 1;
        final year = int.tryParse(parts[2]) ?? 2026;
        fechaVencimiento = DateTime(year, month, day).toIso8601String();
      }
    }

    final data = <String, dynamic>{
      if (!_isEditing) 'sedeId': _sedeId ?? '',
      if (!_isEditing) 'vendedorId': _vendedorId ?? '',
      if (_clienteId != null) 'clienteId': _clienteId,
      if (_nombreCotizacionController.text.trim().isNotEmpty)
        'nombre': _nombreCotizacionController.text.trim(),
      'nombreCliente': _nombreClienteController.text.trim(),
      if (_documentoController.text.isNotEmpty)
        'documentoCliente': _documentoController.text.trim(),
      if (_emailController.text.isNotEmpty)
        'emailCliente': _emailController.text.trim(),
      if (_telefonoController.text.isNotEmpty)
        'telefonoCliente': _telefonoController.text.trim(),
      if (_direccionController.text.isNotEmpty)
        'direccionCliente': _direccionController.text.trim(),
      'moneda': _moneda,
      if (_observacionesController.text.isNotEmpty)
        'observaciones': _observacionesController.text.trim(),
      if (_condicionesController.text.isNotEmpty)
        'condiciones': _condicionesController.text.trim(),
      if (fechaVencimiento != null) 'fechaVencimiento': fechaVencimiento,
      'detalles': _items.map((item) => item.toMap()).toList(),
    };

    if (_isEditing) {
      context.read<CotizacionFormCubit>().actualizarCotizacion(
        widget.cotizacionId!,
        data,
      );
    } else {
      context.read<CotizacionFormCubit>().crearCotizacion(data);
    }
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _SummaryRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppSubtitle(label),
          AppSubtitle(value, color: bold ? AppColors.blue1 : Colors.black),
        ],
      ),
    );
  }
}
