import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart'
    show CustomText, FieldType;
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/usecases/consultar_dni_usecase.dart';
import '../bloc/cliente_form/cliente_form_cubit.dart';
import '../bloc/cliente_form/cliente_form_state.dart';

class ClienteFormPage extends StatefulWidget {
  final String empresaId;

  const ClienteFormPage({
    super.key,
    required this.empresaId,
  });

  @override
  State<ClienteFormPage> createState() => _ClienteFormPageState();
}

class _ClienteFormPageState extends State<ClienteFormPage> {
  final _consultarDniUseCase = locator<ConsultarDniUseCase>();

  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _distritoController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _departamentoController = TextEditingController();

  bool _isLookingUpDni = false;
  bool _dniFieldsFilled = false;
  String? _dniError;
  String? _origenDatos;

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
      SnackBarHelper.showSuccess(
          context, 'Datos encontrados: ${data.nombreCompleto}');
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
    if (telefono.isEmpty || !RegExp(r'^\d{9}$').hasMatch(telefono)) {
      SnackBarHelper.showError(context, 'El teléfono debe tener 9 dígitos');
      return false;
    }
    if (email.isNotEmpty &&
        !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
            .hasMatch(email)) {
      SnackBarHelper.showError(context, 'Email inválido');
      return false;
    }
    return true;
  }

  void _submitForm(BuildContext context) {
    if (!_validateForm()) return;

    context.read<ClienteFormCubit>().registrarCliente(
          empresaId: widget.empresaId,
          dni: _dniController.text.trim(),
          nombres: _nombresController.text.trim(),
          apellidos: _apellidosController.text.trim(),
          telefono: _telefonoController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
          direccion: _direccionController.text.trim().isEmpty
              ? null
              : _direccionController.text.trim(),
          distrito: _distritoController.text.trim().isEmpty
              ? null
              : _distritoController.text.trim(),
          provincia: _provinciaController.text.trim().isEmpty
              ? null
              : _provinciaController.text.trim(),
          departamento: _departamentoController.text.trim().isEmpty
              ? null
              : _departamentoController.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ClienteFormCubit>(),
      child: BlocListener<ClienteFormCubit, ClienteFormState>(
        listener: (context, state) {
          if (state is ClienteFormSuccess) {
            final response = state.response;
            if (response.yaExistia) {
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: const Text('Cliente Existente',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                  content: Text(
                    response.yaEraClienteEmpresa
                        ? 'Este cliente ya está registrado en tu empresa.'
                        : 'Este cliente ya existe en el sistema y ha sido asociado a tu empresa.',
                    style: const TextStyle(fontSize: 13),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        context.pop(true);
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            } else {
              SnackBarHelper.showSuccess(context, response.mensaje);
              context.pop(true);
            }
          } else if (state is ClienteFormError) {
            SnackBarHelper.showError(context, state.message);
          }
        },
        child: GradientBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: SmartAppBar(title: 'Registrar Cliente'),
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
                  const SizedBox(height: 20),
                  BlocBuilder<ClienteFormCubit, ClienteFormState>(
                    builder: (context, state) {
                      final isLoading = state is ClienteFormLoading;
                      return CustomButton(
                        text: 'Registrar Cliente',
                        isLoading: isLoading,
                        icon: const Icon(Icons.person_add,
                            color: Colors.white, size: 18),
                        onPressed:
                            isLoading ? null : () => _submitForm(context),
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
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('Buscar por DNI', Icons.search),
            const SizedBox(height: 6),
            Text(
              'Ingresa el DNI para autocompletar los datos del cliente.',
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
              hintText: 'cliente@example.com',
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
                'Dirección obtenida de RENIEC. Puedes editarla si necesitas.',
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
}
