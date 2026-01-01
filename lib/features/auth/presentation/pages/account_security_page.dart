import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../bloc/account_security/account_security_cubit.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text.dart';

class AccountSecurityPage extends StatelessWidget {
  const AccountSecurityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<AccountSecurityCubit>()..init(),
      child: const _AccountSecurityView(),
    );
  }
}

class _AccountSecurityView extends StatefulWidget {
  const _AccountSecurityView();

  @override
  State<_AccountSecurityView> createState() => _AccountSecurityViewState();
}

class _AccountSecurityViewState extends State<_AccountSecurityView> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ValueNotifier<bool> _submitSignal = ValueNotifier(false);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _submitSignal.dispose();
    super.dispose();
  }

  void _fireSubmitSignal() {
    _submitSignal.value = true;
    _submitSignal.value = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguridad de la cuenta'),
        elevation: 0,
      ),
      body: BlocConsumer<AccountSecurityCubit, AccountSecurityState>(
        listener: (context, state) {
          if (state.submitAttempt) _fireSubmitSignal();

          final response = state.setPasswordResponse;

          if (response is Success) {
            SnackBarHelper.showSuccess(
              context,
              'Contraseña establecida correctamente',
            );
            _passwordController.clear();
            _confirmPasswordController.clear();
          } else if (response is Error) {
            SnackBarHelper.showError(context, response.message);
          }
        },
        builder: (context, state) {
          final isLoading = state.setPasswordResponse is Loading;
          final isLoadingMethods = state.isLoadingMethods;

          if (isLoadingMethods) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Text(
                  'Métodos de autenticación',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Administra cómo inicias sesión en tu cuenta',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
                const SizedBox(height: 32),

                // Current methods card
                _buildCurrentMethodsCard(context, state),

                const SizedBox(height: 32),

                // Add password section (only if user doesn't have password)
                if (state.canAddPassword) ...[
                  Text(
                    'Agregar contraseña',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Agrega una contraseña para tener una opción adicional de inicio de sesión',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                  ),
                  const SizedBox(height: 24),

                  // Password field
                  CustomText(
                    label: 'Nueva contraseña',
                    controller: _passwordController,
                    fieldType: FieldType.password,
                    enabled: !isLoading,
                    hintText: '••••••••',
                    borderColor: Colors.blue,
                    borderWidth: 0.6,
                    required: true,
                    autovalidateMode: AutovalidateModeX.afterSubmit,
                    submitSignal: _submitSignal,
                    externalError: state.password.error,
                    showValidationIndicator: false,
                    onChanged: (v) => context.read<AccountSecurityCubit>().passwordChanged(v),
                    onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                  ),
                  const SizedBox(height: 16),

                  // Confirm password field
                  CustomText(
                    label: 'Confirmar contraseña',
                    controller: _confirmPasswordController,
                    fieldType: FieldType.password,
                    enabled: !isLoading,
                    hintText: '••••••••',
                    borderColor: Colors.blue,
                    borderWidth: 0.6,
                    required: true,
                    autovalidateMode: AutovalidateModeX.afterSubmit,
                    submitSignal: _submitSignal,
                    externalError: state.confirmPassword.error,
                    showValidationIndicator: false,
                    onChanged: (v) => context.read<AccountSecurityCubit>().confirmPasswordChanged(v),
                    onSubmitted: (_) {
                      if (!isLoading) {
                        FocusManager.instance.primaryFocus?.unfocus();
                        context.read<AccountSecurityCubit>().setPassword();
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Submit button
                  CustomButton(
                    text: 'Establecer contraseña',
                    isLoading: isLoading,
                    onPressed: isLoading
                        ? null
                        : () {
                            FocusManager.instance.primaryFocus?.unfocus();
                            context.read<AccountSecurityCubit>().setPassword();
                          },
                  ),

                  const SizedBox(height: 16),

                  // Password requirements info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Requisitos de contraseña:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade900,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildRequirement('Mínimo 8 caracteres'),
                        _buildRequirement('Al menos una letra mayúscula'),
                        _buildRequirement('Al menos una letra minúscula'),
                        _buildRequirement('Al menos un número'),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCurrentMethodsCard(BuildContext context, AccountSecurityState state) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Métodos activos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade700,
                  ),
            ),
            const SizedBox(height: 16),

            // Password method
            _buildMethodTile(
              context,
              icon: Icons.lock_outline,
              title: 'Email y contraseña',
              subtitle: state.hasPassword
                  ? 'Activo - Puedes iniciar sesión con tu email y contraseña'
                  : 'No configurado',
              isActive: state.hasPassword,
            ),
            const SizedBox(height: 12),

            // Google method
            _buildMethodTile(
              context,
              icon: Icons.g_mobiledata,
              title: 'Google Sign-In',
              subtitle: state.hasGoogle
                  ? 'Activo - Puedes iniciar sesión con tu cuenta de Google'
                  : 'No configurado',
              isActive: state.hasGoogle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? Colors.green.shade200 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? Colors.green.shade100 : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green.shade900 : Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isActive ? Colors.green.shade700 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            isActive ? Icons.check_circle : Icons.cancel,
            color: isActive ? Colors.green.shade700 : Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 4),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 16, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
