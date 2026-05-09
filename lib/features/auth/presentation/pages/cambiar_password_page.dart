import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/session_expired_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../bloc/change_password/change_password_cubit.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text.dart';

/// Página para cambiar la contraseña del usuario autenticado.
/// Requiere la contraseña actual. Tras éxito, el backend deja la sesión
/// actual viva y revoca todas las demás.
class CambiarPasswordPage extends StatelessWidget {
  const CambiarPasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ChangePasswordCubit>(),
      child: const _CambiarPasswordView(),
    );
  }
}

class _CambiarPasswordView extends StatefulWidget {
  const _CambiarPasswordView();

  @override
  State<_CambiarPasswordView> createState() => _CambiarPasswordViewState();
}

class _CambiarPasswordViewState extends State<_CambiarPasswordView> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  final ValueNotifier<bool> _submitSignal = ValueNotifier(false);

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
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
      appBar: AppBar(
        title: const Text('Cambiar contraseña'),
        elevation: 0,
      ),
      body: BlocConsumer<ChangePasswordCubit, ChangePasswordState>(
        listener: (context, state) {
          if (state.submitAttempt) _fireSubmitSignal();
          final res = state.response;
          if (res is Success) {
            // El backend revoca TODAS las sesiones (incluida la actual).
            // Disparamos al notifier para que AuthBloc haga logout y
            // GoRouter redirija al login mostrando el motivo.
            locator<SessionExpiredNotifier>().notify(
              'Contraseña actualizada. Inicia sesión con la nueva.',
            );
          } else if (res is Error) {
            SnackBarHelper.showError(context, res.message);
          }
        },
        builder: (context, state) {
          final isLoading = state.response is Loading;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 18, color: Colors.amber.shade800),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Por seguridad, al cambiar tu contraseña cerraremos '
                          'sesión en tus otros dispositivos. Mantendremos viva '
                          'esta sesión.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                CustomText(
                  label: 'Contraseña actual',
                  controller: _currentController,
                  fieldType: FieldType.password,
                  enabled: !isLoading,
                  hintText: '••••••••',
                  borderColor: AppColors.blue2,
                  borderWidth: 0.6,
                  required: true,
                  autovalidateMode: AutovalidateModeX.afterSubmit,
                  submitSignal: _submitSignal,
                  externalError: state.currentPassword.error,
                  showValidationIndicator: false,
                  onChanged: (v) => context
                      .read<ChangePasswordCubit>()
                      .currentPasswordChanged(v),
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 14),

                CustomText(
                  label: 'Nueva contraseña',
                  controller: _newController,
                  fieldType: FieldType.password,
                  enabled: !isLoading,
                  hintText: '••••••••',
                  borderColor: AppColors.blue2,
                  borderWidth: 0.6,
                  required: true,
                  autovalidateMode: AutovalidateModeX.afterSubmit,
                  submitSignal: _submitSignal,
                  externalError: state.newPassword.error,
                  showValidationIndicator: false,
                  onChanged: (v) => context
                      .read<ChangePasswordCubit>()
                      .newPasswordChanged(v),
                  onSubmitted: (_) => FocusScope.of(context).nextFocus(),
                ),
                const SizedBox(height: 14),

                CustomText(
                  label: 'Confirmar nueva contraseña',
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
                      .read<ChangePasswordCubit>()
                      .confirmPasswordChanged(v),
                  onSubmitted: (_) {
                    if (!isLoading) {
                      FocusManager.instance.primaryFocus?.unfocus();
                      context.read<ChangePasswordCubit>().submit();
                    }
                  },
                ),
                const SizedBox(height: 20),

                CustomButton(
                  text: 'Cambiar contraseña',
                  backgroundColor: AppColors.blue2,
                  isLoading: isLoading,
                  onPressed: isLoading
                      ? null
                      : () {
                          FocusManager.instance.primaryFocus?.unfocus();
                          context.read<ChangePasswordCubit>().submit();
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
                              size: 18, color: Colors.blue.shade700),
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
            ),
          );
        },
      ),
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
}
