import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/container_large.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../bloc/auth/auth_bloc.dart';
import '../../domain/entities/rubro_empresa.dart';
import '../../../catalogo/presentation/bloc/catalogo_preview/catalogo_preview_cubit.dart';
import '../../../catalogo/presentation/widgets/catalogo_preview_widget.dart';
import '../../../consultas_externas/presentation/bloc/consulta_ruc_cubit.dart';
import '../bloc/create_empresa/create_empresa_cubit.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/floating_button_icon.dart';
import '../widgets/custom_text.dart' show CustomText, FieldType, TextCase;
import '../widgets/widgets.dart';

class CreateEmpresaPage extends StatelessWidget {
  const CreateEmpresaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<CreateEmpresaCubit>()),
        BlocProvider(create: (_) => locator<CatalogoPreviewCubit>()),
        BlocProvider(create: (_) => locator<ConsultaRucCubit>()),
      ],
      child: const _CreateEmpresaView(),
    );
  }
}

class _CreateEmpresaView extends StatefulWidget {
  const _CreateEmpresaView();

  @override
  State<_CreateEmpresaView> createState() => _CreateEmpresaViewState();
}

class _CreateEmpresaViewState extends State<_CreateEmpresaView> {
  final _formKey = GlobalKey<FormState>();
  final _rucController = TextEditingController();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _webController = TextEditingController();
  final _subdominioController = TextEditingController();

  RubroEmpresa? _selectedRubro;

