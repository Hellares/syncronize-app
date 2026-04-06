import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../consultas_externas/domain/usecases/consultar_licencia_usecase.dart';
import '../../../consultas_externas/domain/usecases/consultar_placa_usecase.dart';
import '../../domain/entities/guia_remision.dart';
import '../../domain/repositories/guia_remision_repository.dart';
import '../widgets/ubigeo_selector.dart';

class GuiaRemisionEditarPage extends StatefulWidget {
  final String guiaId;

  const GuiaRemisionEditarPage({super.key, required this.guiaId});

  @override
  State<GuiaRemisionEditarPage> createState() =>
      _GuiaRemisionEditarPageState();
}

class _GuiaRemisionEditarPageState extends State<GuiaRemisionEditarPage> {
  final _formKey = GlobalKey<FormState>();
  final _repository = locator<GuiaRemisionRepository>();

  bool _loading = true;
  bool _submitting = false;
  bool _consultandoLicencia = false;
  bool _consultandoPlaca = false;
  String? _error;

  // Loaded guia data
  GuiaRemision? _guia;
  String _codigoGenerado = '';
  String? _errorAnterior;

  // Editable fields
  DateTime _fechaInicioTraslado = DateTime.now();
  final _observacionesController = TextEditingController();

  // Destinatario
  String _clienteTipoDoc = '6';
  final _clienteNumDocController = TextEditingController();
  final _clienteDenominacionController = TextEditingController();
  final _clienteDireccionController = TextEditingController();
  final _clienteEmailController = TextEditingController();

  // Puntos
  final _puntoPartidaUbigeoController = TextEditingController();
  final _puntoPartidaDireccionController = TextEditingController();
  final _puntoLlegadaUbigeoController = TextEditingController();
  final _puntoLlegadaDireccionController = TextEditingController();

  // Transporte
  String _tipoTransporte = 'PRIVADO';
  final _conductorDniController = TextEditingController();
  final _conductorNombreController = TextEditingController();
  final _conductorApellidosController = TextEditingController();
  final _conductorLicenciaController = TextEditingController();
  final _placaController = TextEditingController();
  final _transportistaRucController = TextEditingController();
  final _transportistaRazonSocialController = TextEditingController();

  // Peso
  final _pesoController = TextEditingController(text: '1');
  final _bultosController = TextEditingController(text: '1');

  // Items (read-only display)
  List<Map<String, dynamic>> _items = [];

  @override
  void initState() {
    super.initState();
    _cargarGuia();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    _clienteNumDocController.dispose();
    _clienteDenominacionController.dispose();
    _clienteDireccionController.dispose();
    _clienteEmailController.dispose();
    _puntoPartidaUbigeoController.dispose();
    _puntoPartidaDireccionController.dispose();
    _puntoLlegadaUbigeoController.dispose();
    _puntoLlegadaDireccionController.dispose();
    _conductorDniController.dispose();
    _conductorNombreController.dispose();
    _conductorApellidosController.dispose();
    _conductorLicenciaController.dispose();
    _placaController.dispose();
    _transportistaRucController.dispose();
    _transportistaRazonSocialController.dispose();
    _pesoController.dispose();
    _bultosController.dispose();
    super.dispose();
  }

  Future<void> _cargarGuia() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final result = await _repository.obtener(widget.guiaId);

    if (!mounted) return;

