import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import '../../../../core/di/injection_container.dart';
import '../../domain/entities/proveedor.dart';
import '../bloc/proveedor_form/proveedor_form_cubit.dart';
import '../bloc/proveedor_form/proveedor_form_state.dart';
import '../widgets/proveedor_form_fields.dart';

class ProveedorFormPage extends StatelessWidget {
  final String empresaId;
  final Proveedor? proveedor; // null = crear, not null = editar

  const ProveedorFormPage({super.key, required this.empresaId, this.proveedor});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ProveedorFormCubit>(),
      child: _ProveedorFormView(empresaId: empresaId, proveedor: proveedor),
    );
  }
}

class _ProveedorFormView extends StatefulWidget {
  final String empresaId;
  final Proveedor? proveedor;

  const _ProveedorFormView({required this.empresaId, this.proveedor});

  @override
  State<_ProveedorFormView> createState() => _ProveedorFormViewState();
}

class _ProveedorFormViewState extends State<_ProveedorFormView> {
  final _formKey = GlobalKey<FormState>();

  // Controllers - Identificación
  late final TextEditingController _nombreController;
  late final TextEditingController _nombreComercialController;
  late final TextEditingController _documentoController;

  // Controllers - Contacto
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _telefonoAlternativoController;
  late final TextEditingController _sitioWebController;

  // Controllers - Dirección
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _provinciaController;
  late final TextEditingController _paisController;
  late final TextEditingController _codigoPostalController;

  // Controllers - Términos Comerciales
  late final TextEditingController _limiteCreditoController;
  late final TextEditingController _descuentoPreferencialController;

  // Controllers - Contacto Principal
  late final TextEditingController _contactoPrincipalController;
  late final TextEditingController _cargoContactoController;

  // Controllers - Notas
  late final TextEditingController _notasController;

  String _tipoDocumento = 'RUC';
  String? _terminosPago;
  int? _diasCredito;

  bool get _isEditing => widget.proveedor != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;

    // Identificación
    _nombreController = TextEditingController(text: p?.nombre);
    _nombreComercialController = TextEditingController(
      text: p?.nombreComercial,
    );
    _documentoController = TextEditingController(text: p?.numeroDocumento);

    // Contacto
    _emailController = TextEditingController(text: p?.email);
    _telefonoController = TextEditingController(text: p?.telefono);
    _telefonoAlternativoController = TextEditingController(
      text: p?.telefonoAlternativo,
    );
    _sitioWebController = TextEditingController(text: p?.sitioWeb);

    // Dirección
    _direccionController = TextEditingController(text: p?.direccion);
    _ciudadController = TextEditingController(text: p?.ciudad);
    _provinciaController = TextEditingController(text: p?.provincia);
    _paisController = TextEditingController(text: p?.pais ?? 'PE');
    _codigoPostalController = TextEditingController(text: p?.codigoPostal);

    // Términos Comerciales
    _limiteCreditoController = TextEditingController(
      text: p?.limiteCredito?.toString() ?? '',
    );
    _descuentoPreferencialController = TextEditingController(
      text: p?.descuentoPreferencial?.toString() ?? '',
    );

    // Contacto Principal
    _contactoPrincipalController = TextEditingController(
      text: p?.contactoPrincipal,
    );
    _cargoContactoController = TextEditingController(text: p?.cargoContacto);

    // Notas
    _notasController = TextEditingController(text: p?.notas);

