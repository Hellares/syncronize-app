import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/constants/storage_constants.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';
import 'package:syncronize/core/storage/secure_storage_service.dart';

import '../../domain/entities/atributo_plantilla.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/repositories/plantilla_repository.dart';
import '../bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_state.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';

/// Diálogo para crear o editar una plantilla de atributos
class PlantillaFormDialog extends StatefulWidget {
  final AtributoPlantilla? plantilla; // null = crear, no-null = editar
  final String empresaId;

  const PlantillaFormDialog({
    super.key,
    this.plantilla,
    required this.empresaId,
  });

  @override
  State<PlantillaFormDialog> createState() => _PlantillaFormDialogState();
}

class _PlantillaFormDialogState extends State<PlantillaFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  String? _icono;
  String? _categoriaId;
  List<_AtributoSeleccionado> _atributosSeleccionados = [];
  String? _currentEmpresaId; // Track para detectar cambios de empresa

  bool get _esEdicion => widget.plantilla != null;

  @override
  void initState() {
    super.initState();
    // Guardar el empresaId inicial
    _currentEmpresaId = widget.empresaId;

    if (_esEdicion) {
      _nombreController.text = widget.plantilla!.nombre;
      _descripcionController.text = widget.plantilla!.descripcion ?? '';
      _icono = widget.plantilla!.icono;
      _categoriaId = widget.plantilla!.categoriaId;
      _atributosSeleccionados = widget.plantilla!.atributos
          .map((pa) => _AtributoSeleccionado(
                atributoId: pa.atributoId,
                nombre: pa.atributo.nombre,
                clave: pa.atributo.clave,
                tipo: pa.atributo.tipo,
                orden: pa.orden,
                requeridoOverride: pa.requeridoOverride,
                valoresOverride: pa.valoresOverride,
                valoresDisponibles: pa.atributo.valores,
              ))
          .toList();
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<EmpresaContextCubit, EmpresaContextState>(
      listener: (context, empresaState) {
        if (empresaState is EmpresaContextLoaded) {
          final newEmpresaId = empresaState.context.empresa.id;

          // Detectar si cambió la empresa
          if (_currentEmpresaId != null && _currentEmpresaId != newEmpresaId) {
            // Opción 2: Actualizar los atributos con la nueva empresa
            // (aunque el diálogo se cerrará, esto evita errores)
            context.read<ProductoAtributoCubit>().loadAtributos(newEmpresaId);

            // Opción 1: Cerrar el diálogo automáticamente
            Navigator.of(context).pop();

            // Mostrar notificación al usuario
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Diálogo cerrado: cambiaste a ${empresaState.context.empresa.nombre}'),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 2),
              ),
            );
          }
        }
      },
      child: BlocProvider(
        create: (_) => locator<ProductoAtributoCubit>()..loadAtributos(widget.empresaId),
        child: AlertDialog(
        title: Text(_esEdicion ? 'Editar Plantilla' : 'Nueva Plantilla'),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre
                  TextFormField(
                    controller: _nombreController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre *',
                      hintText: 'Ej: Motherboard, Procesador, RAM',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Ingresa un nombre';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  TextFormField(
                    controller: _descripcionController,
                    decoration: const InputDecoration(
                      labelText: 'Descripción',
                      hintText: 'Describe para qué se usa esta plantilla',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),

                  // Icono (emoji picker simple)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Icono: ${_icono ?? "(ninguno)"}',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                      TextButton(
                        onPressed: () => _seleccionarIcono(context),
                        child: const Text('Cambiar'),
                      ),
                    ],
                  ),

                  const Divider(height: 32),

                  // Atributos seleccionados
                  const Text(
                    'Atributos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  if (_atributosSeleccionados.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 20),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Agrega atributos a esta plantilla',
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    ReorderableListView(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      onReorder: _reordenarAtributos,
                      children: _atributosSeleccionados
                          .asMap()
                          .entries
                          .map((entry) => _buildAtributoItem(entry.key, entry.value))
                          .toList(),
                    ),

                  const SizedBox(height: 12),

                  // Botón agregar atributo
                  BlocBuilder<ProductoAtributoCubit, ProductoAtributoState>(
                    builder: (context, state) {
                      return OutlinedButton.icon(
                        onPressed: state is ProductoAtributoLoaded
                            ? () => _mostrarSelectorAtributos(context, state.atributos)
                            : null,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar atributo'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: _guardar,
            child: Text(_esEdicion ? 'Actualizar' : 'Crear'),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildAtributoItem(int index, _AtributoSeleccionado atributo) {
    final tieneValores = atributo.valoresDisponibles.isNotEmpty;
    final cantidadOverride = atributo.valoresOverride?.length ?? atributo.valoresDisponibles.length;

    return Card(
      key: ValueKey(atributo.atributoId),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            // Drag handle + índice
            const Icon(Icons.drag_handle, size: 20, color: Colors.grey),
            const SizedBox(width: 4),
            SizedBox(
              width: 20,
              child: Text(
                '${index + 1}',
                style: const TextStyle(fontSize: 13, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 8),
            // Nombre, clave y tipo
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    atributo.nombre,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        atributo.tipo,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (tieneValores) ...[
                        Text(
                          ' • $cantidadOverride/${atributo.valoresDisponibles.length} val.',
                          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Configurar valores
            if (tieneValores)
              IconButton(
                icon: const Icon(Icons.tune, size: 18),
                tooltip: 'Configurar valores',
                onPressed: () => _editarValoresOverride(context, index, atributo),
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                padding: EdgeInsets.zero,
              ),
            // Requerido toggle
            SizedBox(
              height: 32,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      value: atributo.requeridoOverride ?? false,
                      onChanged: (value) {
                        setState(() {
                          _atributosSeleccionados[index] =
                              atributo.copyWith(requeridoOverride: value);
                        });
                      },
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text('Req.', style: TextStyle(fontSize: 11)),
                ],
              ),
            ),
            // Eliminar
            IconButton(
              icon: Icon(Icons.close, size: 18, color: Colors.red.shade300),
              onPressed: () {
                setState(() {
                  _atributosSeleccionados.removeAt(index);
                  _actualizarOrdenes();
                });
              },
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              padding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  void _reordenarAtributos(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _atributosSeleccionados.removeAt(oldIndex);
      _atributosSeleccionados.insert(newIndex, item);
      _actualizarOrdenes();
    });
  }

  void _actualizarOrdenes() {
    for (var i = 0; i < _atributosSeleccionados.length; i++) {
      _atributosSeleccionados[i] = _atributosSeleccionados[i].copyWith(orden: i);
    }
  }

  void _seleccionarIcono(BuildContext context) {
    final emojis = ['📱', '💻', '🖥️', '⌨️', '🖱️', '🎮', '🎧', '📷', '💾', '🔌'];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar icono'),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emojis
              .map((emoji) => InkWell(
                    onTap: () {
                      setState(() => _icono = emoji);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 50,
                      height: 50,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ))
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _icono = null);
              Navigator.pop(context);
            },
            child: const Text('Sin icono'),
          ),
        ],
      ),
    );
  }

  void _editarValoresOverride(
    BuildContext context,
    int index,
    _AtributoSeleccionado atributo,
  ) {
    // Valores actualmente seleccionados (override o todos si no hay override)
    final valoresActuales = atributo.valoresOverride ?? atributo.valoresDisponibles;
    final valoresSeleccionados = Set<String>.from(valoresActuales);

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Configurar valores: ${atributo.nombre}'),
              const SizedBox(height: 4),
              Text(
                'Selecciona los valores que aparecerán en esta plantilla',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: atributo.valoresDisponibles.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Este atributo no tiene valores predefinidos'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Botones de selección rápida
                      Row(
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                valoresSeleccionados.clear();
                                valoresSeleccionados.addAll(atributo.valoresDisponibles);
                              });
                            },
                            icon: const Icon(Icons.select_all, size: 16),
                            label: const Text('Todos'),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setDialogState(() {
                                valoresSeleccionados.clear();
                              });
                            },
                            icon: const Icon(Icons.deselect, size: 16),
                            label: const Text('Ninguno'),
                          ),
                        ],
                      ),
                      const Divider(),
                      // Lista de valores
                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: atributo.valoresDisponibles.length,
                          itemBuilder: (context, i) {
                            final valor = atributo.valoresDisponibles[i];
                            final isSelected = valoresSeleccionados.contains(valor);
                            return CheckboxListTile(
                              dense: true,
                              title: Text(valor),
                              value: isSelected,
                              onChanged: (bool? checked) {
                                setDialogState(() {
                                  if (checked == true) {
                                    valoresSeleccionados.add(valor);
                                  } else {
                                    valoresSeleccionados.remove(valor);
                                  }
                                });
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Restablecer a usar todos los valores (sin override)
                setState(() {
                  _atributosSeleccionados[index] =
                      atributo.copyWith(valoresOverride: null);
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Usar todos'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (valoresSeleccionados.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Debes seleccionar al menos un valor'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }

                setState(() {
                  // Si se seleccionaron todos los valores, no usar override
                  final todosSeleccionados =
                      valoresSeleccionados.length == atributo.valoresDisponibles.length;

                  _atributosSeleccionados[index] = atributo.copyWith(
                    valoresOverride: todosSeleccionados
                        ? null
                        : valoresSeleccionados.toList()?..sort(),
                  );
                });
                Navigator.pop(dialogContext);
              },
              child: const Text('Aplicar'),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorAtributos(
    BuildContext context,
    List<ProductoAtributo> atributosDisponibles,
  ) {
    // Filtrar atributos ya seleccionados
    final atributosNoSeleccionados = atributosDisponibles
        .where((a) => !_atributosSeleccionados.any((s) => s.atributoId == a.id))
        .toList();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar atributos'),
        content: SizedBox(
          width: double.maxFinite,
          child: atributosNoSeleccionados.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No hay más atributos disponibles'),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  itemCount: atributosNoSeleccionados.length,
                  itemBuilder: (context, index) {
                    final atributo = atributosNoSeleccionados[index];
                    return ListTile(
                      title: Text(atributo.nombre),
                      subtitle: Text('${atributo.clave} • ${atributo.tipo.value}'),
                      onTap: () {
                        setState(() {
                          _atributosSeleccionados.add(_AtributoSeleccionado(
                            atributoId: atributo.id,
                            nombre: atributo.nombre,
                            clave: atributo.clave,
                            tipo: atributo.tipo.value,
                            orden: _atributosSeleccionados.length,
                            requeridoOverride: atributo.requerido,
                            valoresDisponibles: atributo.valores,
                          ));
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Future<void> _guardar() async {
    // Verificar estado de autenticación antes de enviar
    final localStorage = locator<LocalStorageService>();
    final secureStorage = locator<SecureStorageService>();

    final tenantId = localStorage.getString(StorageConstants.tenantId);
    final accessToken = await secureStorage.read(key: StorageConstants.accessToken);

    // ✅ Verificar que el widget sigue montado después del await
    if (!mounted) return;

    // Validar que exista empresa seleccionada
    if (tenantId == null || tenantId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: No hay empresa seleccionada. Por favor, selecciona una empresa primero.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    // Validar que exista token de autenticación
    if (accessToken == null || accessToken.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Error: No estás autenticado. Por favor, inicia sesión nuevamente.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    if (_atributosSeleccionados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos un atributo a la plantilla'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final atributos = _atributosSeleccionados
        .map((a) => PlantillaAtributoCreate(
              atributoId: a.atributoId,
              orden: a.orden,
              requeridoOverride: a.requeridoOverride,
              valoresOverride: a.valoresOverride,
            ))
        .toList();
    if (_esEdicion) {
      context.read<AtributoPlantillaCubit>().actualizarPlantilla(
            plantillaId: widget.plantilla!.id,
            nombre: _nombreController.text,
            descripcion: _descripcionController.text.isEmpty
                ? null
                : _descripcionController.text,
            icono: _icono,
            categoriaId: _categoriaId,
            atributos: atributos,
          );
    } else {
      context.read<AtributoPlantillaCubit>().crearPlantilla(
            nombre: _nombreController.text,
            descripcion: _descripcionController.text.isEmpty
                ? null
                : _descripcionController.text,
            icono: _icono,
            categoriaId: _categoriaId,
            atributos: atributos,
          );
    }

    // ✅ Verificar mounted antes de usar Navigator
    if (!mounted) return;
    Navigator.pop(context);
  }
}

/// Clase auxiliar para manejar atributos seleccionados
class _AtributoSeleccionado {
  final String atributoId;
  final String nombre;
  final String clave;
  final String tipo;
  final int orden;
  final bool? requeridoOverride;
  final List<String>? valoresOverride;
  final List<String> valoresDisponibles; // Valores del atributo global

  _AtributoSeleccionado({
    required this.atributoId,
    required this.nombre,
    required this.clave,
    required this.tipo,
    required this.orden,
    this.requeridoOverride,
    this.valoresOverride,
    required this.valoresDisponibles,
  });

  _AtributoSeleccionado copyWith({
    String? atributoId,
    String? nombre,
    String? clave,
    String? tipo,
    int? orden,
    bool? requeridoOverride,
    List<String>? valoresOverride,
    List<String>? valoresDisponibles,
  }) {
    return _AtributoSeleccionado(
      atributoId: atributoId ?? this.atributoId,
      nombre: nombre ?? this.nombre,
      clave: clave ?? this.clave,
      tipo: tipo ?? this.tipo,
      orden: orden ?? this.orden,
      requeridoOverride: requeridoOverride ?? this.requeridoOverride,
      valoresOverride: valoresOverride ?? this.valoresOverride,
      valoresDisponibles: valoresDisponibles ?? this.valoresDisponibles,
    );
  }
}
