import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_state.dart';
import '../widgets/plantilla_selector_dialog.dart';

class ProductoAtributosPage extends StatefulWidget {
  const ProductoAtributosPage({super.key});

  @override
  State<ProductoAtributosPage> createState() => _ProductoAtributosPageState();
}

class _ProductoAtributosPageState extends State<ProductoAtributosPage> {
  @override
  void initState() {
    super.initState();
    _loadAtributos();
  }

  void _loadAtributos() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      context.read<ProductoAtributoCubit>().loadAtributos(
            empresaState.context.empresa.id,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Atributos de Productos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.dashboard_customize),
            onPressed: () {
              _showPlantillasDialog();
            },
            tooltip: 'Aplicar Plantilla',
          ),
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              _showHelpDialog();
            },
            tooltip: 'Ayuda',
          ),
        ],
      ),
      body: BlocConsumer<ProductoAtributoCubit, ProductoAtributoState>(
        listener: (context, state) {
          if (state is ProductoAtributoOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is ProductoAtributoError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ProductoAtributoLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductoAtributoError) {
            return _buildErrorView(state.message);
          }

          final atributos = state is ProductoAtributoLoaded
              ? state.atributos
              : state is ProductoAtributoOperationSuccess
                  ? state.atributos
                  : <ProductoAtributo>[];

          return RefreshIndicator(
            onRefresh: () async => _loadAtributos(),
            child: atributos.isEmpty
                ? _buildEmptyState()
                : _buildAtributosList(atributos),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAtributoDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo Atributo'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.tune,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No hay atributos configurados',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Los atributos te permiten crear variantes de productos con características específicas como color, talla, material, etc.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showPlantillasDialog(),
                  icon: const Icon(Icons.dashboard_customize),
                  label: const Text('Usar Plantilla'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _showAtributoDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Crear Manualmente'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              '💡 Tip: Usa plantillas para agregar múltiples atributos rápidamente',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtributosList(List<ProductoAtributo> atributos) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: atributos.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final atributo = atributos[index];
        return _buildAtributoCard(atributo);
      },
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadAtributos,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtributoCard(ProductoAtributo atributo) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: _getTipoColor(atributo.tipo).withValues(alpha: 0.2),
          child: Icon(
            _getTipoIcon(atributo.tipo),
            color: _getTipoColor(atributo.tipo),
            size: 20,
          ),
        ),
        title: Text(
          atributo.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _getTipoLabel(atributo.tipo),
          style: TextStyle(color: Colors.grey[600], fontSize: 13),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (atributo.requerido)
              Chip(
                label: const Text('Requerido', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.orange.shade50,
                visualDensity: VisualDensity.compact,
                side: BorderSide(color: Colors.orange.shade200),
              ),
            const SizedBox(width: 8),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 18),
                      SizedBox(width: 8),
                      Text('Editar'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Eliminar', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showAtributoDialog(atributo: atributo);
                } else if (value == 'delete') {
                  _confirmDelete(atributo);
                }
              },
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (atributo.descripcion != null) ...[
                  Text(
                    atributo.descripcion!,
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                ],

                // Valores
                if (atributo.hasValores) ...[
                  const Text(
                    'Valores disponibles:',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: atributo.valores.map((valor) {
                      return Chip(
                        label: Text(valor, style: const TextStyle(fontSize: 12)),
                        visualDensity: VisualDensity.compact,
                        backgroundColor: Colors.blue.shade50,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                ],

                // Configuración
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    _buildConfigChip(
                      'Mostrar en listado',
                      atributo.mostrarEnListado,
                      Icons.list,
                    ),
                    _buildConfigChip(
                      'Usar para filtros',
                      atributo.usarParaFiltros,
                      Icons.filter_list,
                    ),
                    _buildConfigChip(
                      'Mostrar en marketplace',
                      atributo.mostrarEnMarketplace,
                      Icons.store,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigChip(String label, bool enabled, IconData icon) {
    return Chip(
      avatar: Icon(
        icon,
        size: 14,
        color: enabled ? Colors.green : Colors.grey,
      ),
      label: Text(label, style: const TextStyle(fontSize: 11)),
      backgroundColor: enabled ? Colors.green.shade50 : Colors.grey.shade100,
      side: BorderSide(
        color: enabled ? Colors.green.shade200 : Colors.grey.shade300,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  IconData _getTipoIcon(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color:
        return Icons.palette;
      case AtributoTipo.talla:
        return Icons.straighten;
      case AtributoTipo.material:
        return Icons.category;
      case AtributoTipo.capacidad:
        return Icons.storage;
      case AtributoTipo.select:
        return Icons.list;
      case AtributoTipo.multiSelect:
        return Icons.checklist;
      case AtributoTipo.boolean:
        return Icons.toggle_on;
      case AtributoTipo.numero:
        return Icons.numbers;
      case AtributoTipo.texto:
        return Icons.text_fields;
    }
  }

  Color _getTipoColor(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color:
        return Colors.purple;
      case AtributoTipo.talla:
        return Colors.blue;
      case AtributoTipo.material:
        return Colors.brown;
      case AtributoTipo.capacidad:
        return Colors.orange;
      case AtributoTipo.select:
        return Colors.green;
      case AtributoTipo.multiSelect:
        return Colors.lightGreen;
      case AtributoTipo.boolean:
        return Colors.teal;
      case AtributoTipo.numero:
        return Colors.indigo;
      case AtributoTipo.texto:
        return Colors.cyan;
    }
  }

  String _getTipoLabel(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color:
        return 'Color';
      case AtributoTipo.talla:
        return 'Talla';
      case AtributoTipo.material:
        return 'Material';
      case AtributoTipo.capacidad:
        return 'Capacidad';
      case AtributoTipo.select:
        return 'Selección';
      case AtributoTipo.multiSelect:
        return 'Selección múltiple';
      case AtributoTipo.boolean:
        return 'Sí/No';
      case AtributoTipo.numero:
        return 'Número';
      case AtributoTipo.texto:
        return 'Texto';
    }
  }

  void _showAtributoDialog({ProductoAtributo? atributo}) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AtributoFormDialog(
        atributo: atributo,
        empresaId: empresaState.context.empresa.id,
        onSave: (data) {
          if (atributo == null) {
            context.read<ProductoAtributoCubit>().crearAtributo(
                  empresaId: empresaState.context.empresa.id,
                  data: data,
                );
          } else {
            context.read<ProductoAtributoCubit>().actualizarAtributo(
                  atributoId: atributo.id,
                  empresaId: empresaState.context.empresa.id,
                  data: data,
                );
          }
        },
      ),
    );
  }

  void _confirmDelete(ProductoAtributo atributo) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar Atributo'),
        content: Text(
          '¿Estás seguro de eliminar el atributo "${atributo.nombre}"?\n\nEsto afectará a las variantes que usen este atributo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<ProductoAtributoCubit>().eliminarAtributo(
                    atributoId: atributo.id,
                    empresaId: empresaState.context.empresa.id,
                  );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showPlantillasDialog() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    showDialog(
      context: context,
      builder: (context) => PlantillaSelectorDialog(
        empresaId: empresaState.context.empresa.id,
        onPlantillaAplicada: () {
          // Recargar atributos después de aplicar plantilla
          _loadAtributos();
        },
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline),
            SizedBox(width: 8),
            Text('¿Qué son los atributos?'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Los atributos son características configurables que puedes usar para crear variantes de tus productos.',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 16),
              Text(
                'Ejemplos de uso:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('• Color: Rojo, Azul, Verde, Negro'),
              Text('• Talla: XS, S, M, L, XL, XXL'),
              Text('• Material: Algodón, Poliéster, Lana'),
              Text('• Capacidad: 16GB, 32GB, 64GB, 128GB'),
              Text('• Conexión: USB, Bluetooth, Inalámbrico'),
              SizedBox(height: 16),
              Text(
                'Beneficios:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('✓ Estandariza las características'),
              Text('✓ Facilita la creación de variantes'),
              Text('✓ Permite filtrar productos'),
              Text('✓ Mejora la búsqueda en marketplace'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}

// Diálogo para crear/editar atributo
class AtributoFormDialog extends StatefulWidget {
  final ProductoAtributo? atributo;
  final String empresaId;
  final Function(Map<String, dynamic>) onSave;

  const AtributoFormDialog({
    super.key,
    this.atributo,
    required this.empresaId,
    required this.onSave,
  });

  @override
  State<AtributoFormDialog> createState() => _AtributoFormDialogState();
}

class _AtributoFormDialogState extends State<AtributoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _valoresController;
  late AtributoTipo _selectedTipo;
  late bool _requerido;
  late bool _mostrarEnListado;
  late bool _usarParaFiltros;
  late bool _mostrarEnMarketplace;
  String? _categoriaId;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.atributo?.nombre);
    _descripcionController =
        TextEditingController(text: widget.atributo?.descripcion);
    _valoresController = TextEditingController(
      text: widget.atributo?.valores.join(', '),
    );
    _selectedTipo = widget.atributo?.tipo ?? AtributoTipo.select;
    _requerido = widget.atributo?.requerido ?? false;
    _mostrarEnListado = widget.atributo?.mostrarEnListado ?? true;
    _usarParaFiltros = widget.atributo?.usarParaFiltros ?? true;
    _mostrarEnMarketplace = widget.atributo?.mostrarEnMarketplace ?? true;
    _categoriaId = widget.atributo?.categoriaId;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _valoresController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.atributo == null ? 'Nuevo Atributo' : 'Editar Atributo',
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selector de categoría
                _buildCategoriaSelector(),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre *',
                    hintText: 'Ej: Color, Talla, Material',
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'El nombre es requerido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<AtributoTipo>(
                  initialValue: _selectedTipo,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de Atributo *',
                    prefixIcon: Icon(Icons.category),
                  ),
                  items: AtributoTipo.values.map((tipo) {
                    return DropdownMenuItem(
                      value: tipo,
                      child: Row(
                        children: [
                          Icon(_getTipoIcon(tipo), size: 18),
                          const SizedBox(width: 8),
                          Text(_getTipoLabel(tipo)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedTipo = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción (opcional)',
                    hintText: 'Descripción del atributo',
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _valoresController,
                  decoration: const InputDecoration(
                    labelText: 'Valores (separados por coma)',
                    hintText: 'Rojo, Azul, Verde, Negro',
                    prefixIcon: Icon(Icons.list),
                    helperText: 'Separa los valores con comas',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),

                // Opciones
                const Text(
                  'Configuración:',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                CheckboxListTile(
                  value: _requerido,
                  onChanged: (value) {
                    setState(() => _requerido = value ?? false);
                  },
                  title: const Text('Requerido al crear variantes'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),

                CheckboxListTile(
                  value: _mostrarEnListado,
                  onChanged: (value) {
                    setState(() => _mostrarEnListado = value ?? true);
                  },
                  title: const Text('Mostrar en listado de productos'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),

                CheckboxListTile(
                  value: _usarParaFiltros,
                  onChanged: (value) {
                    setState(() => _usarParaFiltros = value ?? true);
                  },
                  title: const Text('Usar para filtros de búsqueda'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                ),

                CheckboxListTile(
                  value: _mostrarEnMarketplace,
                  onChanged: (value) {
                    setState(() => _mostrarEnMarketplace = value ?? true);
                  },
                  title: const Text('Mostrar en marketplace'),
                  dense: true,
                  contentPadding: EdgeInsets.zero,
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
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  Widget _buildCategoriaSelector() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, state) {
        if (state is CategoriasEmpresaLoaded) {
          final categorias = state.categorias;

          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, size: 18, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    const Text(
                      'Categoría (opcional)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Asocia este atributo a una categoría específica para que aparezca solo en productos de esa categoría',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _categoriaId,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Sin categoría (atributo global)'),
                    ),
                    ...categorias.map((categoria) {
                      return DropdownMenuItem(
                        value: categoria.id,
                        child: Text(categoria.nombreDisplay),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _categoriaId = value;
                    });
                  },
                  hint: const Text('Selecciona una categoría'),
                ),
              ],
            ),
          );
        }

        // Si está cargando, mostrar un indicador
        if (state is CategoriasEmpresaLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si hay error o estado inicial, cargar categorías
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context.read<CategoriasEmpresaCubit>().loadCategorias(widget.empresaId);
        });

        return const SizedBox.shrink();
      },
    );
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      final nombre = _nombreController.text.trim();
      final valores = _valoresController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // Validación de consistencia entre tipo y valores
      final requiresValues = [AtributoTipo.select, AtributoTipo.multiSelect];
      final forbidsValues = [AtributoTipo.texto, AtributoTipo.numero, AtributoTipo.boolean];

      if (requiresValues.contains(_selectedTipo) && valores.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTipoLabel(_selectedTipo)} requiere al menos un valor predefinido'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      if (forbidsValues.contains(_selectedTipo) && valores.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_getTipoLabel(_selectedTipo)} no admite valores predefinidos'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Generar clave a partir del nombre (slug)
      final clave = _generarClave(nombre);

      final data = {
        'nombre': nombre,
        'clave': clave,
        'tipo': _selectedTipo.value,
        'descripcion': _descripcionController.text.trim().isEmpty
            ? null
            : _descripcionController.text.trim(),
        'valores': valores,
        'requerido': _requerido,
        'mostrarEnListado': _mostrarEnListado,
        'usarParaFiltros': _usarParaFiltros,
        'mostrarEnMarketplace': _mostrarEnMarketplace,
        if (_categoriaId != null) 'categoriaId': _categoriaId,
      };

      widget.onSave(data);
      Navigator.pop(context);
    }
  }

  /// Genera una clave a partir del nombre (slug)
  String _generarClave(String nombre) {
    // Convertir a minúsculas
    String clave = nombre.toLowerCase();
    // Reemplazar espacios y caracteres especiales con guiones bajos
    clave = clave.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    // Eliminar guiones bajos al inicio y final
    clave = clave.replaceAll(RegExp(r'^_+|_+$'), '');
    // Si queda vacío, usar "atributo"
    if (clave.isEmpty) clave = 'atributo';
    return clave;
  }

  IconData _getTipoIcon(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color:
        return Icons.palette;
      case AtributoTipo.talla:
        return Icons.straighten;
      case AtributoTipo.material:
        return Icons.category;
      case AtributoTipo.capacidad:
        return Icons.storage;
      case AtributoTipo.select:
        return Icons.list;
      case AtributoTipo.multiSelect:
        return Icons.checklist;
      case AtributoTipo.boolean:
        return Icons.toggle_on;
      case AtributoTipo.numero:
        return Icons.numbers;
      case AtributoTipo.texto:
        return Icons.text_fields;
    }
  }

  String _getTipoLabel(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color:
        return 'Color';
      case AtributoTipo.talla:
        return 'Talla';
      case AtributoTipo.material:
        return 'Material';
      case AtributoTipo.capacidad:
        return 'Capacidad';
      case AtributoTipo.select:
        return 'Selección';
      case AtributoTipo.multiSelect:
        return 'Selección múltiple';
      case AtributoTipo.boolean:
        return 'Sí/No';
      case AtributoTipo.numero:
        return 'Número';
      case AtributoTipo.texto:
        return 'Texto';
    }
  }
}
