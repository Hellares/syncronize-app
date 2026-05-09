import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/usecases/consultar_dni_usecase.dart';
import '../bloc/register/register_cubit.dart';
import '../widgets/widgets.dart';

class RegisterPage extends StatelessWidget {
  const RegisterPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<RegisterCubit>(),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatefulWidget {
  const _RegisterView();

  @override
  State<_RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<_RegisterView> {
  final _formKey = GlobalKey<FormState>();
  final _dniController = TextEditingController();
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // DNI lookup state — replica del patrón de usuario_form_page.dart.
  final _consultarDniUseCase = locator<ConsultarDniUseCase>();
  bool _isLookingUpDni = false;
  bool _dniFieldsFilled = false;
  String? _dniError;
  String? _origenDatos;

  @override
  void dispose() {
    _dniController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      _nombresController.text = data.nombres;
      _apellidosController.text = data.apellidos;
      if (data.telefono != null && data.telefono!.isNotEmpty) {
        _telefonoController.text = data.telefono!;
      }
      // Sincronizar con el cubit para que el form use estos valores al
      // submitear y disparar la validación.
      context.read<RegisterCubit>().datosRenieFill(
            nombres: data.nombres,
            apellidos: data.apellidos,
            telefono: data.telefono,
          );
      setState(() {
        _dniFieldsFilled = true;
        _origenDatos = data.origen;
        _isLookingUpDni = false;
      });
      SnackBarHelper.showSuccess(
        context,
        'Datos encontrados: ${data.nombreCompleto}',
      );
    } else if (result is Error<ConsultaDni>) {
      setState(() {
        _dniError = result.message;
        _isLookingUpDni = false;
      });
    }
  }

  void _onDniChanged(String value) {
    context.read<RegisterCubit>().dniChanged(value);
    if (_dniError != null) {
      setState(() => _dniError = null);
    }
    // Reset auto-fill cuando cambia el DNI.
    if (_dniFieldsFilled) {
      setState(() {
        _nombresController.clear();
        _apellidosController.clear();
        _telefonoController.clear();
        _dniFieldsFilled = false;
        _origenDatos = null;
      });
      // También sincroniza limpieza con el cubit.
      context.read<RegisterCubit>().datosRenieFill(
            nombres: '',
            apellidos: '',
            telefono: '',
          );
    }
    // Auto-search cuando llega a 8 dígitos.
    if (value.length == 8 && RegExp(r'^\d{8}$').hasMatch(value)) {
      _lookupDni();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Cuenta'),
      ),
      body: SafeArea(
        child: BlocConsumer<RegisterCubit, RegisterState>(
          listener: (context, state) {
            final response = state.response;

            if (response is Success) {
              // Mostrar mensaje de éxito
              SnackBarHelper.showSuccess(
                context,
                'Cuenta creada exitosamente. Por favor verifica tu email.',
              );

              // Navegar a la pantalla de verificación de email
              // Pasamos el email como parámetro extra
              context.go('/verify-email', extra: response.data.user.email);
            } else if (response is Error) {
              // Mostrar mensaje de error con SnackBarHelper
              SnackBarHelper.showError(context, response.message);
            }
          },
          builder: (context, state) {
            final isLoading = state.response is Loading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Completa tus datos',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ingresa tu DNI para autocompletar; el teléfono es '
                      'opcional. Podrás crear tu empresa después.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // DNI con lookup RENIEC
                    _buildDniLookupField(isLoading),
                    const SizedBox(height: 16),

                    // Nombres
                    CustomTextField(
                      controller: _nombresController,
                      label: 'Nombres',
                      hint: 'Juan',
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(Icons.person_outline),
                      enabled: !isLoading,
                      errorText: state.nombres.error,
                      onChanged: (value) {
                        context.read<RegisterCubit>().nombresChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Apellidos
                    CustomTextField(
                      controller: _apellidosController,
                      label: 'Apellidos',
                      hint: 'Pérez',
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(Icons.person_outline),
                      enabled: !isLoading,
                      errorText: state.apellidos.error,
                      onChanged: (value) {
                        context.read<RegisterCubit>().apellidosChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Correo electrónico',
                      hint: 'correo@ejemplo.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      enabled: !isLoading,
                      errorText: state.email.error,
                      onChanged: (value) {
                        context.read<RegisterCubit>().emailChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono (opcional)
                    CustomTextField(
                      controller: _telefonoController,
                      label: 'Teléfono (opcional)',
                      hint: '+51 999 999 999',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      enabled: !isLoading,
                      errorText: state.telefono.error,
                      onChanged: (value) {
                        context.read<RegisterCubit>().telefonoChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Contraseña
                    PasswordField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      hint: '••••••••',
                      enabled: !isLoading,
                      errorText: state.password.error,
                      onChanged: (value) {
                        context.read<RegisterCubit>().passwordChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirmar contraseña
                    PasswordField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar Contraseña',
                      hint: '••••••••',
                      enabled: !isLoading,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Confirma tu contraseña';
                        }
                        if (value != _passwordController.text) {
                          return 'Las contraseñas no coinciden';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),

                    // Botón de registro
                    CustomButton(
                      text: 'Crear Cuenta',
                      isLoading: isLoading,
                      onPressed: () {
                        // Validar solo el campo de confirmar contraseña localmente
                        if (_formKey.currentState!.validate()) {
                          // Llamar register sin parámetros (usa el estado del cubit)
                          context.read<RegisterCubit>().register();
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ya tengo cuenta
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '¿Ya tienes cuenta? ',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () {
                                  context.pop();
                                },
                          child: const Text('Inicia Sesión'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Campo DNI con auto-lookup RENIEC. Mismo patrón que la sección
  /// "Buscar por DNI" de la página de agregar usuario, pero compactado a
  /// un solo input embebido en el form de registro.
  Widget _buildDniLookupField(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: _dniController,
          enabled: !isLoading && !_isLookingUpDni,
          keyboardType: TextInputType.number,
          maxLength: 8,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          onChanged: _onDniChanged,
          onSubmitted: (_) => _lookupDni(),
          decoration: InputDecoration(
            labelText: 'DNI (opcional, autocompleta)',
            hintText: '12345678',
            prefixIcon: const Icon(Icons.badge_outlined),
            counterText: '',
            errorText: _dniError,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            suffixIcon: _isLookingUpDni
                ? const Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    ),
                  )
                : (_dniController.text.length == 8
                    ? IconButton(
                        icon: Icon(Icons.search, color: AppColors.blue1),
                        onPressed: _lookupDni,
                        tooltip: 'Buscar en RENIEC',
                      )
                    : null),
          ),
        ),
        if (_dniFieldsFilled) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
    );
  }
}
