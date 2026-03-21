import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../domain/entities/categoria_gasto.dart';
import '../bloc/categoria_gasto_cubit.dart';
import '../bloc/categoria_gasto_state.dart';

class CategoriasGastoPage extends StatelessWidget {
  const CategoriasGastoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<CategoriaGastoCubit>()..loadCategorias(),
      child: const _CategoriasGastoView(),
    );
  }
}

class _CategoriasGastoView extends StatefulWidget {
  const _CategoriasGastoView();

  @override
  State<_CategoriasGastoView> createState() => _CategoriasGastoViewState();
}

class _CategoriasGastoViewState extends State<_CategoriasGastoView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const List<Color> _predefinedColors = [
    Color(0xFF1976D2),
    Color(0xFF388E3C),
    Color(0xFFD32F2F),
    Color(0xFFE65100),
    Color(0xFF7B1FA2),
    Color(0xFF00838F),
    Color(0xFFC2185B),
    Color(0xFF455A64),
    Color(0xFF6D4C41),
    Color(0xFF33691E),
    Color(0xFFAD1457),
    Color(0xFF0277BD),
  ];

  static const List<IconData> _predefinedIcons = [
    Icons.shopping_cart,
    Icons.restaurant,
    Icons.local_gas_station,
    Icons.house,
    Icons.directions_car,
    Icons.phone_android,
    Icons.electrical_services,
    Icons.medical_services,
    Icons.school,
    Icons.flight,
    Icons.sports_esports,
    Icons.build,
    Icons.storefront,
    Icons.payments,
    Icons.local_shipping,
    Icons.cleaning_services,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<CategoriaGasto> _filteredByTipo(List<CategoriaGasto> categorias, String tipo) {
    return categorias.where((c) => c.tipo == tipo).toList();
  }

  void _showAddEditDialog({CategoriaGasto? existing}) {
    final isEditing = existing != null;
    final nombreCtrl = TextEditingController(text: existing?.nombre ?? '');
    final currentTab = _tabController.index;
    String tipo = existing?.tipo ?? (currentTab == 0 ? 'INGRESO' : 'EGRESO');

    Color selectedColor = _predefinedColors[0];
    if (existing?.color != null) {
      final hexStr = existing!.color!.replaceFirst('#', '');
      final parsed = int.tryParse(hexStr, radix: 16);
      if (parsed != null) {
        selectedColor = Color(0xFF000000 | parsed);
      }
    }

    IconData selectedIcon = _predefinedIcons[0];
    if (existing?.icono != null) {
      final code = int.tryParse(existing!.icono!);
      if (code != null) {
        selectedIcon = IconData(code, fontFamily: 'MaterialIcons');
      }
    }

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              title: Text(
                isEditing ? 'Editar Categoria' : 'Nueva Categoria',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.blue3),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nombreCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        labelStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      ),
                      style: const TextStyle(fontSize: 13),
                    ),
                    const SizedBox(height: 14),
                    if (!isEditing) ...[
                      Text('Tipo', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('INGRESO', style: TextStyle(fontSize: 11)),
                              selected: tipo == 'INGRESO',
                              selectedColor: AppColors.green.withValues(alpha: 0.2),
                              onSelected: (_) => setDialogState(() => tipo = 'INGRESO'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ChoiceChip(
                              label: const Text('EGRESO', style: TextStyle(fontSize: 11)),
                              selected: tipo == 'EGRESO',
                              selectedColor: AppColors.red.withValues(alpha: 0.2),
                              onSelected: (_) => setDialogState(() => tipo = 'EGRESO'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                    ],
                    Text('Color', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _predefinedColors.map((color) {
                        final isSelected = selectedColor.value == color.value;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedColor = color),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: AppColors.blue3, width: 2.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 6)]
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, size: 16, color: Colors.white)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    Text('Icono', style: TextStyle(fontSize: 11, color: Colors.grey.shade700, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _predefinedIcons.map((icon) {
                        final isSelected = selectedIcon.codePoint == icon.codePoint;
                        return GestureDetector(
                          onTap: () => setDialogState(() => selectedIcon = icon),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? selectedColor.withValues(alpha: 0.15)
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(color: selectedColor, width: 1.5)
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              size: 18,
                              color: isSelected ? selectedColor : Colors.grey.shade600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
                ),
                CustomButton(
                  text: isEditing ? 'Guardar' : 'Crear',
                  backgroundColor: AppColors.blue1,
                  textColor: Colors.white,
                  height: 34,
                  width: 90,
                  fontSize: 11,
                  onPressed: () {
                    final nombre = nombreCtrl.text.trim();
                    if (nombre.isEmpty) return;
                    Navigator.pop(ctx);
                    final colorHex = '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
                    final iconoStr = selectedIcon.codePoint.toString();
                    final cubit = context.read<CategoriaGastoCubit>();
                    if (isEditing) {
                      cubit.actualizar(
                        id: existing.id,
                        nombre: nombre,
                        color: colorHex,
                        icono: iconoStr,
                      );
                    } else {
                      cubit.crear(
                        nombre: nombre,
                        tipo: tipo,
                        color: colorHex,
                        icono: iconoStr,
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _deleteCategoria(String id) {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar categoria', style: TextStyle(fontSize: 15)),
        content: const Text(
          'Esta accion no se puede deshacer. Los movimientos con esta categoria no se veran afectados.',
          style: TextStyle(fontSize: 12),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(fontSize: 12)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx, true);
              context.read<CategoriaGastoCubit>().eliminar(id: id);
            },
            child: const Text('Eliminar', style: TextStyle(fontSize: 12, color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Categorias de Gasto',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.6),
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          tabs: const [
            Tab(text: 'INGRESO'),
            Tab(text: 'EGRESO'),
          ],
        ),
      ),
      body: GradientBackground(
        child: BlocBuilder<CategoriaGastoCubit, CategoriaGastoState>(
          builder: (context, state) {
            if (state is CategoriaGastoLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is CategoriaGastoError) {
              return Center(
                child: Text(
                  state.message,
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                ),
              );
            }
            if (state is CategoriaGastoLoaded) {
              return TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoriaList(state.categorias, 'INGRESO'),
                  _buildCategoriaList(state.categorias, 'EGRESO'),
                ],
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue1,
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildCategoriaList(List<CategoriaGasto> allCategorias, String tipo) {
    final categorias = _filteredByTipo(allCategorias, tipo);

    if (categorias.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.category_outlined,
                size: 56,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                'No hay categorias de ${tipo.toLowerCase()}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
              const SizedBox(height: 16),
              GradientContainer(
                borderColor: AppColors.blueborder,
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    const Icon(Icons.lightbulb_outline, color: AppColors.orange, size: 24),
                    const SizedBox(height: 8),
                    Text(
                      'Puedes crear categorias para organizar tus ${tipo == 'INGRESO' ? 'ingresos' : 'gastos'}. Toca el boton + para comenzar.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<CategoriaGastoCubit>().loadCategorias(),
      color: AppColors.blue1,
      child: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final cat = categorias[index];
          return _CategoriaCard(
            categoria: cat,
            onEdit: () => _showAddEditDialog(existing: cat),
            onDelete: () => _deleteCategoria(cat.id),
          );
        },
      ),
    );
  }
}

class _CategoriaCard extends StatelessWidget {
  final CategoriaGasto categoria;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _CategoriaCard({
    required this.categoria,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = categoria.colorValue;
    final catIcon = categoria.iconData;

    return Dismissible(
      key: Key(categoria.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.delete_outline, color: AppColors.red),
      ),
      confirmDismiss: (_) async {
        onDelete();
        return false;
      },
      child: GradientContainer(
        margin: const EdgeInsets.only(bottom: 8),
        borderColor: AppColors.blueborder,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(catIcon, size: 20, color: catColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoria.nombre,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blue3,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: catColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          categoria.tipo,
                          style: TextStyle(
                            fontSize: 10,
                            color: categoria.tipo == 'INGRESO' ? AppColors.green : AppColors.red,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined, size: 18, color: Colors.grey.shade500),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
