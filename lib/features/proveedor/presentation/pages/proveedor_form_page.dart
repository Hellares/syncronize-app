import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_button.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../consultas_externas/domain/usecases/consultar_ruc_usecase.dart';
import '../../../consultas_externas/domain/usecases/consultar_dni_usecase.dart';
import '../../domain/entities/proveedor.dart';
import '../bloc/proveedor_form/proveedor_form_cubit.dart';
import '../bloc/proveedor_form/proveedor_form_state.dart';
import '../widgets/proveedor_form_fields.dart';

class ProveedorFormPage extends StatelessWidget {
  final String empresaId;
  final Proveedor? proveedor;

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

  late final TextEditingController _nombreController;
  late final TextEditingController _nombreComercialController;
  late final TextEditingController _documentoController;
  late final TextEditingController _emailController;
  late final TextEditingController _telefonoController;
  late final TextEditingController _telefonoAlternativoController;
  late final TextEditingController _sitioWebController;
  late final TextEditingController _direccionController;
  late final TextEditingController _ciudadController;
  late final TextEditingController _provinciaController;
  late final TextEditingController _paisController;
  late final TextEditingController _codigoPostalController;
  late final TextEditingController _limiteCreditoController;
  late final TextEditingController _descuentoPreferencialController;
  late final TextEditingController _contactoPrincipalController;
  late final TextEditingController _cargoContactoController;
  late final TextEditingController _notasController;

  String _tipoDocumento = 'RUC';
  String? _terminosPago;
  int? _diasCredito;

  bool _isSearching = false;

  bool get _isEditing => widget.proveedor != null;

