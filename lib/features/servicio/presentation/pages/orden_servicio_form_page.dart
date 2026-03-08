import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../cotizacion/presentation/widgets/cliente_selector_bottom_sheet.dart';
import '../../domain/entities/configuracion_campo.dart';
import '../../domain/entities/servicio.dart';
import '../../domain/entities/servicio_filtros.dart';
import '../../domain/repositories/orden_servicio_repository.dart';
import '../../domain/repositories/plantilla_servicio_repository.dart';
import '../../domain/repositories/servicio_repository.dart';
import '../widgets/dynamic_form_renderer.dart';

class OrdenServicioFormPage extends StatefulWidget {
  const OrdenServicioFormPage({super.key});

  @override
  State<OrdenServicioFormPage> createState() => _OrdenServicioFormPageState();
}

class _OrdenServicioFormPageState extends State<OrdenServicioFormPage> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  late final String _empresaId;

  // Step 0: Cliente (via bottom sheet)
  String? _clienteId;
  String _clienteNombre = '';
  String _clienteDni = '';
  String _clienteTelefono = '';
  String? _clienteEmail;

  // Step 1: Equipo
  final _tipoEquipoController = TextEditingController();
  final _marcaEquipoController = TextEditingController();
  final _numeroSerieController = TextEditingController();
  final _condicionEquipoController = TextEditingController();

  // Step 2: Servicio
  String _tipoServicio = 'REPARACION';
  String _prioridad = 'NORMAL';
  final _descripcionProblemaController = TextEditingController();
  List<Servicio> _serviciosDisponibles = [];
  Servicio? _servicioSeleccionado;
  bool _cargandoServicios = false;

  // Step 3: Campos personalizados
  List<ConfiguracionCampo> _camposPersonalizados = [];
  Map<String, dynamic> _datosPersonalizados = {};
  bool _cargandoCampos = false;

  // Step 4: Notas + Aviso
  final _notasController = TextEditingController();
  bool _incluirAviso = true;
  final _fechaAvisoController = TextEditingController();
  DateTime? _fechaAvisoPersonalizado;

  bool _isLoading = false;

  static const _totalSteps = 5;

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    _empresaId = empresaState is EmpresaContextLoaded
        ? empresaState.context.empresa.id
        : '';
    _loadServicios();
  }

  @override
  void dispose() {
    _tipoEquipoController.dispose();
    _marcaEquipoController.dispose();
    _numeroSerieController.dispose();
    _condicionEquipoController.dispose();
    _descripcionProblemaController.dispose();
    _notasController.dispose();
    _fechaAvisoController.dispose();
    super.dispose();
  }

  // ─── Data loading ───

  Future<void> _loadServicios() async {
    setState(() => _cargandoServicios = true);
    final repo = locator<ServicioRepository>();
    final result = await repo.getServicios(
      empresaId: _empresaId,
      filtros: const ServicioFiltros(limit: 100),
    );
    if (!mounted) return;
    setState(() {
      _cargandoServicios = false;
      if (result is Success<ServiciosPaginados>) {
        _serviciosDisponibles = result.data.data;
      }
    });
  }

  Future<void> _loadCamposPorServicio(String servicioId) async {
    setState(() {
      _cargandoCampos = true;
      _camposPersonalizados = [];
      _datosPersonalizados = {};
    });
    final repo = locator<PlantillaServicioRepository>();
    final result = await repo.getCamposByServicioId(servicioId);
    if (!mounted) return;
    setState(() {
      _cargandoCampos = false;
      if (result is Success<List<ConfiguracionCampo>>) {
        _camposPersonalizados = result.data;
      }
    });
  }

  // ─── Cliente selector ───

  Future<void> _openClienteSelector() async {
    final result = await ClienteSelectorBottomSheet.show(
      context: context,
      empresaId: _empresaId,
    );

    if (result != null && mounted) {
      setState(() {
        _clienteId = result.clienteId;
        _clienteNombre = result.nombreCompleto;
        _clienteDni = result.dni ?? '';
        _clienteTelefono = result.telefono ?? '';
        _clienteEmail = result.email;
      });
    }
  }

  void _clearCliente() {
    setState(() {
      _clienteId = null;
      _clienteNombre = '';
      _clienteDni = '';
      _clienteTelefono = '';
      _clienteEmail = null;
    });
  }

  // ─── Step validation ───

  bool _isStepValid(int step) {
    switch (step) {
      case 0:
        return _clienteId != null;
      case 1:
        return _tipoEquipoController.text.trim().isNotEmpty;
      case 2:
        return _tipoServicio.isNotEmpty;
      default:
        return true;
    }
  }

  void _showStepError(int step) {
    final messages = {
      0: 'Selecciona un cliente',
      1: 'Indica el tipo de equipo',
      2: 'Selecciona el tipo de servicio',
    };
    final msg = messages[step];
    if (msg != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg)),
      );
    }
  }

  void _onStepContinue() {
    if (!_isStepValid(_currentStep)) {
      _showStepError(_currentStep);
      return;
    }
    if (_cargandoCampos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando campos, espera un momento...')),
      );
      return;
    }
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _submit();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    } else {
      context.pop();
    }
  }

  void _onStepTapped(int step) {
    if (step <= _currentStep) {
      setState(() => _currentStep = step);
      return;
    }
    for (int i = _currentStep; i < step; i++) {
      if (!_isStepValid(i)) {
        _showStepError(i);
        return;
      }
    }
    setState(() => _currentStep = step);
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Nueva Orden de Servicio',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
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
                    connectorColor: const WidgetStatePropertyAll(AppColors.blue1),
                    onStepContinue: _onStepContinue,
                    onStepCancel: _onStepCancel,
                    onStepTapped: _onStepTapped,
                    controlsBuilder: (context, details) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Row(
                          children: [
                            if (_currentStep < _totalSteps - 1)
                              CustomButton(
                                text: 'Siguiente',
                                onPressed: details.onStepContinue,
                                backgroundColor: AppColors.blue1,
                              ),
                            if (_currentStep == _totalSteps - 1)
                              CustomButton(
                                text: 'Crear Orden',
                                onPressed: details.onStepContinue,
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
                      // ── Step 0: Cliente ──
                      Step(
                        title: AppSubtitle('CLIENTE'),
                        subtitle: _clienteNombre.isNotEmpty
                            ? Text(_clienteNombre)
                            : null,
                        isActive: _currentStep >= 0,
                        state: _clienteId != null
                            ? StepState.complete
                            : StepState.indexed,
                        content: _buildClienteStep(),
                      ),

                      // ── Step 1: Equipo ──
                      Step(
                        title: AppSubtitle('EQUIPO'),
                        subtitle: _tipoEquipoController.text.trim().isNotEmpty
                            ? Text([
                                _tipoEquipoController.text.trim(),
                                if (_marcaEquipoController.text.trim().isNotEmpty)
                                  _marcaEquipoController.text.trim(),
                              ].join(' - '))
                            : null,
                        isActive: _currentStep >= 1,
                        state: _currentStep > 1
                            ? StepState.complete
                            : StepState.indexed,
                        content: _currentStep >= 1
                            ? _buildEquipoStep()
                            : const SizedBox.shrink(),
                      ),

                      // ── Step 2: Servicio ──
                      Step(
                        title: AppSubtitle('SERVICIO'),
                        subtitle: _servicioSeleccionado != null
                            ? Text(_servicioSeleccionado!.nombre)
                            : null,
                        isActive: _currentStep >= 2,
                        state: _currentStep > 2
                            ? StepState.complete
                            : StepState.indexed,
                        content: _currentStep >= 2
                            ? _buildServicioStep()
                            : const SizedBox.shrink(),
                      ),

                      // ── Step 3: Campos personalizados ──
                      Step(
                        title: AppSubtitle('DATOS ADICIONALES'),
                        subtitle: _camposPersonalizados.isEmpty
                            ? const Text('Sin campos configurados')
                            : Text('${_camposPersonalizados.length} campos'),
                        isActive: _currentStep >= 3,
                        state: _currentStep > 3
                            ? StepState.complete
                            : StepState.indexed,
                        content: _currentStep >= 3
                            ? _buildCamposPersonalizadosStep()
                            : const SizedBox.shrink(),
                      ),

                      // ── Step 4: Notas + Aviso ──
                      Step(
                        title: AppSubtitle('NOTAS Y AVISO'),
                        isActive: _currentStep >= 4,
                        content: _currentStep >= 4
                            ? _buildNotasAvisoStep()
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  // ─── Step 0: Cliente ───

  Widget _buildClienteStep() {
    if (_clienteId != null) {
      return Column(
        children: [
          // Cliente vinculado card (same style as cotizacion)
          Container(
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
                        _clienteNombre,
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
                  onPressed: _clearCliente,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Info card
          Container(
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
                _buildInfoRow(Icons.person_outline, 'Cliente', _clienteNombre),
                if (_clienteDni.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.badge_outlined, 'DNI', _clienteDni),
                ],
                if (_clienteTelefono.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.phone_outlined, 'Teléfono', _clienteTelefono),
                ],
                if (_clienteEmail != null && _clienteEmail!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.email_outlined, 'Email', _clienteEmail!),
                ],
              ],
            ),
          ),
        ],
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
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ─── Step 1: Equipo ───

  Widget _buildEquipoStep() {
    return Column(
      children: [
        CustomText(
          controller: _tipoEquipoController,
          label: 'Tipo de equipo *',
          hintText: 'Ej: Laptop, PC, Impresora, Celular',
          borderColor: AppColors.blue1,
          prefixIcon: const Icon(Icons.devices_outlined),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _marcaEquipoController,
          label: 'Marca',
          hintText: 'Ej: HP, Lenovo, Samsung',
          borderColor: AppColors.blue1,
          prefixIcon: const Icon(Icons.branding_watermark_outlined),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _numeroSerieController,
          label: 'Número de serie',
          hintText: 'Ej: SN12345678',
          borderColor: AppColors.blue1,
          prefixIcon: const Icon(Icons.qr_code_outlined),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _condicionEquipoController,
          label: 'Condición del equipo',
          hintText: 'Estado físico al recibir',
          borderColor: AppColors.blue1,
          prefixIcon: const Icon(Icons.info_outline),
          maxLines: null,
          minLines: 2,
        ),
      ],
    );
  }

  // ─── Step 2: Servicio ───

  Widget _buildServicioStep() {
    return Column(
      children: [
        // Servicio del catálogo (opcional)
        if (_cargandoServicios)
          const Padding(
            padding: EdgeInsets.all(8),
            child: CircularProgressIndicator(),
          )
        else if (_serviciosDisponibles.isNotEmpty) ...[
          CustomDropdown<String>(
            label: 'Servicio del catálogo (opcional)',
            value: _servicioSeleccionado?.id,
            borderColor: AppColors.blue1,
            items: [
              const DropdownItem(value: '', label: 'Sin servicio vinculado'),
              ..._serviciosDisponibles.map((s) => DropdownItem(
                    value: s.id,
                    label: '${s.nombre}${s.precio != null ? " - S/ ${s.precio!.toStringAsFixed(2)}" : ""}',
                  )),
            ],
            onChanged: (v) {
              setState(() {
                _servicioSeleccionado = (v != null && v.isNotEmpty)
                    ? _serviciosDisponibles.where((s) => s.id == v).firstOrNull
                    : null;
              });
              if (_servicioSeleccionado != null &&
                  _servicioSeleccionado!.plantillaServicioId != null) {
                _loadCamposPorServicio(_servicioSeleccionado!.id);
              } else {
                setState(() {
                  _camposPersonalizados = [];
                  _datosPersonalizados = {};
                });
              }
            },
          ),
          const SizedBox(height: 12),
        ],

        CustomDropdown<String>(
          label: 'Tipo de servicio *',
          value: _tipoServicio,
          borderColor: AppColors.blue1,
          items: const [
            DropdownItem(value: 'REPARACION', label: 'Reparación'),
            DropdownItem(value: 'MANTENIMIENTO', label: 'Mantenimiento'),
            DropdownItem(value: 'INSTALACION', label: 'Instalación'),
            DropdownItem(value: 'DIAGNOSTICO', label: 'Diagnóstico'),
            DropdownItem(value: 'ACTUALIZACION', label: 'Actualización'),
            DropdownItem(value: 'LIMPIEZA', label: 'Limpieza'),
            DropdownItem(value: 'RECUPERACION_DATOS', label: 'Recuperación de Datos'),
            DropdownItem(value: 'CONFIGURACION', label: 'Configuración'),
            DropdownItem(value: 'CONSULTORIA', label: 'Consultoría'),
            DropdownItem(value: 'FORMACION', label: 'Formación'),
            DropdownItem(value: 'SOPORTE', label: 'Soporte'),
          ],
          onChanged: (v) => setState(() => _tipoServicio = v ?? 'REPARACION'),
        ),
        const SizedBox(height: 12),
        CustomDropdown<String>(
          label: 'Prioridad *',
          value: _prioridad,
          borderColor: AppColors.blue1,
          items: const [
            DropdownItem(value: 'BAJA', label: 'Baja'),
            DropdownItem(value: 'NORMAL', label: 'Normal'),
            DropdownItem(value: 'ALTA', label: 'Alta'),
            DropdownItem(value: 'URGENTE', label: 'Urgente'),
            DropdownItem(value: 'EMERGENCIA', label: 'Emergencia'),
          ],
          onChanged: (v) => setState(() => _prioridad = v ?? 'NORMAL'),
        ),
        const SizedBox(height: 12),
        CustomText(
          controller: _descripcionProblemaController,
          label: 'Descripción del problema',
          hintText: 'Describe el problema o motivo del servicio',
          borderColor: AppColors.blue1,
          prefixIcon: const Icon(Icons.report_problem_outlined),
          enableVoiceInput: true,
          maxLines: null,
          minLines: 3,
        ),
      ],
    );
  }

  // ─── Step 3: Campos personalizados ───

  Widget _buildCamposPersonalizadosStep() {
    if (_cargandoCampos) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_camposPersonalizados.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(Icons.info_outline, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              'Selecciona un servicio con plantilla asignada\npara ver los campos personalizados.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return DynamicFormRenderer(
      campos: _camposPersonalizados,
      values: _datosPersonalizados,
      empresaId: _empresaId,
      onChanged: (newValues) {
        setState(() => _datosPersonalizados = newValues);
      },
    );
  }

  // ─── Step 4: Notas + Aviso ───

  Widget _buildNotasAvisoStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          controller: _notasController,
          label: 'Notas adicionales',
          hintText: 'Observaciones, indicaciones, etc.',
          borderColor: AppColors.blue1,
          prefixIcon: const Icon(Icons.notes_outlined),
          enableVoiceInput: true,
          maxLines: null,
          minLines: 3,
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.notifications_outlined, size: 16, color: AppColors.blue1),
            const SizedBox(width: 8),
            AppSubtitle('AVISO DE MANTENIMIENTO', fontSize: 12),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Al finalizar la orden, se generará un aviso para recordar al cliente su próximo servicio.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
        ),
        CustomSwitchTile(
          title: 'Incluir en avisos de mantenimiento',
          subtitle: 'Se notificará al cliente para su próximo servicio',
          value: _incluirAviso,
          onChanged: (v) => setState(() {
            _incluirAviso = v;
            if (!v) {
              _fechaAvisoPersonalizado = null;
              _fechaAvisoController.clear();
            }
          }),
        ),
        if (_incluirAviso) ...[
          const SizedBox(height: 4),
          CustomDate(
            label: 'Fecha personalizada (opcional)',
            controller: _fechaAvisoController,
            borderColor: AppColors.blue1,
            firstDate: DateTime.now(),
            lastDate: DateTime.now().add(const Duration(days: 730)),
            onChanged: (value) {
              if (value.isNotEmpty) {
                final parts = value.split('/');
                if (parts.length == 3) {
                  final day = int.tryParse(parts[0]) ?? 1;
                  final month = int.tryParse(parts[1]) ?? 1;
                  final year = int.tryParse(parts[2]) ?? 2026;
                  _fechaAvisoPersonalizado = DateTime(year, month, day);
                }
              } else {
                _fechaAvisoPersonalizado = null;
              }
            },
          ),
          const SizedBox(height: 4),
          Text(
            'Si no se indica, se calculará según los intervalos configurados por tipo de servicio.',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }

  // ─── Submit ───

  void _submit() async {
    if (_clienteId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un cliente')),
      );
      setState(() => _currentStep = 0);
      return;
    }

    final repo = locator<OrdenServicioRepository>();
    setState(() => _isLoading = true);

    final datosFinales = Map<String, dynamic>.from(_datosPersonalizados)
      ..removeWhere((_, v) => v == null || (v is String && v.isEmpty));

    final result = await repo.crear(
      empresaId: _empresaId,
      clienteId: _clienteId!,
      tipoServicio: _tipoServicio,
      prioridad: _prioridad,
      tipoEquipo: _tipoEquipoController.text.trim().isEmpty
          ? null
          : _tipoEquipoController.text.trim(),
      marcaEquipo: _marcaEquipoController.text.trim().isEmpty
          ? null
          : _marcaEquipoController.text.trim(),
      numeroSerie: _numeroSerieController.text.trim().isEmpty
          ? null
          : _numeroSerieController.text.trim(),
      condicionEquipo: _condicionEquipoController.text.trim().isEmpty
          ? null
          : _condicionEquipoController.text.trim(),
      descripcionProblema: _descripcionProblemaController.text.trim().isEmpty
          ? null
          : _descripcionProblemaController.text.trim(),
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
      servicioId: _servicioSeleccionado?.id,
      datosPersonalizados: datosFinales.isNotEmpty ? datosFinales : null,
      incluirAvisoMantenimiento: _incluirAviso ? null : false,
      fechaAvisoPersonalizado: _fechaAvisoPersonalizado,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orden de servicio creada')),
      );
      context.pop();
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Error).message)),
      );
    }
  }
}
