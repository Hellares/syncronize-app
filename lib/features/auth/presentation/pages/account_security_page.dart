import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/services/session_expired_notifier.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../bloc/account_security/account_security_cubit.dart';
import '../bloc/auth/auth_bloc.dart';
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Seguridad de la cuenta'),
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

          final emailResponse = state.updateEmailResponse;
          if (emailResponse is Success) {
            // El backend revoca TODAS las sesiones tras cambiar el email.
            // Mostramos dialog informativo con los pasos siguientes y al
            // confirmar disparamos al notifier para hacer logout y redirect
            // al login. Microtask para no abrir el dialog en medio del
            // rebuild del BlocConsumer.
            final authState = context.read<AuthBloc>().state;
            final newEmail = authState is Authenticated
                ? authState.user.email ?? ''
                : '';
            Future.microtask(() {
              if (!context.mounted) return;
              _showEmailUpdatedDialog(context, newEmail);
            });
          } else if (emailResponse is Error) {
            SnackBarHelper.showError(context, emailResponse.message);
          }

          final resendResponse = state.resendVerificationResponse;
          if (resendResponse is Success) {
            SnackBarHelper.showSuccess(
              context,
              'Correo de verificación reenviado. Revisa tu bandeja o spam.',
            );
          } else if (resendResponse is Error) {
            SnackBarHelper.showError(context, resendResponse.message);
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
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Subheader (el título principal vive en el SmartAppBar)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Text(
                    'Administra cómo inicias sesión en tu cuenta.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Email de la cuenta (agregar / cambiar)
                _buildEmailCard(context, state),

                const SizedBox(height: 16),

                // Current methods card
                _buildCurrentMethodsCard(context, state),

                const SizedBox(height: 16),

                // Change password card (when user already has password)
                if (state.hasPassword) ...[
                  _buildChangePasswordCard(context),
                  const SizedBox(height: 16),
                ],

                // Add password section (only if user doesn't have password)
                if (state.canAddPassword) ...[
                  GradientContainer(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.lock_outline,
                                size: 20, color: AppColors.blue3),
                            const SizedBox(width: 8),
                            Text(
                              'Agregar contraseña',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: AppColors.blue3,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Suma una opción adicional de inicio de sesión.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(height: 14),

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
                          onChanged: (v) => context
                              .read<AccountSecurityCubit>()
                              .passwordChanged(v),
                          onSubmitted: (_) =>
                              FocusScope.of(context).nextFocus(),
                        ),
                        const SizedBox(height: 12),

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
                              context
                                  .read<AccountSecurityCubit>()
                                  .setPassword();
                            }
                          },
                        ),
                        const SizedBox(height: 16),

                        CustomButton(
                          text: 'Establecer contraseña',
                          backgroundColor: AppColors.blue2,
                          isLoading: isLoading,
                          onPressed: isLoading
                              ? null
                              : () {
                                  FocusManager.instance.primaryFocus
                                      ?.unfocus();
                                  context
                                      .read<AccountSecurityCubit>()
                                      .setPassword();
                                },
                        ),
                        const SizedBox(height: 12),

                        // Password requirements info
                        Container(
                          padding: const EdgeInsets.all(10),
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
                                      color: Colors.blue.shade700, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Requisitos:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blue.shade900,
                                      fontSize: 11.5,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              _buildRequirement('Mínimo 8 caracteres'),
                              _buildRequirement('Una mayúscula y una minúscula'),
                              _buildRequirement('Un número'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    ),
    );
  }

  /// Card del email asociado a la cuenta. Soporta dos casos:
  /// - Cuenta DNI-only (user.email == null): CTA "Agregar email" para
  ///   habilitar luego login con Google.
  /// - Cuenta con email: muestra el email + estado verificado y botón
  ///   "Cambiar email".
  Widget _buildEmailCard(BuildContext context, AccountSecurityState state) {
    final authState = context.watch<AuthBloc>().state;
    final email = authState is Authenticated ? authState.user.email : null;
    final emailVerificado =
        authState is Authenticated ? authState.user.emailVerificado : false;
    final isLoading = state.updateEmailResponse is Loading;

    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.email_outlined, size: 20, color: AppColors.blue3),
              const SizedBox(width: 8),
              Text(
                'Correo electrónico',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (email == null || email.isEmpty) ...[
            Text(
              'Tu cuenta aún no tiene un correo asociado. Agrégalo para '
              'poder iniciar sesión con Google o recuperar la contraseña.',
              style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            CustomButton(
              text: 'Agregar email',
              backgroundColor: AppColors.blue2,
              isLoading: isLoading,
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              onPressed: isLoading
                  ? null
                  : () => _promptUpdateEmail(context, currentEmail: null),
            ),
          ] else ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: emailVerificado
                      ? Colors.green.shade50
                      : Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: emailVerificado
                        ? Colors.green.shade200
                        : Colors.orange.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      emailVerificado
                          ? Icons.verified_outlined
                          : Icons.mark_email_unread_outlined,
                      size: 18,
                      color: emailVerificado
                          ? Colors.green.shade700
                          : Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            email,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: emailVerificado
                                  ? Colors.green.shade900
                                  : Colors.orange.shade900,
                            ),
                          ),
                          Text(
                            emailVerificado
                                ? 'Verificado'
                                : 'Sin verificar — revisa tu bandeja',
                            style: TextStyle(
                              fontSize: 11,
                              color: emailVerificado
                                  ? Colors.green.shade700
                                  : Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              if (!emailVerificado) ...[
                _buildResendVerificationButton(context, state),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () =>
                        _promptUpdateEmail(context, currentEmail: email),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: Text(
                  isLoading ? 'Procesando...' : 'Cambiar email',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ],
        ),
    );
  }

  /// Botón compacto para pedir un reenvío del correo de verificación.
  /// Mostrado solo si el email existe y no está verificado. Respeta el
  /// cooldown de 60s del backend mostrando contador en el label.
  Widget _buildResendVerificationButton(
    BuildContext context,
    AccountSecurityState state,
  ) {
    final isResending = state.resendVerificationResponse is Loading;
    final cooldown = state.resendCooldownSeconds;
    final disabled = isResending || cooldown > 0;
    final label = isResending
        ? 'Enviando...'
        : cooldown > 0
            ? 'Reenviar en ${cooldown}s'
            : 'Reenviar correo de verificación';

    return TextButton.icon(
      onPressed: disabled
          ? null
          : () =>
              context.read<AccountSecurityCubit>().resendVerificationEmail(),
      icon: isResending
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh, size: 16),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(0, 32),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }

  /// Diálogo con input de email (y contraseña actual si la cuenta tiene
  /// password) para Agregar/Cambiar el email.
  /// Delega al cubit que valida formato + llama al backend.
  Future<void> _promptUpdateEmail(
    BuildContext context, {
    String? currentEmail,
  }) async {
    final cubit = context.read<AccountSecurityCubit>();
    final requiresPassword = cubit.state.hasPassword;
    final result = await showDialog<UpdateEmailResult>(
      context: context,
      builder: (_) => _UpdateEmailDialog(
        currentEmail: currentEmail,
        requiresPassword: requiresPassword,
      ),
    );
    if (result != null && result.email.isNotEmpty) {
      await cubit.updateEmail(
        result.email,
        currentPassword: result.currentPassword,
      );
    }
  }

  /// Dialog informativo post-cambio de email exitoso. Explica los dos
  /// pasos que debe seguir el usuario:
  ///   1) Revisar el correo y hacer clic en el link de verificación.
  ///   2) Cerrar sesión y volver a iniciar para usar el nuevo email.
  /// Ofrece botón "Cerrar sesión ahora" como atajo.
  Future<void> _showEmailUpdatedDialog(
    BuildContext context,
    String newEmail,
  ) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
        title: Row(
          children: [
            Icon(Icons.mark_email_read_outlined,
                color: Colors.green.shade700, size: 22),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Email actualizado',
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (newEmail.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.email_outlined,
                        size: 16, color: Colors.green.shade700),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        newEmail,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Text(
              'Por seguridad cerramos tu sesión actual. Sigue estos pasos:',
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 12),
            _buildStepRow(
              number: '1',
              title: 'Revisa tu bandeja de entrada',
              description:
                  'Te enviamos un correo de verificación al nuevo email. Haz clic en el link para confirmar. Revisa también la carpeta de spam.',
              color: Colors.orange,
            ),
            const SizedBox(height: 10),
            _buildStepRow(
              number: '2',
              title: 'Inicia sesión nuevamente',
              description:
                  'Vuelve a entrar con tu nuevo email después de verificarlo.',
              color: Colors.blue,
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
        actions: [
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(dialogCtx);
              locator<SessionExpiredNotifier>().notify(
                'Email actualizado. Inicia sesión nuevamente.',
              );
            },
            icon: const Icon(Icons.login, size: 16),
            label: const Text('Ir a iniciar sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepRow({
    required String number,
    required String title,
    required String description,
    required MaterialColor color,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: color.shade100,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color.shade800,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Card que ofrece cambiar la contraseña actual. Solo se muestra cuando
  /// el usuario ya tiene una contraseña configurada (`hasPassword == true`).
  Widget _buildChangePasswordCard(BuildContext context) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.password_outlined, size: 20, color: AppColors.blue3),
              const SizedBox(width: 8),
              Text(
                'Contraseña',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Cambiar tu contraseña periódicamente ayuda a mantener tu cuenta '
            'segura. Al cambiarla, todas las sesiones se cerrarán.',
            style: TextStyle(fontSize: 11.5, color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/cambiar-password'),
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text(
              'Cambiar contraseña',
              style: TextStyle(fontSize: 12),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.blue2,
              side: BorderSide(color: AppColors.blue2),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMethodsCard(BuildContext context, AccountSecurityState state) {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: AppColors.blue3),
              const SizedBox(width: 8),
              Text(
                'Métodos activos',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Password method
          _buildMethodTile(
            context,
            icon: Icons.lock_outline,
            title: 'Email y contraseña',
            subtitle: state.hasPassword
                ? 'Activo · Inicia sesión con email y contraseña'
                : 'No configurado',
            isActive: state.hasPassword,
          ),
          const SizedBox(height: 8),

          // Google method
          _buildMethodTile(
            context,
            icon: Icons.g_mobiledata,
            title: 'Google Sign-In',
            subtitle: state.hasGoogle
                ? 'Activo · Inicia sesión con tu cuenta de Google'
                : 'No configurado',
            isActive: state.hasGoogle,
          ),
        ],
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

/// Resultado del `_UpdateEmailDialog`. Si la cuenta tiene contraseña, el
/// dialog también solicita confirmarla y la devuelve aquí. Para cuentas
/// sin password, [currentPassword] queda null.
class UpdateEmailResult {
  final String email;
  final String? currentPassword;
  const UpdateEmailResult({required this.email, this.currentPassword});
}

/// Diálogo con form de email autocontenido. Aislado en su propio
/// StatefulWidget para que el `TextEditingController` siga el ciclo de
/// vida del widget (evita "TextEditingController used after dispose"
/// cuando el AlertDialog rebuildea durante su animación de salida).
/// Devuelve un [UpdateEmailResult] vía `Navigator.pop` o `null` si el
/// usuario cancela.
class _UpdateEmailDialog extends StatefulWidget {
  final String? currentEmail;
  final bool requiresPassword;

  const _UpdateEmailDialog({
    this.currentEmail,
    this.requiresPassword = false,
  });

  @override
  State<_UpdateEmailDialog> createState() => _UpdateEmailDialogState();
}

class _UpdateEmailDialogState extends State<_UpdateEmailDialog> {
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _emailController =
        TextEditingController(text: widget.currentEmail ?? '');
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Ingresa un email';
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,}$');
    if (!regex.hasMatch(v)) return 'Email inválido';
    return null;
  }

  String? _validatePassword(String? value) {
    if (!widget.requiresPassword) return null;
    final v = value ?? '';
    if (v.isEmpty) return 'Ingresa tu contraseña actual';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing =
        widget.currentEmail != null && widget.currentEmail!.isNotEmpty;
    return AlertDialog(
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      title: Text(
        isEditing ? 'Cambiar email' : 'Agregar email',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Te enviaremos un correo de verificación a la nueva '
                'dirección. Hasta verificar, no podrás recibir notificaciones '
                'a ese email.',
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Correo electrónico',
                  hintText: 'tucorreo@ejemplo.com',
                  prefixIcon: const Icon(Icons.email_outlined, size: 20),
                  isDense: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: _validateEmail,
              ),
              if (widget.requiresPassword) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 14, color: Colors.amber.shade800),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Por seguridad confirma con tu contraseña actual.',
                          style: TextStyle(
                              fontSize: 10.5,
                              color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: 'Contraseña actual',
                    prefixIcon: const Icon(Icons.lock_outline, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: _validatePassword,
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () =>
              Navigator.pop<UpdateEmailResult>(context, null),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_formKey.currentState?.validate() ?? false) {
              Navigator.pop<UpdateEmailResult>(
                context,
                UpdateEmailResult(
                  email: _emailController.text.trim(),
                  currentPassword: widget.requiresPassword
                      ? _passwordController.text
                      : null,
                ),
              );
            }
          },
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}