  @override
  void initState() {
    super.initState();
    final p = widget.proveedor;

    _nombreController = TextEditingController(text: p?.nombre);
    _nombreComercialController = TextEditingController(text: p?.nombreComercial);
    _documentoController = TextEditingController(text: p?.numeroDocumento);
    _emailController = TextEditingController(text: p?.email);
    _telefonoController = TextEditingController(text: p?.telefono);
    _telefonoAlternativoController = TextEditingController(text: p?.telefonoAlternativo);
    _sitioWebController = TextEditingController(text: p?.sitioWeb);
    _direccionController = TextEditingController(text: p?.direccion);
    _ciudadController = TextEditingController(text: p?.ciudad);
    _provinciaController = TextEditingController(text: p?.provincia);
    _paisController = TextEditingController(text: p?.pais ?? 'PE');
    _codigoPostalController = TextEditingController(text: p?.codigoPostal);
    _limiteCreditoController = TextEditingController(text: p?.limiteCredito?.toString() ?? '');
    _descuentoPreferencialController = TextEditingController(text: p?.descuentoPreferencial?.toString() ?? '');
    _contactoPrincipalController = TextEditingController(text: p?.contactoPrincipal);
    _cargoContactoController = TextEditingController(text: p?.cargoContacto);
    _notasController = TextEditingController(text: p?.notas);

    if (p != null) {
      _tipoDocumento = p.tipoDocumento.toString().split('.').last;
      _terminosPago = p.terminosPago?.toString().split('.').last;
      _diasCredito = p.diasCredito;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _nombreComercialController.dispose();
    _documentoController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    _telefonoAlternativoController.dispose();
    _sitioWebController.dispose();
    _direccionController.dispose();
    _ciudadController.dispose();
    _provinciaController.dispose();
    _paisController.dispose();
    _codigoPostalController.dispose();
    _limiteCreditoController.dispose();
    _descuentoPreferencialController.dispose();
    _contactoPrincipalController.dispose();
    _cargoContactoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _searchDocument() async {
    final doc = _documentoController.text.trim();
    if (doc.isEmpty) return;

    setState(() => _isSearching = true);

    try {
      if (_tipoDocumento == 'RUC' && doc.length == 11) {
        final useCase = locator<ConsultarRucUseCase>();
        final result = await useCase(doc);
        if (!mounted) return;
        if (result is Success) {
          final data = (result as Success).data;
          setState(() {
            _nombreController.text = data.razonSocial;
            _direccionController.text = data.direccion;
            _ciudadController.text = data.distrito;
            _provinciaController.text = '${data.departamento} - ${data.provincia}';
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos cargados desde SUNAT'), backgroundColor: Colors.green),
          );
        } else if (result is Error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((result as Error).message), backgroundColor: Colors.red),
          );
        }
      } else if (_tipoDocumento == 'DNI' && doc.length == 8) {
        final useCase = locator<ConsultarDniUseCase>();
        final result = await useCase(doc);
        if (!mounted) return;
        if (result is Success) {
          final data = (result as Success).data;
          setState(() {
            _nombreController.text = data.nombreCompleto;
            _direccionController.text = data.direccion;
            _ciudadController.text = data.distrito;
            _provinciaController.text = '${data.departamento} - ${data.provincia}';
            if (data.telefono != null && data.telefono!.isNotEmpty) {
              _telefonoController.text = data.telefono!;
            }
            if (data.email != null && data.email!.isNotEmpty) {
              _emailController.text = data.email!;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Datos cargados desde ${data.origen ?? "RENIEC"}'), backgroundColor: Colors.green),
          );
        } else if (result is Error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((result as Error).message), backgroundColor: Colors.red),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_tipoDocumento == 'RUC' ? 'Ingresa 11 digitos para RUC' : 'Ingresa 8 digitos para DNI'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al consultar documento'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final limiteCredito = _limiteCreditoController.text.trim().isEmpty
        ? null : double.tryParse(_limiteCreditoController.text.trim());
    final descuentoPreferencial = _descuentoPreferencialController.text.trim().isEmpty
        ? null : double.tryParse(_descuentoPreferencialController.text.trim());

    final data = {
      'nombre': _nombreController.text.trim(),
      if (_nombreComercialController.text.trim().isNotEmpty) 'nombreComercial': _nombreComercialController.text.trim(),
      'tipoDocumento': _tipoDocumento,
      'numeroDocumento': _documentoController.text.trim(),
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
      if (_telefonoController.text.trim().isNotEmpty) 'telefono': _telefonoController.text.trim(),
      if (_telefonoAlternativoController.text.trim().isNotEmpty) 'telefonoAlternativo': _telefonoAlternativoController.text.trim(),
      if (_sitioWebController.text.trim().isNotEmpty) 'sitioWeb': _sitioWebController.text.trim(),
      if (_direccionController.text.trim().isNotEmpty) 'direccion': _direccionController.text.trim(),
      if (_ciudadController.text.trim().isNotEmpty) 'ciudad': _ciudadController.text.trim(),
      if (_provinciaController.text.trim().isNotEmpty) 'provincia': _provinciaController.text.trim(),
      if (_paisController.text.trim().isNotEmpty) 'pais': _paisController.text.trim(),
      if (_codigoPostalController.text.trim().isNotEmpty) 'codigoPostal': _codigoPostalController.text.trim(),
      if (_terminosPago != null) 'terminosPago': _terminosPago,
      if (_diasCredito != null) 'diasCredito': _diasCredito,
      if (limiteCredito != null) 'limiteCredito': limiteCredito,
      if (descuentoPreferencial != null) 'descuentoPreferencial': descuentoPreferencial,
      if (_contactoPrincipalController.text.trim().isNotEmpty) 'contactoPrincipal': _contactoPrincipalController.text.trim(),
      if (_cargoContactoController.text.trim().isNotEmpty) 'cargoContacto': _cargoContactoController.text.trim(),
      if (_notasController.text.trim().isNotEmpty) 'notas': _notasController.text.trim(),
    };

    if (_isEditing) {
      context.read<ProveedorFormCubit>().actualizarProveedor(empresaId: widget.empresaId, proveedorId: widget.proveedor!.id, data: data);
    } else {
      context.read<ProveedorFormCubit>().crearProveedor(empresaId: widget.empresaId, data: data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
      appBar: SmartAppBar(backgroundColor: AppColors.blue1, foregroundColor: Colors.white, title: '${_isEditing ? 'Editar' : 'Nuevo'} Proveedor'),
      body: BlocConsumer<ProveedorFormCubit, ProveedorFormState>(
        listener: (context, state) {
          if (state is ProveedorFormSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(state.isUpdate ? 'Proveedor actualizado correctamente' : 'Proveedor creado correctamente'),
              backgroundColor: Colors.green,
            ));
            Future.delayed(const Duration(milliseconds: 500), () { if (context.mounted) context.pop(); });
          } else if (state is ProveedorFormError) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.message), backgroundColor: Colors.red));
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
                        telefonoAlternativoController: _telefonoAlternativoController,
                        sitioWebController: _sitioWebController,
                        direccionController: _direccionController,
                        ciudadController: _ciudadController,
                        provinciaController: _provinciaController,
                        paisController: _paisController,
                        limiteCreditoController: _limiteCreditoController,
                        descuentoPreferencialController: _descuentoPreferencialController,
                        contactoPrincipalController: _contactoPrincipalController,
                        cargoContactoController: _cargoContactoController,
                        notasController: _notasController,
                        tipoDocumento: _tipoDocumento,
                        terminosPago: _terminosPago,
                        isLoading: isLoading,
                        isEditing: _isEditing,
                        onTipoDocumentoChanged: (value) => setState(() => _tipoDocumento = value),
                        onTerminosPagoChanged: (value) => setState(() => _terminosPago = value),
                        onSearchDocument: _searchDocument,
                        isSearching: _isSearching,
                      ),
                      const SizedBox(height: 24),
                      CustomButton(
                        backgroundColor: AppColors.blue1,
                        text: _isEditing ? 'Actualizar Proveedor' : 'Crear Proveedor',
                        onPressed: isLoading ? null : _submit,
                      ),
                    ],
                  ),
                ),
              ),
              if (isLoading)
                Container(
                  color: Colors.black.withValues(alpha: 0.5),
                  child: const Center(
                    child: Card(child: Padding(padding: EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Guardando proveedor...', style: TextStyle(fontSize: 16))]))),
                  ),
                ),
            ],
          );
        },
      ),
    ),
    );
  }
}
