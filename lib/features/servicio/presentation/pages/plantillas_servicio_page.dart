import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/core/widgets/animated_confirm_dialog.dart';
import 'package:syncronize/core/widgets/animated_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/core/widgets/floating_button_text.dart';
import 'package:syncronize/core/widgets/popup_item.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/plantilla_servicio.dart';
import '../../domain/repositories/plantilla_servicio_repository.dart';

class PlantillasServicioPage extends StatefulWidget {
  const PlantillasServicioPage({super.key});

  @override
  State<PlantillasServicioPage> createState() => _PlantillasServicioPageState();
}

class _PlantillasServicioPageState extends State<PlantillasServicioPage> {
  List<PlantillaServicio> _plantillas = [];
  List<PlantillaServicio> _filtered = [];
  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    final repo = locator<PlantillaServicioRepository>();
    final result = await repo.getAll();
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result is Success<List<PlantillaServicio>>) {
        _plantillas = result.data;
        _applySearch();
      } else if (result is Error) {
        _error = (result as Error).message;
      }
    });
  }

  void _applySearch() {
    if (_searchQuery.isEmpty) {
      _filtered = _plantillas;
    } else {
      final q = _searchQuery.toLowerCase();
      _filtered = _plantillas.where((p) {
        return p.nombre.toLowerCase().contains(q) ||
            (p.descripcion?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Plantillas de Servicio',
      ),
      body: GradientContainer(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CustomSearchField(
                borderColor: AppColors.blue1,
                hintText: 'Buscar por nombre o descripcion',
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                    _applySearch();
                  });
                },
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
      floatingActionButton: FloatingButtonText(
        width: 140,
        onPressed: () => _showPlantillaDialog(),
        icon: Icons.add,
        label: 'Nueva Plantilla',
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.view_list_outlined, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No se encontraron plantillas'
                  : 'No hay plantillas creadas',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            if (_searchQuery.isEmpty)
              const Text(
                'Presiona el boton + para crear una',
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        itemCount: _filtered.length,
        itemBuilder: (context, index) {
          final p = _filtered[index];
          return _PlantillaListTile(
            plantilla: p,
            onEdit: () => _showPlantillaDialog(plantilla: p),
            onDelete: () => _confirmDelete(p),
            onAddCampo: () => _showAddCampoDialog(p),
          );
        },
      ),
    );
  }

  void _showPlantillaDialog({PlantillaServicio? plantilla}) {
    final nombreCtrl = TextEditingController(text: plantilla?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: plantilla?.descripcion ?? '');
    final isEditing = plantilla != null;

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
                    // Header con icono
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.blue1.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            isEditing ? Icons.edit_outlined : Icons.view_list,
                            color: AppColors.blue1,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: AppTitle(
                            isEditing ? 'Editar Plantilla' : 'Nueva Plantilla',
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

                    // Campo nombre
                    CustomText(
                      controller: nombreCtrl,
                      label: 'Nombre',
                      hintText: 'Ej: Reparacion de PC',
                      required: true,
                      prefixIcon: const Icon(Icons.label_outline, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),

                    const SizedBox(height: 16),

                    // Campo descripcion
                    CustomText(
                      controller: descripcionCtrl,
                      label: 'Descripcion (opcional)',
                      hintText: 'Describe el proposito de esta plantilla',
                      maxLines: 3,
                      height: null,
                      prefixIcon: const Icon(Icons.description_outlined, size: 18),
                      borderColor: AppColors.blue1,
                      colorIcon: AppColors.blue1,
                    ),

                    const SizedBox(height: 24),

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
                          text: isEditing ? 'Guardar' : 'Crear',
                          onPressed: () async {
                            if (nombreCtrl.text.trim().isEmpty) return;
                            Navigator.pop(dialogContext);
                            final repo = locator<PlantillaServicioRepository>();
                            final result = isEditing
                                ? await repo.actualizar(
                                    id: plantilla.id,
                                    nombre: nombreCtrl.text.trim(),
                                    descripcion: descripcionCtrl.text.trim().isEmpty
                                        ? null
                                        : descripcionCtrl.text.trim(),
                                  )
                                : await repo.crear(
                                    nombre: nombreCtrl.text.trim(),
                                    descripcion: descripcionCtrl.text.trim().isEmpty
                                        ? null
                                        : descripcionCtrl.text.trim(),
                                  );
                            if (!mounted) return;
                            if (result is Success) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEditing
                                      ? 'Plantilla actualizada'
                                      : 'Plantilla creada'),
                                ),
                              );
                              _load();
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

  void _confirmDelete(PlantillaServicio plantilla) {
    AnimatedConfirmDialog.show(
      context: context,
      title: 'Eliminar plantilla',
      message: 'Eliminar "${plantilla.nombre}"? Los servicios vinculados perderan esta plantilla.',
      confirmText: 'Eliminar',
      cancelText: 'Cancelar',
      confirmButtonColor: Colors.red,
      onConfirm: () async {
        final repo = locator<PlantillaServicioRepository>();
        final result = await repo.eliminar(plantilla.id);
        if (!mounted) return;
        if (result is Success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Plantilla eliminada')),
          );
          _load();
        } else if (result is Error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text((result).message)),
          );
        }
      },
    );
  }

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
                              _load();
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
    'PATRON_DESBLOQUEO': 'Patron desbloqueo',
    'INSPECCION_VISUAL': 'Inspeccion visual',
  };

  static const _subCampoTipos = {
    'TEXTO': 'Texto',
    'NUMERO': 'Numero',
    'CHECKBOX': 'Si/No',
    'OPCION_SIMPLES': 'Seleccion',
  };

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
    'PATRON_DESBLOQUEO': Icons.pattern,
    'INSPECCION_VISUAL': Icons.car_crash_outlined,
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
}

