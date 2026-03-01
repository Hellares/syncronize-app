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
    // Sincronizar controllers con el estado inicial del cubit
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
    return BlocListener<CompleteProfileCubit, CompleteProfileState>(
      listener: (context, state) {
        if (state.response is Success) {
          final user = (state.response as Success).data;
          // Actualizar AuthBloc con el usuario actualizado
          context.read<AuthBloc>().add(UserLoggedInEvent(user: user));

          SnackBarHelper.showSuccess(
            context,
            'Perfil completado exitosamente',
          );

          // Navegar a crear empresa
          context.go('/create-empresa');
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
          appBar: SmartAppBar(
            title: 'Completar Perfil',
          ),
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
                          Icon(
                            Icons.info_outline,
                            color: AppColors.info,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Para crear una empresa necesitas completar tu perfil con DNI, teléfono y dirección.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppColors.info,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
            
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
                    const SizedBox(height: 32),
            
                    // Botón submit
                    BlocBuilder<CompleteProfileCubit, CompleteProfileState>(
                      buildWhen: (prev, curr) => prev.response != curr.response,
                      builder: (context, state) {
                        final isLoading = state.response is Loading;
                        return SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    context.read<CompleteProfileCubit>().submit();
                                  },
                            child: isLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Guardar y Continuar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          ),
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
}
