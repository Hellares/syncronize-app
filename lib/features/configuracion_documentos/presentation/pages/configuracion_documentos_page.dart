import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/storage_service.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/configuracion_documentos.dart';
import '../../domain/entities/configuracion_documento_completa.dart';
import '../../domain/entities/plantilla_documento.dart';
import '../../../cotizacion/domain/entities/cotizacion.dart';
import '../../../cotizacion/domain/entities/cotizacion_detalle.dart';
import '../../../cotizacion/presentation/services/pdf_cotizacion_generator.dart';
import '../bloc/configuracion_documentos_cubit.dart';
import '../bloc/configuracion_documentos_state.dart';

class ConfiguracionDocumentosPage extends StatefulWidget {
  const ConfiguracionDocumentosPage({super.key});

  @override
  State<ConfiguracionDocumentosPage> createState() =>
      _ConfiguracionDocumentosPageState();
}

class _ConfiguracionDocumentosPageState
    extends State<ConfiguracionDocumentosPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Form controllers for identity section
  final _nombreComercialCtrl = TextEditingController();
  final _rucCtrl = TextEditingController();
  final _direccionCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _colorPrimarioCtrl = TextEditingController();
  final _colorSecundarioCtrl = TextEditingController();
  final _colorTextoCtrl = TextEditingController();
  final _textoPieCtrl = TextEditingController();
  bool _mostrarPaginacion = true;

  // Logo
  String? _logoUrl;
  bool _isUploadingLogo = false;

  // Template section
  TipoDocumento _selectedTipo = TipoDocumento.COTIZACION;
  FormatoPapel _selectedFormato = FormatoPapel.A4;

  // Margin controllers
  final _margenSuperiorCtrl = TextEditingController(text: '10');
  final _margenInferiorCtrl = TextEditingController(text: '10');
  final _margenIzquierdoCtrl = TextEditingController(text: '10');
  final _margenDerechoCtrl = TextEditingController(text: '10');

  // Visibility toggles
  bool _mostrarLogo = true;
  bool _mostrarDatosEmpresa = true;
  bool _mostrarDatosCliente = true;
  bool _mostrarDetalles = true;
  bool _mostrarTotales = true;
  bool _mostrarObservaciones = true;
  bool _mostrarCondiciones = true;
  bool _mostrarFirma = true;
  bool _mostrarCodigoQR = false;
  bool _mostrarPiePagina = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<ConfiguracionDocumentosCubit>().cargarConfiguracion();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nombreComercialCtrl.dispose();
    _rucCtrl.dispose();
    _direccionCtrl.dispose();
    _telefonoCtrl.dispose();
    _emailCtrl.dispose();
    _colorPrimarioCtrl.dispose();
    _colorSecundarioCtrl.dispose();
    _colorTextoCtrl.dispose();
    _textoPieCtrl.dispose();
    _margenSuperiorCtrl.dispose();
    _margenInferiorCtrl.dispose();
    _margenIzquierdoCtrl.dispose();
    _margenDerechoCtrl.dispose();
    super.dispose();
  }

  void _populateConfigFields(ConfiguracionDocumentos config) {
    _nombreComercialCtrl.text = config.nombreComercial ?? '';
    _rucCtrl.text = config.ruc ?? '';
    _direccionCtrl.text = config.direccion ?? '';
    _telefonoCtrl.text = config.telefono ?? '';
    _emailCtrl.text = config.email ?? '';
    _colorPrimarioCtrl.text = config.colorPrimario;
    _colorSecundarioCtrl.text = config.colorSecundario;
    _colorTextoCtrl.text = config.colorTexto;
    _textoPieCtrl.text = config.textoPiePagina;
    _mostrarPaginacion = config.mostrarPaginacion;
    _logoUrl = config.logoUrl;
  }

  void _populatePlantillaFields(PlantillaDocumento plantilla) {
    _margenSuperiorCtrl.text = plantilla.margenSuperior.toStringAsFixed(0);
    _margenInferiorCtrl.text = plantilla.margenInferior.toStringAsFixed(0);
    _margenIzquierdoCtrl.text = plantilla.margenIzquierdo.toStringAsFixed(0);
    _margenDerechoCtrl.text = plantilla.margenDerecho.toStringAsFixed(0);
    _mostrarLogo = plantilla.mostrarLogo;
    _mostrarDatosEmpresa = plantilla.mostrarDatosEmpresa;
    _mostrarDatosCliente = plantilla.mostrarDatosCliente;
    _mostrarDetalles = plantilla.mostrarDetalles;
    _mostrarTotales = plantilla.mostrarTotales;
    _mostrarObservaciones = plantilla.mostrarObservaciones;
    _mostrarCondiciones = plantilla.mostrarCondiciones;
    _mostrarFirma = plantilla.mostrarFirma;
    _mostrarCodigoQR = plantilla.mostrarCodigoQR;
    _mostrarPiePagina = plantilla.mostrarPiePagina;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuracion de Documentos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Identidad'),
            Tab(text: 'Plantillas'),
          ],
        ),
      ),
      body: BlocConsumer<ConfiguracionDocumentosCubit,
          ConfiguracionDocumentosState>(
        listener: (context, state) {
          if (state is ConfiguracionDocumentosLoaded) {
            _populateConfigFields(state.configuracion);
            final plantilla = state.plantillas.where(
              (p) =>
                  p.tipoDocumento == _selectedTipo &&
                  p.formatoPapel == _selectedFormato,
            );
            if (plantilla.isNotEmpty) {
              _populatePlantillaFields(plantilla.first);
            } else {
              // No existe para este formato, cargar del backend
              context.read<ConfiguracionDocumentosCubit>().cargarPlantilla(
                    _selectedTipo.apiValue,
                    formato: _selectedFormato.apiValue,
                  );
            }
          }
          if (state is PlantillaCargada) {
            _populatePlantillaFields(state.plantilla);
            setState(() {});
          }
          if (state is ConfiguracionDocumentosUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Configuracion actualizada')),
            );
            context.read<ConfiguracionDocumentosCubit>().cargarConfiguracion();
          }
          if (state is PlantillaDocumentoUpdated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Plantilla actualizada')),
            );
            context.read<ConfiguracionDocumentosCubit>().cargarConfiguracion();
          }
          if (state is ConfiguracionDocumentosError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ConfiguracionDocumentosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              _buildIdentidadTab(),
              _buildPlantillasTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIdentidadTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo de empresa
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Logo de la empresa',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 160,
                          height: 80,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade50,
                          ),
                          child: _logoUrl != null && _logoUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _logoUrl!,
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.broken_image,
                                      size: 40,
                                      color: Colors.grey,
                                    ),
                                  ),
                                )
                              : const Icon(
                                  Icons.business,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                        ),
                        const SizedBox(height: 12),
                        if (_isUploadingLogo)
                          const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                onPressed: _seleccionarLogo,
                                icon: const Icon(Icons.upload, size: 18),
                                label: Text(
                                    _logoUrl != null ? 'Cambiar' : 'Subir logo'),
                              ),
                              if (_logoUrl != null) ...[
                                const SizedBox(width: 8),
                                OutlinedButton.icon(
                                  onPressed: _eliminarLogo,
                                  icon: const Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  label: const Text('Eliminar',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Datos de empresa
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Datos de la empresa',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _nombreComercialCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Nombre comercial'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _rucCtrl,
                    decoration: const InputDecoration(labelText: 'RUC'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _direccionCtrl,
                    decoration: const InputDecoration(labelText: 'Direccion'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _telefonoCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Telefono'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _emailCtrl,
                          decoration:
                              const InputDecoration(labelText: 'Email'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Colores
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Colores del documento',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildColorField(
                          controller: _colorPrimarioCtrl,
                          label: 'Color primario',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildColorField(
                          controller: _colorSecundarioCtrl,
                          label: 'Color secundario',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildColorField(
                          controller: _colorTextoCtrl,
                          label: 'Color texto',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Pie de pagina
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pie de pagina',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _textoPieCtrl,
                    decoration:
                        const InputDecoration(labelText: 'Texto pie de pagina'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Mostrar paginacion'),
                    subtitle: const Text('Pagina X de Y'),
                    value: _mostrarPaginacion,
                    onChanged: (v) => setState(() => _mostrarPaginacion = v),
                    contentPadding: EdgeInsets.zero,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardarConfiguracion,
              child: const Text('Guardar configuracion'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlantillasTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tipo selector
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tipo de documento',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<TipoDocumento>(
                    initialValue: _selectedTipo,
                    items: TipoDocumento.values
                        .map((t) => DropdownMenuItem(
                              value: t,
                              child: Text(t.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedTipo = v);
                        _cargarPlantillaSeleccionada();
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Formato de papel',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<FormatoPapel>(
                    initialValue: _selectedFormato,
                    items: FormatoPapel.values
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(f.label),
                            ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedFormato = v);
                        _cargarPlantillaSeleccionada();
                      }
                    },
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Margenes
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Margenes (mm)',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _margenSuperiorCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Superior'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _margenInferiorCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Inferior'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _margenIzquierdoCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Izquierdo'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _margenDerechoCtrl,
                          keyboardType: TextInputType.number,
                          decoration:
                              const InputDecoration(labelText: 'Derecho'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Secciones visibles
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Secciones visibles',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _buildToggle('Logo', _mostrarLogo,
                      (v) => setState(() => _mostrarLogo = v)),
                  _buildToggle('Datos de empresa', _mostrarDatosEmpresa,
                      (v) => setState(() => _mostrarDatosEmpresa = v)),
                  _buildToggle('Datos del cliente', _mostrarDatosCliente,
                      (v) => setState(() => _mostrarDatosCliente = v)),
                  _buildToggle('Detalles/Items', _mostrarDetalles,
                      (v) => setState(() => _mostrarDetalles = v)),
                  _buildToggle('Totales', _mostrarTotales,
                      (v) => setState(() => _mostrarTotales = v)),
                  _buildToggle('Observaciones', _mostrarObservaciones,
                      (v) => setState(() => _mostrarObservaciones = v)),
                  _buildToggle('Condiciones', _mostrarCondiciones,
                      (v) => setState(() => _mostrarCondiciones = v)),
                  _buildToggle('Firma', _mostrarFirma,
                      (v) => setState(() => _mostrarFirma = v)),
                  _buildToggle('Codigo QR', _mostrarCodigoQR,
                      (v) => setState(() => _mostrarCodigoQR = v)),
                  _buildToggle('Pie de pagina', _mostrarPiePagina,
                      (v) => setState(() => _mostrarPiePagina = v)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _guardarPlantilla,
              child: const Text('Guardar plantilla'),
            ),
          ),
          const SizedBox(height: 12),

          // Preview button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _mostrarVistaPrevia,
              icon: const Icon(Icons.visibility),
              label: const Text('Vista previa'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColorField({
    required TextEditingController controller,
    required String label,
  }) {
    Color? previewColor;
    try {
      final hex = controller.text.replaceFirst('#', '');
      if (hex.length == 6) {
        previewColor = Color(int.parse('FF$hex', radix: 16));
      }
    } catch (_) {}

    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: '#RRGGBB',
        prefixIcon: Container(
          margin: const EdgeInsets.all(10),
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: previewColor ?? Colors.grey,
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      contentPadding: EdgeInsets.zero,
      dense: true,
    );
  }

  void _cargarPlantillaSeleccionada() {
    final state = context.read<ConfiguracionDocumentosCubit>().state;
    if (state is ConfiguracionDocumentosLoaded) {
      final plantilla = state.plantillas.where(
        (p) =>
            p.tipoDocumento == _selectedTipo &&
            p.formatoPapel == _selectedFormato,
      );
      if (plantilla.isNotEmpty) {
        _populatePlantillaFields(plantilla.first);
        setState(() {});
        return;
      }
    }
    // Not in local list — fetch from backend (creates with defaults if needed)
    context.read<ConfiguracionDocumentosCubit>().cargarPlantilla(
          _selectedTipo.apiValue,
          formato: _selectedFormato.apiValue,
        );
  }

  Future<void> _seleccionarLogo() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;
    final empresaId = empresaState.context.empresa.id;
    final cubit = context.read<ConfiguracionDocumentosCubit>();

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 400,
      imageQuality: 85,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingLogo = true);

    try {
      final storageService = locator<StorageService>();
      final response = await storageService.uploadFile(
        file: File(picked.path),
        empresaId: empresaId,
        entidadTipo: 'EMPRESA',
        entidadId: empresaId,
        categoria: 'LOGO',
      );

      // Guardar la URL del logo en la configuración
      cubit.actualizarConfiguracion({'logoUrl': response.url});

      if (mounted) {
        setState(() {
          _logoUrl = response.url;
          _isUploadingLogo = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al subir logo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _eliminarLogo() {
    context.read<ConfiguracionDocumentosCubit>().actualizarConfiguracion({
      'logoUrl': null,
    });
    setState(() => _logoUrl = null);
  }

  void _guardarConfiguracion() {
    final data = <String, dynamic>{};
    if (_nombreComercialCtrl.text.isNotEmpty) {
      data['nombreComercial'] = _nombreComercialCtrl.text;
    }
    if (_rucCtrl.text.isNotEmpty) data['ruc'] = _rucCtrl.text;
    if (_direccionCtrl.text.isNotEmpty) {
      data['direccion'] = _direccionCtrl.text;
    }
    if (_telefonoCtrl.text.isNotEmpty) {
      data['telefono'] = _telefonoCtrl.text;
    }
    if (_emailCtrl.text.isNotEmpty) data['email'] = _emailCtrl.text;
    if (_colorPrimarioCtrl.text.isNotEmpty) {
      data['colorPrimario'] = _colorPrimarioCtrl.text;
    }
    if (_colorSecundarioCtrl.text.isNotEmpty) {
      data['colorSecundario'] = _colorSecundarioCtrl.text;
    }
    if (_colorTextoCtrl.text.isNotEmpty) {
      data['colorTexto'] = _colorTextoCtrl.text;
    }
    if (_textoPieCtrl.text.isNotEmpty) {
      data['textoPiePagina'] = _textoPieCtrl.text;
    }
    data['mostrarPaginacion'] = _mostrarPaginacion;

    context.read<ConfiguracionDocumentosCubit>().actualizarConfiguracion(data);
  }

  Future<void> _mostrarVistaPrevia() async {
    // Build a PlantillaDocumento from current form values
    final plantilla = PlantillaDocumento(
      id: 'preview',
      empresaId: 'preview',
      tipoDocumento: _selectedTipo,
      formatoPapel: _selectedFormato,
      nombre: 'Vista previa',
      margenSuperior: double.tryParse(_margenSuperiorCtrl.text) ?? 10.0,
      margenInferior: double.tryParse(_margenInferiorCtrl.text) ?? 10.0,
      margenIzquierdo: double.tryParse(_margenIzquierdoCtrl.text) ?? 10.0,
      margenDerecho: double.tryParse(_margenDerechoCtrl.text) ?? 10.0,
      mostrarLogo: _mostrarLogo,
      mostrarDatosEmpresa: _mostrarDatosEmpresa,
      mostrarDatosCliente: _mostrarDatosCliente,
      mostrarDetalles: _mostrarDetalles,
      mostrarTotales: _mostrarTotales,
      mostrarObservaciones: _mostrarObservaciones,
      mostrarCondiciones: _mostrarCondiciones,
      mostrarFirma: _mostrarFirma,
      mostrarCodigoQR: _mostrarCodigoQR,
      mostrarPiePagina: _mostrarPiePagina,
      colorEncabezado: _colorPrimarioCtrl.text.isNotEmpty
          ? _colorPrimarioCtrl.text
          : null,
    );

    // Build ConfiguracionDocumentos from form values
    final config = ConfiguracionDocumentos(
      id: 'preview',
      empresaId: 'preview',
      nombreComercial: _nombreComercialCtrl.text.isNotEmpty
          ? _nombreComercialCtrl.text
          : 'Mi Empresa S.A.C.',
      ruc: _rucCtrl.text.isNotEmpty ? _rucCtrl.text : '20123456789',
      direccion: _direccionCtrl.text.isNotEmpty
          ? _direccionCtrl.text
          : 'Av. Ejemplo 123, Lima',
      telefono: _telefonoCtrl.text.isNotEmpty
          ? _telefonoCtrl.text
          : '(01) 234-5678',
      email: _emailCtrl.text.isNotEmpty
          ? _emailCtrl.text
          : 'contacto@miempresa.com',
      colorPrimario: _colorPrimarioCtrl.text.isNotEmpty
          ? _colorPrimarioCtrl.text
          : '#1565C0',
      colorSecundario: _colorSecundarioCtrl.text.isNotEmpty
          ? _colorSecundarioCtrl.text
          : '#1E88E5',
      colorTexto: _colorTextoCtrl.text.isNotEmpty
          ? _colorTextoCtrl.text
          : '#333333',
      textoPiePagina: _textoPieCtrl.text.isNotEmpty
          ? _textoPieCtrl.text
          : 'Gracias por su preferencia',
      mostrarPaginacion: _mostrarPaginacion,
    );

    final documentConfig = ConfiguracionDocumentoCompleta(
      configuracion: config,
      plantilla: plantilla,
    );

    // Dummy cotizacion data
    final now = DateTime.now();
    final dummyCotizacion = Cotizacion(
      id: 'preview',
      empresaId: 'preview',
      sedeId: 'preview',
      vendedorId: 'preview',
      codigo: 'COT-0001',
      nombre: 'Cotizacion de ejemplo',
      nombreCliente: 'Cliente de Prueba',
      documentoCliente: '10987654321',
      emailCliente: 'cliente@ejemplo.com',
      telefonoCliente: '987 654 321',
      direccionCliente: 'Calle Los Olivos 456, Lima',
      vendedorNombre: 'Juan Vendedor',
      moneda: 'PEN',
      subtotal: 1500.00,
      descuento: 50.00,
      impuestos: 261.00,
      total: 1711.00,
      fechaEmision: now,
      fechaVencimiento: now.add(const Duration(days: 30)),
      estado: EstadoCotizacion.pendiente,
      creadoEn: now,
      actualizadoEn: now,
      observaciones: 'Esta es una cotizacion de ejemplo para vista previa.',
      condiciones: 'Validez: 30 dias. Forma de pago: 50% adelanto.',
      detalles: [
        CotizacionDetalle(
          id: 'd1',
          cotizacionId: 'preview',
          descripcion: 'Servicio de consultoria',
          cantidad: 2,
          precioUnitario: 500.00,
          subtotal: 1000.00,
          total: 1000.00,
        ),
        CotizacionDetalle(
          id: 'd2',
          cotizacionId: 'preview',
          descripcion: 'Licencia de software anual',
          cantidad: 1,
          precioUnitario: 350.00,
          subtotal: 350.00,
          total: 350.00,
        ),
        CotizacionDetalle(
          id: 'd3',
          cotizacionId: 'preview',
          descripcion: 'Soporte tecnico mensual',
          cantidad: 3,
          precioUnitario: 50.00,
          descuento: 0,
          subtotal: 150.00,
          total: 150.00,
        ),
      ],
    );

    // Generate PDF
    Uint8List pdfBytes;
    try {
      pdfBytes = await PdfCotizacionGenerator.generarDocumento(
        cotizacion: dummyCotizacion,
        empresaNombre: config.nombreComercial ?? 'Mi Empresa S.A.C.',
        empresaRuc: config.ruc,
        empresaDireccion: config.direccion,
        empresaTelefono: config.telefono,
        documentConfig: documentConfig,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al generar vista previa: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    // Show preview in a full-screen dialog
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: Text('Vista previa - ${_selectedFormato.label}'),
          ),
          body: PdfPreview(
            build: (format) => pdfBytes,
            allowSharing: false,
            allowPrinting: false,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
            pdfFileName: 'vista_previa.pdf',
            actions: const [],
          ),
        ),
      ),
    );
  }

  void _guardarPlantilla() {
    final data = <String, dynamic>{
      'formatoPapel': _selectedFormato.apiValue,
      'margenSuperior':
          double.tryParse(_margenSuperiorCtrl.text) ?? 10.0,
      'margenInferior':
          double.tryParse(_margenInferiorCtrl.text) ?? 10.0,
      'margenIzquierdo':
          double.tryParse(_margenIzquierdoCtrl.text) ?? 10.0,
      'margenDerecho':
          double.tryParse(_margenDerechoCtrl.text) ?? 10.0,
      'mostrarLogo': _mostrarLogo,
      'mostrarDatosEmpresa': _mostrarDatosEmpresa,
      'mostrarDatosCliente': _mostrarDatosCliente,
      'mostrarDetalles': _mostrarDetalles,
      'mostrarTotales': _mostrarTotales,
      'mostrarObservaciones': _mostrarObservaciones,
      'mostrarCondiciones': _mostrarCondiciones,
      'mostrarFirma': _mostrarFirma,
      'mostrarCodigoQR': _mostrarCodigoQR,
      'mostrarPiePagina': _mostrarPiePagina,
    };

    context
        .read<ConfiguracionDocumentosCubit>()
        .actualizarPlantilla(_selectedTipo.apiValue, data);
  }
}