    if (result is Success<GuiaRemision>) {
      final guia = result.data;
      setState(() {
        _guia = guia;
        _codigoGenerado = guia.codigoGenerado;
        _errorAnterior = guia.errorProveedor;

        // Destinatario
        _clienteTipoDoc = guia.clienteTipoDocumento;
        _clienteNumDocController.text = guia.clienteNumeroDocumento;
        _clienteDenominacionController.text = guia.clienteDenominacion;
        _clienteDireccionController.text = guia.clienteDireccion ?? '';
        _clienteEmailController.text = guia.clienteEmail ?? '';

        // Puntos
        _puntoPartidaUbigeoController.text = guia.puntoPartidaUbigeo;
        _puntoPartidaDireccionController.text = guia.puntoPartidaDireccion;
        _puntoLlegadaUbigeoController.text = guia.puntoLlegadaUbigeo;
        _puntoLlegadaDireccionController.text = guia.puntoLlegadaDireccion;

        // Transporte
        _tipoTransporte = guia.tipoTransporte ?? 'PRIVADO';
        _conductorNombreController.text = guia.conductorNombre ?? '';
        _conductorApellidosController.text = guia.conductorApellidos ?? '';
        _conductorLicenciaController.text = guia.conductorNumeroLicencia ?? '';
        _placaController.text = guia.transportistaPlacaNumero ?? '';
        _transportistaRazonSocialController.text =
            guia.transportistaDenominacion ?? '';

        // Peso
        _pesoController.text = guia.pesoBrutoTotal.toString();
        _bultosController.text = (guia.numeroBultos ?? 1).toString();

        // Fecha
        _fechaInicioTraslado = guia.fechaInicioTraslado;

        // Observaciones
        _observacionesController.text = guia.observaciones ?? '';

        // Items from detalles
        _items = guia.detalles
            .map((d) => <String, dynamic>{
                  'productoId': d.productoId,
                  'varianteId': d.varianteId,
                  'descripcion': d.descripcion,
                  'codigo': d.codigo,
                  'cantidad': d.cantidad,
                  'unidadMedida': d.unidadMedida,
                })
            .toList();

        _loading = false;
      });
    } else if (result is Error) {
      setState(() {
        _error = (result as Error).message;
        _loading = false;
      });
    }
  }

  Future<void> _consultarLicencia() async {
    final dni = _conductorDniController.text.trim();
    if (dni.isEmpty || dni.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un DNI de 8 digitos'),
          backgroundColor: Colors.orange,
        ),
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
        final estadoMsg =
            data.esVigente ? 'VIGENTE' : data.licenciaEstado;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${data.nombreCompleto} — Lic: ${data.licenciaNumero} (${data.licenciaCategoria}) — $estadoMsg',
            ),
            backgroundColor:
                data.esVigente ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (result is Error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result as Error).message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _consultandoLicencia = false);
    }
  }

  Future<void> _consultarPlaca() async {
    final placa = _placaController.text.trim();
    if (placa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingrese un numero de placa'),
          backgroundColor: Colors.orange,
        ),
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
            content: Text(
              '${data.placa} — ${data.marca} ${data.modelo} — ${data.color}',
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (result is Error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((result as Error).message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _consultandoPlaca = false);
    }
  }

  Future<void> _guardarYReenviar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final guia = _guia!;

    final data = <String, dynamic>{
      'tipo': guia.tipo,
      'motivoTraslado': guia.motivoTraslado,
      'fechaInicioTraslado':
          DateFormatter.formatForApi(_fechaInicioTraslado),
      'pesoBrutoTotal':
          double.tryParse(_pesoController.text) ?? 1,
      'pesoBrutoUnidadMedida': 'KGM',
      'numeroBultos': int.tryParse(_bultosController.text),
      'clienteTipoDocumento': _clienteTipoDoc,
      'clienteNumeroDocumento':
          _clienteNumDocController.text.trim(),
      'clienteDenominacion':
          _clienteDenominacionController.text.trim(),
      'clienteDireccion':
          _clienteDireccionController.text.trim(),
      'clienteEmail': _clienteEmailController.text.trim(),
      'puntoPartidaUbigeo':
          _puntoPartidaUbigeoController.text.trim(),
      'puntoPartidaDireccion':
          _puntoPartidaDireccionController.text.trim(),
      'puntoLlegadaUbigeo':
          _puntoLlegadaUbigeoController.text.trim(),
      'puntoLlegadaDireccion':
          _puntoLlegadaDireccionController.text.trim(),
      'tipoTransporte': _tipoTransporte,
      'items': _items.map((item) {
        return {
          'productoId': item['productoId'],
          'varianteId': item['varianteId'],
          'descripcion': item['descripcion'],
          'codigo': item['codigo'] ?? '',
          'cantidad': item['cantidad'],
          'unidadMedida': item['unidadMedida'] ?? 'NIU',
        };
      }).toList(),
    };

    // Add transport data
    if (_tipoTransporte == 'PRIVADO') {
      data['conductorDocumentoTipo'] = '1';
      data['conductorDocumentoNumero'] =
          _conductorDniController.text.trim();
      data['conductorNombre'] =
          _conductorNombreController.text.trim();
      data['conductorApellidos'] =
          _conductorApellidosController.text.trim();
      data['conductorNumeroLicencia'] =
          _conductorLicenciaController.text.trim();
      data['transportistaPlacaNumero'] =
          _placaController.text.trim();
    } else {
      data['transportistaDocumentoTipo'] = '6';
      data['transportistaDocumentoNumero'] =
          _transportistaRucController.text.trim();
      data['transportistaDenominacion'] =
          _transportistaRazonSocialController.text.trim();
      data['transportistaPlacaNumero'] =
          _placaController.text.trim();
    }

    if (_observacionesController.text.trim().isNotEmpty) {
      data['observaciones'] = _observacionesController.text.trim();
    }

    // Preserve origin references
    if (guia.ventaId != null) data['ventaId'] = guia.ventaId;
    if (guia.compraId != null) data['compraId'] = guia.compraId;
    if (guia.transferenciaId != null) {
      data['transferenciaId'] = guia.transferenciaId;
    }
    if (guia.devolucionId != null) {
      data['devolucionId'] = guia.devolucionId;
    }

    // Preserve doc relacionados
    if (guia.documentosRelacionados.isNotEmpty) {
      data['documentosRelacionados'] = guia.documentosRelacionados
          .map((d) => {
                'tipo': d.tipo,
                'serie': d.serie,
                'numero': d.numero,
              })
          .toList();
    }

    // Step 1: Actualizar
    final updateResult =
        await _repository.actualizar(widget.guiaId, data);
    if (updateResult is! Success) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text((updateResult as Error).message),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // Step 2: Enviar
    final enviarResult = await _repository.enviar(widget.guiaId);

    if (mounted) {
      setState(() => _submitting = false);
      if (enviarResult is Success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guia actualizada y reenviada a SUNAT'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Guia actualizada. El envio se reintentara.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
      context.pushReplacement(
          '/empresa/guias-remision/${widget.guiaId}');
    }
  }

  Future<void> _selectFecha() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaInicioTraslado,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (picked != null) {
      setState(() => _fechaInicioTraslado = picked);
    }
  }

  // ── UI Helpers ──

  Widget _buildSection(
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return GradientContainer(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                AppSubtitle(title, fontSize: 13),
              ],
            ),
            const Divider(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, top: 6),
      child: AppText(text, size: 11, fontWeight: FontWeight.w600),
    );
  }

  // ── Build ──

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: GradientBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: SmartAppBar(
            title:
                'Editar Guia${_codigoGenerado.isNotEmpty ? ' $_codigoGenerado' : ''}',
          ),
          body: _buildBody(),
          bottomNavigationBar: (!_loading && _error == null)
              ? Container(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 8,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: _buildSubmitButton(),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text(
              'Cargando guia de remision...',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline,
                  size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _cargarGuia,
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Reintentar',
                    style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorAnterior != null) _buildErrorBanner(),
            _buildDestinatarioSection(),
            const SizedBox(height: 10),
            _buildPuntoPartidaSection(),
            const SizedBox(height: 10),
            _buildPuntoLlegadaSection(),
            const SizedBox(height: 10),
            _buildTransporteSection(),
            const SizedBox(height: 10),
            _buildItemsSection(),
            const SizedBox(height: 10),
            _buildPesoBultosSection(),
            const SizedBox(height: 10),
            _buildFechaTrasladoSection(),
            const SizedBox(height: 10),
            _buildObservacionesSection(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Sections ──

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline,
              size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText('Error anterior:',
                    size: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade700),
                const SizedBox(height: 2),
                AppText(_errorAnterior!,
                    size: 10, color: Colors.red.shade600),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDestinatarioSection() {
    return _buildSection(
      'Destinatario',
      Icons.person_outline,
      [
        CustomDropdown<String>(
          label: 'Tipo documento',
          value: _clienteTipoDoc,
          borderColor: AppColors.blue1,
          items: const [
            DropdownItem(value: '6', label: 'RUC'),
            DropdownItem(value: '1', label: 'DNI'),
            DropdownItem(value: '4', label: 'Carnet de Extranjeria'),
            DropdownItem(value: '7', label: 'Pasaporte'),
            DropdownItem(value: '0', label: 'Otros'),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _clienteTipoDoc = v);
          },
        ),
        _buildLabel('Numero documento'),
        CustomText(
          controller: _clienteNumDocController,
          hintText: 'Numero documento',
          borderColor: AppColors.blue1,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
        _buildLabel('Denominacion / Razon Social'),
        CustomText(
          borderColor: AppColors.blue1,
          controller: _clienteDenominacionController,
          hintText: 'Denominacion',
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
        _buildLabel('Direccion'),
        CustomText(
          controller: _clienteDireccionController,
          hintText: 'Direccion del destinatario',
          borderColor: AppColors.blue1,
        ),
        _buildLabel('Email (opcional)'),
        CustomText(
          controller: _clienteEmailController,
          hintText: 'Email',
          borderColor: AppColors.blue1,
          keyboardType: TextInputType.emailAddress,
        ),
      ],
    );
  }

  Widget _buildPuntoPartidaSection() {
    return _buildSection(
      'Punto de Partida',
      Icons.location_on_outlined,
      [
        UbigeoSelector(
          initialUbigeo: _puntoPartidaUbigeoController.text.isNotEmpty
              ? _puntoPartidaUbigeoController.text
              : null,
          ubigeoController: _puntoPartidaUbigeoController,
          onUbigeoSelected: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        _buildLabel('Direccion exacta'),
        CustomText(
          controller: _puntoPartidaDireccionController,
          hintText: 'Direccion punto de partida',
          borderColor: AppColors.blue1,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _buildPuntoLlegadaSection() {
    return _buildSection(
      'Punto de Llegada',
      Icons.flag_outlined,
      [
        UbigeoSelector(
          initialUbigeo: _puntoLlegadaUbigeoController.text.isNotEmpty
              ? _puntoLlegadaUbigeoController.text
              : null,
          ubigeoController: _puntoLlegadaUbigeoController,
          onUbigeoSelected: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        _buildLabel('Direccion exacta'),
        CustomText(
          controller: _puntoLlegadaDireccionController,
          hintText: 'Direccion punto de llegada',
          borderColor: AppColors.blue1,
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Requerido' : null,
        ),
      ],
    );
  }

  Widget _buildTransporteSection() {
    return _buildSection(
      'Transporte',
      Icons.local_shipping_outlined,
      [
        CustomDropdown<String>(
          label: 'Modalidad de transporte',
          value: _tipoTransporte,
          borderColor: AppColors.blue1,
          items: const [
            DropdownItem(
                value: 'PRIVADO', label: 'Transporte Privado'),
            DropdownItem(
                value: 'PUBLICO', label: 'Transporte Publico'),
          ],
          onChanged: (v) {
            if (v != null) setState(() => _tipoTransporte = v);
          },
        ),
        const SizedBox(height: 8),
        if (_tipoTransporte == 'PRIVADO') ..._buildPrivadoFields(),
        if (_tipoTransporte == 'PUBLICO') ..._buildPublicoFields(),
      ],
    );
  }

  List<Widget> _buildPrivadoFields() {
    return [
      _buildLabel('DNI del conductor'),
      Row(
        children: [
          Expanded(
            child: CustomText(
              controller: _conductorDniController,
              hintText: 'DNI (8 digitos)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.number,
              maxLength: 8,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed:
                  _consultandoLicencia ? null : _consultarLicencia,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _consultandoLicencia
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search, size: 18),
            ),
          ),
        ],
      ),
      _buildLabel('Nombre'),
      CustomText(
        controller: _conductorNombreController,
        hintText: 'Nombre del conductor',
        borderColor: AppColors.blue1,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Requerido' : null,
      ),
      _buildLabel('Apellidos'),
      CustomText(
        controller: _conductorApellidosController,
        hintText: 'Apellidos del conductor',
        borderColor: AppColors.blue1,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Requerido' : null,
      ),
      _buildLabel('Numero de licencia'),
      CustomText(
        controller: _conductorLicenciaController,
        hintText: 'Licencia de conducir',
        borderColor: AppColors.blue1,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Requerido' : null,
      ),
      _buildLabel('Placa del vehiculo'),
      Row(
        children: [
          Expanded(
            child: CustomText(
              controller: _placaController,
              hintText: 'Placa',
              borderColor: AppColors.blue1,
              textCase: TextCase.upper,
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Requerido' : null,
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 38,
            child: ElevatedButton(
              onPressed: _consultandoPlaca ? null : _consultarPlaca,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue1,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _consultandoPlaca
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.search, size: 18),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _buildPublicoFields() {
    return [
      _buildLabel('RUC del transportista'),
      CustomText(
        controller: _transportistaRucController,
        hintText: 'RUC (11 digitos)',
        borderColor: AppColors.blue1,
        keyboardType: TextInputType.number,
        maxLength: 11,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Requerido' : null,
      ),
      _buildLabel('Razon social'),
      CustomText(
        controller: _transportistaRazonSocialController,
        hintText: 'Razon social del transportista',
        borderColor: AppColors.blue1,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Requerido' : null,
      ),
      _buildLabel('Placa del vehiculo'),
      CustomText(
        controller: _placaController,
        hintText: 'Placa',
        borderColor: AppColors.blue1,
        textCase: TextCase.upper,
        validator: (v) =>
            v == null || v.trim().isEmpty ? 'Requerido' : null,
      ),
    ];
  }

  Widget _buildItemsSection() {
    return _buildSection(
      'Items (${_items.length})',
      Icons.inventory_2_outlined,
      [
        // Header
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Row(
            children: [
              Expanded(
                  flex: 5,
                  child: AppText('PRODUCTO',
                      size: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1)),
              SizedBox(width: 8),
              SizedBox(
                  width: 40,
                  child: AppText('CANT',
                      size: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1,
                      textAlign: TextAlign.center)),
              SizedBox(width: 8),
              SizedBox(
                  width: 40,
                  child: AppText('U.M.',
                      size: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.blue1,
                      textAlign: TextAlign.center)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Rows
        ...List.generate(_items.length, (i) {
          final item = _items[i];
          final desc = '${item['descripcion'] ?? 'Producto'}';
          final cant = '${item['cantidad'] ?? 0}';
          final um = '${item['unidadMedida'] ?? 'NIU'}';
          return Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(
                  bottom: BorderSide(
                      color: Colors.grey.shade200, width: 0.5)),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 5,
                    child: Text(desc,
                        style: const TextStyle(fontSize: 11))),
                const SizedBox(width: 8),
                SizedBox(
                    width: 40,
                    child: Text(cant,
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center)),
                const SizedBox(width: 8),
                SizedBox(
                    width: 40,
                    child: Text(um,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600),
                        textAlign: TextAlign.center)),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPesoBultosSection() {
    return _buildSection(
      'Peso y Bultos',
      Icons.scale_outlined,
      [
        _buildLabel('Peso bruto total'),
        Row(
          children: [
            Expanded(
              child: CustomText(
                controller: _pesoController,
                hintText: 'Peso bruto',
                borderColor: AppColors.blue1,
                keyboardType:
                    const TextInputType.numberWithOptions(
                        decimal: true),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Requerido';
                  }
                  final n = double.tryParse(v);
                  if (n == null || n <= 0) return 'Debe ser > 0';
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: const Text('KGM',
                  style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        _buildLabel('Numero de bultos'),
        CustomText(
          controller: _bultosController,
          hintText: 'Bultos',
          borderColor: AppColors.blue1,
          keyboardType: TextInputType.number,
        ),
      ],
    );
  }

  Widget _buildFechaTrasladoSection() {
    return _buildSection(
      'Fecha de traslado',
      Icons.calendar_today_outlined,
      [
        InkWell(
          onTap: _selectFecha,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.date_range,
                    size: 16, color: AppColors.blue1),
                const SizedBox(width: 8),
                Text(
                  DateFormatter.formatDate(_fechaInicioTraslado),
                  style: const TextStyle(fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.edit_calendar,
                    size: 14, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildObservacionesSection() {
    return _buildSection(
      'Observaciones',
      Icons.notes_outlined,
      [
        CustomText(
          controller: _observacionesController,
          hintText: 'Observaciones (opcional)',
          borderColor: AppColors.blue1,
          maxLines: 3,
          minLines: 1,
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: 'Guardar y Reenviar',
      onPressed: _submitting ? null : _guardarYReenviar,
      isLoading: _submitting,
      loadingText: 'Enviando...',
      backgroundColor: AppColors.green,
      textColor: Colors.white,
      fontWeight: FontWeight.w600,
      icon: const Icon(Icons.send, size: 18, color: Colors.white),
      width: double.infinity,
      enableShadows: true,
    );
  }
}
