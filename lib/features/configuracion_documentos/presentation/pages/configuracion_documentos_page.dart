import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:printing/printing.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_fonts.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_loading.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
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
    extends State<ConfiguracionDocumentosPage> {
  // Identity controllers
  final _nombreComercialCtrl = TextEditingController();
  // ruc, direccion, telefono, email eliminados — se configuran en datos de Empresa/Sede
  final _colorPrimarioCtrl = TextEditingController();
  final _colorSecundarioCtrl = TextEditingController();
  final _colorTextoCtrl = TextEditingController();
  final _textoPieCtrl = TextEditingController();
  bool _mostrarPaginacion = true;

  // Logo
  String? _logoUrl;
  bool _isUploadingLogo = false;

  // Template
  TipoDocumento _selectedTipo = TipoDocumento.COTIZACION;
  FormatoPapel _selectedFormato = FormatoPapel.A4;

  // Margins
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
    context.read<ConfiguracionDocumentosCubit>().cargarConfiguracion();
  }

  @override
  void dispose() {
    _nombreComercialCtrl.dispose();
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
    _colorPrimarioCtrl.text = config.colorPrimario;
    _colorSecundarioCtrl.text = config.colorSecundario;
    _colorTextoCtrl.text = config.colorTexto;
    _textoPieCtrl.text = config.textoPiePagina;
    _mostrarPaginacion = config.mostrarPaginacion;

    // Fallback: si no hay logoUrl en configuración, usar el logo de la empresa
    _logoUrl = config.logoUrl;
    if (_logoUrl == null || _logoUrl!.isEmpty) {
      final empresaState = context.read<EmpresaContextCubit>().state;
      if (empresaState is EmpresaContextLoaded) {
        _logoUrl = empresaState.context.empresa.logo;
      }
    }
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
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Configuracion de documentos',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
        ),
        body: BlocConsumer<ConfiguracionDocumentosCubit, ConfiguracionDocumentosState>(
          listener: (context, state) {
            if (state is ConfiguracionDocumentosLoaded) {
              _populateConfigFields(state.configuracion);
              final plantilla = state.plantillas.where(
                (p) => p.tipoDocumento == _selectedTipo && p.formatoPapel == _selectedFormato,
              );
              if (plantilla.isNotEmpty) {
                _populatePlantillaFields(plantilla.first);
              } else {
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
                const SnackBar(content: Text('Configuracion actualizada'), backgroundColor: Colors.green),
              );
              context.read<ConfiguracionDocumentosCubit>().cargarConfiguracion();
            }
            if (state is PlantillaDocumentoUpdated) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Plantilla actualizada'), backgroundColor: Colors.green),
              );
              context.read<ConfiguracionDocumentosCubit>().cargarConfiguracion();
            }
            if (state is ConfiguracionDocumentosError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(state.message), backgroundColor: Colors.red),
              );
            }
          },
          builder: (context, state) {
            if (state is ConfiguracionDocumentosLoading) {
              return const Center(child: CustomLoading());
            }
            return _buildContent();
          },
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        // ─── Logo ───
        _buildLogoCard(),
        const SizedBox(height: 12),

        // ─── Datos de empresa ───
        _buildDatosEmpresaCard(),
        const SizedBox(height: 12),

        // ─── Colores + Pie de página ───
        _buildColoresCard(),
        const SizedBox(height: 12),

        // Guardar identidad
        CustomButton(
          text: 'Guardar configuracion',
          icon: const Icon(Icons.save_outlined, size: 14, color: Colors.white),
          backgroundColor: AppColors.blue1,
          height: 38,
          borderRadius: 8,
          onPressed: _guardarConfiguracion,
        ),
        const SizedBox(height: 20),

        // ─── Separador plantillas ───
        Row(
          children: [
            Expanded(child: Divider(color: Colors.grey.shade300)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'PLANTILLAS',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade400,
                  letterSpacing: 1.2,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                ),
              ),
            ),
            Expanded(child: Divider(color: Colors.grey.shade300)),
          ],
        ),
        const SizedBox(height: 12),

        // ─── Selector de plantilla ───
        _buildPlantillaSelector(),
        const SizedBox(height: 12),

        // ─── Márgenes ───
        _buildMargenesCard(),
        const SizedBox(height: 12),

        // ─── Secciones visibles ───
        _buildSeccionesCard(),
        const SizedBox(height: 14),

        // Acciones de plantilla
        Row(
          children: [
            Expanded(
              child: CustomButton(
                text: 'Vista previa',
                icon: const Icon(Icons.visibility_outlined, size: 14, color: AppColors.blue1),
                isOutlined: true,
                borderColor: AppColors.blue1,
                textColor: AppColors.blue1,
                enableShadows: false,
                height: 38,
                borderRadius: 8,
                onPressed: _mostrarVistaPrevia,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomButton(
                text: 'Guardar plantilla',
                icon: const Icon(Icons.save_outlined, size: 14, color: Colors.white),
                backgroundColor: AppColors.blue1,
                height: 38,
                borderRadius: 8,
                onPressed: _guardarPlantilla,
              ),
            ),
          ],
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // ─── Logo Card ───

  Widget _buildLogoCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Logo del documento', Icons.image_outlined),
            const SizedBox(height: 4),
            AppLabelText(
              'Se mostrara en el encabezado de los documentos',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 14),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.blueborder),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade50,
                    ),
                    child: _logoUrl != null && _logoUrl!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(7),
                            child: Image.network(
                              _logoUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => Icon(Icons.broken_image, size: 28, color: Colors.grey.shade300),
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.business, size: 24, color: Colors.grey.shade300),
                              Text('Sin logo', style: TextStyle(fontSize: 8, color: Colors.grey.shade400)),
                            ],
                          ),
                  ),
                  const SizedBox(width: 14),
                  if (_isUploadingLogo)
                    const SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
                    )
                  else
                    Column(
                      children: [
                        InkWell(
                          onTap: _seleccionarLogo,
                          borderRadius: BorderRadius.circular(6),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.bluechip,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.upload_outlined, size: 13, color: AppColors.blue1),
                                const SizedBox(width: 4),
                                Text(
                                  _logoUrl != null ? 'Cambiar' : 'Subir',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.blue1,
                                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_logoUrl != null) ...[
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: _eliminarLogo,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.red.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.delete_outline, size: 13, color: Colors.red.shade400),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Eliminar',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.red.shade400,
                                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
    );
  }

  // ─── Datos Empresa Card ───

  Widget _buildDatosEmpresaCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blue1,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Datos de la empresa', Icons.business_outlined),
            const SizedBox(height: 12),
            CustomText(
              controller: _nombreComercialCtrl,
              label: 'Nombre comercial',
              borderColor: AppColors.blue1,
            ),
            const SizedBox(height: 4),
            Text('RUC, dirección, teléfono y email se configuran en Datos de Empresa y Sede',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontStyle: FontStyle.italic)),
          ],
        ),
      ),
    );
  }

  // ─── Colores Card ───

  Widget _buildColoresCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Colores y pie de pagina', Icons.palette_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _buildColorField(_colorPrimarioCtrl, 'Primario')),
                const SizedBox(width: 8),
                Expanded(child: _buildColorField(_colorSecundarioCtrl, 'Secundario')),
                const SizedBox(width: 8),
                Expanded(child: _buildColorField(_colorTextoCtrl, 'Texto')),
              ],
            ),

            _sectionDivider(),

            CustomText(
              controller: _textoPieCtrl,
              label: 'Texto pie de pagina',
              borderColor: AppColors.blue1,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            CustomSwitchTile(
              title: 'Mostrar paginacion',
              subtitle: 'Pagina X de Y',
              value: _mostrarPaginacion,
              onChanged: (v) => setState(() => _mostrarPaginacion = v),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorField(TextEditingController controller, String label) {
    Color? previewColor;
    try {
      final hex = controller.text.replaceFirst('#', '');
      if (hex.length == 6) previewColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: previewColor ?? Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.grey.shade300, width: 0.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        CustomText(
          controller: controller,
          hintText: '#RRGGBB',
          borderColor: AppColors.blue1,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  // ─── Plantilla Selector ───

  Widget _buildPlantillaSelector() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Tipo de documento', Icons.description_outlined),
            const SizedBox(height: 12),
            CustomDropdown<String>(
              label: 'Documento',
              value: _selectedTipo.apiValue,
              borderColor: AppColors.blue1,
              items: TipoDocumento.values
                  .map((t) => DropdownItem<String>(value: t.apiValue, label: t.label))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedTipo = TipoDocumento.fromString(v));
                  _cargarPlantillaSeleccionada();
                }
              },
            ),
            const SizedBox(height: 8),
            CustomDropdown<String>(
              label: 'Formato de papel',
              value: _selectedFormato.apiValue,
              borderColor: AppColors.blue1,
              items: FormatoPapel.values
                  .map((f) => DropdownItem<String>(value: f.apiValue, label: f.label))
                  .toList(),
              onChanged: (v) {
                if (v != null) {
                  setState(() => _selectedFormato = FormatoPapel.fromString(v));
                  _cargarPlantillaSeleccionada();
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── Márgenes Card ───

  Widget _buildMargenesCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Margenes (mm)', Icons.crop_outlined),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _margenSuperiorCtrl,
                    label: 'Superior',
                    borderColor: AppColors.blue1,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    controller: _margenInferiorCtrl,
                    label: 'Inferior',
                    borderColor: AppColors.blue1,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: CustomText(
                    controller: _margenIzquierdoCtrl,
                    label: 'Izquierdo',
                    borderColor: AppColors.blue1,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    controller: _margenDerechoCtrl,
                    label: 'Derecho',
                    borderColor: AppColors.blue1,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Secciones Card ───

  Widget _buildSeccionesCard() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('Secciones visibles', Icons.visibility_outlined),
            const SizedBox(height: 4),
            AppLabelText(
              'Selecciona que secciones mostrar en el documento',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            const SizedBox(height: 10),
            CustomSwitchTile(title: 'Logo', value: _mostrarLogo,
                onChanged: (v) => setState(() => _mostrarLogo = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Datos de empresa', value: _mostrarDatosEmpresa,
                onChanged: (v) => setState(() => _mostrarDatosEmpresa = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Datos del cliente', value: _mostrarDatosCliente,
                onChanged: (v) => setState(() => _mostrarDatosCliente = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Detalles / Items', value: _mostrarDetalles,
                onChanged: (v) => setState(() => _mostrarDetalles = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Totales', value: _mostrarTotales,
                onChanged: (v) => setState(() => _mostrarTotales = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Observaciones', value: _mostrarObservaciones,
                onChanged: (v) => setState(() => _mostrarObservaciones = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Condiciones', value: _mostrarCondiciones,
                onChanged: (v) => setState(() => _mostrarCondiciones = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Firma', value: _mostrarFirma,
                onChanged: (v) => setState(() => _mostrarFirma = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Codigo QR', value: _mostrarCodigoQR,
                onChanged: (v) => setState(() => _mostrarCodigoQR = v)),
            const SizedBox(height: 4),
            CustomSwitchTile(title: 'Pie de pagina', value: _mostrarPiePagina,
                onChanged: (v) => setState(() => _mostrarPiePagina = v)),
          ],
        ),
      ),
    );
  }

  // ─── Helpers ───

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.blue1,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, color: AppColors.blue1, size: 16),
        ),
        const SizedBox(width: 10),
        AppTitle(title, fontSize: 12, color: AppColors.blue1),
      ],
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(height: 1, color: Colors.grey.shade200),
    );
  }

  // ─── Actions ───

  void _cargarPlantillaSeleccionada() {
    final state = context.read<ConfiguracionDocumentosCubit>().state;
    if (state is ConfiguracionDocumentosLoaded) {
      final plantilla = state.plantillas.where(
        (p) => p.tipoDocumento == _selectedTipo && p.formatoPapel == _selectedFormato,
      );
      if (plantilla.isNotEmpty) {
        _populatePlantillaFields(plantilla.first);
        setState(() {});
        return;
      }
    }
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
          SnackBar(content: Text('Error al subir logo: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _eliminarLogo() {
    context.read<ConfiguracionDocumentosCubit>().actualizarConfiguracion({'logoUrl': null});
    setState(() => _logoUrl = null);
  }

  void _guardarConfiguracion() {
    final data = <String, dynamic>{};
    if (_nombreComercialCtrl.text.isNotEmpty) data['nombreComercial'] = _nombreComercialCtrl.text;
    if (_colorPrimarioCtrl.text.isNotEmpty) data['colorPrimario'] = _colorPrimarioCtrl.text;
    if (_colorSecundarioCtrl.text.isNotEmpty) data['colorSecundario'] = _colorSecundarioCtrl.text;
    if (_colorTextoCtrl.text.isNotEmpty) data['colorTexto'] = _colorTextoCtrl.text;
    if (_textoPieCtrl.text.isNotEmpty) data['textoPiePagina'] = _textoPieCtrl.text;
    data['mostrarPaginacion'] = _mostrarPaginacion;

    context.read<ConfiguracionDocumentosCubit>().actualizarConfiguracion(data);
  }

  void _guardarPlantilla() {
    final data = <String, dynamic>{
      'formatoPapel': _selectedFormato.apiValue,
      'margenSuperior': double.tryParse(_margenSuperiorCtrl.text) ?? 10.0,
      'margenInferior': double.tryParse(_margenInferiorCtrl.text) ?? 10.0,
      'margenIzquierdo': double.tryParse(_margenIzquierdoCtrl.text) ?? 10.0,
      'margenDerecho': double.tryParse(_margenDerechoCtrl.text) ?? 10.0,
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

    context.read<ConfiguracionDocumentosCubit>().actualizarPlantilla(_selectedTipo.apiValue, data);
  }

  Future<void> _mostrarVistaPrevia() async {
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
      colorEncabezado: _colorPrimarioCtrl.text.isNotEmpty ? _colorPrimarioCtrl.text : null,
    );

    final config = ConfiguracionDocumentos(
      id: 'preview',
      empresaId: 'preview',
      nombreComercial: _nombreComercialCtrl.text.isNotEmpty ? _nombreComercialCtrl.text : 'Mi Empresa S.A.C.',
      ruc: '20123456789',
      direccion: 'Av. Ejemplo 123, Lima',
      telefono: '(01) 234-5678',
      email: 'contacto@miempresa.com',
      colorPrimario: _colorPrimarioCtrl.text.isNotEmpty ? _colorPrimarioCtrl.text : '#1565C0',
      colorSecundario: _colorSecundarioCtrl.text.isNotEmpty ? _colorSecundarioCtrl.text : '#1E88E5',
      colorTexto: _colorTextoCtrl.text.isNotEmpty ? _colorTextoCtrl.text : '#333333',
      textoPiePagina: _textoPieCtrl.text.isNotEmpty ? _textoPieCtrl.text : 'Gracias por su preferencia',
      mostrarPaginacion: _mostrarPaginacion,
    );

    final documentConfig = ConfiguracionDocumentoCompleta(
      configuracion: config,
      plantilla: plantilla,
    );

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
        CotizacionDetalle(id: 'd1', cotizacionId: 'preview', descripcion: 'Servicio de consultoria', cantidad: 2, precioUnitario: 500.00, subtotal: 1000.00, total: 1000.00),
        CotizacionDetalle(id: 'd2', cotizacionId: 'preview', descripcion: 'Licencia de software anual', cantidad: 1, precioUnitario: 350.00, subtotal: 350.00, total: 350.00),
        CotizacionDetalle(id: 'd3', cotizacionId: 'preview', descripcion: 'Soporte tecnico mensual', cantidad: 3, precioUnitario: 50.00, descuento: 0, subtotal: 150.00, total: 150.00),
      ],
    );

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
          SnackBar(content: Text('Error al generar vista previa: $e'), backgroundColor: Colors.red),
        );
      }
      return;
    }

    if (!mounted) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text('Vista previa - ${_selectedFormato.label}')),
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
}
