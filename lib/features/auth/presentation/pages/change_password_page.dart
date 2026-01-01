import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../bloc/account_security/account_security_cubit.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text.dart';

/// Página de cambio de contraseña obligatorio
/// Se muestra cuando un usuario inicia sesión con contraseña temporal (DNI)
class ChangePasswordPage extends StatelessWidget {
  final Map<String, dynamic>? extra;

  const ChangePasswordPage({super.key, this.extra});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<AccountSecurityCubit>(),
      child: _ChangePasswordView(extra: extra),
    );
  }
}

class _ChangePasswordView extends StatefulWidget {
  final Map<String, dynamic>? extra;

  const _ChangePasswordView({this.extra});

  @override
  State<_ChangePasswordView> createState() => _ChangePasswordViewState();
}

class _ChangePasswordViewState extends State<_ChangePasswordView> {
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final ValueNotifier<bool> _submitSignal = ValueNotifier(false);

  final GradientStyle _gradientStyle = GradientStyle.professional;

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
    return PopScope(
      // Prevent back navigation until password is changed
      canPop: false,
      child: Scaffold(
        body: GradientBackground(
          style: _gradientStyle,
          child: SafeArea(
            child: BlocConsumer<AccountSecurityCubit, AccountSecurityState>(
              listener: (context, state) {
                if (state.submitAttempt) _fireSubmitSignal();

                final response = state.setPasswordResponse;

                if (response is Success) {
                  if (!context.mounted) return;

                  SnackBarHelper.showSuccess(
                    context,
                    'Contraseña actualizada correctamente',
                  );

                  // Redirigir al marketplace después de cambiar la contraseña
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (context.mounted) {
                      context.go('/marketplace');
                    }
                  });
                } else if (response is Error) {
                  if (!context.mounted) return;
                  SnackBarHelper.showError(context, response.message);
                }
              },
              builder: (context, state) {
                final isLoading = state.setPasswordResponse is Loading;

                return Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Card(
                      elevation: 8,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      color: AppColors.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Icon
                            Icon(
                              Icons.security,
                              size: 64,
                              color: AppColors.blue2,
                            ),
                            const SizedBox(height: 24),

                            // Title
                            AppTitle(
                              'Cambio de contraseña requerido',
                              textAlign: TextAlign.center,
                              fontSize: 18,
                              color: AppColors.blue2,
                            ),
                            const SizedBox(height: 12),

                            // Subtitle
                            AppSubtitle(
                              'Por tu seguridad, debes establecer una nueva contraseña antes de continuar.',
                              textAlign: TextAlign.center,
                              fontSize: 12,
                              color: AppColors.blue,
                            ),
                            const SizedBox(height: 8),

                            AppSubtitle(
                              'Tu contraseña temporal basada en tu DNI debe ser reemplazada.',
                              textAlign: TextAlign.center,
                              fontSize: 11,
                              color: Colors.grey.shade600,
                            ),

                            const SizedBox(height: 32),

                            // Password field
                            CustomText(
                              label: 'Nueva contraseña',
                              controller: _passwordController,
                              fieldType: FieldType.password,
                              enabled: !isLoading,
                              hintText: '••••••••',
                              borderColor: AppColors.blue2,
                              borderWidth: 0.6,
                              required: true,
                              autovalidateMode: AutovalidateModeX.afterSubmit,
                              submitSignal: _submitSignal,
                              externalError: state.password.error,
                              showValidationIndicator: false,
                              onChanged: (v) =>
                                  context.read<AccountSecurityCubit>().passwordChanged(v),
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
                              borderColor: AppColors.blue2,
                              borderWidth: 0.6,
                              required: true,
                              autovalidateMode: AutovalidateModeX.afterSubmit,
                              submitSignal: _submitSignal,
                              externalError: state.confirmPassword.error,
                              showValidationIndicator: false,
                              onChanged: (v) => context
                                  .read<AccountSecurityCubit>()
                                  .confirmPasswordChanged(v),
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
                              text: 'Cambiar contraseña',
                              backgroundColor: AppColors.blue2,
                              isLoading: isLoading,
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      FocusManager.instance.primaryFocus?.unfocus();
                                      context.read<AccountSecurityCubit>().setPassword();
                                    },
                            ),

                            const SizedBox(height: 24),

                            // Password requirements info
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        color: Colors.blue.shade700,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 8),
                                      AppSubtitle(
                                        'Requisitos de contraseña:',
                                        fontSize: 11,
                                        color: Colors.blue.shade900,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  _buildRequirement('Mínimo 8 caracteres'),
                                  _buildRequirement('Al menos una letra mayúscula'),
                                  _buildRequirement('Al menos una letra minúscula'),
                                  _buildRequirement('Al menos un número'),
                                ],
                              ),
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
        ),
      ),
    );
  }

  Widget _buildRequirement(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 28, top: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 14, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.blue.shade900,
            ),
          ),
        ],
      ),
    );
  }
}
