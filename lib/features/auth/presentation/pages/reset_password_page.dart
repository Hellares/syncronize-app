import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../bloc/reset_password/reset_password_cubit.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text.dart';

class ResetPasswordPage extends StatelessWidget {
  final String token;
  const ResetPasswordPage({super.key, required this.token});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ResetPasswordCubit>()..setToken(token),
      child: const _ResetPasswordView(),
    );
  }
}

class _ResetPasswordView extends StatefulWidget {
  const _ResetPasswordView();

  @override
  State<_ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<_ResetPasswordView> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final ValueNotifier<bool> _submitSignal = ValueNotifier(false);

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
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
      body: GradientBackground(
        style: GradientStyle.professional,
        child: SafeArea(
          child: BlocConsumer<ResetPasswordCubit, ResetPasswordState>(
            listener: (context, state) {
              if (state.submitAttempt) _fireSubmitSignal();
              final res = state.response;
              if (res is Error) {
                SnackBarHelper.showError(context, res.message);
              }
            },
            builder: (context, state) {
              final isLoading = state.response is Loading;
              final done = state.response is Success;
              final tokenMissing = state.token.isEmpty;
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
                      padding: const EdgeInsets.all(28),
                      child: tokenMissing
                          ? _buildInvalidLinkView(context)
                          : done
                              ? _buildDoneView(context)
                              : _buildFormView(context, state, isLoading),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildInvalidLinkView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.link_off, size: 56, color: Colors.red.shade600),
        const SizedBox(height: 16),
        const Text(
          'Enlace inválido',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Este enlace ya no es válido o ha expirado. Solicita uno nuevo desde '
          'la pantalla "Olvidé mi contraseña".',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Solicitar nuevo enlace',
          backgroundColor: AppColors.blue2,
          onPressed: () => context.go('/forgot-password'),
        ),
      ],
    );
  }

  Widget _buildFormView(
    BuildContext context,
    ResetPasswordState state,
    bool isLoading,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.lock_outline, size: 56, color: AppColors.blue2),
        const SizedBox(height: 16),
        Text(
          'Nueva contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blue2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crea una contraseña segura para acceder a tu cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 24),

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
              context.read<ResetPasswordCubit>().passwordChanged(v),
          onSubmitted: (_) => FocusScope.of(context).nextFocus(),
        ),
        const SizedBox(height: 14),
        CustomText(
          label: 'Confirmar contraseña',
          controller: _confirmController,
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
              .read<ResetPasswordCubit>()
              .confirmPasswordChanged(v),
          onSubmitted: (_) {
            if (!isLoading) {
              FocusManager.instance.primaryFocus?.unfocus();
              context.read<ResetPasswordCubit>().submit();
            }
          },
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Restablecer',
          backgroundColor: AppColors.blue2,
          isLoading: isLoading,
          onPressed: isLoading
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.read<ResetPasswordCubit>().submit();
                },
        ),
        const SizedBox(height: 16),
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
                  Icon(Icons.info_outline,
                      color: Colors.blue.shade700, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Requisitos:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              _bullet('Mínimo 8 caracteres'),
              _bullet('Una mayúscula y una minúscula'),
              _bullet('Un número'),
              _bullet('Un carácter especial (@\$!%*?&)'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(left: 4, top: 2),
        child: Row(
          children: [
            Icon(Icons.check_circle_outline,
                size: 12, color: Colors.blue.shade700),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(fontSize: 11, color: Colors.blue.shade900),
              ),
            ),
          ],
        ),
      );

  Widget _buildDoneView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.verified, size: 64, color: Colors.green.shade600),
        const SizedBox(height: 16),
        const Text(
          'Contraseña restablecida',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Tu contraseña fue actualizada. Por seguridad cerramos todas tus '
          'sesiones activas. Inicia sesión de nuevo con la nueva contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 24),
        CustomButton(
          text: 'Ir al inicio de sesión',
          backgroundColor: AppColors.blue2,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