    if (p != null) {
      _tipoDocumento = p.tipoDocumento.toString().split('.').last;
      _terminosPago = p.terminosPago?.toString().split('.').last;
      _diasCredito = p.diasCredito;
    }
  }

  @override
  void dispose() {
    // Identificación
    _nombreController.dispose();
    _nombreComercialController.dispose();
    _documentoController.dispose();

    // Contacto
    _emailController.dispose();
    _telefonoController.dispose();
    _telefonoAlternativoController.dispose();
    _sitioWebController.dispose();

    // Dirección
    _direccionController.dispose();
    _ciudadController.dispose();
    _provinciaController.dispose();
    _paisController.dispose();
    _codigoPostalController.dispose();

    // Términos Comerciales
    _limiteCreditoController.dispose();
    _descuentoPreferencialController.dispose();

    // Contacto Principal
    _contactoPrincipalController.dispose();
    _cargoContactoController.dispose();

    // Notas
    _notasController.dispose();

    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final limiteCredito = _limiteCreditoController.text.trim().isEmpty
        ? null
        : double.tryParse(_limiteCreditoController.text.trim());
    final descuentoPreferencial =
        _descuentoPreferencialController.text.trim().isEmpty
        ? null
        : double.tryParse(_descuentoPreferencialController.text.trim());

    final data = {
      // Identificación
      'nombre': _nombreController.text.trim(),
      if (_nombreComercialController.text.trim().isNotEmpty)
        'nombreComercial': _nombreComercialController.text.trim(),
      'tipoDocumento': _tipoDocumento,
      'numeroDocumento': _documentoController.text.trim(),

      // Contacto
      if (_emailController.text.trim().isNotEmpty)
        'email': _emailController.text.trim(),
      if (_telefonoController.text.trim().isNotEmpty)
        'telefono': _telefonoController.text.trim(),
      if (_telefonoAlternativoController.text.trim().isNotEmpty)
        'telefonoAlternativo': _telefonoAlternativoController.text.trim(),
      if (_sitioWebController.text.trim().isNotEmpty)
        'sitioWeb': _sitioWebController.text.trim(),

      // Dirección
      if (_direccionController.text.trim().isNotEmpty)
        'direccion': _direccionController.text.trim(),
      if (_ciudadController.text.trim().isNotEmpty)
        'ciudad': _ciudadController.text.trim(),
      if (_provinciaController.text.trim().isNotEmpty)
        'provincia': _provinciaController.text.trim(),
      if (_paisController.text.trim().isNotEmpty)
        'pais': _paisController.text.trim(),
      if (_codigoPostalController.text.trim().isNotEmpty)
        'codigoPostal': _codigoPostalController.text.trim(),

      // Términos Comerciales
      if (_terminosPago != null) 'terminosPago': _terminosPago,
      if (_diasCredito != null) 'diasCredito': _diasCredito,
      if (limiteCredito != null) 'limiteCredito': limiteCredito,
      if (descuentoPreferencial != null)
        'descuentoPreferencial': descuentoPreferencial,

      // Contacto Principal
      if (_contactoPrincipalController.text.trim().isNotEmpty)
        'contactoPrincipal': _contactoPrincipalController.text.trim(),
      if (_cargoContactoController.text.trim().isNotEmpty)
        'cargoContacto': _cargoContactoController.text.trim(),

      // Notas
      if (_notasController.text.trim().isNotEmpty)
        'notas': _notasController.text.trim(),
    };

    if (_isEditing) {
      context.read<ProveedorFormCubit>().actualizarProveedor(
        empresaId: widget.empresaId,
        proveedorId: widget.proveedor!.id,
        data: data,
      );
    } else {
      context.read<ProveedorFormCubit>().crearProveedor(
        empresaId: widget.empresaId,
        data: data,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        title: '${_isEditing ? 'Editar' : 'Nuevo'} Proveedor',
      ),
      body: BlocConsumer<ProveedorFormCubit, ProveedorFormState>(
        listener: (context, state) {
          if (state is ProveedorFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.isUpdate
                      ? 'Proveedor actualizado correctamente'
                      : 'Proveedor creado correctamente',
                ),
                backgroundColor: Colors.green,
                duration: const Duration(seconds: 2),
              ),
            );

            // Volver a la lista de proveedores
            Future.delayed(const Duration(milliseconds: 500), () {
              if (context.mounted) {
                context.pop();
              }
            });
          } else if (state is ProveedorFormError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is ProveedorFormLoading;

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ProveedorFormFields(
                        nombreController: _nombreController,
                        nombreComercialController: _nombreComercialController,
                        documentoController: _documentoController,
                        emailController: _emailController,
                        telefonoController: _telefonoController,
                        telefonoAlternativoController:
                            _telefonoAlternativoController,
                        sitioWebController: _sitioWebController,
                        direccionController: _direccionController,
                        ciudadController: _ciudadController,
                        provinciaController: _provinciaController,
                        paisController: _paisController,
                        codigoPostalController: _codigoPostalController,
                        limiteCreditoController: _limiteCreditoController,
                        descuentoPreferencialController:
                            _descuentoPreferencialController,
                        contactoPrincipalController:
                            _contactoPrincipalController,
                        cargoContactoController: _cargoContactoController,
                        notasController: _notasController,
                        tipoDocumento: _tipoDocumento,
                        terminosPago: _terminosPago,
                        isLoading: isLoading,
                        isEditing: _isEditing,
                        onTipoDocumentoChanged: (value) {
                          setState(() => _tipoDocumento = value);
                        },
                        onTerminosPagoChanged: (value) {
                          setState(() => _terminosPago = value);
                        },
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        backgroundColor: AppColors.blue1,
                        text: _isEditing
                            ? 'Actualizar Proveedor'
                            : 'Crear Proveedor',
                        onPressed: isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
              // Loading overlay
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Guardando proveedor...',
                              style: TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
