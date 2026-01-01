import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../domain/entities/rubro_empresa.dart';
import '../../../catalogo/presentation/bloc/catalogo_preview/catalogo_preview_cubit.dart';
import '../../../catalogo/presentation/widgets/catalogo_preview_widget.dart';
import '../bloc/create_empresa/create_empresa_cubit.dart';
import '../widgets/widgets.dart';

class CreateEmpresaPage extends StatelessWidget {
  const CreateEmpresaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => locator<CreateEmpresaCubit>()),
        BlocProvider(create: (_) => locator<CatalogoPreviewCubit>()),
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
  final _nombreController = TextEditingController();
  final _rucController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _webController = TextEditingController();
  final _subdominioController = TextEditingController();

  RubroEmpresa? _selectedRubro;

  @override
  void dispose() {
    _nombreController.dispose();
    _rucController.dispose();
    _descripcionController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _webController.dispose();
    _subdominioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Mi Empresa'),
      ),
      body: SafeArea(
        child: BlocConsumer<CreateEmpresaCubit, CreateEmpresaState>(
          listener: (context, state) {
            final response = state.response;

            if (response is Success) {
              SnackBarHelper.showSuccess(
                context,
                'Empresa creada exitosamente',
              );
              context.go('/home');
            } else if (response is Error) {
              SnackBarHelper.showError(context, response.message);
            }
          },
          builder: (context, state) {
            final isLoading = state.response is Loading;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Título y descripción
                    Text(
                      'Información de tu Empresa',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completa los datos de tu empresa. El nombre y rubro son obligatorios.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Selector de Rubro (NUEVO - requerido)
                    DropdownButtonFormField<RubroEmpresa>(
                      initialValue: _selectedRubro,
                      decoration: InputDecoration(
                        labelText: 'Rubro de la Empresa *',
                        hintText: 'Selecciona el rubro',
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        errorText: state.rubro.error,
                      ),
                      items: RubroEmpresa.values.map((rubro) {
                        return DropdownMenuItem(
                          value: rubro,
                          child: Row(
                            children: [
                              Text(
                                rubro.emoji,
                                style: const TextStyle(fontSize: 20),
                              ),
                              const SizedBox(width: 12),
                              Text(rubro.displayName),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _selectedRubro = value;
                              });
                              if (value != null) {
                                context
                                    .read<CreateEmpresaCubit>()
                                    .rubroChanged(value.value);
                                // Cargar preview de catálogos
                                context
                                    .read<CatalogoPreviewCubit>()
                                    .loadPreview(value.value);
                              }
                            },
                    ),
                    const SizedBox(height: 16),

                    // Preview de catálogos (NUEVO)
                    BlocBuilder<CatalogoPreviewCubit, CatalogoPreviewState>(
                      builder: (context, previewState) {
                        if (previewState is CatalogoPreviewLoading) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Text(
                                    'Cargando catálogos...',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          );
                        } else if (previewState is CatalogoPreviewLoaded) {
                          return CatalogoPreviewWidget(
                            preview: previewState.preview,
                          );
                        } else if (previewState is CatalogoPreviewError) {
                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            color: Colors.red.shade50,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: Colors.red.shade700),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      previewState.message,
                                      style: TextStyle(color: Colors.red.shade700),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),

                    // Nombre de la empresa (requerido)
                    CustomTextField(
                      controller: _nombreController,
                      label: 'Nombre de la Empresa *',
                      hint: 'Mi Empresa S.A.C.',
                      textCapitalization: TextCapitalization.words,
                      prefixIcon: const Icon(Icons.business),
                      enabled: !isLoading,
                      errorText: state.nombre.error,
                      onChanged: (value) {
                        context.read<CreateEmpresaCubit>().nombreChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // RUC (opcional)
                    CustomTextField(
                      controller: _rucController,
                      label: 'RUC (opcional)',
                      hint: '20123456789',
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.badge_outlined),
                      enabled: !isLoading,
                      errorText: state.ruc.error,
                      onChanged: (value) {
                        context.read<CreateEmpresaCubit>().rucChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Descripción (opcional)
                    CustomTextField(
                      controller: _descripcionController,
                      label: 'Descripción (opcional)',
                      hint: 'Breve descripción de tu empresa',
                      maxLines: 3,
                      textCapitalization: TextCapitalization.sentences,
                      prefixIcon: const Icon(Icons.description_outlined),
                      enabled: !isLoading,
                      errorText: state.descripcion.error,
                      onChanged: (value) {
                        context.read<CreateEmpresaCubit>().descripcionChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono (opcional)
                    CustomTextField(
                      controller: _telefonoController,
                      label: 'Teléfono (opcional)',
                      hint: '+51 999 999 999',
                      keyboardType: TextInputType.phone,
                      prefixIcon: const Icon(Icons.phone_outlined),
                      enabled: !isLoading,
                      errorText: state.telefono.error,
                      onChanged: (value) {
                        context.read<CreateEmpresaCubit>().telefonoChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email (opcional)
                    CustomTextField(
                      controller: _emailController,
                      label: 'Email Empresarial (opcional)',
                      hint: 'contacto@empresa.com',
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.email_outlined),
                      enabled: !isLoading,
                      errorText: state.email.error,
                      onChanged: (value) {
                        context.read<CreateEmpresaCubit>().emailChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Sitio Web (opcional)
                    CustomTextField(
                      controller: _webController,
                      label: 'Sitio Web (opcional)',
                      hint: 'https://www.miempresa.com',
                      keyboardType: TextInputType.url,
                      prefixIcon: const Icon(Icons.language_outlined),
                      enabled: !isLoading,
                      errorText: state.web.error,
                      onChanged: (value) {
                        context.read<CreateEmpresaCubit>().webChanged(value);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Subdominio (opcional)
                    CustomTextField(
                      controller: _subdominioController,
                      label: 'Subdominio (opcional)',
                      hint: 'mi-empresa',
                      prefixIcon: const Icon(Icons.link_outlined),
                      enabled: !isLoading,
                      errorText: state.subdominio.error,
                      onChanged: (value) {
                        context.read<CreateEmpresaCubit>().subdominioChanged(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    // Helper text para subdominio
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
                    const SizedBox(height: 32),

                    // Información adicional
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Obtendrás 30 días de prueba gratis del plan Básico',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Botón de crear empresa
                    CustomButton(
                      text: 'Crear Empresa',
                      isLoading: isLoading,
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          context.read<CreateEmpresaCubit>().createEmpresa();
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Botón de cancelar
                    CustomButton(
                      text: 'Cancelar',
                      isOutlined: true,
                      onPressed: isLoading
                          ? null
                          : () {
                              context.pop();
                            },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
