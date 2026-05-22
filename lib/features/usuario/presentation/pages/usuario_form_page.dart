import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_gradients.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/usecases/consultar_dni_usecase.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/presentation/widgets/accesos_rapidos_section.dart'
    show AccesosRapidosCatalogo;
import '../../../../core/utils/granular_permissions_catalog.dart';
import '../../../../core/utils/rol_presets.dart';
import '../../domain/entities/usuario_filtros.dart';
import '../bloc/usuario_form/usuario_form_cubit.dart';
import '../bloc/usuario_form/usuario_form_state.dart';
import '../widgets/asignar_rol_dialog.dart' show SedeOption;

/// Página para registrar un nuevo usuario/empleado
class UsuarioFormPage extends StatefulWidget {
  const UsuarioFormPage({super.key});

  @override
  State<UsuarioFormPage> createState() => _UsuarioFormPageState();
}

class _UsuarioFormPageState extends State<UsuarioFormPage> {
  late final UsuarioFormCubit _cubit;
  final _consultarDniUseCase = locator<ConsultarDniUseCase>();
  String? _empresaId;

  // Controllers
  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _distritoController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _departamentoController = TextEditingController();

  // Form values
  RolUsuario? _selectedRol;
  bool _puedeAbrirCaja = false;
  bool _puedeCerrarCaja = false;
  /// Set de IDs de accesos rápidos del dashboard que el usuario tendrá
  /// OCULTOS. El admin marca "ver" → quita del set; desmarca → agrega.
  /// Default: ninguno oculto (ve todos los del rol).
  final Set<String> _accesosRapidosOcultos = {};
  /// Permisos granulares activos (catálogo extensible).
  final Set<String> _permisosEspeciales = {};

  /// Sedes activas disponibles de la empresa (leídas del EmpresaContext).
  List<SedeOption> _sedesDisponibles = [];
  /// IDs de sedes seleccionadas para asignar al nuevo usuario.
  final List<String> _sedesSeleccionadas = [];

  /// Estado expandido de los bloques colapsables del rol.
  /// Por default ambos arrancan cerrados para reducir scroll inicial;
  /// el admin los abre cuando necesita ajustar permisos finos.
  bool _permisosExpanded = false;
  bool _accesosExpanded = false;

  // DNI lookup state
  bool _isLookingUpDni = false;
  bool _dniFieldsFilled = false;
  String? _dniError;
  String? _origenDatos;

