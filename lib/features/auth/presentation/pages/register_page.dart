import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
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
  final _nombresController = TextEditingController();
  final _apellidosController = TextEditingController();
  final _emailController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
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
                      'El teléfono es opcional. Podrás crear tu empresa después.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 32),

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
}
