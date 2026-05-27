import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:syncronize/core/widgets/floating_button_icon.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_state.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_state.dart';

class ProductoAtributosPage extends StatefulWidget {
  const ProductoAtributosPage({super.key});

  @override
  State<ProductoAtributosPage> createState() => _ProductoAtributosPageState();
}

class _ProductoAtributosPageState extends State<ProductoAtributosPage> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAtributos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadAtributos() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      context.read<ProductoAtributoCubit>().loadAtributos(
            empresaState.context.empresa.id,
          );
    }
  }

  List<ProductoAtributo> _filter(List<ProductoAtributo> source) {
    if (_searchQuery.isEmpty) return source;
    return source.where((a) {
      final txt = '${a.nombre} ${a.descripcion ?? ''} ${a.tipo.name}'.toLowerCase();
      return txt.contains(_searchQuery);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: SmartAppBar(
        title: 'Atributos de Productos',
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        showLogo: false,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, size: 18),
            tooltip: 'Ayuda',
            onPressed: _showHelpDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, size: 18),
            tooltip: 'Actualizar',
            onPressed: _loadAtributos,
          ),
        ],
      ),
      body: GradientBackground(
        style: GradientStyle.professional,
        child: SafeArea(
          child: BlocConsumer<ProductoAtributoCubit, ProductoAtributoState>(
            listener: (context, state) {
              if (state is ProductoAtributoOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.green),
                );
              } else if (state is ProductoAtributoError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(state.message),
                      backgroundColor: Colors.red),
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

              return _buildContent(atributos);
            },
          ),
        ),
      ),
      floatingActionButton: FloatingButtonIcon(
        icon: Icons.add,
        onPressed: () => _showAtributoDialog(),
      ),
    );
  }

  Widget _buildContent(List<ProductoAtributo> atributos) {
    final filtered = _filter(atributos);
    return Column(
      children: [
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: CustomSearchField(
            controller: _searchController,
            hintText: 'Buscar atributo...',
            borderColor: AppColors.blue1,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            onClear: () => setState(() {
              _searchQuery = '';
              _searchController.clear();
            }),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              Icon(Icons.tune, size: 14, color: AppColors.blue1),
              const SizedBox(width: 6),
              AppSubtitle('Atributos configurados',
                  fontSize: 11, color: AppColors.blue1),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: AppColors.blue1.withValues(alpha: 0.3),
                      width: 0.5),
                ),
                child: Text(
                  '${filtered.length} ${filtered.length == 1 ? 'atributo' : 'atributos'}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: atributos.isEmpty
              ? _buildEmptyState()
              : filtered.isEmpty
                  ? _buildEmptyFilteredState()
                  : RefreshIndicator(
                      onRefresh: () async => _loadAtributos(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(10, 4, 10, 80),
                        itemCount: filtered.length,
                        itemBuilder: (_, i) =>
                            _buildAtributoCard(filtered[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.tune, size: 80, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No hay atributos configurados',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700),
            ),
            const SizedBox(height: 6),
            Text(
              'Los atributos te permiten crear variantes de productos (color, talla, material, etc.)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Crear Atributo',
              icon: const Icon(Icons.add, size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              textColor: Colors.white,
              onPressed: () => _showAtributoDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFilteredState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'Sin resultados para "$_searchQuery"',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Reintentar',
              icon: const Icon(Icons.refresh, size: 16, color: Colors.white),
              backgroundColor: AppColors.blue1,
              textColor: Colors.white,
              onPressed: _loadAtributos,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAtributoCard(ProductoAtributo atributo) {
    final color = _getTipoColor(atributo.tipo);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteBlue(),
        borderColor: AppColors.blueborder,
        shadowStyle: ShadowStyle.colorful,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            leading: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_getTipoIcon(atributo.tipo), color: color, size: 16),
            ),
            title: AppSubtitle(atributo.nombre, fontSize: 12),
            subtitle: Row(
              children: [
                Text(
                  _getTipoLabel(atributo.tipo),
                  style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                ),
                if (atributo.requerido) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade300, width: 0.5),
                    ),
                    child: Text('Requerido',
                        style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Colors.orange.shade700)),
                  ),
                ],
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => _showAtributoDialog(atributo: atributo),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.edit_outlined,
                        size: 16, color: AppColors.blue1),
                  ),
                ),
                InkWell(
                  onTap: () => _confirmDelete(atributo),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child:
                        Icon(Icons.delete_outlined, size: 16, color: Colors.red),
                  ),
                ),
              ],
            ),
            children: [
              if (atributo.descripcion != null &&
                  atributo.descripcion!.isNotEmpty) ...[
                Text(atributo.descripcion!,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade700)),
                const SizedBox(height: 8),
              ],
              if (atributo.hasValores) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppLabelText('Valores disponibles'),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: atributo.valores.map((valor) {
                    return InfoChip(
                      text: valor,
                      icon: Icons.label,
                      fontSize: 9,
                      backgroundColor: AppColors.white,
                      borderColor: AppColors.blue1,
                      borderRadius: 4,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 4),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 8),
              ],
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _configBadge('Listado', atributo.mostrarEnListado, Icons.list),
                  _configBadge('Filtros', atributo.usarParaFiltros, Icons.filter_list),
                  _configBadge('Marketplace', atributo.mostrarEnMarketplace, Icons.store),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _configBadge(String label, bool enabled, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: enabled
            ? Colors.green.shade50
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: enabled ? Colors.green.shade300 : Colors.grey.shade300,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 10, color: enabled ? Colors.green : Colors.grey.shade500),
          const SizedBox(width: 3),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: enabled ? Colors.green.shade700 : Colors.grey.shade500)),
        ],
      ),
    );
  }

  // ── Helpers ──

  IconData _getTipoIcon(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color: return Icons.palette;
      case AtributoTipo.talla: return Icons.straighten;
      case AtributoTipo.material: return Icons.category;
      case AtributoTipo.capacidad: return Icons.storage;
      case AtributoTipo.select: return Icons.list;
      case AtributoTipo.multiSelect: return Icons.checklist;
      case AtributoTipo.boolean: return Icons.toggle_on;
      case AtributoTipo.numero: return Icons.numbers;
      case AtributoTipo.texto: return Icons.text_fields;
    }
  }

  Color _getTipoColor(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color: return Colors.purple;
      case AtributoTipo.talla: return Colors.blue;
      case AtributoTipo.material: return Colors.brown;
      case AtributoTipo.capacidad: return Colors.orange;
      case AtributoTipo.select: return Colors.green;
      case AtributoTipo.multiSelect: return Colors.lightGreen;
      case AtributoTipo.boolean: return Colors.teal;
      case AtributoTipo.numero: return Colors.indigo;
      case AtributoTipo.texto: return Colors.cyan;
    }
  }

  String _getTipoLabel(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color: return 'Color';
      case AtributoTipo.talla: return 'Talla';
      case AtributoTipo.material: return 'Material';
      case AtributoTipo.capacidad: return 'Capacidad';
      case AtributoTipo.select: return 'Selección';
      case AtributoTipo.multiSelect: return 'Selección múltiple';
      case AtributoTipo.boolean: return 'Sí/No';
      case AtributoTipo.numero: return 'Número';
      case AtributoTipo.texto: return 'Texto';
    }
  }

  // ── Dialogs ──

  void _showAtributoDialog({ProductoAtributo? atributo}) {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    showDialog(
      context: context,
      builder: (dialogContext) => _AtributoFormDialog(
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

    StyledDialog.show(
      context,
      accentColor: Colors.red,
      icon: Icons.delete_outline,
      titulo: 'Eliminar Atributo',
      content: [
        Text(
          '¿Eliminar "${atributo.nombre}"?',
          style: const TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 6),
        Text(
          'Esto afectará a las variantes que usen este atributo.',
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
      actions: [
        Expanded(
          child: TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancelar',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
        ),
        Expanded(
          child: CustomButton(
            text: 'Eliminar',
            icon: const Icon(Icons.delete, size: 14, color: Colors.white),
            backgroundColor: Colors.red,
            textColor: Colors.white,
            onPressed: () {
              Navigator.pop(context);
              context.read<ProductoAtributoCubit>().eliminarAtributo(
                    atributoId: atributo.id,
                    empresaId: empresaState.context.empresa.id,
                  );
            },
          ),
        ),
      ],
    );
  }

  void _showHelpDialog() {
    StyledDialog.show(
      context,
      accentColor: AppColors.blue1,
      icon: Icons.help_outline,
      titulo: '¿Qué son los atributos?',
      content: [
        const Text(
          'Los atributos son características configurables para crear variantes de tus productos.',
          style: TextStyle(fontSize: 12),
        ),
        const SizedBox(height: 10),
        Text('Ejemplos:',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.blue1)),
        const SizedBox(height: 4),
        const Text('• Color: Rojo, Azul, Verde, Negro',
            style: TextStyle(fontSize: 11)),
        const Text('• Talla: XS, S, M, L, XL, XXL',
            style: TextStyle(fontSize: 11)),
        const Text('• Material: Algodón, Poliéster, Lana',
            style: TextStyle(fontSize: 11)),
        const Text('• Capacidad: 16GB, 32GB, 64GB',
            style: TextStyle(fontSize: 11)),
      ],
      actions: [
        Expanded(
          child: CustomButton(
            text: 'Entendido',
            backgroundColor: AppColors.blue1,
            textColor: Colors.white,
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }
}

// ── Dialog de formulario ──

class _AtributoFormDialog extends StatefulWidget {
  final ProductoAtributo? atributo;
  final String empresaId;
  final Function(Map<String, dynamic>) onSave;

  const _AtributoFormDialog({
    this.atributo,
    required this.empresaId,
    required this.onSave,
  });

  @override
  State<_AtributoFormDialog> createState() => _AtributoFormDialogState();
}

class _AtributoFormDialogState extends State<_AtributoFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _valoresController;
  late AtributoTipo _selectedTipo;
  late bool _requerido;
  late bool _mostrarEnListado;
  late bool _usarParaFiltros;
  late bool _mostrarEnMarketplace;
  List<String> _categoriaIds = [];

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.atributo?.nombre);
    _descripcionController =
        TextEditingController(text: widget.atributo?.descripcion);
    _valoresController =
        TextEditingController(text: widget.atributo?.valores.join(', '));
    _selectedTipo = widget.atributo?.tipo ?? AtributoTipo.select;
    _requerido = widget.atributo?.requerido ?? false;
    _mostrarEnListado = widget.atributo?.mostrarEnListado ?? true;
    _usarParaFiltros = widget.atributo?.usarParaFiltros ?? true;
    _mostrarEnMarketplace = widget.atributo?.mostrarEnMarketplace ?? true;
    _categoriaIds = List<String>.from(widget.atributo?.categoriaIds ?? []);
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
    final isEditing = widget.atributo != null;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: GradientContainer(
        borderColor: AppColors.blue1.withValues(alpha: 0.4),
        borderWidth: 1,
        customShadows: [
          BoxShadow(
            color: AppColors.blue1.withValues(alpha: 0.18),
            blurRadius: 18,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
        padding: const EdgeInsets.all(18),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.blue1.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                          isEditing ? Icons.edit : Icons.add_circle_outline,
                          color: AppColors.blue1,
                          size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isEditing ? 'Editar Atributo' : 'Nuevo Atributo',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.blue1,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close, size: 18),
                      color: Colors.grey.shade500,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                _buildCategoriaSelector(),
                const SizedBox(height: 12),

                CustomText(
                  label: 'Nombre *',
                  hintText: 'Ej: Color, Talla, Material',
                  controller: _nombreController,
                  borderColor: AppColors.blue1,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),

                CustomDropdown<AtributoTipo>(
                  label: 'Tipo de Atributo',
                  borderColor: AppColors.blue1,
                  value: _selectedTipo,
                  items: AtributoTipo.values
                      .map((t) => DropdownItem(value: t, label: _getTipoLabel(t)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedTipo = v);
                  },
                ),
                const SizedBox(height: 12),

                CustomText(
                  label: 'Descripción (opcional)',
                  controller: _descripcionController,
                  borderColor: AppColors.blue1,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),

                CustomText(
                  label: 'Valores (separados por coma)',
                  hintText: 'Rojo, Azul, Verde, Negro',
                  controller: _valoresController,
                  borderColor: AppColors.blue1,
                  maxLines: 2,
                ),
                const SizedBox(height: 14),

                AppLabelText('Configuración'),
                const SizedBox(height: 6),
                CustomSwitchTile(
                  title: 'Requerido al crear variantes',
                  value: _requerido,
                  onChanged: (v) => setState(() => _requerido = v),
                  padding: EdgeInsets.zero,
                ),
                CustomSwitchTile(
                  title: 'Mostrar en listado',
                  value: _mostrarEnListado,
                  onChanged: (v) => setState(() => _mostrarEnListado = v),
                  padding: EdgeInsets.zero,
                ),
                CustomSwitchTile(
                  title: 'Usar para filtros',
                  value: _usarParaFiltros,
                  onChanged: (v) => setState(() => _usarParaFiltros = v),
                  padding: EdgeInsets.zero,
                ),
                CustomSwitchTile(
                  title: 'Mostrar en marketplace',
                  value: _mostrarEnMarketplace,
                  onChanged: (v) => setState(() => _mostrarEnMarketplace = v),
                  padding: EdgeInsets.zero,
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text('Cancelar',
                            style: TextStyle(color: Colors.grey.shade600)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomButton(
                        text: 'Guardar',
                        icon: const Icon(Icons.check, size: 16, color: Colors.white),
                        backgroundColor: AppColors.blue1,
                        textColor: Colors.white,
                        onPressed: _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriaSelector() {
    return BlocBuilder<CategoriasEmpresaCubit, CategoriasEmpresaState>(
      builder: (context, state) {
        if (state is CategoriasEmpresaLoaded) {
          final categorias = state.categorias;
          return Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: AppColors.blue1.withValues(alpha: 0.2), width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.category, size: 14, color: AppColors.blue1),
                    const SizedBox(width: 6),
                    const Text('Categorías (opcional)',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w600)),
                    const Spacer(),
                    Text(
                      _categoriaIds.isEmpty
                          ? 'Global'
                          : '${_categoriaIds.length} selec.',
                      style: TextStyle(
                          fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: categorias.map((cat) {
                    final sel = _categoriaIds.contains(cat.id);
                    return FilterChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (sel) ...[
                            const Icon(Icons.check, size: 12, color: Colors.white),
                            const SizedBox(width: 3),
                          ],
                          Text(cat.nombreDisplay,
                              style: TextStyle(
                                  fontSize: 8,
                                  color: sel ? Colors.white : null)),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      selected: sel,
                      onSelected: (s) {
                        setState(() {
                          s ? _categoriaIds.add(cat.id)
                            : _categoriaIds.remove(cat.id);
                        });
                      },
                      selectedColor: AppColors.blue1,
                      showCheckmark: false,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                        side: BorderSide(
                            color: sel
                                ? AppColors.blue1
                                : Colors.grey.shade300),
                      ),
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        }
        if (state is CategoriasEmpresaLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          context
              .read<CategoriasEmpresaCubit>()
              .loadCategorias(widget.empresaId);
        });
        return const SizedBox.shrink();
      },
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final nombre = _nombreController.text.trim();
    final valores = _valoresController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final requiresValues = [AtributoTipo.select, AtributoTipo.multiSelect];
    final forbidsValues = [AtributoTipo.texto, AtributoTipo.numero, AtributoTipo.boolean];

    if (requiresValues.contains(_selectedTipo) && valores.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_getTipoLabel(_selectedTipo)} requiere al menos un valor'),
            backgroundColor: Colors.red),
      );
      return;
    }
    if (forbidsValues.contains(_selectedTipo) && valores.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                '${_getTipoLabel(_selectedTipo)} no admite valores predefinidos'),
            backgroundColor: Colors.red),
      );
      return;
    }

    String clave = nombre.toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    if (clave.isEmpty) clave = 'atributo';

    widget.onSave({
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
      'categoriaIds': _categoriaIds,
    });
    Navigator.pop(context);
  }

  String _getTipoLabel(AtributoTipo tipo) {
    switch (tipo) {
      case AtributoTipo.color: return 'Color';
      case AtributoTipo.talla: return 'Talla';
      case AtributoTipo.material: return 'Material';
      case AtributoTipo.capacidad: return 'Capacidad';
      case AtributoTipo.select: return 'Selección';
      case AtributoTipo.multiSelect: return 'Selección múltiple';
      case AtributoTipo.boolean: return 'Sí/No';
      case AtributoTipo.numero: return 'Número';
      case AtributoTipo.texto: return 'Texto';
    }
  }
}
