import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

class CompleteProfilePage extends StatelessWidget {
  const CompleteProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = locator<CompleteProfileCubit>();
        // Pre-llenar datos existentes del usuario
        final authState = context.read<AuthBloc>().state;
        if (authState is Authenticated) {
          cubit.initFromUser(authState.user);
        }
        return cubit;
      },
      child: const _CompleteProfileView(),
    );
  }
}

class _CompleteProfileView extends StatefulWidget {
  const _CompleteProfileView();

  @override
  State<_CompleteProfileView> createState() => _CompleteProfileViewState();
}

class _CompleteProfileViewState extends State<_CompleteProfileView> {
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
    return MultiBlocListener(
      listeners: [
        // Listener para actualizar perfil
        BlocListener<CompleteProfileCubit, CompleteProfileState>(
          listenWhen: (prev, curr) => prev.response != curr.response,
          listener: (context, state) {
            if (state.response is Success) {
              final user = (state.response as Success).data;
              context.read<AuthBloc>().add(UserLoggedInEvent(user: user));
              SnackBarHelper.showSuccess(context, 'Perfil completado exitosamente');
              context.push('/create-empresa');
            } else if (state.response is Error) {
              SnackBarHelper.showError(context, (state.response as Error).message);
            }
          },
        ),
        // Listener para vinculación de cuentas
        BlocListener<CompleteProfileCubit, CompleteProfileState>(
          listenWhen: (prev, curr) => prev.linkResponse != curr.linkResponse,
          listener: (context, state) {
            if (state.linkResponse is Success) {
              final authResponse = (state.linkResponse as Success).data;
              context.read<AuthBloc>().add(UserLoggedInEvent(user: authResponse.user));
              SnackBarHelper.showSuccess(context, 'Cuentas vinculadas exitosamente');
              context.go('/marketplace');
            } else if (state.linkResponse is Error) {
              SnackBarHelper.showError(context, (state.linkResponse as Error).message);
            }
          },
        ),
      ],
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SmartAppBar(title: 'Completar Perfil'),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: GradientContainer(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner informativo
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.info.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.info, size: 24),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Ingresa tu DNI para cargar tus datos automáticamente desde RENIEC.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.info,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Campo DNI con botón de consulta al costado
                    BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                      buildWhen: (prev, curr) =>
                          prev.dni != curr.dni ||
                          prev.isConsultingDni != curr.isConsultingDni ||
                          prev.dniError != curr.dniError,
                      builder: (context, state) {
                        final dniValido = RegExp(r'^\d{8}$').hasMatch(state.dni.value);
                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: CustomText(
                                controller: _dniController,
                                label: 'DNI',
                                borderColor: AppColors.blue1,
                                hintText: 'Ingresa tu DNI (8 dígitos)',
                                fieldType: FieldType.number,
                                maxLength: 8,
                                prefixIcon: const Icon(Icons.badge_outlined),
                                externalError: state.dni.error ?? state.dniError,
                                onChanged: (value) {
                                  context.read<CompleteProfileCubit>().dniChanged(value);
                                },
                                onSubmitted: (_) {
                                  if (dniValido) {
                                    FocusScope.of(context).unfocus();
                                    context.read<CompleteProfileCubit>().consultarDni();
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: SizedBox(
                                width: 120,
                                child: CustomButton(
                                text: 'Consultar',
                                borderRadius: 8,
                                icon: const Icon(Icons.search, color: Colors.white, size: 18),
                                backgroundColor: AppColors.blue1,
                                // height: 35,
                                isLoading: state.isConsultingDni,
                                onPressed: state.isConsultingDni || !dniValido
                                    ? null
                                    : () {
                                        FocusScope.of(context).unfocus();
                                        context.read<CompleteProfileCubit>().consultarDni();
                                      },
                              ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    // Datos de RENIEC (si se consultó)
                    BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                      buildWhen: (prev, curr) =>
                          prev.dniConsultado != curr.dniConsultado ||
                          prev.nombres != curr.nombres,
                      builder: (context, state) {
                        if (!state.dniConsultado || state.nombres == null) {
                          return const SizedBox.shrink();
                        }
                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: AppColors.greenContainer,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.greenBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.check_circle, color: AppColors.greendark, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Datos obtenidos de RENIEC',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.greendark,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _buildInfoRow('Nombres', state.nombres ?? ''),
                              _buildInfoRow('Apellidos', state.apellidos ?? ''),
                              if (state.departamento != null)
                                _buildInfoRow('Ubicación', '${state.distrito ?? ''}, ${state.provincia ?? ''}, ${state.departamento ?? ''}'),
                            ],
                          ),
                        );
                      },
                    ),

                    // Banner de vinculación (si el DNI pertenece a otra cuenta)
                    BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                      buildWhen: (prev, curr) =>
                          prev.dniPerteneceAOtro != curr.dniPerteneceAOtro ||
                          prev.isLinking != curr.isLinking,
                      builder: (context, state) {
                        if (!state.dniPerteneceAOtro) return const SizedBox.shrink();

                        return Container(
                          padding: const EdgeInsets.all(16),
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.orange.shade300),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.link, color: Colors.orange.shade700, size: 22),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Este DNI ya tiene una cuenta',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Una empresa ya te registró como cliente con este DNI. '
                                'Puedes vincular tu cuenta de Google con esa cuenta para unificar tu perfil.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange.shade900,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: CustomButton(
                                  text: 'Vincular mi cuenta de Google',
                                  icon: Icon(Icons.link, color: Colors.white, size: 18),
                                  backgroundColor: Colors.orange.shade700,
                                  isLoading: state.isLinking,
                                  onPressed: state.isLinking
                                      ? null
                                      : () => context.read<CompleteProfileCubit>().confirmarVinculacion(),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    // Campo Teléfono
                    BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                      buildWhen: (prev, curr) => prev.telefono != curr.telefono,
                      builder: (context, state) {
                        return CustomText(
                          controller: _telefonoController,
                          label: 'Teléfono',
                          borderColor: AppColors.blue1,
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
                      buildWhen: (prev, curr) =>
                          prev.direccion != curr.direccion ||
                          prev.dniConsultado != curr.dniConsultado,
                      builder: (context, state) {
                        // Sincronizar controller si la dirección fue auto-llenada por RENIEC
                        if (state.dniConsultado && _direccionController.text != state.direccion.value) {
                          _direccionController.text = state.direccion.value;
                        }
                        return CustomText(
                          controller: _direccionController,
                          label: 'Dirección',
                          borderColor: AppColors.blue1,
                          hintText: 'Ingresa tu dirección',
                          prefixIcon: const Icon(Icons.location_on_outlined),
                          externalError: state.direccion.error,
                          onChanged: (value) {
                            context.read<CompleteProfileCubit>().direccionChanged(value);
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 32),

                    // Botón submit (oculto cuando debe vincular)
                    BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                      buildWhen: (prev, curr) =>
                          prev.response != curr.response ||
                          prev.dniPerteneceAOtro != curr.dniPerteneceAOtro,
                      builder: (context, state) {
                        if (state.dniPerteneceAOtro) return const SizedBox.shrink();

                        final isLoading = state.response is Loading;
                        return CustomButton(
                          text: 'Guardar y Continuar',
                          backgroundColor: AppColors.blue1,
                          isLoading: isLoading,
                          icon: const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
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
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
