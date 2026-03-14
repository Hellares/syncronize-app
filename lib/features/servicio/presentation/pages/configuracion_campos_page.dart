import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../bloc/configuracion_campos/configuracion_campos_cubit.dart';
import '../bloc/configuracion_campos/configuracion_campos_state.dart';
import '../../../empresa/presentation/widgets/empresa_drawer.dart';

class ConfiguracionCamposPage extends StatelessWidget {
  const ConfiguracionCamposPage({super.key});

  static const _tipoCampoLabels = {
    'TEXTO': 'Texto',
    'NUMERO': 'Número',
    'EMAIL': 'Email',
    'FECHA': 'Fecha',
    'HORA': 'Hora',
    'TEXTO_AREA': 'Texto largo',
    'OPCION_SIMPLES': 'Selección simple',
    'OPCION_MULTIPLE': 'Selección múltiple',
    'CHECKBOX': 'Checkbox',
    'CHECKBOX_MULTIPLE': 'Checkbox múltiple',
    'ARCHIVO': 'Archivo',
    'TELEFONO': 'Teléfono',
    'URL': 'URL',
    'OBJETO': 'Objeto (sub-campos)',
    'PATRON_DESBLOQUEO': 'Patrón desbloqueo',
    'INSPECCION_VISUAL': 'Inspección visual',
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
    'DIAGNOSTICO': 'Diagnóstico',
    'CLIENTE': 'Cliente',
    'TECNICO': 'Técnico',
    'COMPONENTE': 'Componente',
    'COSTOS': 'Costos',
    'TIEMPOS': 'Tiempos',
    'EQUIPO_CLIENTE': 'Equipo del Cliente',
  };

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
                      _tipoCampoIcons[campo.tipoCampo] ?? Icons.text_fields,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: Text(campo.nombre),
                    subtitle: Text(
                      [
                        _tipoCampoLabels[campo.tipoCampo] ?? campo.tipoCampo,
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

  static const _subCampoTipos = {
    'TEXTO': 'Texto',
    'NUMERO': 'Número',
    'CHECKBOX': 'Sí/No',
    'OPCION_SIMPLES': 'Selección',
  };

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
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nombre del campo'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedTipoCampo,
                    decoration: const InputDecoration(labelText: 'Tipo de campo'),
                    items: _tipoCampoLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setState(() {
                      selectedTipoCampo = v!;
                      if (v != 'OBJETO') subCampos.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategoria,
                    decoration: const InputDecoration(labelText: 'Categoría (opcional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                      ..._categoriaLabels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                    ],
                    onChanged: (v) => setState(() => selectedCategoria = v),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Campo requerido'),
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
                                    value: sub['tipo'] as String? ?? 'TEXTO',
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
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
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
              child: const Text('Crear'),
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
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nombre del campo'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              cubit.delete(campo.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              cubit.update(
                id: campo.id,
                nombre: nameController.text.trim(),
              );
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
