import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../bloc/forgot_password/forgot_password_cubit.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text.dart';

class ForgotPasswordPage extends StatelessWidget {
  const ForgotPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ForgotPasswordCubit>(),
      child: const _ForgotPasswordView(),
    );
  }
}

class _ForgotPasswordView extends StatefulWidget {
  const _ForgotPasswordView();

  @override
  State<_ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<_ForgotPasswordView> {
  final _emailController = TextEditingController();
  final ValueNotifier<bool> _submitSignal = ValueNotifier(false);

  @override
  void dispose() {
    _emailController.dispose();
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
          child: BlocConsumer<ForgotPasswordCubit, ForgotPasswordState>(
            listener: (context, state) {
              if (state.submitAttempt) _fireSubmitSignal();
              final res = state.response;
              if (res is Error) {
                SnackBarHelper.showError(context, res.message);
              }
            },
            builder: (context, state) {
              final isLoading = state.response is Loading;
              final sent = state.response is Success;
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
                      child: sent
                          ? _buildSentView(context)
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

  Widget _buildFormView(
    BuildContext context,
    ForgotPasswordState state,
    bool isLoading,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Back link
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: isLoading ? null : () => context.pop(),
            icon: const Icon(Icons.arrow_back, size: 16, color: AppColors.blue3),
            label: const Text(
              'Volver al inicio de sesión',
              style: TextStyle(color: AppColors.blue3, fontSize: 12),
            ),
          ),
        ),
        const SizedBox(height: 8),

        Icon(Icons.lock_reset, size: 56, color: AppColors.blue2),
        const SizedBox(height: 16),
        Text(
          'Recuperar contraseña',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.blue2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Ingresa el email de tu cuenta. Te enviaremos un enlace para crear '
          'una nueva contraseña.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 24),

        CustomText(
          label: 'Email',
          controller: _emailController,
          fieldType: FieldType.email,
          enabled: !isLoading,
          hintText: 'tu@email.com',
          borderColor: AppColors.blue2,
          borderWidth: 0.6,
          required: true,
          autovalidateMode: AutovalidateModeX.afterSubmit,
          submitSignal: _submitSignal,
          externalError: state.email.error,
          showValidationIndicator: false,
          onChanged: (v) =>
              context.read<ForgotPasswordCubit>().emailChanged(v),
          onSubmitted: (_) {
            if (!isLoading) {
              FocusManager.instance.primaryFocus?.unfocus();
              context.read<ForgotPasswordCubit>().submit();
            }
          },
        ),
        const SizedBox(height: 20),

        CustomButton(
          text: 'Enviar enlace',
          backgroundColor: AppColors.blue2,
          isLoading: isLoading,
          onPressed: isLoading
              ? null
              : () {
                  FocusManager.instance.primaryFocus?.unfocus();
                  context.read<ForgotPasswordCubit>().submit();
                },
        ),
      ],
    );
  }

  Widget _buildSentView(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Icon(Icons.mark_email_read_outlined,
            size: 64, color: Colors.green.shade600),
        const SizedBox(height: 16),
        const Text(
          'Revisa tu bandeja',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Si el email está registrado, recibirás un enlace para restablecer '
          'tu contraseña. El enlace expira en 1 hora.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.tips_and_updates_outlined,
                  size: 18, color: Colors.amber.shade800),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Si no lo ves en unos minutos, revisa la carpeta de spam.',
                  style: TextStyle(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        CustomButton(
          text: 'Volver al inicio de sesión',
          backgroundColor: AppColors.blue2,
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}