// ─────────────────────────────────────────────────────────────
// Card tile con el mismo estilo que OrdenCompraListTile
// ─────────────────────────────────────────────────────────────
class _PlantillaListTile extends StatelessWidget {
  final PlantillaServicio plantilla;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onAddCampo;

  const _PlantillaListTile({
    required this.plantilla,
    required this.onEdit,
    required this.onDelete,
    required this.onAddCampo,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        shadowStyle: ShadowStyle.glow,
        borderColor: AppColors.blueborder,
        borderWidth: 0.8,
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 8),
                Container(height: 1, color: Colors.grey.shade200),
                const SizedBox(height: 8),
                _buildCamposPreview(),
                const SizedBox(height: 8),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.blue1.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.view_list,
            color: AppColors.blue1,
            size: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                plantilla.nombre,
                style: TextStyle(
                  fontSize: 13,
                  fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (plantilla.descripcion != null && plantilla.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 3),
                Text(
                  plantilla.descripcion!,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade700,
                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
        CustomActionMenu(
          items: [
            ActionMenuItem(
              type: ActionMenuType.addField,
              label: 'Agregar campo',
              icon: Icons.add_circle_outline,
              color: AppColors.blue1,
              onTap: onAddCampo,
            ),
            ActionMenuItem(
              type: ActionMenuType.edit,
              label: 'Editar',
              icon: Icons.edit_outlined,
              color: AppColors.blue1,
              onTap: onEdit,
            ),
            ActionMenuItem(
              type: ActionMenuType.delete,
              label: 'Eliminar',
              icon: Icons.delete_outline,
              color: Colors.red,
              onTap: onDelete,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCamposPreview() {
    if (plantilla.campos.isEmpty) {
      return Text(
        'Sin campos configurados',
        style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: plantilla.campos.take(5).map((c) {
        final icon = _PlantillasServicioPageState._tipoCampoIcons[c.tipoCampo] ?? Icons.text_fields;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.bluechip,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 10, color: AppColors.blue1),
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
                const Text('*', style: TextStyle(fontSize: 9, color: Colors.red)),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.bluechip,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.dashboard_customize_outlined, size: 10, color: AppColors.blue1),
              const SizedBox(width: 3),
              AppSubtitle(
                '${plantilla.campos.length} campos',
                fontSize: 9,
                color: AppColors.blue1,
              ),
            ],
          ),
        ),
        if (plantilla.serviciosCount != null && plantilla.serviciosCount! > 0) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.bluechip,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.room_service_outlined, size: 10, color: AppColors.blue1),
                const SizedBox(width: 3),
                AppSubtitle(
                  '${plantilla.serviciosCount} servicios',
                  fontSize: 9,
                  color: AppColors.blue1,
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: (plantilla.isActive ? AppColors.green : Colors.grey).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: (plantilla.isActive ? AppColors.green : Colors.grey).withValues(alpha: 0.4),
              width: 0.6,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                plantilla.isActive ? Icons.check_circle : Icons.cancel,
                size: 10,
                color: plantilla.isActive ? AppColors.green : Colors.grey,
              ),
              const SizedBox(width: 4),
              AppSubtitle(
                plantilla.isActive ? 'ACTIVA' : 'INACTIVA',
                fontSize: 9,
                color: plantilla.isActive ? AppColors.green : Colors.grey,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
