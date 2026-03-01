import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../bloc/auth/auth_bloc.dart';
import '../bloc/complete_profile/complete_profile_cubit.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_text.dart' show CustomText, FieldType;

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = locator<CompleteProfileCubit>();
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          cubit.initFromUser(authState.user);
        }
        return cubit;
      },
      child: const _ProfileView(),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final _dniController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final state = context.read<CompleteProfileCubit>().state;
    _dniController.text = state.dni.value;
    _telefonoController.text = state.telefono.value;
    _direccionController.text = state.direccion.value;
  }

  @override
  void dispose() {
    _dniController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    if (authState is! Authenticated) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = authState.user;

    return BlocListener<CompleteProfileCubit, CompleteProfileState>(
      listener: (context, state) {
        if (state.response is Success) {
          final updatedUser = (state.response as Success).data;
          context.read<AuthBloc>().add(UserLoggedInEvent(user: updatedUser));
          SnackBarHelper.showSuccess(context, 'Perfil actualizado exitosamente');
        } else if (state.response is Error) {
          SnackBarHelper.showError(
            context,
            (state.response as Error).message,
          );
        }
      },
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SmartAppBar(title: 'Mi Perfil'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header con avatar e info del usuario
                GradientContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 40,
                          backgroundColor: AppColors.blue2,
                          child: Text(
                            user.iniciales,
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          user.nombreCompleto,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user.identificador,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 12),
                        // Badge de estado del perfil
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: user.perfilCompleto
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: user.perfilCompleto
                                  ? Colors.green.withValues(alpha: 0.3)
                                  : Colors.orange.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                user.perfilCompleto
                                    ? Icons.check_circle
                                    : Icons.warning_amber_rounded,
                                size: 16,
                                color: user.perfilCompleto
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                user.perfilCompleto
                                    ? 'Perfil completo'
                                    : 'Perfil incompleto',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: user.perfilCompleto
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
                ),
                const SizedBox(height: 16),

                // Información de la cuenta (read-only)
                GradientContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Información de la cuenta',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Nombres',
                          value: user.nombres,
                        ),
                        const Divider(height: 24),
                        _InfoRow(
                          icon: Icons.person_outline,
                          label: 'Apellidos',
                          value: user.apellidos,
                        ),
                        if (user.email != null) ...[
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: user.email!,
                            trailing: Icon(
                              user.emailVerificado
                                  ? Icons.verified
                                  : Icons.error_outline,
                              size: 18,
                              color: user.emailVerificado
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          ),
                        ],
                        if (user.metodoPrincipalLogin != null) ...[
                          const Divider(height: 24),
                          _InfoRow(
                            icon: Icons.login,
                            label: 'Método de login',
                            value: user.metodoPrincipalLogin!,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Datos personales (editables)
                GradientContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Datos personales',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Estos datos son necesarios para crear una empresa.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey.shade600,
                              ),
                        ),
                        const SizedBox(height: 20),

                        // Campo DNI
                        BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                          buildWhen: (prev, curr) => prev.dni != curr.dni,
                          builder: (context, state) {
                            return CustomText(
                              controller: _dniController,
                              label: 'DNI',
                              hintText: 'Ingresa tu DNI (8 dígitos)',
                              fieldType: FieldType.number,
                              maxLength: 8,
                              prefixIcon: const Icon(Icons.badge_outlined),
                              externalError: state.dni.error,
                              onChanged: (value) {
                                context.read<CompleteProfileCubit>().dniChanged(value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Teléfono
                        BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                          buildWhen: (prev, curr) => prev.telefono != curr.telefono,
                          builder: (context, state) {
                            return CustomText(
                              controller: _telefonoController,
                              label: 'Teléfono',
                              hintText: 'Ej: 987654321',
                              fieldType: FieldType.number,
                              maxLength: 9,
                              prefixIcon: const Icon(Icons.phone_outlined),
                              externalError: state.telefono.error,
                              onChanged: (value) {
                                context.read<CompleteProfileCubit>().telefonoChanged(value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Campo Dirección
                        BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                          buildWhen: (prev, curr) => prev.direccion != curr.direccion,
                          builder: (context, state) {
                            return CustomText(
                              controller: _direccionController,
                              label: 'Dirección',
                              hintText: 'Ingresa tu dirección',
                              prefixIcon: const Icon(Icons.location_on_outlined),
                              externalError: state.direccion.error,
                              onChanged: (value) {
                                context.read<CompleteProfileCubit>().direccionChanged(value);
                              },
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        // Botón guardar
                        BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                          buildWhen: (prev, curr) => prev.response != curr.response,
                          builder: (context, state) {
                            final isLoading = state.response is Loading;
                            return CustomButton(
                              text: 'Guardar cambios',
                              isLoading: isLoading,
                              icon: const Icon(Icons.save_outlined, color: Colors.white, size: 20),
                              onPressed: isLoading
                                  ? null
                                  : () {
                                      context.read<CompleteProfileCubit>().submit();
                                    },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.blue2),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
