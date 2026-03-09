import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/animated_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/plantilla_servicio.dart';
import '../../domain/repositories/plantilla_servicio_repository.dart';
import '../../domain/repositories/servicio_repository.dart';

class ServicioFormPage extends StatefulWidget {
  final String? servicioId;

  const ServicioFormPage({super.key, this.servicioId});

  bool get isEditing => servicioId != null;

  @override
  State<ServicioFormPage> createState() => _ServicioFormPageState();
}

class _ServicioFormPageState extends State<ServicioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _precioPorHoraController = TextEditingController();
  final _duracionMinutosController = TextEditingController();
  bool _requiereReserva = false;
  bool _requiereDeposito = false;
  bool _visibleMarketplace = true;
  bool _enOferta = false;
  final _precioOfertaController = TextEditingController();
  bool _isLoading = false;

  // Plantilla
  List<PlantillaServicio> _plantillas = [];
  String? _selectedPlantillaId;
  bool _loadingPlantillas = false;

  @override
  void initState() {
    super.initState();
    _loadPlantillas();
    if (widget.isEditing) {
      _loadServicio();
    }
  }

  Future<void> _loadPlantillas() async {
    setState(() => _loadingPlantillas = true);
    final repo = locator<PlantillaServicioRepository>();
    final result = await repo.getAll();
    if (!mounted) return;
    setState(() {
      _loadingPlantillas = false;
      if (result is Success<List<PlantillaServicio>>) {
        _plantillas = result.data;
      }
    });
  }

  Future<void> _loadServicio() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    setState(() => _isLoading = true);
    final repo = locator<ServicioRepository>();
    final result = await repo.getServicio(
      id: widget.servicioId!,
      empresaId: empresaState.context.empresa.id,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result is Success) {
        final s = (result as Success).data;
        _nombreController.text = s.nombre;
        _descripcionController.text = s.descripcion ?? '';
        _precioController.text = s.precio?.toString() ?? '';
        _precioPorHoraController.text = s.precioPorHora?.toString() ?? '';
        _duracionMinutosController.text = s.duracionMinutos?.toString() ?? '';
        _requiereReserva = s.requiereReserva;
        _requiereDeposito = s.requiereDeposito;
        _visibleMarketplace = s.visibleMarketplace;
        _enOferta = s.enOferta;
        _precioOfertaController.text = s.precioOferta?.toString() ?? '';
        _selectedPlantillaId = s.plantillaServicioId;
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _precioPorHoraController.dispose();
    _duracionMinutosController.dispose();
    _precioOfertaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: widget.isEditing ? 'Editar Servicio' : 'Nuevo Servicio',
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GradientContainer(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // --- Seccion: Informacion basica ---
                      _buildSectionCard(
                        icon: Icons.info_outline,
                        title: 'Informacion basica',
                        children: [
                          CustomText(
                            controller: _nombreController,
                            label: 'Nombre del servicio',
                            hintText: 'Ej: Reparacion de laptop',
                            required: true,
                            prefixIcon: const Icon(Icons.room_service, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                          ),
                          const SizedBox(height: 14),
                          CustomText(
                            controller: _descripcionController,
                            label: 'Descripcion (opcional)',
                            hintText: 'Describe el servicio',
                            maxLines: 3,
                            height: null,
                            prefixIcon: const Icon(Icons.description_outlined, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- Seccion: Precios y duracion ---
                      _buildSectionCard(
                        icon: Icons.attach_money,
                        title: 'Precios y duracion',
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  controller: _precioController,
                                  label: 'Precio',
                                  hintText: '0.00',
                                  prefixText: 'S/ ',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                                  borderColor: AppColors.blue1,
                                  colorIcon: AppColors.blue1,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: CustomText(
                                  controller: _precioPorHoraController,
                                  label: 'Precio/Hora',
                                  hintText: '0.00',
                                  prefixText: 'S/ ',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.schedule, size: 18),
                                  borderColor: AppColors.blue1,
                                  colorIcon: AppColors.blue1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          CustomText(
                            controller: _duracionMinutosController,
                            label: 'Duracion estimada (minutos)',
                            hintText: 'Ej: 60',
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- Seccion: Plantilla ---
                      _buildSectionCard(
                        icon: Icons.view_list,
                        title: 'Plantilla de campos',
                        children: [
                          if (_loadingPlantillas)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: LinearProgressIndicator(),
                            )
                          else ...[
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: CustomDropdown<String?>(
                                    label: 'Plantilla',
                                    hintText: 'Sin plantilla',
                                    value: _selectedPlantillaId,
                                    items: [
                                      const DropdownItem(value: null, label: 'Sin plantilla'),
                                      ..._plantillas.map((p) => DropdownItem(
                                            value: p.id,
                                            label: '${p.nombre}${p.campos.isNotEmpty ? " (${p.campos.length} campos)" : ""}',
                                            leading: const Icon(Icons.view_list, size: 16, color: AppColors.blue1),
                                          )),
                                    ],
                                    onChanged: (v) => setState(() => _selectedPlantillaId = v),
                                    borderColor: AppColors.blue1,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                InkWell(
                                  onTap: _showCrearPlantillaDialog,
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue1.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: AppColors.blue1.withValues(alpha: 0.3),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Icon(Icons.add, size: 20, color: AppColors.blue1),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (_selectedPlantillaId != null) ...[
                            const SizedBox(height: 10),
                            _buildPlantillaPreview(),
                          ],
                          const SizedBox(height: 4),
                          AppLabelText(
                            'Los campos de la plantilla se mostraran al crear ordenes de servicio',
                            fontSize: 10,
                            color: Colors.grey.shade500,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- Seccion: Configuracion ---
                      _buildSectionCard(
                        icon: Icons.settings_outlined,
                        title: 'Configuracion',
                        children: [
                          CustomSwitchTile(
                            title: 'Requiere reserva',
                            subtitle: 'El cliente debe reservar cita',
                            value: _requiereReserva,
                            onChanged: (v) => setState(() => _requiereReserva = v),
                            activeTrackColor: AppColors.blue1,
                          ),
                          const SizedBox(height: 6),
                          CustomSwitchTile(
                            title: 'Requiere deposito',
                            subtitle: 'Se cobra un adelanto al cliente',
                            value: _requiereDeposito,
                            onChanged: (v) => setState(() => _requiereDeposito = v),
                            activeTrackColor: AppColors.blue1,
                          ),
                          const SizedBox(height: 6),
                          CustomSwitchTile(
                            title: 'Visible en marketplace',
                            subtitle: 'Mostrar en el catalogo publico',
                            value: _visibleMarketplace,
                            onChanged: (v) => setState(() => _visibleMarketplace = v),
                            activeTrackColor: AppColors.blue1,
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // --- Seccion: Oferta ---
                      _buildSectionCard(
                        icon: Icons.local_offer_outlined,
                        title: 'Oferta',
                        children: [
                          CustomSwitchTile(
                            title: 'En oferta',
                            subtitle: 'Activar precio promocional',
                            value: _enOferta,
                            onChanged: (v) => setState(() => _enOferta = v),
                            activeTrackColor: AppColors.green,
                          ),
                          if (_enOferta) ...[
                            const SizedBox(height: 14),
                            CustomText(
                              controller: _precioOfertaController,
                              label: 'Precio de oferta',
                              hintText: '0.00',
                              prefixText: 'S/ ',
                              keyboardType: TextInputType.number,
                              prefixIcon: const Icon(Icons.sell_outlined, size: 18),
                              borderColor: AppColors.green,
                              colorIcon: AppColors.green,
                            ),
                          ],
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Boton guardar
                      CustomButton(
                        text: widget.isEditing ? 'Guardar cambios' : 'Crear servicio',
                        onPressed: _submit,
                        backgroundColor: AppColors.blue1,
                        borderColor: AppColors.blue1,
                        textColor: Colors.white,
                        height: 44,
                        width: double.infinity,
                        isLoading: _isLoading,
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.8,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de seccion
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: AppColors.blue1, size: 16),
              ),
              const SizedBox(width: 10),
              AppSubtitle(
                title,
                fontSize: 12,
                color: AppColors.blue1,
                font: AppFont.oxygenBold,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _buildPlantillaPreview() {
    final plantilla =
        _plantillas.where((p) => p.id == _selectedPlantillaId).firstOrNull;
    if (plantilla == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.15),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSubtitle(
                  plantilla.campos.isEmpty
                      ? 'Sin campos - "${plantilla.nombre}"'
                      : 'Campos de "${plantilla.nombre}"',
                  fontSize: 11,
                  color: AppColors.blue1,
                  font: AppFont.oxygenBold,
                ),
              ),
              InkWell(
                onTap: () => _showAddCampoDialog(plantilla),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, size: 16, color: AppColors.blue1),
                ),
              ),
            ],
          ),
          if (plantilla.campos.isEmpty) ...[
            const SizedBox(height: 8),
            AppLabelText(
              'Agrega campos con el boton + para definir la informacion que se solicitara en las ordenes',
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
          ],
          if (plantilla.campos.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: plantilla.campos.map((c) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.bluechip,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _tipoCampoIcons[c.tipoCampo] ?? Icons.text_fields,
                        size: 10,
                        color: AppColors.blue1,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        c.nombre,
                        style: TextStyle(
                          fontSize: 9,
                          color: AppColors.blue1,
                          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                        ),
                      ),
                      if (c.esRequerido) ...[
                        const SizedBox(width: 2),
                        const Text('*',
                            style: TextStyle(fontSize: 9, color: Colors.red)),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static const _tipoCampoIcons = {
    'TEXTO': Icons.text_fields,
    'NUMERO': Icons.pin,
    'EMAIL': Icons.email,
    'FECHA': Icons.calendar_today,
    'HORA': Icons.access_time,
    'TEXTO_AREA': Icons.notes,
    'OPCION_SIMPLES': Icons.radio_button_checked,
    'OPCION_MULTIPLE': Icons.checklist,
    'CHECKBOX': Icons.check_box,
    'CHECKBOX_MULTIPLE': Icons.playlist_add_check,
    'ARCHIVO': Icons.attach_file,
    'TELEFONO': Icons.phone,
    'URL': Icons.link,
    'OBJETO': Icons.account_tree_outlined,
  };

  static const _tipoCampoLabels = {
    'TEXTO': 'Texto',
    'NUMERO': 'Numero',
    'EMAIL': 'Email',
    'FECHA': 'Fecha',
    'HORA': 'Hora',
    'TEXTO_AREA': 'Texto largo',
    'OPCION_SIMPLES': 'Seleccion simple',
    'OPCION_MULTIPLE': 'Seleccion multiple',
    'CHECKBOX': 'Checkbox',
    'CHECKBOX_MULTIPLE': 'Checkbox multiple',
    'ARCHIVO': 'Archivo',
    'TELEFONO': 'Telefono',
    'URL': 'URL',
    'OBJETO': 'Objeto (sub-campos)',
  };

  static const _subCampoTipos = {
    'TEXTO': 'Texto',
    'NUMERO': 'Numero',
    'CHECKBOX': 'Si/No',
    'OPCION_SIMPLES': 'Seleccion',
  };

  static const _categoriaLabels = {
    'DIAGNOSTICO': 'Diagnostico',
    'CLIENTE': 'Cliente',
    'TECNICO': 'Tecnico',
    'COMPONENTE': 'Componente',
    'COSTOS': 'Costos',
    'TIEMPOS': 'Tiempos',
    'EQUIPO_CLIENTE': 'Equipo del Cliente',
  };

  void _showAddCampoDialog(PlantillaServicio plantilla) {
    final nombreCtrl = TextEditingController();
    String tipoCampo = 'TEXTO';
    String? categoria;
    bool esRequerido = false;
    final placeholderCtrl = TextEditingController();
    final opcionesCtrl = TextEditingController();
    final subCampos = <Map<String, dynamic>>[];

    showDialog(
      context: context,
      barrierColor: const Color(0x1A000000),
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: AnimatedNeonBorder(
            borderRadius: 14,
            borderWidth: 1.5,
            padding: const EdgeInsets.all(1.5),
            enableHighlight: true,
            highlightWidth: 0.12,
            highlightOpacity: 0.85,
            duration: const Duration(seconds: 5),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.add_circle_outline,
                            color: AppColors.blue1,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const AppTitle(
                                'Agregar campo',
                                fontSize: 14,
                                color: AppColors.blue1,
                              ),
                              AppSubtitle(
                                plantilla.nombre,
                                fontSize: 10,
                                color: Colors.grey.shade600,
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(dialogContext),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Nombre del campo
                    CustomText(
                      controller: nombreCtrl,
                      textCase: TextCase.upper,
                      label: 'Nombre del campo',
                      hintText: 'Ej: Numero de serie',
                      required: true,
                      prefixIcon: const Icon(Icons.label_outline, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),

                    const SizedBox(height: 14),

                    // Tipo de campo
                    CustomDropdown<String>(
                      label: 'Tipo de campo',
                      hintText: 'Selecciona un tipo',
                      value: tipoCampo,
                      items: _tipoCampoLabels.entries
                          .map((e) => DropdownItem(
                                value: e.key,
                                label: e.value,
                                leading: Icon(
                                  _tipoCampoIcons[e.key] ?? Icons.text_fields,
                                  size: 16,
                                  color: AppColors.blue1,
                                ),
                              ))
                          .toList(),
                      onChanged: (v) => setDialogState(() {
                        tipoCampo = v ?? 'TEXTO';
                        if (v != 'OBJETO') subCampos.clear();
                      }),
                      borderColor: AppColors.blue1,
                    ),

                    // Opciones para seleccion simple/multiple
                    if (tipoCampo == 'OPCION_SIMPLES' || tipoCampo == 'OPCION_MULTIPLE') ...[
                      const SizedBox(height: 14),
                      CustomText(
                        controller: opcionesCtrl,
                        textCase: TextCase.upper,
                        label: 'Opciones (separadas por coma)',
                        hintText: 'Opcion 1, Opcion 2, Opcion 3',
                        prefixIcon: const Icon(Icons.list, size: 18),
                        borderColor: AppColors.blue1,
                        colorIcon: AppColors.blue1,
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Categoria
                    CustomDropdown<String?>(
                      label: 'Categoria (opcional)',
                      hintText: 'Sin categoria',
                      value: categoria,
                      items: [
                        const DropdownItem(value: null, label: 'Sin categoria'),
                        ..._categoriaLabels.entries.map(
                          (e) => DropdownItem(value: e.key, label: e.value),
                        ),
                      ],
                      onChanged: (v) => setDialogState(() => categoria = v),
                      borderColor: AppColors.blue1,
                    ),

                    const SizedBox(height: 14),

                    // Placeholder
                    CustomText(
                      controller: placeholderCtrl,
                      textCase: TextCase.upper,
                      label: 'Placeholder (opcional)',
                      hintText: 'Texto de ayuda para el campo',
                      prefixIcon: const Icon(Icons.short_text, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),

                    // Sub-campos para tipo OBJETO
                    if (tipoCampo == 'OBJETO') ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.blue1.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.blue1.withValues(alpha: 0.15),
                            width: 0.8,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.account_tree_outlined, size: 16, color: AppColors.blue1),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: AppSubtitle('Sub-campos', fontSize: 11, color: AppColors.blue1),
                                ),
                                InkWell(
                                  onTap: () => setDialogState(() {
                                    subCampos.add({'nombre': '', 'tipo': 'TEXTO'});
                                  }),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.blue1.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.add, size: 16, color: AppColors.blue1),
                                  ),
                                ),
                              ],
                            ),
                            if (subCampos.isNotEmpty) const SizedBox(height: 10),
                            ...subCampos.asMap().entries.map((entry) {
                              final i = entry.key;
                              final sub = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: CustomText(
                                            controller: TextEditingController(text: sub['nombre'] as String? ?? ''),
                                            textCase: TextCase.upper,
                                            hintText: 'Nombre',
                                            height: 33,
                                            borderColor: AppColors.blue1,
                                            onChanged: (v) => sub['nombre'] = v,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: CustomDropdown<String>(
                                            value: sub['tipo'] as String? ?? 'TEXTO',
                                            hintText: 'Tipo',
                                            items: _subCampoTipos.entries
                                                .map((e) => DropdownItem(value: e.key, label: e.value))
                                                .toList(),
                                            onChanged: (v) => setDialogState(() {
                                              sub['tipo'] = v ?? 'TEXTO';
                                              if (v != 'OPCION_SIMPLES') sub.remove('opciones');
                                            }),
                                            borderColor: AppColors.blue1,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        InkWell(
                                          onTap: () => setDialogState(() => subCampos.removeAt(i)),
                                          borderRadius: BorderRadius.circular(20),
                                          child: Padding(
                                            padding: const EdgeInsets.all(4),
                                            child: Icon(Icons.remove_circle_outline,
                                                size: 16, color: Colors.red.shade400),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (sub['tipo'] == 'OPCION_SIMPLES')
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8, top: 6),
                                        child: CustomText(
                                          controller: TextEditingController(
                                            text: sub['opciones'] is List ? (sub['opciones'] as List).join(', ') : '',
                                          ),
                                          textCase: TextCase.upper,
                                          hintText: 'Opciones separadas por coma',
                                          height: 33,
                                          prefixIcon: const Icon(Icons.list, size: 14),
                                          borderColor: AppColors.blue1,
                                          colorIcon: AppColors.blue1,
                                          onChanged: (v) {
                                            sub['opciones'] = v.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
                                          },
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            }),
                            if (subCampos.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: AppLabelText(
                                  'Agrega sub-campos con el boton +',
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Switch requerido
                    CustomSwitchTile(
                      title: 'Campo requerido',
                      value: esRequerido,
                      onChanged: (v) => setDialogState(() => esRequerido = v),
                      activeTrackColor: AppColors.blue1,
                    ),

                    const SizedBox(height: 20),

                    // Botones
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomButton(
                          text: 'Cancelar',
                          onPressed: () => Navigator.pop(dialogContext),
                          backgroundColor: Colors.transparent,
                          borderColor: AppColors.blue3,
                          borderWidth: 0.6,
                          textColor: AppColors.blue3,
                          enableShadows: false,
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          text: 'Agregar',
                          onPressed: () async {
                            if (nombreCtrl.text.trim().isEmpty) return;
                            if (tipoCampo == 'OBJETO' && subCampos.isEmpty) return;
                            Navigator.pop(dialogContext);

                            List<dynamic>? opcionesData;
                            if (tipoCampo == 'OBJETO') {
                              opcionesData = subCampos
                                  .where((s) => (s['nombre'] as String?)?.isNotEmpty == true)
                                  .map((s) {
                                    final entry = <String, dynamic>{
                                      'nombre': s['nombre'],
                                      'tipo': s['tipo'],
                                    };
                                    if (s['tipo'] == 'OPCION_SIMPLES' && s['opciones'] is List) {
                                      entry['opciones'] = s['opciones'];
                                    }
                                    return entry;
                                  })
                                  .toList();
                            } else if (opcionesCtrl.text.trim().isNotEmpty) {
                              opcionesData = opcionesCtrl.text
                                  .split(',')
                                  .map((e) => e.trim())
                                  .where((e) => e.isNotEmpty)
                                  .toList();
                            }

                            final campoData = <String, dynamic>{
                              'nombre': nombreCtrl.text.trim(),
                              'tipoCampo': tipoCampo,
                              'esRequerido': esRequerido,
                              if (categoria != null) 'categoria': categoria,
                              if (placeholderCtrl.text.trim().isNotEmpty)
                                'placeholder': placeholderCtrl.text.trim(),
                              if (opcionesData != null) 'opciones': opcionesData,
                            };

                            final repo = locator<PlantillaServicioRepository>();
                            final result = await repo.addCampo(
                              plantillaId: plantilla.id,
                              campoData: campoData,
                            );
                            if (!mounted) return;
                            if (result is Success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Campo agregado')),
                              );
                              await _loadPlantillas();
                            } else if (result is Error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text((result as Error).message)),
                              );
                            }
                          },
                          backgroundColor: AppColors.blue1,
                          borderColor: AppColors.blue1,
                          borderWidth: 0.6,
                          textColor: Colors.white,
                          enableShadows: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showCrearPlantillaDialog() {
    final nombreCtrl = TextEditingController();
    final descripcionCtrl = TextEditingController();

    showDialog(
      context: context,
      barrierColor: const Color(0x1A000000),
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: AnimatedNeonBorder(
            borderRadius: 14,
            borderWidth: 1.5,
            padding: const EdgeInsets.all(1.5),
            enableHighlight: true,
            highlightWidth: 0.12,
            highlightOpacity: 0.85,
            duration: const Duration(seconds: 5),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 420),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.view_list, color: AppColors.blue1, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: AppTitle(
                            'Nueva Plantilla',
                            fontSize: 14,
                            color: AppColors.blue1,
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.pop(dialogContext),
                          borderRadius: BorderRadius.circular(20),
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(Icons.close, size: 18, color: Colors.grey.shade400),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    CustomText(
                      controller: nombreCtrl,
                      textCase: TextCase.upper,
                      label: 'Nombre',
                      hintText: 'Ej: Reparacion de PC',
                      required: true,
                      prefixIcon: const Icon(Icons.label_outline, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),

                    const SizedBox(height: 16),

                    CustomText(
                      controller: descripcionCtrl,
                      textCase: TextCase.upper,
                      label: 'Descripcion (opcional)',
                      hintText: 'Describe el proposito de esta plantilla',
                      maxLines: 3,
                      height: null,
                      prefixIcon: const Icon(Icons.description_outlined, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        CustomButton(
                          text: 'Cancelar',
                          onPressed: () => Navigator.pop(dialogContext),
                          backgroundColor: Colors.transparent,
                          borderColor: AppColors.blue3,
                          borderWidth: 0.6,
                          textColor: AppColors.blue3,
                          enableShadows: false,
                        ),
                        const SizedBox(width: 8),
                        CustomButton(
                          text: 'Crear',
                          onPressed: () async {
                            if (nombreCtrl.text.trim().isEmpty) return;
                            Navigator.pop(dialogContext);
                            final repo = locator<PlantillaServicioRepository>();
                            final result = await repo.crear(
                              nombre: nombreCtrl.text.trim(),
                              descripcion: descripcionCtrl.text.trim().isEmpty
                                  ? null
                                  : descripcionCtrl.text.trim(),
                            );
                            if (!mounted) return;
                            if (result is Success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Plantilla creada')),
                              );
                              // Recargar plantillas y seleccionar la nueva
                              await _loadPlantillas();
                              if (_plantillas.isNotEmpty) {
                                setState(() {
                                  _selectedPlantillaId = _plantillas.last.id;
                                });
                              }
                            } else if (result is Error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text((result as Error).message)),
                              );
                            }
                          },
                          backgroundColor: AppColors.blue1,
                          borderColor: AppColors.blue1,
                          borderWidth: 0.6,
                          textColor: Colors.white,
                          enableShadows: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresaId = empresaState.context.empresa.id;
    final repo = locator<ServicioRepository>();

    setState(() => _isLoading = true);

    final result = widget.isEditing
        ? await repo.actualizar(
            id: widget.servicioId!,
            empresaId: empresaId,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            precio: double.tryParse(_precioController.text),
            precioPorHora: double.tryParse(_precioPorHoraController.text),
            duracionMinutos: int.tryParse(_duracionMinutosController.text),
            requiereReserva: _requiereReserva,
            requiereDeposito: _requiereDeposito,
            visibleMarketplace: _visibleMarketplace,
            enOferta: _enOferta,
            precioOferta: double.tryParse(_precioOfertaController.text),
            plantillaServicioId: _selectedPlantillaId,
          )
        : await repo.crear(
            empresaId: empresaId,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            precio: double.tryParse(_precioController.text),
            precioPorHora: double.tryParse(_precioPorHoraController.text),
            duracionMinutos: int.tryParse(_duracionMinutosController.text),
            requiereReserva: _requiereReserva,
            requiereDeposito: _requiereDeposito,
            visibleMarketplace: _visibleMarketplace,
            enOferta: _enOferta,
            precioOferta: double.tryParse(_precioOfertaController.text),
            plantillaServicioId: _selectedPlantillaId,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(widget.isEditing
                ? 'Servicio actualizado'
                : 'Servicio creado')),
      );
      context.pop(true);
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Error).message)),
      );
    }
  }
}
