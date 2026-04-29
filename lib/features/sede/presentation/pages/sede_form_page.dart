import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
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
  Sede? _sedeActual;

  // Controladores de texto
  final _codigoController = TextEditingController();
  final _nombreController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _emailController = TextEditingController();
  final _direccionController = TextEditingController();
  final _referenciaController = TextEditingController();
  final _standController = TextEditingController();
  final _distritoController = TextEditingController();
  final _provinciaController = TextEditingController();
  final _departamentoController = TextEditingController();
  final _serieFacturaController = TextEditingController();
  final _serieBoletaController = TextEditingController();
  final _serieNotaCreditoController = TextEditingController();
  final _serieNotaCreditoBoletaController = TextEditingController();
  final _serieNotaDebitoController = TextEditingController();
  final _serieNotaDebitoBoletaController = TextEditingController();
  final _serieGuiaRemisionController = TextEditingController();
  // Facturación electrónica por sede
  final _rucSedeController = TextEditingController();
  final _razonSocialSedeController = TextEditingController();
  final _direccionFiscalSedeController = TextEditingController();
  final _proveedorRutaController = TextEditingController();
  final _proveedorTokenController = TextEditingController();
  final _resolucionSunatController = TextEditingController();

  TipoSede _selectedTipoSede = TipoSede.operativaCompleta;
  bool _isActive = true;
  Map<String, dynamic> _horarioAtencion = {};
  Map<String, dynamic>? _coordenadas;
  List<String> _imagenes = [];
  double? _uploadProgress;

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
    _serieNotaCreditoBoletaController.addListener(_markAsChanged);
    _serieNotaDebitoController.addListener(_markAsChanged);
    _serieNotaDebitoBoletaController.addListener(_markAsChanged);
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
    _standController.text = sede.stand ?? '';
    _distritoController.text = sede.distrito ?? '';
    _provinciaController.text = sede.provincia ?? '';
    _departamentoController.text = sede.departamento ?? '';
    _serieFacturaController.text = sede.serieFactura;
    _serieBoletaController.text = sede.serieBoleta;
    _serieNotaCreditoController.text = sede.serieNotaCredito;
    _serieNotaCreditoBoletaController.text = sede.serieNotaCreditoBoleta;
    _serieNotaDebitoController.text = sede.serieNotaDebito;
    _serieNotaDebitoBoletaController.text = sede.serieNotaDebitoBoleta;
    _serieGuiaRemisionController.text = sede.serieGuiaRemision ?? '';
    _rucSedeController.text = sede.rucSede ?? '';
    _razonSocialSedeController.text = sede.razonSocialSede ?? '';
    _direccionFiscalSedeController.text = sede.direccionFiscalSede ?? '';
    _proveedorRutaController.text = sede.proveedorRuta ?? '';
    _proveedorTokenController.text = sede.proveedorToken ?? '';
    _resolucionSunatController.text = sede.resolucionSunat ?? '';

    setState(() {
      _selectedTipoSede = sede.tipoSede;
      _isActive = sede.isActive;
      _horarioAtencion = sede.horarioAtencion != null
          ? Map<String, dynamic>.from(sede.horarioAtencion!)
          : {};
      _coordenadas = sede.coordenadas != null
          ? Map<String, dynamic>.from(sede.coordenadas!)
          : null;
      _imagenes = List<String>.from(sede.imagenes);
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

  Future<void> _pickAndUploadImages() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galería'),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Cámara'),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null || _currentEmpresaId == null) return;

    final picker = ImagePicker();
    List<XFile> files = [];

    if (source == ImageSource.gallery) {
      files = await picker.pickMultiImage(imageQuality: 85);
    } else {
      final photo = await picker.pickImage(source: source, imageQuality: 85);
      if (photo != null) files = [photo];
    }
    if (files.isEmpty) return;

    final storageService = locator<StorageService>();
    for (int i = 0; i < files.length; i++) {
      try {
        setState(() => _uploadProgress = i / files.length);
        final result = await storageService.uploadFile(
          file: File(files[i].path),
          empresaId: _currentEmpresaId!,
          entidadTipo: 'SEDE',
          onProgress: (p) {
            setState(() => _uploadProgress = (i + p) / files.length);
          },
        );
        setState(() {
          _imagenes.add(result.url);
          _markAsChanged();
        });
      } catch (e) {
        // Continuar con las siguientes
      }
    }
    setState(() => _uploadProgress = null);
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
      if (_standController.text.trim().isNotEmpty)
        'stand': _standController.text.trim(),
      if (_distritoController.text.trim().isNotEmpty)
        'distrito': _distritoController.text.trim(),
      if (_provinciaController.text.trim().isNotEmpty)
        'provincia': _provinciaController.text.trim(),
      if (_departamentoController.text.trim().isNotEmpty)
        'departamento': _departamentoController.text.trim(),
      'pais': 'PERU',
      if (_horarioAtencion.isNotEmpty)
        'horarioAtencion': _horarioAtencion,
      if (_coordenadas != null)
        'coordenadas': {
          'lat': _coordenadas!['lat'],
          'lon': _coordenadas!['lng'] ?? _coordenadas!['lon'],
        },
      'imagenes': _imagenes,
      // Solo incluir series si el usuario las proporcionó (no vacías)
      // Si están vacías, el backend las generará automáticamente
      if (_serieFacturaController.text.trim().isNotEmpty)
        'serieFactura': _serieFacturaController.text.trim().toUpperCase(),
      if (_serieBoletaController.text.trim().isNotEmpty)
        'serieBoleta': _serieBoletaController.text.trim().toUpperCase(),
      if (_serieNotaCreditoController.text.trim().isNotEmpty)
        'serieNotaCredito': _serieNotaCreditoController.text.trim().toUpperCase(),
      if (_serieNotaCreditoBoletaController.text.trim().isNotEmpty)
        'serieNotaCreditoBoleta':
            _serieNotaCreditoBoletaController.text.trim().toUpperCase(),
      if (_serieNotaDebitoController.text.trim().isNotEmpty)
        'serieNotaDebito': _serieNotaDebitoController.text.trim().toUpperCase(),
      if (_serieNotaDebitoBoletaController.text.trim().isNotEmpty)
        'serieNotaDebitoBoleta':
            _serieNotaDebitoBoletaController.text.trim().toUpperCase(),
      if (_serieGuiaRemisionController.text.trim().isNotEmpty)
        'serieGuiaRemision':
            _serieGuiaRemisionController.text.trim().toUpperCase(),
      // Facturación electrónica por sede (override)
      if (_rucSedeController.text.trim().isNotEmpty)
        'rucSede': _rucSedeController.text.trim(),
      if (_razonSocialSedeController.text.trim().isNotEmpty)
        'razonSocialSede': _razonSocialSedeController.text.trim(),
      if (_direccionFiscalSedeController.text.trim().isNotEmpty)
        'direccionFiscalSede': _direccionFiscalSedeController.text.trim(),
      if (_proveedorRutaController.text.trim().isNotEmpty)
        'proveedorRuta': _proveedorRutaController.text.trim(),
      if (_proveedorTokenController.text.trim().isNotEmpty)
        'proveedorToken': _proveedorTokenController.text.trim(),
      if (_resolucionSunatController.text.trim().isNotEmpty)
        'resolucionSunat': _resolucionSunatController.text.trim(),
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
    _serieNotaCreditoBoletaController.dispose();
    _serieNotaDebitoController.dispose();
    _serieNotaDebitoBoletaController.dispose();
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
                    _sedeActual = state.sede;
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
                            standController: _standController,
                            distritoController: _distritoController,
                            provinciaController: _provinciaController,
                            departamentoController: _departamentoController,
                            serieFacturaController: _serieFacturaController,
                            serieBoletaController: _serieBoletaController,
                            serieNotaCreditoController:
                                _serieNotaCreditoController,
                            serieNotaCreditoBoletaController:
                                _serieNotaCreditoBoletaController,
                            serieNotaDebitoController:
                                _serieNotaDebitoController,
                            serieNotaDebitoBoletaController:
                                _serieNotaDebitoBoletaController,
                            serieGuiaRemisionController:
                                _serieGuiaRemisionController,
                            rucSedeController: _rucSedeController,
                            razonSocialSedeController: _razonSocialSedeController,
                            direccionFiscalSedeController: _direccionFiscalSedeController,
                            proveedorRutaController: _proveedorRutaController,
                            proveedorTokenController: _proveedorTokenController,
                            resolucionSunatController: _resolucionSunatController,
                            selectedTipoSede: _selectedTipoSede,
                            isActive: _isActive,
                            isEditing: widget.isEditing,
                            ultimoNumeroFactura: _sedeActual?.ultimoNumeroFactura ?? 0,
                            ultimoNumeroBoleta: _sedeActual?.ultimoNumeroBoleta ?? 0,
                            ultimoNumeroNotaCredito: _sedeActual?.ultimoNumeroNotaCredito ?? 0,
                            ultimoNumeroNotaCreditoBoleta: _sedeActual?.ultimoNumeroNotaCreditoBoleta ?? 0,
                            ultimoNumeroNotaDebito: _sedeActual?.ultimoNumeroNotaDebito ?? 0,
                            ultimoNumeroNotaDebitoBoleta: _sedeActual?.ultimoNumeroNotaDebitoBoleta ?? 0,
                            onTipoSedeChanged: _handleTipoSedeChanged,
                            onIsActiveChanged: (value) {
                              setState(() {
                                _isActive = value;
                                _markAsChanged();
                              });
                            },
                            imagenes: _imagenes,
                            uploadProgress: _uploadProgress,
                            onAddImagenes: () => _pickAndUploadImages(),
                            onRemoveImagen: (index) {
                              setState(() {
                                _imagenes.removeAt(index);
                                _markAsChanged();
                              });
                            },
                            coordenadas: _coordenadas,
                            onCoordenadasChanged: (coords) {
                              setState(() {
                                _coordenadas = coords;
                                _markAsChanged();
                              });
                            },
                            horarioAtencion: _horarioAtencion,
                            onHorarioChanged: (horario) {
                              setState(() {
                                _horarioAtencion = horario;
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