  @override
  void initState() {
    super.initState();
    _cubit = locator<UsuarioFormCubit>();
    _loadEmpresaId();
    // Default: TODOS los accesos rápidos arrancan desmarcados (ocultos).
    // El admin marca explícitamente los que quiere que el usuario vea —
    // política conservadora: por defecto el usuario nuevo no ve ningún
    // acceso rápido en su dashboard hasta que el admin lo habilite.
    _accesosRapidosOcultos.addAll(
      AccesosRapidosCatalogo.items.map((e) => e.$1),
    );
    // _loadSedesDisponibles depende del context (lee EmpresaContextCubit),
    // así que se ejecuta después del primer frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadSedesDisponibles();
    });
  }

  void _loadEmpresaId() {
    final localStorage = locator<LocalStorageService>();
    _empresaId = localStorage.getString(StorageConstants.tenantId);
  }

  /// Carga sedes activas del EmpresaContext. Si la empresa tiene una
  /// sola sede, se auto-selecciona y el selector queda oculto.
  void _loadSedesDisponibles() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final sedes = empresaState.context.sedes
        .where((sede) => sede.isActive)
        .map((sede) => SedeOption(
              id: sede.id,
              nombre: sede.nombre,
              direccion: sede.direccion,
            ))
        .toList();

    setState(() {
      _sedesDisponibles = sedes;
      // Auto-seleccionar si hay una sola sede (no hace falta UI).
      if (sedes.length == 1) {
        _sedesSeleccionadas
          ..clear()
          ..add(sedes.first.id);
      }
    });
  }

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _distritoController.dispose();
    _provinciaController.dispose();
    _departamentoController.dispose();
    super.dispose();
  }

  Future<void> _lookupDni() async {
    final dni = _dniController.text.trim();

    if (dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
      setState(() => _dniError = 'Ingresa un DNI válido de 8 dígitos');
      return;
    }

    setState(() {
      _isLookingUpDni = true;
      _dniError = null;
    });

    final result = await _consultarDniUseCase(dni);

    if (!mounted) return;

    if (result is Success<ConsultaDni>) {
      final data = result.data;
      setState(() {
        _nombresController.text = data.nombres;
        _apellidosController.text = data.apellidos;
        if (data.telefono != null && data.telefono!.isNotEmpty) {
          _telefonoController.text = data.telefono!;
        }
        if (data.email != null && data.email!.isNotEmpty) {
          _emailController.text = data.email!;
        }
        _direccionController.text = data.direccion;
        _distritoController.text = data.distrito;
        _provinciaController.text = data.provincia;
        _departamentoController.text = data.departamento;
        _dniFieldsFilled = true;
        _origenDatos = data.origen;
        _isLookingUpDni = false;
      });
      SnackBarHelper.showSuccess(context, 'Datos encontrados: ${data.nombreCompleto}');
    } else if (result is Error<ConsultaDni>) {
      setState(() {
        _dniError = result.message;
        _isLookingUpDni = false;
      });
    }
  }

  void _onDniChanged(String value) {
    if (_dniError != null) {
      setState(() => _dniError = null);
    }
    // Reset auto-filled fields when DNI changes
    if (_dniFieldsFilled) {
      setState(() {
        _nombresController.clear();
        _apellidosController.clear();
        _telefonoController.clear();
        _emailController.clear();
        _direccionController.clear();
        _distritoController.clear();
        _provinciaController.clear();
        _departamentoController.clear();
        _dniFieldsFilled = false;
        _origenDatos = null;
      });
    }
    // Auto-search when 8 digits are entered
    if (value.length == 8 && RegExp(r'^\d{8}$').hasMatch(value)) {
      _lookupDni();
    }
  }

  bool _validateForm() {
    final dni = _dniController.text.trim();
    final nombres = _nombresController.text.trim();
    final apellidos = _apellidosController.text.trim();
    final telefono = _telefonoController.text.trim();
    final email = _emailController.text.trim();

    if (dni.isEmpty || dni.length != 8 || !RegExp(r'^\d{8}$').hasMatch(dni)) {
      SnackBarHelper.showError(context, 'El DNI debe tener 8 dígitos');
      return false;
    }
    if (nombres.isEmpty) {
      SnackBarHelper.showError(context, 'Los nombres son obligatorios');
      return false;
    }
    if (apellidos.isEmpty) {
      SnackBarHelper.showError(context, 'Los apellidos son obligatorios');
      return false;
    }
    if (telefono.isEmpty || !RegExp(r'^9\d{8}$').hasMatch(telefono)) {
      SnackBarHelper.showError(
          context, 'El teléfono debe tener 9 dígitos y empezar con 9');
      return false;
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email)) {
      SnackBarHelper.showError(context, 'Email inválido');
      return false;
    }
    if (_selectedRol == null) {
      SnackBarHelper.showError(context, 'Debe seleccionar un rol');
      return false;
    }
    // Validar selección de sede solo si hay >1 disponibles. Con 1 sola
    // ya viene auto-seleccionada en _loadSedesDisponibles.
    if (_sedesDisponibles.isNotEmpty && _sedesSeleccionadas.isEmpty) {
      SnackBarHelper.showError(
        context,
        'Debe asignar al menos una sede al usuario',
      );
      return false;
    }
    return true;
  }

  void _submitForm() {
    if (!_validateForm()) return;

    if (_empresaId == null) {
      SnackBarHelper.showError(context, 'No se pudo obtener la empresa');
      return;
    }

    _cubit.registrarUsuario(
      empresaId: _empresaId!,
      dni: _dniController.text.trim(),
      nombres: _nombresController.text.trim(),
      apellidos: _apellidosController.text.trim(),
      telefono: _telefonoController.text.trim(),
      rol: _selectedRol!.value,
      email: _emailController.text.trim().isNotEmpty
          ? _emailController.text.trim()
          : null,
      direccion: _direccionController.text.trim().isNotEmpty
          ? _direccionController.text.trim()
          : null,
      distrito: _distritoController.text.trim().isNotEmpty
          ? _distritoController.text.trim()
          : null,
      provincia: _provinciaController.text.trim().isNotEmpty
          ? _provinciaController.text.trim()
          : null,
      departamento: _departamentoController.text.trim().isNotEmpty
          ? _departamentoController.text.trim()
          : null,
      sedeIds:
          _sedesSeleccionadas.isNotEmpty ? _sedesSeleccionadas : null,
      puedeAbrirCaja: _puedeAbrirCaja,
      puedeCerrarCaja: _puedeCerrarCaja,
      accesosRapidosOcultos: _accesosRapidosOcultos.toList(),
      permisos: _permisosEspeciales.toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<UsuarioFormCubit, UsuarioFormState>(
        listener: (context, state) {
          if (state is UsuarioFormSuccess) {
            _showSuccessDialog(context, state.response.mensaje);
          } else if (state is UsuarioFormError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        child: GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: SmartAppBar(title: 'Nuevo Usuario'),
            body: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                children: [
                  _buildDniLookupSection(),
                  const SizedBox(height: 12),
                  _buildPersonaSection(),
                  const SizedBox(height: 12),
                  _buildSedesSection(),
                  const SizedBox(height: 12),
                  _buildRolSection(),
                  const SizedBox(height: 16),
                ],
              ),
            ),
            // Botón fijo al final: el form puede ser largo (DNI + persona
            // + sedes + rol + permisos + accesos). Tenerlo siempre visible
            // evita que el admin tenga que scrollear hasta el fondo.
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: BlocBuilder<UsuarioFormCubit, UsuarioFormState>(
                  builder: (context, state) {
                    final isSubmitting = state is UsuarioFormSubmitting;
                    return CustomButton(
                      text: 'Registrar Usuario',
                      isLoading: isSubmitting,
                      icon: const Icon(
                        Icons.person_add,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: isSubmitting ? null : _submitForm,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.blue2),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  Widget _buildDniLookupSection() {
    return GradientContainer(
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Buscar por DNI', Icons.search),
            const SizedBox(height: 6),
            Text(
              'Ingresa el DNI para autocompletar los datos del usuario.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 14),
            CustomSearchField(
              controller: _dniController,
              label: 'DNI',
              hintText: '12345678',
              borderColor: AppColors.blue1,
              enabled: !_isLookingUpDni,
              maxLength: 8,
              searchIcon: Icons.badge_outlined,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              debounceDelay: Duration.zero,
              onChanged: _onDniChanged,
              onSubmitted: (_) => _lookupDni(),
              showClearButton: !_isLookingUpDni && _dniController.text.isNotEmpty,
              onClear: () => _onDniChanged(''),
              actionButtons: [
                if (_isLookingUpDni)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: AppColors.blue2,
                      ),
                    ),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.search, size: 20),
                    color: AppColors.blue2,
                    onPressed: _dniController.text.length == 8
                        ? _lookupDni
                        : null,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                    splashRadius: 16,
                  ),
              ],
            ),
            if (_dniError != null) ...[
              const SizedBox(height: 4),
              Text(
                _dniError!,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.red,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            if (_dniFieldsFilled) ...[
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border:
                      Border.all(color: Colors.green.withValues(alpha: 0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle,
                        size: 14, color: Colors.green),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _origenDatos == 'INTERNO'
                            ? 'Persona encontrada en el sistema'
                            : 'Datos autocompletados desde RENIEC',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Card único con los 3 sub-bloques (Datos Personales + Contacto +
  /// Ubicación). Antes vivían en 3 GradientContainer separados; los
  /// unificamos para compactar el form sin perder la organización
  /// visual (cada bloque mantiene su sub-título e ícono propios).
  Widget _buildPersonaSection() {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Datos Personales ───
            _buildSectionTitle('Datos Personales', Icons.person_outline),
            const SizedBox(height: 14),
            CustomText(
              controller: _nombresController,
              label: 'Nombres',
              hintText: 'Juan Carlos',
              prefixIcon: const Icon(Icons.person_outline),
              borderColor: AppColors.blue1,
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _apellidosController,
              label: 'Apellidos',
              hintText: 'Pérez García',
              prefixIcon: const Icon(Icons.person_outline),
              borderColor: AppColors.blue1,
            ),

            const SizedBox(height: 20),

            // ─── Contacto ───
            _buildSectionTitle('Contacto', Icons.contact_mail_outlined),
            const SizedBox(height: 14),
            CustomText(
              controller: _telefonoController,
              label: 'Teléfono',
              hintText: '987654321',
              fieldType: FieldType.number,
              maxLength: 9,
              prefixIcon: const Icon(Icons.phone_outlined),
              borderColor: AppColors.blue1,
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _emailController,
              label: 'Email (opcional)',
              hintText: 'usuario@example.com',
              fieldType: FieldType.email,
              prefixIcon: const Icon(Icons.email_outlined),
              borderColor: AppColors.blue1,
            ),

            const SizedBox(height: 20),

            // ─── Ubicación ───
            _buildSectionTitle('Ubicación', Icons.location_on_outlined),
            if (_dniFieldsFilled) ...[
              const SizedBox(height: 6),
              Text(
                _origenDatos == 'INTERNO'
                    ? 'Dirección obtenida del sistema. Puedes editarla si necesitas.'
                    : 'Dirección obtenida de RENIEC. Puedes editarla si necesitas.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              ),
            ],
            const SizedBox(height: 14),
            CustomText(
              controller: _direccionController,
              label: 'Dirección (opcional)',
              hintText: 'Av. Principal 123',
              prefixIcon: const Icon(Icons.home_outlined),
              borderColor: AppColors.blue1,
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _distritoController,
              label: 'Distrito (opcional)',
              hintText: 'Miraflores',
              prefixIcon: const Icon(Icons.place_outlined),
              borderColor: AppColors.blue1,
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _provinciaController,
              label: 'Provincia (opcional)',
              hintText: 'Lima',
              prefixIcon: const Icon(Icons.location_city_outlined),
              borderColor: AppColors.blue1,
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _departamentoController,
              label: 'Departamento (opcional)',
              hintText: 'Lima',
              prefixIcon: const Icon(Icons.map_outlined),
              borderColor: AppColors.blue1,
            ),
          ],
        ),
      ),
    );
  }

  /// Selector de sedes a asignar al usuario. Se oculta si la empresa
  /// tiene una sola sede (auto-seleccionada en _loadSedesDisponibles).
  /// Los permisos de caja / accesos / permisos especiales solo se
  /// persisten si el usuario tiene al menos una sede asignada — el
  /// backend ignora esos flags cuando sedeIds está vacío.
  Widget _buildSedesSection() {
    // Sin sedes cargadas todavía o solo hay una → no mostrar nada.
    if (_sedesDisponibles.length < 2) return const SizedBox.shrink();

    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Sedes Asignadas', Icons.store_outlined),
            const SizedBox(height: 6),
            Text(
              'Selecciona las sedes donde trabajará. Los permisos de caja '
              'y accesos rápidos aplicarán en cada sede asignada.',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 8),
            ..._sedesDisponibles.map((sede) {
              final isSelected = _sedesSeleccionadas.contains(sede.id);
              return _buildCompactCheckbox(
                sede.direccion != null && sede.direccion!.isNotEmpty
                    ? '${sede.nombre} · ${sede.direccion}'
                    : sede.nombre,
                isSelected,
                (value) {
                  setState(() {
                    if (value == true) {
                      _sedesSeleccionadas.add(sede.id);
                    } else {
                      _sedesSeleccionadas.remove(sede.id);
                    }
                  });
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRolSection() {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Información Laboral', Icons.work_outline),
            const SizedBox(height: 14),
            CustomDropdown<RolUsuario>(
              label: 'Rol',
              hintText: 'Selecciona un rol',
              value: _selectedRol,
              items: RolUsuario.values
                  .map((rol) => DropdownItem(
                        value: rol,
                        label: rol.label,
                      ))
                  .toList(),
              prefixIcon: const Icon(Icons.work_outline, size: 20),
              borderColor: AppColors.blue2,
              onChanged: (value) {
                setState(() => _selectedRol = value);
              },
            ),
            if (_selectedRol != null) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _aplicarPresetDelRol,
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: Text(
                    'Aplicar configuración estándar de ${_selectedRol!.label}',
                    style: const TextStyle(fontSize: 11),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.blue1,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
            // Sección "Permisos de Caja" eliminada: los toggles Abrir/
            // Cerrar caja ahora viven en "Permisos especiales" (catálogo
            // granular, categoría Caja). Los flags legacy
            // `puedeAbrirCaja`/`puedeCerrarCaja` se siguen sincronizando
            // en el payload para compat con backend (hasGranularPermission
            // une ambos sistemas vía OR mientras dure la migración).
            const SizedBox(height: 12),
            _buildPermisosEspeciales(),
            const SizedBox(height: 12),
            _buildAccesosRapidosSeleccion(),
          ],
        ),
      ),
    );
  }

  /// Sección de permisos granulares — espejo de la del dialog editar,
  /// agrupada por categoría.
  /// Header tappable estilizado con chevron animado que pliega/despliega
  /// la sección. Pensado como un mini-ExpansionTile sin las molestias
  /// de padding/Material del default de Flutter — encaja en nuestro
  /// GradientContainer sin romper el estilo.
  Widget _buildCollapsibleHeader({
    required String title,
    required bool expanded,
    required VoidCallback onToggle,
    int? itemsActivos,
  }) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            if (itemsActivos != null && itemsActivos > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$itemsActivos',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ],
            const Spacer(),
            AnimatedRotation(
              turns: expanded ? 0.5 : 0,
              duration: const Duration(milliseconds: 180),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermisosEspeciales() {
    final grupos = groupedGranularPermissions();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCollapsibleHeader(
          title: 'Permisos especiales',
          expanded: _permisosExpanded,
          itemsActivos: _permisosEspeciales.length,
          onToggle: () =>
              setState(() => _permisosExpanded = !_permisosExpanded),
        ),
        if (_permisosExpanded) ...[
          Text(
            'Capacidades adicionales que no dependen del rol (descuentos, '
            'anular ventas, ver costos, etc.).',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          for (final entry in grupos.entries) ...[
            Padding(
              padding: const EdgeInsets.only(top: 6, bottom: 2),
              child: Text(
                entry.key.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue1.withValues(alpha: 0.7),
                  letterSpacing: 0.6,
                ),
              ),
            ),
            ...entry.value.map((perm) {
              final activo = _permisosEspeciales.contains(perm.id);
              return Tooltip(
                message: perm.description,
                child: _buildCompactCheckbox(perm.label, activo, (value) {
                  setState(() {
                    if (value == true) {
                      _permisosEspeciales.add(perm.id);
                    } else {
                      _permisosEspeciales.remove(perm.id);
                    }
                    // Sync con flags legacy: el backend sigue recibiendo
                    // puedeAbrirCaja/puedeCerrarCaja, y hasGranularPermission
                    // los une vía OR. Mantenemos ambos sistemas sincronizados.
                    if (perm.id == GranularPermissionId.cajaAbrir) {
                      _puedeAbrirCaja = value == true;
                    } else if (perm.id == GranularPermissionId.cajaCerrar) {
                      _puedeCerrarCaja = value == true;
                    }
                  });
                }),
              );
            }),
          ],
          // Botón "Quitar todos" al final del contenido expandido.
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => setState(() {
                _permisosEspeciales.clear();
                _puedeAbrirCaja = false;
                _puedeCerrarCaja = false;
              }),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Quitar todos',
                style: TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Aplica el preset del rol seleccionado (puedeAbrir/Cerrar, accesos
  /// ocultos, permisos especiales). Solo visible si el rol tiene preset.
  void _aplicarPresetDelRol() {
    final rol = _selectedRol;
    if (rol == null) return;
    final preset = presetParaRol(rol.value);
    setState(() {
      _puedeAbrirCaja = preset.puedeAbrirCaja;
      _puedeCerrarCaja = preset.puedeCerrarCaja;
      _accesosRapidosOcultos
        ..clear()
        ..addAll(preset.accesosRapidosOcultos);
      _permisosEspeciales
        ..clear()
        ..addAll(preset.permisosEspeciales);
      // Sync: si el preset prende los flags legacy, reflejarlo en el
      // catálogo granular para que el checkbox se vea marcado en UI.
      if (_puedeAbrirCaja) {
        _permisosEspeciales.add(GranularPermissionId.cajaAbrir);
      }
      if (_puedeCerrarCaja) {
        _permisosEspeciales.add(GranularPermissionId.cajaCerrar);
      }
    });
  }

  /// Sección plegable con todos los accesos rápidos. Por default todos
  /// activos (ningún oculto) — el admin desmarca los que NO quiere que
  /// el usuario vea.
  Widget _buildAccesosRapidosSeleccion() {
    final totalAccesos = AccesosRapidosCatalogo.items.length;
    final visiblesCount = totalAccesos - _accesosRapidosOcultos.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCollapsibleHeader(
          title: 'Accesos rápidos visibles',
          expanded: _accesosExpanded,
          itemsActivos: visiblesCount,
          onToggle: () =>
              setState(() => _accesosExpanded = !_accesosExpanded),
        ),
        if (_accesosExpanded) ...[
          Text(
            'Marca los accesos del dashboard que verá el usuario. '
            'Los desmarcados se ocultarán solo a este usuario, sin afectar '
            'su rol ni los permisos del backend.',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 4),
          // Grid de 2 columnas con checkboxes compactos.
          Wrap(
            spacing: 4,
            runSpacing: 0,
            children: AccesosRapidosCatalogo.items.map((entry) {
              final id = entry.$1;
              final label = entry.$2;
              final visible = !_accesosRapidosOcultos.contains(id);
              return SizedBox(
                width: (MediaQuery.of(context).size.width - 56) / 2,
                child: _buildCompactCheckbox(
                  label,
                  visible,
                  (value) {
                    setState(() {
                      if (value == true) {
                        _accesosRapidosOcultos.remove(id);
                      } else {
                        _accesosRapidosOcultos.add(id);
                      }
                    });
                  },
                ),
              );
            }).toList(),
          ),
          // Botones de acción al final del contenido expandido.
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () =>
                    setState(() => _accesosRapidosOcultos.clear()),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Marcar todos',
                  style: TextStyle(fontSize: 11),
                ),
              ),
              TextButton(
                onPressed: () => setState(() {
                  _accesosRapidosOcultos
                    ..clear()
                    ..addAll(AccesosRapidosCatalogo.items.map((e) => e.$1));
                }),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 28),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Desmarcar todos',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildCompactCheckbox(
    String label,
    bool value,
    ValueChanged<bool?> onChanged,
  ) {
    return SizedBox(
      height: 36,
      child: CheckboxListTile(
        title: Text(label, style: const TextStyle(fontSize: 12.5)),
        value: value,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Registro exitoso',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 48),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.pop();
            },
            child: const Text('Aceptar'),
          ),
        ],
      ),
    );
  }
}
