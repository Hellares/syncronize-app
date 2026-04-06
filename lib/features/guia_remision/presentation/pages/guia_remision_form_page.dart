import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../consultas_externas/domain/usecases/consultar_ruc_usecase.dart';
import '../../../consultas_externas/domain/usecases/consultar_dni_usecase.dart';
import '../../../consultas_externas/domain/usecases/consultar_licencia_usecase.dart';
import '../../../consultas_externas/domain/usecases/consultar_placa_usecase.dart';
import '../../domain/entities/guia_remision.dart';
import '../../domain/repositories/guia_remision_repository.dart';

class GuiaRemisionFormPage extends StatefulWidget {
  final String? ventaId;
  final String? compraId;
  final String? transferenciaId;
  final String? devolucionId;
  final String? motivoTraslado;

  const GuiaRemisionFormPage({
    super.key,
    this.ventaId,
    this.compraId,
    this.transferenciaId,
    this.devolucionId,
    this.motivoTraslado,
  });

  @override
  State<GuiaRemisionFormPage> createState() => _GuiaRemisionFormPageState();
}

class _GuiaRemisionFormPageState extends State<GuiaRemisionFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = locator<GuiaRemisionRepository>();

  int _currentStep = 0;
  bool _submitting = false;
  bool _consultandoDoc = false;
  bool _consultandoLicencia = false;
  bool _consultandoPlaca = false;

  // Step 1 - General
  String _tipo = 'REMITENTE';
  MotivoTraslado _motivo = MotivoTraslado.VENTA;
  DateTime _fechaInicioTraslado = DateTime.now();
  final _observacionesController = TextEditingController();

  // Step 2 - Destinatario
  String _clienteTipoDoc = '6'; // RUC default
  final _clienteNumeroDocController = TextEditingController();
  final _clienteDenominacionController = TextEditingController();
  final _clienteDireccionController = TextEditingController();
  final _clienteEmailController = TextEditingController();

  // Step 3 - Puntos
  final _puntoPartidaUbigeoController = TextEditingController();
  final _puntoPartidaDireccionController = TextEditingController();
  final _puntoPartidaCodEstablecimientoController = TextEditingController();
  final _puntoLlegadaUbigeoController = TextEditingController();
  final _puntoLlegadaDireccionController = TextEditingController();
  final _puntoLlegadaCodEstablecimientoController = TextEditingController();

  // Step 4 - Transporte
  String _tipoTransporte = 'PRIVADO';
  // Publico
  final _transportistaRucController = TextEditingController();
  final _transportistaRazonSocialController = TextEditingController();
  final _transportistaPlacaController = TextEditingController();
  // Privado
  final _conductorDniController = TextEditingController();
  final _conductorNombreController = TextEditingController();
  final _conductorApellidosController = TextEditingController();
  final _conductorLicenciaController = TextEditingController();
  final _vehiculoPlacaController = TextEditingController();

  // Step 5 - Items
  final List<_ItemForm> _items = [];

  // Step 6 - Peso
  final _pesoBrutoController = TextEditingController(text: '0');
  String _pesoUnidad = 'KGM';
  final _numeroBultosController = TextEditingController();

  // Catalogs loaded
  List<VehiculoEmpresa> _vehiculos = [];
  List<ConductorEmpresa> _conductores = [];
  List<TransportistaEmpresa> _transportistas = [];

  @override
  void initState() {
    super.initState();
    _cargarCatalogos();
    _autoLlenarDesdeContexto();
    // Pre-fill from navigation params
    if (widget.motivoTraslado != null) {
      try {
        _motivo = MotivoTraslado.values.firstWhere((e) => e.name == widget.motivoTraslado);
      } catch (_) {}
    }
  }

  /// Auto-llena punto de partida con datos de la sede/empresa
  void _autoLlenarDesdeContexto() {
    final state = context.read<EmpresaContextCubit>().state;
    if (state is! EmpresaContextLoaded) return;

    final empresa = state.context.empresa;
    final sede = state.context.sedePrincipal;

    // Punto de partida: Sede > Empresa
    final ubigeoOrigen = sede?.ubigeo ?? empresa.ubigeo;
    final direccionOrigen = sede?.direccionFiscalSede ?? sede?.direccion ?? empresa.direccionFiscal;

    if (ubigeoOrigen != null && ubigeoOrigen.isNotEmpty) {
      _puntoPartidaUbigeoController.text = ubigeoOrigen;
    }
    if (direccionOrigen != null && direccionOrigen.isNotEmpty) {
      _puntoPartidaDireccionController.text = direccionOrigen;
    }

    // Para motivo TRASLADO_ENTRE_ESTABLECIMIENTOS, poner código establecimiento "0000"
    if (widget.motivoTraslado == 'TRASLADO_ENTRE_ESTABLECIMIENTOS') {
      _puntoPartidaCodEstablecimientoController.text = '0000';
      _puntoLlegadaCodEstablecimientoController.text = '0000';
    }
  }

  /// Consulta RUC/DNI via Factiliza y auto-llena destinatario + punto de llegada
  Future<void> _consultarDocumento() async {
    final doc = _clienteNumeroDocController.text.trim();
    if (doc.isEmpty) return;

    setState(() => _consultandoDoc = true);

    try {
      if (_clienteTipoDoc == '6' && doc.length == 11) {
        // Consultar RUC
        final useCase = locator<ConsultarRucUseCase>();
        final result = await useCase(doc);
        if (!mounted) return;
        if (result is Success) {
          final data = (result as Success).data;
          setState(() {
            _clienteDenominacionController.text = data.razonSocial;
            _clienteDireccionController.text = data.direccionCompleta;
            // Auto-llenar punto de llegada
            if (data.ubigeo.isNotEmpty) {
              _puntoLlegadaUbigeoController.text = data.ubigeo;
            }
            if (data.direccionCompleta.isNotEmpty) {
              _puntoLlegadaDireccionController.text = data.direccionCompleta;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos cargados desde SUNAT'), backgroundColor: Colors.green),
          );
        } else if (result is Error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((result as Error).message), backgroundColor: Colors.red),
          );
        }
      } else if (_clienteTipoDoc == '1' && doc.length == 8) {
        // Consultar DNI
        final useCase = locator<ConsultarDniUseCase>();
        final result = await useCase(doc);
        if (!mounted) return;
        if (result is Success) {
          final data = (result as Success).data;
          setState(() {
            _clienteDenominacionController.text = data.nombreCompleto;
            if (data.direccionCompleta.isNotEmpty) {
              _clienteDireccionController.text = data.direccionCompleta;
              _puntoLlegadaDireccionController.text = data.direccionCompleta;
            }
            if (data.ubigeo.isNotEmpty) {
              _puntoLlegadaUbigeoController.text = data.ubigeo;
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Datos cargados desde RENIEC'), backgroundColor: Colors.green),
          );
        } else if (result is Error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((result as Error).message), backgroundColor: Colors.red),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _consultandoDoc = false);
    }
  }

  /// Consulta licencia de conducir por DNI y auto-llena campos del conductor
  Future<void> _consultarLicencia() async {
    final dni = _conductorDniController.text.trim();
    if (dni.isEmpty || dni.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un DNI de 8 dígitos'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _consultandoLicencia = true);
    try {
      final useCase = locator<ConsultarLicenciaUseCase>();
      final result = await useCase(dni);
      if (!mounted) return;
      if (result is Success) {
        final data = (result as Success).data;
        setState(() {
          _conductorNombreController.text = data.nombres;
          _conductorApellidosController.text = data.apellidos;
          _conductorLicenciaController.text = data.licenciaNumero;
        });
        final estadoMsg = data.esVigente ? 'VIGENTE' : data.licenciaEstado;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.nombreCompleto} — Lic: ${data.licenciaNumero} (${data.licenciaCategoria}) — $estadoMsg'),
            backgroundColor: data.esVigente ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (result is Error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((result as Error).message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _consultandoLicencia = false);
    }
  }

  /// Consulta datos del vehículo por placa
  Future<void> _consultarPlaca() async {
    final placa = _tipoTransporte == 'PUBLICO'
        ? _transportistaPlacaController.text.trim()
        : _vehiculoPlacaController.text.trim();
    if (placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ingrese un número de placa'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _consultandoPlaca = true);
    try {
      final useCase = locator<ConsultarPlacaUseCase>();
      final result = await useCase(placa);
      if (!mounted) return;
      if (result is Success) {
        final data = (result as Success).data;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${data.placa} — ${data.marca} ${data.modelo} — ${data.color}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (result is Error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((result as Error).message), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _consultandoPlaca = false);
    }
  }

  Future<void> _cargarCatalogos() async {
    final results = await Future.wait([
      _repository.listarVehiculos(),
      _repository.listarConductores(),
      _repository.listarTransportistas(),
    ]);
    if (mounted) {
      setState(() {
        if (results[0] is Success) _vehiculos = (results[0] as Success<List<VehiculoEmpresa>>).data;
        if (results[1] is Success) _conductores = (results[1] as Success<List<ConductorEmpresa>>).data;
        if (results[2] is Success) _transportistas = (results[2] as Success<List<TransportistaEmpresa>>).data;
      });
    }
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _clienteNumeroDocController.dispose();
    _clienteDenominacionController.dispose();
    _clienteDireccionController.dispose();
    _clienteEmailController.dispose();
    _puntoPartidaUbigeoController.dispose();
    _puntoPartidaDireccionController.dispose();
    _puntoPartidaCodEstablecimientoController.dispose();
    _puntoLlegadaUbigeoController.dispose();
    _puntoLlegadaDireccionController.dispose();
    _puntoLlegadaCodEstablecimientoController.dispose();
    _transportistaRucController.dispose();
    _transportistaRazonSocialController.dispose();
    _transportistaPlacaController.dispose();
    _conductorDniController.dispose();
    _conductorNombreController.dispose();
    _conductorApellidosController.dispose();
    _conductorLicenciaController.dispose();
    _vehiculoPlacaController.dispose();
    _pesoBrutoController.dispose();
    _numeroBultosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Nueva Guia de Remision'),
        body: Form(
          key: _formKey,
          child: Stepper(
            currentStep: _currentStep,
            onStepContinue: _onStepContinue,
            onStepCancel: _onStepCancel,
            onStepTapped: (step) => setState(() => _currentStep = step),
            controlsBuilder: (context, details) {
              return Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (_currentStep < 5)
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue1,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Siguiente', style: TextStyle(fontSize: 12)),
                      ),
                    if (_currentStep == 5)
                      ElevatedButton(
                        onPressed: _submitting ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _submitting
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Crear Guia', style: TextStyle(fontSize: 12)),
                      ),
                    const SizedBox(width: 8),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: Text('Atras', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                      ),
                  ],
                ),
              );
            },
            steps: [
              Step(
                title: const Text('General', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 0,
                state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                content: _buildStepGeneral(),
              ),
              Step(
                title: const Text('Destinatario', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 1,
                state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                content: _buildStepDestinatario(),
              ),
              Step(
                title: const Text('Puntos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 2,
                state: _currentStep > 2 ? StepState.complete : StepState.indexed,
                content: _buildStepPuntos(),
              ),
              Step(
                title: const Text('Transporte', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 3,
                state: _currentStep > 3 ? StepState.complete : StepState.indexed,
                content: _buildStepTransporte(),
              ),
              Step(
                title: const Text('Items', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 4,
                state: _currentStep > 4 ? StepState.complete : StepState.indexed,
                content: _buildStepItems(),
              ),
              Step(
                title: const Text('Peso y Bultos', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                isActive: _currentStep >= 5,
                state: StepState.indexed,
                content: _buildStepPeso(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 1: General ──

  Widget _buildStepGeneral() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tipo
        const Text('Tipo de guia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            _chipSelector('Remitente', 'REMITENTE', _tipo, (v) => setState(() => _tipo = v)),
            const SizedBox(width: 8),
            _chipSelector('Transportista', 'TRANSPORTISTA', _tipo, (v) => setState(() => _tipo = v)),
          ],
        ),
        const SizedBox(height: 14),
        // Motivo
        const Text('Motivo de traslado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<MotivoTraslado>(
          value: _motivo,
          isExpanded: true,
          decoration: _inputDecoration('Seleccionar motivo'),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: MotivoTraslado.values.map((m) {
            return DropdownMenuItem(value: m, child: Text(m.label, style: const TextStyle(fontSize: 12)));
          }).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _motivo = v);
          },
        ),
        const SizedBox(height: 14),
        // Fecha inicio traslado
        const Text('Fecha inicio traslado', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: _seleccionarFecha,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.formatDate(_fechaInicioTraslado),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        // Observaciones
        const Text('Observaciones (opcional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _observacionesController,
          decoration: _inputDecoration('Observaciones'),
          maxLines: 2,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Future<void> _seleccionarFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicioTraslado,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null) {
      setState(() => _fechaInicioTraslado = picked);
    }
  }

  // ── Step 2: Destinatario ──

  Widget _buildStepDestinatario() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo documento', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _clienteTipoDoc,
          decoration: _inputDecoration('Tipo'),
          style: const TextStyle(fontSize: 12, color: Colors.black87),
          items: const [
            DropdownMenuItem(value: '6', child: Text('RUC', style: TextStyle(fontSize: 12))),
            DropdownMenuItem(value: '1', child: Text('DNI', style: TextStyle(fontSize: 12))),
            DropdownMenuItem(value: '4', child: Text('Carnet Extranjeria', style: TextStyle(fontSize: 12))),
            DropdownMenuItem(value: '7', child: Text('Pasaporte', style: TextStyle(fontSize: 12))),
            DropdownMenuItem(value: '0', child: Text('Sin documento', style: TextStyle(fontSize: 12))),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _clienteTipoDoc = v);
          },
        ),
        const SizedBox(height: 10),
        const Text('Numero documento', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _clienteNumeroDocController,
                decoration: _inputDecoration('Ej: 20100000001'),
                style: const TextStyle(fontSize: 12),
                keyboardType: TextInputType.number,
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                onFieldSubmitted: (_) => _consultarDocumento(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _consultandoDoc ? null : _consultarDocumento,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _consultandoDoc
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        const Text('Denominacion', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _clienteDenominacionController,
          decoration: _inputDecoration('Razon social o nombre'),
          style: const TextStyle(fontSize: 12),
          validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
        ),
        const SizedBox(height: 10),
        const Text('Direccion (opcional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _clienteDireccionController,
          decoration: _inputDecoration('Direccion del destinatario'),
          style: const TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 10),
        const Text('Email (opcional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _clienteEmailController,
          decoration: _inputDecoration('correo@ejemplo.com'),
          style: const TextStyle(fontSize: 12),
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  // ── Step 3: Puntos ──

  Widget _buildStepPuntos() {
    final requireCodEstablecimiento =
        _motivo == MotivoTraslado.TRASLADO_ENTRE_ESTABLECIMIENTOS ||
        _motivo == MotivoTraslado.TRASLADO_EMISOR_ITINERANTE;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Punto Partida
        GradientContainer(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.trip_origin, size: 14, color: Colors.green.shade600),
                    const SizedBox(width: 6),
                    const Text('Punto de Partida', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _puntoPartidaUbigeoController,
                  decoration: _inputDecoration('Ubigeo (6 digitos)'),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) => (v == null || v.length != 6) ? 'Ubigeo 6 digitos' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _puntoPartidaDireccionController,
                  decoration: _inputDecoration('Direccion completa'),
                  style: const TextStyle(fontSize: 12),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                if (requireCodEstablecimiento) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _puntoPartidaCodEstablecimientoController,
                    decoration: _inputDecoration('Cod. establecimiento SUNAT'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Punto Llegada
        GradientContainer(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flag, size: 14, color: Colors.red.shade600),
                    const SizedBox(width: 6),
                    const Text('Punto de Llegada', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _puntoLlegadaUbigeoController,
                  decoration: _inputDecoration('Ubigeo (6 digitos)'),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  validator: (v) => (v == null || v.length != 6) ? 'Ubigeo 6 digitos' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _puntoLlegadaDireccionController,
                  decoration: _inputDecoration('Direccion completa'),
                  style: const TextStyle(fontSize: 12),
                  validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
                if (requireCodEstablecimiento) ...[
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _puntoLlegadaCodEstablecimientoController,
                    decoration: _inputDecoration('Cod. establecimiento SUNAT'),
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Step 4: Transporte ──

  Widget _buildStepTransporte() {
    final esPublico = _tipoTransporte == 'PUBLICO';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tipo de transporte', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            _chipSelector('Publico', 'PUBLICO', _tipoTransporte, (v) => setState(() => _tipoTransporte = v)),
            const SizedBox(width: 8),
            _chipSelector('Privado', 'PRIVADO', _tipoTransporte, (v) => setState(() => _tipoTransporte = v)),
          ],
        ),
        const SizedBox(height: 14),

        if (esPublico) ...[
          // Transportista selector
          if (_transportistas.isNotEmpty) ...[
            const Text('Seleccionar transportista', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<TransportistaEmpresa>(
              decoration: _inputDecoration('Transportista'),
              isExpanded: true,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              items: _transportistas.map((t) {
                return DropdownMenuItem(
                  value: t,
                  child: Text('${t.ruc} - ${t.razonSocial}', style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
              onChanged: (t) {
                if (t != null) {
                  _transportistaRucController.text = t.ruc;
                  _transportistaRazonSocialController.text = t.razonSocial;
                }
              },
            ),
            const SizedBox(height: 10),
          ],
          const Text('RUC transportista', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _transportistaRucController,
            decoration: _inputDecoration('RUC'),
            style: const TextStyle(fontSize: 12),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          const Text('Razon social', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _transportistaRazonSocialController,
            decoration: _inputDecoration('Razon social transportista'),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          // Placa
          const Text('Placa vehiculo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _buildPlacaField(_transportistaPlacaController),
        ] else ...[
          // Conductor selector
          if (_conductores.isNotEmpty) ...[
            const Text('Seleccionar conductor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            DropdownButtonFormField<ConductorEmpresa>(
              decoration: _inputDecoration('Conductor'),
              isExpanded: true,
              style: const TextStyle(fontSize: 12, color: Colors.black87),
              items: _conductores.map((c) {
                return DropdownMenuItem(
                  value: c,
                  child: Text('${c.numeroDocumento} - ${c.nombreCompleto}', style: const TextStyle(fontSize: 11)),
                );
              }).toList(),
              onChanged: (c) {
                if (c != null) {
                  _conductorDniController.text = c.numeroDocumento;
                  _conductorNombreController.text = c.nombre;
                  _conductorApellidosController.text = c.apellidos;
                  _conductorLicenciaController.text = c.numeroLicencia;
                }
              },
            ),
            const SizedBox(height: 10),
          ],
          const Text('DNI conductor', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _conductorDniController,
                  decoration: _inputDecoration('DNI del conductor'),
                  style: const TextStyle(fontSize: 12),
                  keyboardType: TextInputType.number,
                  onFieldSubmitted: (_) => _consultarLicencia(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 40,
                child: ElevatedButton(
                  onPressed: _consultandoLicencia ? null : _consultarLicencia,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: _consultandoLicencia
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.search, size: 18, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text('Nombre', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _conductorNombreController,
            decoration: _inputDecoration('Nombre'),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          const Text('Apellidos', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _conductorApellidosController,
            decoration: _inputDecoration('Apellidos'),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          const Text('Numero de licencia', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _conductorLicenciaController,
            decoration: _inputDecoration('Licencia de conducir'),
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 10),
          // Placa
          const Text('Placa vehiculo', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          _buildPlacaField(_vehiculoPlacaController),
        ],
      ],
    );
  }

  Widget _buildPlacaField(TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_vehiculos.isNotEmpty) ...[
          DropdownButtonFormField<VehiculoEmpresa>(
            decoration: _inputDecoration('Seleccionar vehiculo'),
            isExpanded: true,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
            items: _vehiculos.map((v) {
              return DropdownMenuItem(
                value: v,
                child: Text(v.descripcion, style: const TextStyle(fontSize: 11)),
              );
            }).toList(),
            onChanged: (v) {
              if (v != null) controller.text = v.placaNumero;
            },
          ),
          const SizedBox(height: 8),
          const Text('O ingrese manualmente:', style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
        ],
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                decoration: _inputDecoration('Ej: ABC123'),
                style: const TextStyle(fontSize: 12),
                textCapitalization: TextCapitalization.characters,
                onFieldSubmitted: (_) => _consultarPlaca(),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _consultandoPlaca ? null : _consultarPlaca,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _consultandoPlaca
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.search, size: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ── Step 5: Items ──

  Widget _buildStepItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Items (${_items.length})', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const Spacer(),
            GestureDetector(
              onTap: _agregarItem,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.blue1,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text('Agregar', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_items.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'No hay items. Presione "Agregar" para agregar items a la guia.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          )
        else
          ...List.generate(_items.length, (i) => _buildItemCard(i)),
      ],
    );
  }

  void _agregarItem() {
    setState(() {
      _items.add(_ItemForm(
        descripcionController: TextEditingController(),
        cantidadController: TextEditingController(text: '1'),
        unidadMedida: 'NIU',
      ));
    });
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientContainer(
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Item ${index + 1}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => setState(() => _items.removeAt(index)),
                    child: Icon(Icons.delete, size: 16, color: Colors.red.shade400),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: item.descripcionController,
                decoration: _inputDecoration('Descripcion del item'),
                style: const TextStyle(fontSize: 12),
                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: item.cantidadController,
                      decoration: _inputDecoration('Cantidad'),
                      style: const TextStyle(fontSize: 12),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requerido';
                        if (double.tryParse(v) == null || double.parse(v) <= 0) return 'Invalido';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<String>(
                      value: item.unidadMedida,
                      decoration: _inputDecoration('Unidad'),
                      style: const TextStyle(fontSize: 12, color: Colors.black87),
                      items: const [
                        DropdownMenuItem(value: 'NIU', child: Text('Unidad (NIU)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'KGM', child: Text('Kilogramo (KGM)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'TNE', child: Text('Tonelada (TNE)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'LTR', child: Text('Litro (LTR)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'MTR', child: Text('Metro (MTR)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'MTK', child: Text('Metro2 (MTK)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'MTQ', child: Text('Metro3 (MTQ)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'GRM', child: Text('Gramo (GRM)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'BX', child: Text('Caja (BX)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'PK', child: Text('Paquete (PK)', style: TextStyle(fontSize: 11))),
                        DropdownMenuItem(value: 'DZN', child: Text('Docena (DZN)', style: TextStyle(fontSize: 11))),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => item.unidadMedida = v);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Step 6: Peso ──

  Widget _buildStepPeso() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Peso bruto total', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: TextFormField(
                controller: _pesoBrutoController,
                decoration: _inputDecoration('Peso'),
                style: const TextStyle(fontSize: 12),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Requerido';
                  if (double.tryParse(v) == null) return 'Invalido';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 2,
              child: DropdownButtonFormField<String>(
                value: _pesoUnidad,
                decoration: _inputDecoration('Unidad'),
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                items: const [
                  DropdownMenuItem(value: 'KGM', child: Text('KGM', style: TextStyle(fontSize: 12))),
                  DropdownMenuItem(value: 'TNE', child: Text('TNE', style: TextStyle(fontSize: 12))),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _pesoUnidad = v);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        const Text('Numero de bultos (opcional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _numeroBultosController,
          decoration: _inputDecoration('Cantidad de bultos'),
          style: const TextStyle(fontSize: 12),
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  // ── Helpers ──

  Widget _chipSelector(String label, String value, String current, ValueChanged<String> onTap) {
    final selected = current == value;
    return GestureDetector(
      onTap: () => onTap(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: selected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade400),
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.blue1),
      ),
      errorStyle: const TextStyle(fontSize: 10),
      counterText: '',
    );
  }

  void _onStepContinue() {
    if (_currentStep < 5) {
      setState(() => _currentStep++);
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete los campos requeridos'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agregue al menos un item'),
          backgroundColor: Colors.orange,
        ),
      );
      setState(() => _currentStep = 4);
      return;
    }

    setState(() => _submitting = true);

    final esPublico = _tipoTransporte == 'PUBLICO';
    final placa = esPublico ? _transportistaPlacaController.text.trim() : _vehiculoPlacaController.text.trim();

    // Obtener sedeId del contexto de empresa
    final empresaState = context.read<EmpresaContextCubit>().state;
    String? sedeId;
    if (empresaState is EmpresaContextLoaded) {
      sedeId = empresaState.context.sedePrincipal?.id;
    }
    if (sedeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo obtener la sede'), backgroundColor: Colors.red),
      );
      return;
    }

    final data = <String, dynamic>{
      'sedeId': sedeId,
      'tipo': _tipo,
      'motivoTraslado': _motivo.name,
      'fechaInicioTraslado': DateFormatter.formatForApi(_fechaInicioTraslado),
      'pesoBrutoTotal': double.tryParse(_pesoBrutoController.text) ?? 0,
      'pesoBrutoUnidadMedida': _pesoUnidad,
      'clienteTipoDocumento': _clienteTipoDoc,
      'clienteNumeroDocumento': _clienteNumeroDocController.text.trim(),
      'clienteDenominacion': _clienteDenominacionController.text.trim(),
      'puntoPartidaUbigeo': _puntoPartidaUbigeoController.text.trim(),
      'puntoPartidaDireccion': _puntoPartidaDireccionController.text.trim(),
      'puntoLlegadaUbigeo': _puntoLlegadaUbigeoController.text.trim(),
      'puntoLlegadaDireccion': _puntoLlegadaDireccionController.text.trim(),
      'tipoTransporte': _tipoTransporte,
      'items': _items.map((item) {
        return {
          'descripcion': item.descripcionController.text.trim(),
          'cantidad': double.tryParse(item.cantidadController.text) ?? 1,
          'unidadMedida': item.unidadMedida,
        };
      }).toList(),
    };

    // Opcionales
    if (_observacionesController.text.trim().isNotEmpty) {
      data['observaciones'] = _observacionesController.text.trim();
    }
    if (_clienteDireccionController.text.trim().isNotEmpty) {
      data['clienteDireccion'] = _clienteDireccionController.text.trim();
    }
    if (_clienteEmailController.text.trim().isNotEmpty) {
      data['clienteEmail'] = _clienteEmailController.text.trim();
    }
    if (_numeroBultosController.text.trim().isNotEmpty) {
      data['numeroBultos'] = int.tryParse(_numeroBultosController.text.trim());
    }
    if (_puntoPartidaCodEstablecimientoController.text.trim().isNotEmpty) {
      data['puntoPartidaCodigoEstablecimientoSunat'] = _puntoPartidaCodEstablecimientoController.text.trim();
    }
    if (_puntoLlegadaCodEstablecimientoController.text.trim().isNotEmpty) {
      data['puntoLlegadaCodigoEstablecimientoSunat'] = _puntoLlegadaCodEstablecimientoController.text.trim();
    }

    // Transporte
    if (esPublico) {
      if (_transportistaRucController.text.trim().isNotEmpty) {
        data['transportistaDocumentoTipo'] = '6'; // RUC
        data['transportistaDocumentoNumero'] = _transportistaRucController.text.trim();
      }
      if (_transportistaRazonSocialController.text.trim().isNotEmpty) {
        data['transportistaDenominacion'] = _transportistaRazonSocialController.text.trim();
      }
      if (placa.isNotEmpty) {
        data['transportistaPlacaNumero'] = placa;
      }
    } else {
      if (_conductorDniController.text.trim().isNotEmpty) {
        data['conductorDocumentoTipo'] = '1';
        data['conductorDocumentoNumero'] = _conductorDniController.text.trim();
      }
      if (_conductorNombreController.text.trim().isNotEmpty) {
        data['conductorNombre'] = _conductorNombreController.text.trim();
      }
      if (_conductorApellidosController.text.trim().isNotEmpty) {
        data['conductorApellidos'] = _conductorApellidosController.text.trim();
      }
      if (_conductorLicenciaController.text.trim().isNotEmpty) {
        data['conductorNumeroLicencia'] = _conductorLicenciaController.text.trim();
      }
      if (placa.isNotEmpty) {
        data['transportistaPlacaNumero'] = placa;
      }
    }

    // Documento origen (vinculación)
    if (widget.ventaId != null) data['ventaId'] = widget.ventaId;
    if (widget.compraId != null) data['compraId'] = widget.compraId;
    if (widget.transferenciaId != null) data['transferenciaId'] = widget.transferenciaId;
    if (widget.devolucionId != null) data['devolucionId'] = widget.devolucionId;

    final result = await _repository.crear(data);

    if (mounted) {
      setState(() => _submitting = false);

      if (result is Success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Guia de remision creada exitosamente'), backgroundColor: Colors.green),
        );
        context.pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${(result as Error).message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ItemForm {
  final TextEditingController descripcionController;
  final TextEditingController cantidadController;
  String unidadMedida;

  _ItemForm({
    required this.descripcionController,
    required this.cantidadController,
    this.unidadMedida = 'NIU',
  });
}
