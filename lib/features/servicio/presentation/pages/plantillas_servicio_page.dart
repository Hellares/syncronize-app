import 'package:flutter/material.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/widgets/empresa_drawer.dart';
import '../../domain/entities/plantilla_servicio.dart';
import '../../domain/repositories/plantilla_servicio_repository.dart';

class PlantillasServicioPage extends StatefulWidget {
  const PlantillasServicioPage({super.key});

  @override
  State<PlantillasServicioPage> createState() => _PlantillasServicioPageState();
}

class _PlantillasServicioPageState extends State<PlantillasServicioPage> {
  List<PlantillaServicio> _plantillas = [];
  bool _isLoading = true;
  String? _error;

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
      } else if (result is Error) {
        _error = (result as Error).message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Plantillas de Servicio')),
      drawer: const EmpresaDrawer(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPlantillaDialog(),
        child: const Icon(Icons.add),
      ),
      body: _buildBody(),
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
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }

    if (_plantillas.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.view_list, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No hay plantillas creadas',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
            SizedBox(height: 8),
            Text(
              'Crea plantillas con campos personalizados\npara asignarlas a tus servicios',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _plantillas.length,
        itemBuilder: (context, index) {
          final p = _plantillas[index];
          return Card(
            child: ExpansionTile(
              leading: const Icon(Icons.view_list, color: Colors.blue),
              title: Text(p.nombre, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                [
                  '${p.campos.length} campos',
                  if (p.serviciosCount != null && p.serviciosCount! > 0)
                    '${p.serviciosCount} servicios',
                  if (p.descripcion != null) p.descripcion!,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _showPlantillaDialog(plantilla: p);
                  if (v == 'delete') _confirmDelete(p);
                  if (v == 'add_campo') _showAddCampoDialog(p);
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'add_campo', child: Text('Agregar campo')),
                  const PopupMenuItem(value: 'edit', child: Text('Editar')),
                  const PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                ],
              ),
              children: [
                if (p.campos.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Sin campos. Agrega campos a esta plantilla.',
                        style: TextStyle(color: Colors.grey)),
                  )
                else
                  ...p.campos.map((c) => ListTile(
                        dense: true,
                        leading: Icon(
                          _tipoCampoIcons[c.tipoCampo] ?? Icons.text_fields,
                          size: 20,
                          color: Colors.blue.shade700,
                        ),
                        title: Text(c.nombre, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(
                          [
                            _tipoCampoLabels[c.tipoCampo] ?? c.tipoCampo,
                            if (c.categoria != null)
                              _categoriaLabels[c.categoria] ?? c.categoria!,
                          ].join(' · '),
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: c.esRequerido
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text('Requerido',
                                    style: TextStyle(fontSize: 10, color: Colors.red.shade700)),
                              )
                            : null,
                      )),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showPlantillaDialog({PlantillaServicio? plantilla}) {
    final nombreCtrl = TextEditingController(text: plantilla?.nombre ?? '');
    final descripcionCtrl = TextEditingController(text: plantilla?.descripcion ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(plantilla != null ? 'Editar Plantilla' : 'Nueva Plantilla'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nombreCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nombre *',
                  hintText: 'Ej: Reparación de PC',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descripcionCtrl,
                decoration: const InputDecoration(
                  labelText: 'Descripción (opcional)',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nombreCtrl.text.trim().isEmpty) return;
              Navigator.pop(dialogContext);
              final repo = locator<PlantillaServicioRepository>();
              final result = plantilla != null
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
                    content: Text(plantilla != null
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
            child: Text(plantilla != null ? 'Guardar' : 'Crear'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(PlantillaServicio plantilla) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar plantilla'),
        content: Text('¿Eliminar "${plantilla.nombre}"? Los servicios vinculados perderán esta plantilla.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogContext);
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
            child: const Text('Eliminar'),
          ),
        ],
      ),
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
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: Text('Agregar campo a "${plantilla.nombre}"'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nombreCtrl,
                    decoration: const InputDecoration(labelText: 'Nombre del campo *'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: tipoCampo,
                    decoration: const InputDecoration(labelText: 'Tipo de campo'),
                    items: _tipoCampoLabels.entries
                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                        .toList(),
                    onChanged: (v) => setDialogState(() {
                      tipoCampo = v!;
                      if (v != 'OBJETO') subCampos.clear();
                    }),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: categoria,
                    decoration: const InputDecoration(labelText: 'Categoría (opcional)'),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Sin categoría')),
                      ..._categoriaLabels.entries
                          .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))),
                    ],
                    onChanged: (v) => setDialogState(() => categoria = v),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: placeholderCtrl,
                    decoration: const InputDecoration(labelText: 'Placeholder (opcional)'),
                  ),
                  if (tipoCampo == 'OPCION_SIMPLES' || tipoCampo == 'OPCION_MULTIPLE') ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: opcionesCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Opciones (separadas por coma)',
                        hintText: 'Opción 1, Opción 2, Opción 3',
                      ),
                    ),
                  ],
                  // Sub-campos para tipo OBJETO
                  if (tipoCampo == 'OBJETO') ...[
                    const Divider(height: 24),
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
                          onPressed: () => setDialogState(() {
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
                                    decoration: const InputDecoration(
                                      hintText: 'Nombre',
                                      hintStyle: TextStyle(fontSize: 12),
                                      isDense: true,
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                      border: OutlineInputBorder(),
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
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                      border: OutlineInputBorder(),
                                    ),
                                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                                    items: _subCampoTipos.entries
                                        .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                        .toList(),
                                    onChanged: (v) => setDialogState(() {
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
                                  onPressed: () => setDialogState(() => subCampos.removeAt(i)),
                                ),
                              ],
                            ),
                            if (sub['tipo'] == 'OPCION_SIMPLES')
                              Padding(
                                padding: const EdgeInsets.only(left: 8, top: 6),
                                child: TextField(
                                  decoration: InputDecoration(
                                    hintText: 'Opciones separadas por coma (ej: AM5, AM4, LGA1851)',
                                    hintStyle: TextStyle(fontSize: 10, color: Colors.grey.shade400),
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.list, size: 16),
                                    prefixIconConstraints: const BoxConstraints(minWidth: 32),
                                  ),
                                  style: const TextStyle(fontSize: 12),
                                  controller: TextEditingController(
                                    text: sub['opciones'] is List ? (sub['opciones'] as List).join(', ') : '',
                                  ),
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
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('Agrega sub-campos con el botón +',
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                      ),
                  ],
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Campo requerido'),
                    value: esRequerido,
                    onChanged: (v) => setDialogState(() => esRequerido = v),
                  ),
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
              onPressed: () async {
                if (nombreCtrl.text.trim().isEmpty) return;
                if (tipoCampo == 'OBJETO' && subCampos.isEmpty) return;
                Navigator.pop(dialogContext);

                // Build opciones
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
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );
  }

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
  };

  static const _subCampoTipos = {
    'TEXTO': 'Texto',
    'NUMERO': 'Número',
    'CHECKBOX': 'Sí/No',
    'OPCION_SIMPLES': 'Selección',
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
}
