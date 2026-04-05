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
import '../../domain/entities/usuario_filtros.dart';
import '../bloc/usuario_form/usuario_form_cubit.dart';
import '../bloc/usuario_form/usuario_form_state.dart';

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
  }

  void _loadEmpresaId() {
    final localStorage = locator<LocalStorageService>();
    _empresaId = localStorage.getString(StorageConstants.tenantId);
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
      puedeAbrirCaja: _puedeAbrirCaja,
      puedeCerrarCaja: _puedeCerrarCaja,
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
                  _buildDatosPersonalesSection(),
                  const SizedBox(height: 12),
                  _buildContactoSection(),
                  const SizedBox(height: 12),
                  _buildUbicacionSection(),
                  const SizedBox(height: 12),
                  _buildRolSection(),
                  const SizedBox(height: 20),
                  BlocBuilder<UsuarioFormCubit, UsuarioFormState>(
                    builder: (context, state) {
                      final isSubmitting = state is UsuarioFormSubmitting;
                      return CustomButton(
                        text: 'Registrar Usuario',
                        isLoading: isSubmitting,
                        icon: const Icon(Icons.person_add,
                            color: Colors.white, size: 18),
                        onPressed: isSubmitting ? null : _submitForm,
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
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

  Widget _buildDatosPersonalesSection() {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Datos Personales', Icons.person_outline),
            const SizedBox(height: 14),
            CustomText(
              controller: _nombresController,
              label: 'Nombres',
              hintText: 'Juan Carlos',
              prefixIcon: const Icon(Icons.person_outline),
              borderColor: AppColors.blue1,
              enabled: !_dniFieldsFilled,
            ),
            const SizedBox(height: 14),
            CustomText(
              controller: _apellidosController,
              label: 'Apellidos',
              hintText: 'Pérez García',
              prefixIcon: const Icon(Icons.person_outline),
              borderColor: AppColors.blue1,
              enabled: !_dniFieldsFilled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactoSection() {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
          ],
        ),
      ),
    );
  }

  Widget _buildUbicacionSection() {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            const SizedBox(height: 16),
            Text(
              'Permisos de Caja',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            _buildCompactCheckbox(
              'Puede abrir caja',
              _puedeAbrirCaja,
              (value) => setState(() => _puedeAbrirCaja = value ?? false),
            ),
            _buildCompactCheckbox(
              'Puede cerrar caja',
              _puedeCerrarCaja,
              (value) => setState(() => _puedeCerrarCaja = value ?? false),
            ),
          ],
        ),
      ),
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