  @override
  void initState() {
    super.initState();
    // Validar perfil completo antes de mostrar el formulario
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authState = context.read<AuthBloc>().state;
      if (authState is Authenticated && !authState.user.perfilCompleto) {
        SnackBarHelper.showInfo(
          context,
          'Debes completar tu perfil antes de crear una empresa',
        );
        context.pushReplacement('/complete-profile');
      }
    });
  }

  @override
  void dispose() {
    _rucController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _webController.dispose();
    _subdominioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: SmartAppBar(
          title: 'Crear Mi Empresa',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: GradientBackground(
        child: SafeArea(
          child: BlocConsumer<CreateEmpresaCubit, CreateEmpresaState>(
            listener: (context, state) {
              final response = state.response;

              if (response is Success) {
                SnackBarHelper.showSuccess(
                  context,
                  'Empresa creada exitosamente',
                );
                context.go('/empresa/select');
              } else if (response is Error) {
                final errorResponse = response;
                if (errorResponse.errorCode == 'PROFILE_INCOMPLETE') {
                  SnackBarHelper.showError(context, 'Debes completar tu perfil primero');
                  context.push('/complete-profile');
                } else {
                  SnackBarHelper.showError(context, errorResponse.message);
                }
              }
            },
            builder: (context, state) {
              final isLoading = state.response is Loading;
              final showForm = state.tieneDatosSunat && state.esHabido;
        
              return Column(
                children: [
                  // ========== CONTENIDO SCROLLABLE ==========
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(12),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Título y descripción
                            AppSubtitle('INFORMACION DE TU EMPRESA', fontSize: 13,),
                            const SizedBox(height: 8),

                            AppSubtitle('Ingresa el RUC de tu empresa para obtener los datos de SUNAT automáticamente.', color: AppColors.blueGrey,),
                            const SizedBox(height: 25),
        
                            // ========== PASO 1: CAMPO RUC ==========
                            _buildRucSection(context, state, isLoading),
                            const SizedBox(height: 5),
        
                            // ========== CARD DATOS SUNAT ==========
                            _buildSunatDataCard(context, state),
        
                            // ========== PASO 2: DATOS ADICIONALES (solo si condición es HABIDO) ==========
                            if (showForm) ...[
                              const SizedBox(height: 20),

                              AppSubtitle('DATOS ADICIONALES'),
                              const SizedBox(height: 12),
        
                              // Selector de Rubro (requerido)
                              CustomDropdown<RubroEmpresa>(
                                label: 'Rubro de la Empresa *',
                                hintText: 'Selecciona el rubro',
                                borderColor: AppColors.blue1,
                                value: _selectedRubro,
                                enabled: !isLoading,
                                items: RubroEmpresa.values.map((rubro) {
                                  return DropdownItem<RubroEmpresa>(
                                    value: rubro,
                                    label: rubro.displayName,
                                    leading: Text(rubro.emoji, style: const TextStyle(fontSize: 16)),
                                  );
                                }).toList(),
                                validator: (_) => state.rubro.error,
                                onChanged: (value) {
                                  setState(() => _selectedRubro = value);
                                  if (value != null) {
                                    context.read<CreateEmpresaCubit>().rubroChanged(value.value);
                                    context.read<CatalogoPreviewCubit>().loadPreview(value.value);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
        
                              // Nombre comercial
                              CustomText(
                                controller: _nombreController,
                                borderColor: AppColors.blue1,
                                label: 'Nombre Comercial *',
                                hintText: 'Nombre con el que se conoce tu empresa',
                                prefixIcon: const Icon(Icons.business),
                                enabled: false,
                                externalError: state.nombre.error,
                                required: true,
                                onChanged: (value) {
                                  context.read<CreateEmpresaCubit>().nombreChanged(value);
                                },
                              ),
                              const SizedBox(height: 12),
        
                              // Descripción
                              CustomText(
                                controller: _descripcionController,
                                borderColor: AppColors.blue1,
                                label: 'Descripción (opcional)',
                                hintText: 'Breve descripción de tu empresa',
                                maxLines: 3,
                                height: null,
                                prefixIcon: const Icon(Icons.description_outlined),
                                enabled: !isLoading,
                                externalError: state.descripcion.error,
                                onChanged: (value) {
                                  context.read<CreateEmpresaCubit>().descripcionChanged(value);
                                },
                              ),
                              const SizedBox(height: 12),
        
                              // Teléfono
                              CustomText(
                                controller: _telefonoController,
                                borderColor: AppColors.blue1,
                                label: 'Teléfono (opcional)',
                                hintText: '+51 999 999 999',
                                keyboardType: TextInputType.phone,
                                prefixIcon: const Icon(Icons.phone_outlined),
                                enabled: !isLoading,
                                externalError: state.telefono.error,
                                onChanged: (value) {
                                  context.read<CreateEmpresaCubit>().telefonoChanged(value);
                                },
                              ),
                              const SizedBox(height: 12),
        
                              // Email
                              CustomText(
                                controller: _emailController,
                                borderColor: AppColors.blue1,
                                label: 'Email Empresarial (opcional)',
                                hintText: 'contacto@empresa.com',
                                keyboardType: TextInputType.emailAddress,
                                prefixIcon: const Icon(Icons.email_outlined),
                                enabled: !isLoading,
                                externalError: state.email.error,
                                onChanged: (value) {
                                  context.read<CreateEmpresaCubit>().emailChanged(value);
                                },
                              ),
                              const SizedBox(height: 12),
        
                              // Sitio Web
                              CustomText(
                                controller: _webController,
                                borderColor: AppColors.blue1,
                                label: 'Sitio Web (opcional)',
                                hintText: 'https://www.miempresa.com',
                                keyboardType: TextInputType.url,
                                prefixIcon: const Icon(Icons.language_outlined),
                                enabled: !isLoading,
                                externalError: state.web.error,
                                onChanged: (value) {
                                  context.read<CreateEmpresaCubit>().webChanged(value);
                                },
                              ),
                              const SizedBox(height: 12),
        
                              // Subdominio
                              CustomText(
                                controller: _subdominioController,
                                borderColor: AppColors.blue1,
                                label: 'Subdominio (opcional)',
                                hintText: 'mi-empresa',
                                textCase: TextCase.lower,
                                prefixIcon: const Icon(Icons.link_outlined),
                                enabled: !isLoading,
                                externalError: state.subdominio.error,
                                onChanged: (value) {
                                  context.read<CreateEmpresaCubit>().subdominioChanged(value);
                                },
                              ),
                              const SizedBox(height: 8),
                              if (_subdominioController.text.isNotEmpty && state.subdominio.error == null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12),
                                  child: Text(
                                    'Tu empresa estará disponible en: ${_subdominioController.text}.syncronize.com',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 24),
        
                              // Info trial

                              ContainerLarge(leftIcon: Icons.info_outline, leftText: 'Obtendrás 30 días de prueba gratis del plan Básico',),
                              const SizedBox(height: 16),
        
                              // Preview de catálogos (al final del formulario)
                              BlocBuilder<CatalogoPreviewCubit, CatalogoPreviewState>(
                                builder: (context, previewState) {
                                  if (previewState is CatalogoPreviewLoading) {
                                    return GradientContainer(
                                      gradient: AppGradients.blueWhiteBlue(),
                                      borderColor: AppColors.blue1,
                                      padding: const EdgeInsets.all(20),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.blue1),
                                          ),
                                          const SizedBox(width: 12),
                                          AppSubtitle('Cargando catálogos...', color: AppColors.blueGrey),
                                        ],
                                      ),
                                    );
                                  } else if (previewState is CatalogoPreviewLoaded) {
                                    return CatalogoPreviewWidget(preview: previewState.preview);
                                  } else if (previewState is CatalogoPreviewError) {
                                    return GradientContainer(
                                      gradient: AppGradients.gray(),
                                      borderColor: Colors.red.shade300,
                                      padding: const EdgeInsets.all(14),
                                      margin: const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        children: [
                                          Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              previewState.message,
                                              style: TextStyle(color: Colors.red.shade700, fontSize: 11),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
        
                  // ========== BOTONES FIJOS EN LA PARTE INFERIOR ==========
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          offset: const Offset(0, -2),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (showForm) ...[
                          CustomButton(
                            text: 'Crear Empresa',
                            isLoading: isLoading,
                            onPressed: () {
                              if (_formKey.currentState!.validate()) {
                                context.read<CreateEmpresaCubit>().createEmpresa();
                              }
                            },
                          ),
                          const SizedBox(height: 10),
                        ],
                        CustomButton(
                          text: 'Cancelar',
                          isOutlined: true,
                          onPressed: isLoading ? null : () => context.pop(),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
      ),
    );
  }

  /// Sección del campo RUC con botón de búsqueda
  Widget _buildRucSection(BuildContext context, CreateEmpresaState state, bool isLoading) {
    return BlocConsumer<ConsultaRucCubit, ConsultaRucState>(
      listener: (context, rucState) {
        if (rucState.isSuccess && rucState.data != null) {
          context.read<CreateEmpresaCubit>().setDatosSunat(rucState.data!);
          _nombreController.text = rucState.data!.razonSocial;
        } else if (rucState.isCondicionInvalida && rucState.data != null) {
          context.read<CreateEmpresaCubit>().setDatosSunat(rucState.data!);
        } else if (rucState.isError) {
          SnackBarHelper.showError(context, rucState.errorMessage ?? 'Error al consultar RUC');
        }
      },
      builder: (context, rucState) {
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CustomText(
                controller: _rucController,
                borderColor: AppColors.blue1,
                label: 'RUC *',
                hintText: '20123456789',
                keyboardType: TextInputType.number,
                fieldType: FieldType.number,
                maxLength: 11,
                prefixIcon: const Icon(Icons.badge_outlined),
                enabled: !isLoading && !rucState.isLoading,
                externalError: state.ruc.error,
                required: true,
                onChanged: (value) {
                  context.read<CreateEmpresaCubit>().rucChanged(value);
                  _nombreController.clear();
                  if (value.length == 11 && RegExp(r'^\d{11}$').hasMatch(value)) {
                    context.read<ConsultaRucCubit>().consultarRuc(value);
                  }
                },
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: rucState.isLoading
                  ? const SizedBox(
                      width: 35,
                      height: 35,
                      child: Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 1, color: AppColors.blue1),
                        ),
                      ),
                    )
                  : FloatingButtonIcon(
                    size: 35,
                      icon: Icons.search,
                      onPressed: (isLoading || _rucController.text.length != 11)
                          ? () {}
                          : () {
                              context.read<ConsultaRucCubit>().consultarRuc(_rucController.text);
                            },
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Card con datos de SUNAT
  Widget _buildSunatDataCard(BuildContext context, CreateEmpresaState state) {
    if (!state.tieneDatosSunat) return const SizedBox.shrink();

    final esHabido = state.esHabido;

    return GradientContainer(
      gradient: esHabido ? AppGradients.green() : AppGradients.gray(),
      borderColor: esHabido ? AppColors.greenBorder : Colors.red.shade300,
      borderWidth: 0.6,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                esHabido ? Icons.check_circle : Icons.error,
                color: esHabido ? AppColors.green : Colors.red.shade700,
                size: 18,
              ),
              const SizedBox(width: 8),
              AppSubtitle('DATOS SUNAT'),
            ],
          ),
          const Divider(height: 18),

          _buildSunatRow('Razón Social', state.razonSocial ?? ''),
          _buildSunatRow('RUC', state.ruc.value),
          _buildSunatRow('Tipo', state.tipoContribuyente ?? ''),
          _buildSunatRow('Estado', state.estadoContribuyente ?? ''),
          _buildSunatRow('Condición', state.condicionContribuyente ?? '',
              highlight: true, isValid: esHabido),
          _buildSunatRow('Dirección', state.direccionFiscal ?? ''),
          _buildSunatRow(
            'Ubigeo',
            [state.departamento, state.provincia, state.distrito]
                .where((e) => e != null && e.isNotEmpty)
                .join(' - '),
          ),

          if (!esHabido) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'No se puede registrar esta empresa. Solo se permiten empresas con condición HABIDO.',
                      style: TextStyle(
                        color: Colors.red.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSunatRow(String label, String value, {bool highlight = false, bool isValid = true}) {
    if (value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
          Expanded(

            child: AppSubtitle(value, color: highlight ? (isValid ? AppColors.green : AppColors.red) : AppColors.blue1 ,),
          ),
        ],
      ),
    );
  }
}
