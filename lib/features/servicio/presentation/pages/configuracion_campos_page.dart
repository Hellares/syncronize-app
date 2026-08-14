import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../bloc/configuracion_campos/configuracion_campos_cubit.dart';
import '../bloc/configuracion_campos/configuracion_campos_state.dart';
import '../../../empresa/presentation/widgets/empresa_drawer.dart';
import '../constants/tipos_campo_servicio.dart';

class ConfiguracionCamposPage extends StatelessWidget {
  const ConfiguracionCamposPage({super.key});

  // Definicion compartida: presentation/constants/tipos_campo_servicio.dart
  static const _categoriaLabels = kCategoriaLabels;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ConfiguracionCamposCubit>()..load(),
      child: Scaffold(
        appBar: AppBar(title: const Text('Campos de Servicio')),
        drawer: const EmpresaDrawer(),
        floatingActionButton: Builder(
          builder: (context) => FloatingActionButton(
            onPressed: () => _showCreateDialog(context),
            child: const Icon(Icons.add),
          ),
        ),
        body: BlocBuilder<ConfiguracionCamposCubit, ConfiguracionCamposState>(
          builder: (context, state) {
            if (state is ConfiguracionCamposLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ConfiguracionCamposError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.read<ConfiguracionCamposCubit>().load(),
                      child: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final campos = state is ConfiguracionCamposLoaded ? state.campos : [];

            if (campos.isEmpty) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.dashboard_customize, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No hay campos configurados',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                    SizedBox(height: 8),
                    Text('Crea campos personalizados para tus órdenes de servicio',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              );
            }

            // Group by category
            final grouped = <String?, List<dynamic>>{};
            for (final campo in campos) {
              final cat = campo.categoria;
              grouped.putIfAbsent(cat, () => []).add(campo);
            }

            return ReorderableListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: campos.length,
              onReorder: (oldIndex, newIndex) {
                if (newIndex > oldIndex) newIndex--;
                final ids = campos.map((c) => c.id).toList().cast<String>();
                final item = ids.removeAt(oldIndex);
                ids.insert(newIndex, item);
                context.read<ConfiguracionCamposCubit>().reorder(ids);
              },
              itemBuilder: (context, index) {
                final campo = campos[index];
                return Card(
                  key: ValueKey(campo.id),
                  child: ListTile(
                    leading: Icon(
                      tipoCampoIcon(campo.tipoCampo),
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(campo.nombre),
                    subtitle: Text(
                      [
                        tipoCampoLabel(campo.tipoCampo),
                        if (campo.categoria != null)
                          _categoriaLabels[campo.categoria] ?? campo.categoria!,
                      ].join(' · '),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (campo.esRequerido)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Requerido',
                                style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
                          ),
                        const SizedBox(width: 8),
                        const Icon(Icons.drag_handle, color: Colors.grey),
                      ],
                    ),
                    onTap: () => _showEditDialog(context, campo),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  // Definicion compartida: presentation/constants/tipos_campo_servicio.dart
  static const _subCampoTipos = kSubCampoTipos;

  void _showCreateDialog(BuildContext context) {
    final cubit = context.read<ConfiguracionCamposCubit>();
    final nameController = TextEditingController();
    String selectedTipoCampo = 'TEXTO';
    String? selectedCategoria;
    bool esRequerido = false;
    final subCampos = <Map<String, dynamic>>[];

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setState) => AlertDialog(
          title: const Text('Nuevo Campo'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    controller: nameController,
                    label: 'Nombre del campo',
                    borderColor: AppColors.blue1,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTipoCampo,
                    decoration: const InputDecoration(labelText: 'Tipo de campo'),
                    items: kTiposCampoServicio
                        .map((t) => DropdownMenuItem(
                            value: t, child: Text(tipoCampoLabel(t))))
                        .toList(),
                    onChanged: (v) => setState(() {
                      selectedTipoCampo = v!;
                      if (v != 'OBJETO') subCampos.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selectedCategoria,
                    decoration: const InputDecoration(labelText: 'Categoría (opcional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                      ..._categoriaLabels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                    ],
                    onChanged: (v) => setState(() => selectedCategoria = v),
                  ),
                  const SizedBox(height: 16),
                  CustomSwitchTile(
                    title: 'Campo requerido',
                    value: esRequerido,
                    onChanged: (v) => setState(() => esRequerido = v),
                  ),
                  // Sub-campos para tipo OBJETO
                  if (selectedTipoCampo == 'OBJETO') ...[
                    const Divider(),
                    Row(
                      children: [
                        const Icon(Icons.account_tree_outlined, size: 16),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text('Sub-campos',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ),
                        IconButton(
                          icon: const Icon(Icons.add_circle_outline, size: 20),
                          onPressed: () => setState(() {
                            subCampos.add({'nombre': '', 'tipo': 'TEXTO'});
                          }),
                        ),
                      ],
                    ),
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
                                  child: TextField(
                                    decoration: InputDecoration(
                                      hintText: 'Nombre',
                                      hintStyle: const TextStyle(fontSize: 12),
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 10),
                                      border: const OutlineInputBorder(),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                    controller: TextEditingController(text: sub['nombre'] as String? ?? ''),
                                    onChanged: (v) => sub['nombre'] = v,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<String>(
                                    initialValue: sub['tipo'] as String? ?? 'TEXTO',
                                    isDense: true,
                                    decoration: const InputDecoration(
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    items: _subCampoTipos.entries
                                        .map((e) => DropdownMenuItem(
                                            value: e.key, child: Text(e.value)))
                                        .toList(),
                                    onChanged: (v) => setState(() {
                                      sub['tipo'] = v!;
                                      if (v != 'OPCION_SIMPLES') sub.remove('opciones');
                                    }),
                                  ),
                                ),
                                IconButton(
                                  icon: Icon(Icons.remove_circle_outline,
                                      size: 18, color: Colors.red.shade400),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () => setState(() => subCampos.removeAt(i)),
                                ),
                              ],
                            ),
                            // Opciones para sub-campo tipo OPCION_SIMPLES
                            if (sub['tipo'] == 'OPCION_SIMPLES')
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 6),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Opciones separadas por coma (ej: AM5, AM4, LGA1851)',
                                    hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 8),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.list, size: 16),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  controller: TextEditingController(
                                    text: sub['opciones'] is List
                                        ? (sub['opciones'] as List).join(', ')
                                        : '',
                                  ),
                                  onChanged: (v) {
                                    sub['opciones'] = v
                                        .split(',')
                                        .map((s) => s.trim())
                                        .where((s) => s.isNotEmpty)
                                        .toList();
                                  },
                                ),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (subCampos.isEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Agrega sub-campos con el botón +',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            CustomButton(
              text: 'Cancelar',
              onPressed: () => Navigator.pop(dialogContext),
              backgroundColor: Colors.transparent,
              borderColor: AppColors.blue3,
              borderWidth: 0.6,
              textColor: AppColors.blue3,
              enableShadows: false,
            ),
            CustomButton(
              text: 'Crear',
              backgroundColor: AppColors.blue1,
              borderColor: AppColors.blue1,
              borderWidth: 0.6,
              textColor: Colors.white,
              enableShadows: false,
              onPressed: () {
                if (nameController.text.trim().isEmpty) return;
                if (selectedTipoCampo == 'OBJETO' && subCampos.isEmpty) return;
                Navigator.pop(dialogContext);

                // Build opciones for OBJETO type
                List<dynamic>? opciones;
                if (selectedTipoCampo == 'OBJETO') {
                  opciones = subCampos
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
                }

                cubit.create(
                  nombre: nameController.text.trim(),
                  tipoCampo: selectedTipoCampo,
                  categoria: selectedCategoria,
                  esRequerido: esRequerido,
                  opciones: opciones,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, dynamic campo) {
    final cubit = context.read<ConfiguracionCamposCubit>();
    final nameController = TextEditingController(text: campo.nombre);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Editar Campo'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                controller: nameController,
                label: 'Nombre del campo',
                borderColor: AppColors.blue1,
              ),
            ],
          ),
        ),
        actions: [
          CustomButton(
            text: 'Eliminar',
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.delete(campo.id);
            },
            backgroundColor: Colors.transparent,
            borderColor: Colors.red,
            borderWidth: 0.6,
            textColor: Colors.red,
            enableShadows: false,
          ),
          CustomButton(
            text: 'Cancelar',
            onPressed: () => Navigator.pop(dialogContext),
            backgroundColor: Colors.transparent,
            borderColor: AppColors.blue3,
            borderWidth: 0.6,
            textColor: AppColors.blue3,
            enableShadows: false,
          ),
          CustomButton(
            text: 'Guardar',
            backgroundColor: AppColors.blue1,
            borderColor: AppColors.blue1,
            borderWidth: 0.6,
            textColor: Colors.white,
            enableShadows: false,
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              cubit.update(
                id: campo.id,
                nombre: nameController.text.trim(),
              );
            },
          ),
        ],
      ),
    );
  }
}
