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
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../../../empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../../../empresa/domain/entities/configuracion_empresa.dart';
import '../../../cliente_empresa/data/datasources/cliente_empresa_remote_datasource.dart';
import '../../../../core/widgets/cliente_unificado_selector.dart';
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
  final _formKey = GlobalKey<FormState>();
  late final String _empresaId;
  late final String? _sedeId;

  /// Setter del bottom sheet abierto (si hay uno). Lo guardamos cuando se
  /// abre la sheet para poder rebuild el contenido tras un setState del
  /// parent (ej. seleccionar cliente desde dentro de la sheet).
  StateSetter? _sheetSetState;

  // Step 0: Cliente (via bottom sheet)
  ClienteUnificadoResult? _clienteResult;
  String? _clienteId;
  String? _clienteEmpresaId;
  String? _contactoClienteEmpresaId;
  String _clienteNombre = '';
  String _clienteDocumento = '';
  String _clienteTelefono = '';
  String? _clienteEmail;

  // Step 0: Contacto empresa (solo visible si cliente es empresa)
  final _contactoNombreController = TextEditingController();
  final _contactoTelefonoController = TextEditingController();
  final _contactoCargoController = TextEditingController();
  final _contactoDniController = TextEditingController();
  final _contactoEmailController = TextEditingController();

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

  /// Helper que hace setState del parent y, si hay sheet abierta, también
  /// rebuilda su contenido. Usar en callbacks que se disparan desde dentro
  /// de una sheet (p. ej. al seleccionar un cliente).
  void _emit([VoidCallback? fn]) {
    setState(fn ?? () {});
    _sheetSetState?.call(() {});
  }

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    _empresaId = empresaState is EmpresaContextLoaded
        ? empresaState.context.empresa.id
        : '';
    // Sede de la orden: necesaria para que los adelantos se registren en la
    // caja correcta y para series/correlativos al cobrar.
    _sedeId = empresaState is EmpresaContextLoaded
        ? (empresaState.context.sedePrincipal?.id ??
            (empresaState.context.sedes.isNotEmpty
                ? empresaState.context.sedes.first.id
                : null))
        : null;
    _loadServicios();
  }

  @override
  void dispose() {
    _contactoNombreController.dispose();
    _contactoTelefonoController.dispose();
    _contactoCargoController.dispose();
    _contactoDniController.dispose();
    _contactoEmailController.dispose();
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
    _emit(() {
      _cargandoCampos = true;
      _camposPersonalizados = [];
      _datosPersonalizados = {};
    });
    final repo = locator<PlantillaServicioRepository>();
    final result = await repo.getCamposByServicioId(servicioId);
    if (!mounted) return;
    _emit(() {
      _cargandoCampos = false;
      if (result is Success<List<ConfiguracionCampo>>) {
        _camposPersonalizados = result.data;
      }
    });
  }

  // ─── Cliente selector ───

  Future<void> _openClienteSelector() async {
    final result = await ClienteUnificadoSelector.show(
      context: context,
      empresaId: _empresaId,
    );

    if (result != null && mounted) {
      _emit(() {
        _clienteResult = result;
        if (result.isPersona) {
          _clienteId = result.clienteId;
          _clienteEmpresaId = null;
          _contactoClienteEmpresaId = null;
          _clienteNombre = result.nombreCompleto ?? '';
          _clienteDocumento = result.dni ?? '';
          // Limpiar campos de contacto empresa
          _contactoNombreController.clear();
          _contactoTelefonoController.clear();
          _contactoCargoController.clear();
          _contactoDniController.clear();
          _contactoEmailController.clear();
        } else {
          _clienteId = null;
          _clienteEmpresaId = result.clienteEmpresaId;
          _contactoClienteEmpresaId = result.contactoId;
          _clienteNombre = result.displayName;
          _clienteDocumento = result.ruc ?? '';
          // Pre-llenar contacto si fue seleccionado
          if (result.contactoNombre != null) {
            _contactoNombreController.text = result.contactoNombre!;
            _contactoCargoController.text = result.contactoCargo ?? '';
            // Usar telefono/email del contacto, no de la empresa
            _contactoTelefonoController.text = result.telefono ?? '';
            _contactoEmailController.text = result.email ?? '';
          } else {
            _contactoNombreController.clear();
            _contactoTelefonoController.clear();
            _contactoCargoController.clear();
            _contactoDniController.clear();
            _contactoEmailController.clear();
          }
        }
        _clienteTelefono = result.telefono ?? '';
        _clienteEmail = result.email;
      });
    }
  }

  void _clearCliente() {
    _emit(() {
      _clienteResult = null;
      _clienteId = null;
      _clienteEmpresaId = null;
      _contactoClienteEmpresaId = null;
      _clienteNombre = '';
      _clienteDocumento = '';
      _clienteTelefono = '';
      _clienteEmail = null;
      _contactoNombreController.clear();
      _contactoTelefonoController.clear();
      _contactoCargoController.clear();
      _contactoDniController.clear();
      _contactoEmailController.clear();
    });
  }

  bool get _hasCliente => _clienteId != null || _clienteEmpresaId != null;

  // ─── Validación de secciones ───
  //
  // Cada sección puede estar `complete` (todo lleno + válido), `required`
  // (faltan campos obligatorios) u `optional` (siempre OK). Se usa para
  // pintar el estado de cada card y deshabilitar el botón "Crear Orden"
  // cuando hay required pendientes.

  bool get _isClienteValid {
    if (!_hasCliente) return false;
    if (_clienteEmpresaId != null) {
      if (_contactoNombreController.text.trim().isEmpty) return false;
      if (_contactoTelefonoController.text.trim().isEmpty) return false;
    }
    return true;
  }

  bool get _isEquipoValid => _tipoEquipoController.text.trim().isNotEmpty;

  bool get _isServicioValid => _tipoServicio.isNotEmpty;

  /// Lista de mensajes de error para mostrar al usuario si intenta crear
  /// la orden sin completar todo lo requerido.
  List<String> get _missingMessages {
    final out = <String>[];
    if (!_hasCliente) {
      out.add('Selecciona un cliente');
    } else if (_clienteEmpresaId != null) {
      if (_contactoNombreController.text.trim().isEmpty) {
        out.add('Ingresa el nombre del contacto de la empresa');
      }
      if (_contactoTelefonoController.text.trim().isEmpty) {
        out.add('Ingresa el teléfono del contacto');
      }
    }
    if (!_isEquipoValid) out.add('Indica el tipo de equipo');
    if (!_isServicioValid) out.add('Selecciona el tipo de servicio');
    return out;
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // resizeToAvoidBottomInset queda en true (default) para que el body
      // no se quede tapado por el teclado, pero el botón sticky vive en
      // bottomNavigationBar para que se quede fijo abajo y el teclado pase
      // por delante (no lo empuje hacia arriba sobre el formulario).
      appBar: SmartAppBar(
        title: 'Nueva Orden de Servicio',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: GradientContainer(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                  children: [
                    _buildClienteCard(),
                    const SizedBox(height: 8),
                    _buildEquipoInlineSection(),
                    const SizedBox(height: 8),
                    _buildServicioInlineSection(),
                    const SizedBox(height: 8),
                    _buildDatosCard(),
                    const SizedBox(height: 8),
                    _buildNotasCard(),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: _isLoading ? null : _buildSubmitBar(),
    );
  }

  // ─── Cards (resumen + tap → bottom sheet) ───

  Widget _buildClienteCard() {
    final isEmpresa = _clienteResult?.isEmpresa ?? false;
    String subtitle;
    if (!_hasCliente) {
      subtitle = 'Buscar o registrar cliente';
    } else if (isEmpresa) {
      final missingContact = _clienteEmpresaId != null &&
          (_contactoNombreController.text.trim().isEmpty ||
              _contactoTelefonoController.text.trim().isEmpty);
      subtitle = missingContact
          ? '$_clienteNombre · falta contacto'
          : '$_clienteNombre · ${_contactoNombreController.text.trim()}';
    } else {
      subtitle = _clienteDocumento.isNotEmpty
          ? '$_clienteNombre · $_clienteDocumento'
          : _clienteNombre;
    }
    return _OrdenSeccionCard(
      icon: Icons.person_search,
      title: 'CLIENTE',
      subtitle: subtitle,
      state: _isClienteValid ? _SeccionState.complete : _SeccionState.required,
      // Sin cliente → directo al selector (1 sheet en vez de 2).
      // Con cliente → wrapper sheet con info + form de contacto si es empresa.
      onTap: !_hasCliente
          ? _openClienteSelector
          : () => _openSeccion('Cliente', _buildClienteStep),
    );
  }

  /// Sección de equipo INLINE (sin bottom sheet). Tipo y marca en una
  /// sola fila para aprovechar el ancho. Los inputs hacen `_emit()` en
  /// onChanged para que el badge de estado reaccione al typear.
  Widget _buildEquipoInlineSection() {
    final config = _config;
    final labelTipo = config?.labelTipoEquipo ?? 'Tipo de equipo';
    final labelMarca = config?.labelMarcaEquipo ?? 'Marca';
    final labelSerie = config?.labelNumeroSerie ?? 'Número de serie';
    final labelCondicion =
        config?.labelCondicionEquipo ?? 'Condición del equipo';
    final tituloSeccion = config?.labelSeccionEquipo ?? 'Equipo';

    final borderColor = _isEquipoValid
        ? Colors.green.shade300
        : Colors.orange.shade300;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: icono + título + badge estado
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.bluechip.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.devices, color: AppColors.blue1, size: 14),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  tituloSeccion,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (_isEquipoValid)
                const Icon(Icons.check_circle, color: Colors.green, size: 16)
              else
                Icon(Icons.error_outline,
                    color: Colors.orange.shade700, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          // Tipo + Marca en una fila
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomText(
                  controller: _tipoEquipoController,
                  label: '$labelTipo *',
                  hintText: 'Ej. Laptop',
                  textCase: TextCase.upper,
                  borderColor: AppColors.blue1,
                  prefixIcon: const Icon(Icons.devices_outlined),
                  onChanged: (_) => _emit(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomText(
                  controller: _marcaEquipoController,
                  label: labelMarca,
                  hintText: 'Ej. Dell',
                  textCase: TextCase.upper,
                  borderColor: AppColors.blue1,
                  prefixIcon:
                      const Icon(Icons.branding_watermark_outlined),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: _numeroSerieController,
            label: labelSerie,
            hintText: 'Ingrese $labelSerie',
            textCase: TextCase.upper,
            borderColor: AppColors.blue1,
            prefixIcon: const Icon(Icons.qr_code_outlined),
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: _condicionEquipoController,
            label: labelCondicion,
            hintText: 'Describa el estado al recibir',
            textCase: TextCase.upper,
            borderColor: AppColors.blue1,
            prefixIcon: const Icon(Icons.info_outline),
            maxLines: null,
            minLines: 2,
          ),
        ],
      ),
    );
  }

  /// Sección de servicio INLINE. Tipo de servicio + Prioridad en una sola
  /// fila. Servicio del catálogo arriba (carga la plantilla de campos al
  /// cambiar). Descripción del problema abajo, full-width con voice input.
  Widget _buildServicioInlineSection() {
    final borderColor = _isServicioValid
        ? Colors.green.shade300
        : Colors.orange.shade300;

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.bluechip.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(Icons.handyman, color: AppColors.blue1, size: 14),
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'SERVICIO',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
                ),
              ),
              if (_isServicioValid)
                const Icon(Icons.check_circle, color: Colors.green, size: 16)
              else
                Icon(Icons.error_outline,
                    color: Colors.orange.shade700, size: 16),
            ],
          ),
          const SizedBox(height: 8),
          // Servicio del catálogo (opcional) — carga plantilla
          if (_cargandoServicios)
            const Padding(
              padding: EdgeInsets.all(8),
              child: Center(child: CircularProgressIndicator()),
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
                      label:
                          '${s.nombre}${s.precio != null ? " - S/ ${s.precio!.toStringAsFixed(2)}" : ""}',
                    )),
              ],
              onChanged: (v) {
                _emit(() {
                  _servicioSeleccionado = (v != null && v.isNotEmpty)
                      ? _serviciosDisponibles
                          .where((s) => s.id == v)
                          .firstOrNull
                      : null;
                });
                if (_servicioSeleccionado != null &&
                    _servicioSeleccionado!.plantillaServicioId != null) {
                  _loadCamposPorServicio(_servicioSeleccionado!.id);
                } else {
                  _emit(() {
                    _camposPersonalizados = [];
                    _datosPersonalizados = {};
                  });
                }
              },
            ),
            const SizedBox(height: 8),
          ],
          // Tipo + Prioridad en una sola fila
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CustomDropdown<String>(
                  label: 'Tipo de servicio *',
                  value: _tipoServicio,
                  borderColor: AppColors.blue1,
                  items: const [
                    DropdownItem(value: 'REPARACION', label: 'Reparación'),
                    DropdownItem(
                        value: 'MANTENIMIENTO', label: 'Mantenimiento'),
                    DropdownItem(value: 'INSTALACION', label: 'Instalación'),
                    DropdownItem(value: 'DIAGNOSTICO', label: 'Diagnóstico'),
                    DropdownItem(
                        value: 'ACTUALIZACION', label: 'Actualización'),
                    DropdownItem(value: 'LIMPIEZA', label: 'Limpieza'),
                    DropdownItem(
                        value: 'RECUPERACION_DATOS',
                        label: 'Recuperación de Datos'),
                    DropdownItem(
                        value: 'CONFIGURACION', label: 'Configuración'),
                    DropdownItem(value: 'CONSULTORIA', label: 'Consultoría'),
                    DropdownItem(value: 'FORMACION', label: 'Formación'),
                    DropdownItem(value: 'SOPORTE', label: 'Soporte'),
                  ],
                  onChanged: (v) =>
                      _emit(() => _tipoServicio = v ?? 'REPARACION'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CustomDropdown<String>(
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
                  onChanged: (v) => _emit(() => _prioridad = v ?? 'NORMAL'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CustomText(
            controller: _descripcionProblemaController,
            label: 'Descripción del problema',
            textCase: TextCase.upper,
            hintText: 'Describe el problema o motivo del servicio',
            borderColor: AppColors.blue1,
            prefixIcon: const Icon(Icons.report_problem_outlined),
            enableVoiceInput: true,
            maxLines: null,
            minLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildDatosCard() {
    String subtitle;
    if (_cargandoCampos) {
      subtitle = 'Cargando plantilla…';
    } else if (_camposPersonalizados.isEmpty) {
      subtitle = _servicioSeleccionado == null
          ? 'Sin servicio · sin plantilla'
          : 'Sin campos configurados';
    } else {
      final llenos = _datosPersonalizados.values
          .where((v) => v != null && (v is! String || v.isNotEmpty))
          .length;
      subtitle = '${_camposPersonalizados.length} campos · $llenos llenos';
    }
    final disabled = _camposPersonalizados.isEmpty && !_cargandoCampos;
    return _OrdenSeccionCard(
      icon: Icons.list_alt,
      title: 'Datos adicionales',
      subtitle: subtitle,
      state: _SeccionState.optional,
      onTap: disabled
          ? null
          : () => _openSeccion(
                'Datos adicionales',
                _buildCamposPersonalizadosStep,
              ),
    );
  }

  Widget _buildNotasCard() {
    final notas = _notasController.text.trim();
    final partes = <String>[
      if (notas.isNotEmpty) notas else 'Sin notas',
      if (_incluirAviso) 'Aviso de mantenimiento ON',
    ];
    return _OrdenSeccionCard(
      icon: Icons.note_outlined,
      title: 'Notas y aviso',
      subtitle: partes.join(' · '),
      state: _SeccionState.optional,
      onTap: () => _openSeccion('Notas y aviso', _buildNotasAvisoStep),
    );
  }

  Widget _buildSubmitBar() {
    final missing = _missingMessages;
    final ready = missing.isEmpty;
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        8,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!ready)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                missing.length == 1
                    ? missing.first
                    : 'Faltan ${missing.length} secciones por completar',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          CustomButton(
            text: ready ? 'CREAR ORDEN' : 'Completa los campos requeridos',
            icon: Icon(
              ready ? Icons.check_circle : Icons.block,
              color: Colors.white,
              size: 18,
            ),
            backgroundColor: ready ? AppColors.green : Colors.grey,
            textColor: Colors.white,
            onPressed: ready
                ? _submit
                : () => ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(missing.first)),
                    ),
          ),
        ],
      ),
    );
  }

  /// Abre un bottom sheet con altura fija (0.85 × screen) que muestra el
  /// contenido del builder. Mientras está abierto, guardamos su `setState`
  /// para que `_emit()` también lo rebuilde.
  Future<void> _openSeccion(
    String title,
    Widget Function() builder,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            _sheetSetState = setSheetState;
            final keyboardInset = MediaQuery.viewInsetsOf(ctx).bottom;
            return Container(
              height: MediaQuery.of(ctx).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle bar
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSubtitle(
                            title.toUpperCase(),
                            fontSize: 12,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => Navigator.pop(sheetCtx),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        16, 12, 16, 16 + keyboardInset,
                      ),
                      child: builder(),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    _sheetSetState = null;
    if (mounted) setState(() {});
  }

  // ─── Step 0: Cliente ───

  Widget _buildClienteStep() {
    if (_hasCliente) {
      final isEmpresa = _clienteResult?.isEmpresa ?? false;
      final tipoLabel = isEmpresa ? 'Empresa vinculada' : 'Cliente vinculado';
      final docLabel = isEmpresa ? 'RUC' : 'DNI';
      final docIcon = isEmpresa ? Icons.business : Icons.badge_outlined;
      final clienteIcon = isEmpresa ? Icons.business : Icons.person_outline;

      return Column(
        children: [
          // Cliente vinculado card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
            ),
            child: Row(
              children: [
                Icon(
                  isEmpresa ? Icons.business : Icons.check_circle,
                  size: 18,
                  color: Colors.green,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tipoLabel,
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
          const SizedBox(height: 8),
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
                _buildInfoRow(clienteIcon, isEmpresa ? 'Empresa' : 'Cliente', _clienteNombre),
                if (_clienteDocumento.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(docIcon, docLabel, _clienteDocumento),
                ],
                if (!isEmpresa && _clienteTelefono.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.phone_outlined, 'Teléfono', _clienteTelefono),
                ],
                if (!isEmpresa && _clienteEmail != null && _clienteEmail!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.email_outlined, 'Email', _clienteEmail!),
                ],
              ],
            ),
          ),
          // Sección contacto empresa (solo visible para empresas)
          if (isEmpresa) ...[
            const SizedBox(height: 16),
            _buildContactoEmpresaSection(),
          ],
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

  // ─── Contacto empresa (dentro de Step 0) ───

  Widget _buildContactoEmpresaSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.person_pin, size: 16, color: Colors.orange.shade700),
              const SizedBox(width: 6),
              Text(
                'PERSONA DE CONTACTO',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.orange.shade700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Las notificaciones y comunicaciones se enviarán a esta persona.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 12),
          CustomText(
            controller: _contactoNombreController,
            label: 'Nombre del contacto *',
            hintText: 'Juan Pérez',
            prefixIcon: const Icon(Icons.person_outline),
            borderColor: Colors.orange.shade300,
          ),
          const SizedBox(height: 10),
          CustomText(
            controller: _contactoTelefonoController,
            label: 'Teléfono *',
            hintText: '987654321',
            fieldType: FieldType.number,
            maxLength: 9,
            prefixIcon: const Icon(Icons.phone_outlined),
            borderColor: Colors.orange.shade300,
          ),
          const SizedBox(height: 10),
          CustomText(
            controller: _contactoCargoController,
            label: 'Cargo (opcional)',
            hintText: 'Gerente de TI',
            prefixIcon: const Icon(Icons.work_outline),
            borderColor: Colors.orange.shade300,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CustomText(
                  controller: _contactoDniController,
                  label: 'DNI (opcional)',
                  hintText: '12345678',
                  fieldType: FieldType.number,
                  maxLength: 8,
                  prefixIcon: const Icon(Icons.badge_outlined),
                  borderColor: Colors.orange.shade300,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CustomText(
                  controller: _contactoEmailController,
                  label: 'Email (opcional)',
                  hintText: 'contacto@empresa.com',
                  fieldType: FieldType.email,
                  prefixIcon: const Icon(Icons.email_outlined),
                  borderColor: Colors.orange.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Helper: obtener config de etiquetas ───

  ConfiguracionEmpresa? get _config {
    final state = context.read<ConfiguracionEmpresaCubit>().state;
    return state is ConfiguracionEmpresaLoaded ? state.configuracion : null;
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
        _emit(() => _datosPersonalizados = newValues);
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
          onChanged: (v) => _emit(() {
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
    // El botón "CREAR ORDEN" solo se habilita cuando _puedeCrear es true,
    // así que aquí ya tenemos cliente + equipo + servicio. Aún así dejamos
    // estos guards de defensa por si se llama _submit desde otro path.
    if (!_hasCliente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Debes seleccionar un cliente')),
      );
      return;
    }

    if (_clienteEmpresaId != null &&
        _contactoNombreController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Ingresa el nombre del contacto de la empresa')),
      );
      return;
    }

    final repo = locator<OrdenServicioRepository>();
    setState(() => _isLoading = true);

    // Si es empresa y no hay contacto existente seleccionado, crear uno
    String? contactoId = _contactoClienteEmpresaId;
    if (_clienteEmpresaId != null &&
        contactoId == null &&
        _contactoNombreController.text.trim().isNotEmpty) {
      try {
        final dsContacto = locator<ClienteEmpresaRemoteDataSource>();
        final contactoResult = await dsContacto.agregarContacto(
          _empresaId,
          _clienteEmpresaId!,
          {
            'nombre': _contactoNombreController.text.trim(),
            if (_contactoTelefonoController.text.trim().isNotEmpty)
              'telefono': _contactoTelefonoController.text.trim(),
            if (_contactoCargoController.text.trim().isNotEmpty)
              'cargo': _contactoCargoController.text.trim(),
            if (_contactoDniController.text.trim().isNotEmpty)
              'dni': _contactoDniController.text.trim(),
            if (_contactoEmailController.text.trim().isNotEmpty)
              'email': _contactoEmailController.text.trim(),
            'esPrincipal': false,
          },
        );
        contactoId = contactoResult.id;
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al registrar el contacto. Intenta de nuevo.')),
        );
        return;
      }
    }

    final datosFinales = Map<String, dynamic>.from(_datosPersonalizados)
      ..removeWhere((_, v) => v == null || (v is String && v.isEmpty));

    final result = await repo.crear(
      empresaId: _empresaId,
      sedeId: _sedeId,
      clienteId: _clienteId,
      clienteEmpresaId: _clienteEmpresaId,
      contactoClienteEmpresaId: contactoId,
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

/// Estado visual de una sección del form: completa (verde), pendiente
/// requerida (naranja), u opcional (gris, sin badge).
enum _SeccionState { complete, required, optional }

/// Card de resumen de una sección de la orden. Tap → abre bottom sheet.
class _OrdenSeccionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final _SeccionState state;
  final VoidCallback? onTap;

  const _OrdenSeccionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.state,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final (badge, borderColor) = switch (state) {
      _SeccionState.complete => (
          const Icon(Icons.check_circle, color: Colors.green, size: 16),
          Colors.green.shade300,
        ),
      _SeccionState.required => (
          Icon(Icons.error_outline, color: Colors.orange.shade700, size: 16),
          Colors.orange.shade300,
        ),
      _SeccionState.optional => (
          const SizedBox.shrink(),
          AppColors.blueborder,
        ),
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Opacity(
          opacity: onTap == null ? 0.5 : 1,
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: borderColor, width: 0.8),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: AppColors.bluechip.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, color: AppColors.blue1, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          badge,
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    color: Colors.grey, size: 18),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
