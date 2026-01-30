import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/sede_form/sede_form_cubit.dart';
import '../bloc/sede_form/sede_form_state.dart';
import '../widgets/sede_form_fields.dart';

class SedeFormPage extends StatelessWidget {
  final String? sedeId;

  const SedeFormPage({
    super.key,
    this.sedeId,
  });

  bool get isEditing => sedeId != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<SedeFormCubit>(),
      child: _SedeFormView(
        sedeId: sedeId,
        isEditing: isEditing,
      ),
    );
  }
}

class _SedeFormView extends StatefulWidget {
  final String? sedeId;
  final bool isEditing;

  const _SedeFormView({
    this.sedeId,
    required this.isEditing,
  });

  @override
  State<_SedeFormView> createState() => _SedeFormViewState();
}

class _SedeFormViewState extends State<_SedeFormView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores de texto
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _distritoController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _serieFacturaController = TextEditingController();
  final _serieBoletaController = TextEditingController();
  final _serieNotaCreditoController = TextEditingController();
  final _serieNotaDebitoController = TextEditingController();
  final _serieGuiaRemisionController = TextEditingController();

  TipoSede _selectedTipoSede = TipoSede.operativaCompleta;
  bool _isActive = true;

  String? _currentEmpresaId;
  bool _hasUnsavedChanges = false;
  bool _formSubmittedSuccessfully = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
    _addListenersForUnsavedChanges();
  }

  void _initializeForm() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _currentEmpresaId = empresaState.context.empresa.id;

      if (widget.isEditing && widget.sedeId != null) {
        // Cargar datos de sede existente
        context.read<SedeFormCubit>().initForEdit(
              empresaId: _currentEmpresaId!,
              sedeId: widget.sedeId!,
            );
      } else {
        // Inicializar para crear nueva sede
        context.read<SedeFormCubit>().initForCreate();
        // Valores por defecto para series basados en el tipo
        _initializeDefaultSeries();
      }
    }
  }

  /// Inicializa las series por defecto (deja vacío para que el backend las genere)
  void _initializeDefaultSeries() {
    // No hacer nada - el backend generará las series automáticamente
    // basándose en el código de sede generado
  }

  void _addListenersForUnsavedChanges() {
    _nombreController.addListener(_markAsChanged);
    // El código no tiene listener porque es generado automáticamente y no editable
    _telefonoController.addListener(_markAsChanged);
    _emailController.addListener(_markAsChanged);
    _direccionController.addListener(_markAsChanged);
    _referenciaController.addListener(_markAsChanged);
    _distritoController.addListener(_markAsChanged);
    _provinciaController.addListener(_markAsChanged);
    _departamentoController.addListener(_markAsChanged);
    _serieFacturaController.addListener(_markAsChanged);
    _serieBoletaController.addListener(_markAsChanged);
    _serieNotaCreditoController.addListener(_markAsChanged);
    _serieNotaDebitoController.addListener(_markAsChanged);
    _serieGuiaRemisionController.addListener(_markAsChanged);
  }

  void _markAsChanged() {
    if (!_hasUnsavedChanges && !_formSubmittedSuccessfully) {
      setState(() {
        _hasUnsavedChanges = true;
      });
    }
  }


  /// Maneja el cambio de tipo de sede
  void _handleTipoSedeChanged(TipoSede newTipo) {
    setState(() {
      _selectedTipoSede = newTipo;
      _markAsChanged();
    });
    // El backend generará las series automáticamente según el tipo de sede
  }


  void _loadSedeData(Sede sede) {
    _nombreController.text = sede.nombre;
    _codigoController.text = sede.codigo;
    _telefonoController.text = sede.telefono ?? '';
    _emailController.text = sede.email ?? '';
    _direccionController.text = sede.direccion ?? '';
    _referenciaController.text = sede.referencia ?? '';
    _distritoController.text = sede.distrito ?? '';
    _provinciaController.text = sede.provincia ?? '';
    _departamentoController.text = sede.departamento ?? '';
    _serieFacturaController.text = sede.serieFactura;
    _serieBoletaController.text = sede.serieBoleta;
    _serieNotaCreditoController.text = sede.serieNotaCredito;
    _serieNotaDebitoController.text = sede.serieNotaDebito;
    _serieGuiaRemisionController.text = sede.serieGuiaRemision ?? '';

    setState(() {
      _selectedTipoSede = sede.tipoSede;
      _isActive = sede.isActive;
      _hasUnsavedChanges = false;
    });
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges || _formSubmittedSuccessfully) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Descartar cambios?'),
        content: const Text(
          'Tienes cambios sin guardar. ¿Estás seguro de que quieres salir?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );

    return shouldPop ?? false;
  }

  void _handleSubmit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_currentEmpresaId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se pudo identificar la empresa'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final data = {
      'nombre': _nombreController.text.trim(),
      // El código NO se envía - se genera automáticamente en el backend
      if (_telefonoController.text.trim().isNotEmpty)
        'telefono': _telefonoController.text.trim(),
      if (_emailController.text.trim().isNotEmpty)
        'email': _emailController.text.trim(),
      'tipoSede': _selectedTipoSede.value,
      if (_direccionController.text.trim().isNotEmpty)
        'direccion': _direccionController.text.trim(),
      if (_referenciaController.text.trim().isNotEmpty)
        'referencia': _referenciaController.text.trim(),
      if (_distritoController.text.trim().isNotEmpty)
        'distrito': _distritoController.text.trim(),
      if (_provinciaController.text.trim().isNotEmpty)
        'provincia': _provinciaController.text.trim(),
      if (_departamentoController.text.trim().isNotEmpty)
        'departamento': _departamentoController.text.trim(),
      'pais': 'PERU',
      // Solo incluir series si el usuario las proporcionó (no vacías)
      // Si están vacías, el backend las generará automáticamente
      if (_serieFacturaController.text.trim().isNotEmpty)
        'serieFactura': _serieFacturaController.text.trim().toUpperCase(),
      if (_serieBoletaController.text.trim().isNotEmpty)
        'serieBoleta': _serieBoletaController.text.trim().toUpperCase(),
      if (_serieNotaCreditoController.text.trim().isNotEmpty)
        'serieNotaCredito': _serieNotaCreditoController.text.trim().toUpperCase(),
      if (_serieNotaDebitoController.text.trim().isNotEmpty)
        'serieNotaDebito': _serieNotaDebitoController.text.trim().toUpperCase(),
      if (_serieGuiaRemisionController.text.trim().isNotEmpty)
        'serieGuiaRemision':
            _serieGuiaRemisionController.text.trim().toUpperCase(),
      'isActive': _isActive,
    };

    if (widget.isEditing && widget.sedeId != null) {
      context.read<SedeFormCubit>().updateSede(
            empresaId: _currentEmpresaId!,
            sedeId: widget.sedeId!,
            data: data,
          );
    } else {
      context.read<SedeFormCubit>().createSede(
            empresaId: _currentEmpresaId!,
            data: data,
          );
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _codigoController.dispose();
    _telefonoController.dispose();
    _emailController.dispose();
    _direccionController.dispose();
    _referenciaController.dispose();
    _distritoController.dispose();
    _provinciaController.dispose();
    _departamentoController.dispose();
    _serieFacturaController.dispose();
    _serieBoletaController.dispose();
    _serieNotaCreditoController.dispose();
    _serieNotaDebitoController.dispose();
    _serieGuiaRemisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasUnsavedChanges || _formSubmittedSuccessfully,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop && _hasUnsavedChanges && !_formSubmittedSuccessfully) {
          final shouldPop = await _onWillPop();
          if (shouldPop && context.mounted) {
            context.pop();
          }
        }
      },
      child: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
        builder: (context, empresaState) {
          if (empresaState is! EmpresaContextLoaded) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          return Scaffold(
            appBar: SmartAppBar(
              backgroundColor: AppColors.blue1,
              foregroundColor: AppColors.white,
              title: widget.isEditing ? 'Editar Sede' : 'Nueva Sede',
              actions: [
                Text(empresaState.context.empresa.nombre,maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 10),),
                SizedBox(width: 16,)
              ],
            ),
            body: GradientBackground(
              child: BlocConsumer<SedeFormCubit, SedeFormState>(
                listener: (context, state) {
                  if (state is SedeFormReady && widget.isEditing && state.sede != null) {
                    _loadSedeData(state.sede!);
                  }

                  if (state is SedeFormSuccess) {
                    setState(() {
                      _formSubmittedSuccessfully = true;
                    });

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          state.isEdit
                              ? 'Sede actualizada exitosamente'
                              : 'Sede creada exitosamente',
                        ),
                        backgroundColor: Colors.green,
                      ),
                    );

                    // Volver a la lista de sedes
                    Future.delayed(const Duration(milliseconds: 500), () {
                      if (context.mounted) {
                        context.pop();
                      }
                    });
                  }

                  if (state is SedeFormError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(state.message),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
                builder: (context, state) {
                  if (state is SedeFormLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final isSubmitting = state is SedeFormSubmitting;

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Campos del formulario
                          SedeFormFields(
                            nombreController: _nombreController,
                            codigoController: _codigoController,
                            telefonoController: _telefonoController,
                            emailController: _emailController,
                            direccionController: _direccionController,
                            referenciaController: _referenciaController,
                            distritoController: _distritoController,
                            provinciaController: _provinciaController,
                            departamentoController: _departamentoController,
                            serieFacturaController: _serieFacturaController,
                            serieBoletaController: _serieBoletaController,
                            serieNotaCreditoController:
                                _serieNotaCreditoController,
                            serieNotaDebitoController:
                                _serieNotaDebitoController,
                            serieGuiaRemisionController:
                                _serieGuiaRemisionController,
                            selectedTipoSede: _selectedTipoSede,
                            isActive: _isActive,
                            isEditing: widget.isEditing,
                            onTipoSedeChanged: _handleTipoSedeChanged,
                            onIsActiveChanged: (value) {
                              setState(() {
                                _isActive = value;
                                _markAsChanged();
                              });
                            },
                          ),

                          const SizedBox(height: 24),

                          // Botón de guardar
                          CustomButton(
                            onPressed: isSubmitting ? null : _handleSubmit,
                            backgroundColor: AppColors.blue1,
                            text: isSubmitting
                                ? 'Guardando...'
                                : (widget.isEditing
                                    ? 'Actualizar Sede'
                                    : 'Crear Sede'),
                            isLoading: isSubmitting,
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
