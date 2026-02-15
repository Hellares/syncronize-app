import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/core/widgets/popup_item.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_atributo.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/entities/producto_variante.dart';
import '../../domain/usecases/get_stock_variante_en_sede_usecase.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../bloc/producto_atributo/producto_atributo_state.dart';
import '../bloc/producto_variante/producto_variante_cubit.dart';
import '../bloc/producto_variante/producto_variante_state.dart';
import '../bloc/precio_nivel/precio_nivel_cubit.dart';
import '../bloc/variante_atributo/variante_atributo_cubit.dart';
import '../bloc/configurar_precios/configurar_precios_cubit.dart';
import '../bloc/sede_selection/sede_selection_cubit.dart';
import '../widgets/producto_variante_form_dialog.dart';
import '../widgets/generar_combinaciones_dialog.dart';
import '../bloc/ajustar_stock/ajustar_stock_cubit.dart';
import '../widgets/ajustar_stock_dialog.dart';
import '../widgets/configurar_precios_dialog.dart';

class ProductoVariantesPage extends StatelessWidget {
  final String productoId;
  final String productoNombre;
  final bool productoIsActive;
  final String? categoriaId;
  const ProductoVariantesPage({
    super.key,
    required this.productoId,
    required this.productoNombre,
    this.productoIsActive = true, // Por defecto true para compatibilidad
    this.categoriaId,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => locator<ProductoVarianteCubit>(),
        ),
        BlocProvider(
          create: (_) => locator<ProductoAtributoCubit>(),
        ),
      ],
      child: _ProductoVariantesView(
        productoId: productoId,
        productoNombre: productoNombre,
        productoIsActive: productoIsActive,
        categoriaId: categoriaId,
      ),
    );
  }
}

class _ProductoVariantesView extends StatefulWidget {
  final String productoId;
  final String productoNombre;
  final bool productoIsActive;
  final String? categoriaId;

  const _ProductoVariantesView({
    required this.productoId,
    required this.productoNombre,
    required this.productoIsActive,
    this.categoriaId,
  });

  @override
  State<_ProductoVariantesView> createState() => _ProductoVariantesViewState();
}

class _ProductoVariantesViewState extends State<_ProductoVariantesView> {
  String? _empresaId;
  String? _sedeId;
  List<ProductoAtributo> _atributosDisponibles = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      _sedeId = _getSedeIdActual(empresaState.context.sedes);
    }

    if (_empresaId != null) {
      context.read<ProductoVarianteCubit>().loadVariantes(
            productoId: widget.productoId,
            empresaId: _empresaId!,
          );
      context.read<ProductoAtributoCubit>().loadAtributos(_empresaId!);
    }
  }

  String _getSedeIdActual(List<dynamic> sedes) {
    if (sedes.isEmpty) {
      throw Exception('No hay sedes disponibles');
    }

    final selectedSedeId = context.read<SedeSelectionCubit>().selectedSedeId;

    if (selectedSedeId != null && sedes.any((s) => s.id == selectedSedeId)) {
      return selectedSedeId;
    }

    if (sedes.length == 1) {
      return sedes.first.id;
    }

    try {
      final sedePrincipal = sedes.firstWhere((s) => s.esPrincipal);
      return sedePrincipal.id;
    } catch (e) {
      return sedes.first.id;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.blue1 ,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Gestión de Variantes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.white),),
            Text(
              widget.productoNombre,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w400, color: AppColors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, size: 18,),
            onPressed: _loadData,
          ),
        ],
      ),
      
      body: MultiBlocListener(
        listeners: [
          BlocListener<ProductoVarianteCubit, ProductoVarianteState>(
            listener: (context, state) {
              if (state is ProductoVarianteOperationSuccess) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (state is ProductoVarianteError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.red,
                  ),
                );
              } else if (state is ProductoVarianteStockUpdated) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.message),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
          ),
          BlocListener<ProductoAtributoCubit, ProductoAtributoState>(
            listener: (context, state) {
              if (state is ProductoAtributoLoaded) {
                List<ProductoAtributo> atributosFiltrados;
                if (widget.categoriaId != null) {
                  // Filtrar atributos por categoría usando el método del cubit
                  final cubit = context.read<ProductoAtributoCubit>();
                  final lista = cubit.getAtributosPorCategoria(widget.categoriaId);
                  atributosFiltrados = lista.cast<ProductoAtributo>();
                } else {
                  atributosFiltrados = state.atributos;
                }
                setState(() {
                  _atributosDisponibles = atributosFiltrados;
                });
              }
            },
          ),
        ],
        child: BlocBuilder<ProductoVarianteCubit, ProductoVarianteState>(
          builder: (context, state) {
            if (state is ProductoVarianteLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is ProductoVarianteError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar variantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(state.message),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _loadData,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            }

            final variantes = _getVariantes(state);

            if (variantes.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.inventory_2_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(
                      'No hay variantes',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text('Crea la primera variante de este producto'),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => _loadData(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: variantes.length,
                itemBuilder: (context, index) {
                  final variante = variantes[index];
                  return _VarianteCard(
                    variante: variante,
                    onEdit: () => _showVarianteDialog(variante),
                    onDelete: () => _confirmDelete(variante),
                    onUpdateStock: () => _showStockDialog(variante),
                    onPrecioTap: () => _handlePrecioTap(variante),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: _buildFab(),
    );
  }

  Widget _buildFab() {
    return PopupMenuButton<String>(
      onSelected: (value) {
        if (value == 'nueva') {
          _showVarianteDialog(null);
        } else if (value == 'combinaciones') {
          _showGenerarCombinacionesDialog();
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'nueva',
          child: Row(
            children: [
              Icon(Icons.add, size: 20, color: AppColors.blue1),
              SizedBox(width: 8),
              Text('Nueva Variante'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'combinaciones',
          child: Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: AppColors.blue1),
              SizedBox(width: 8),
              Text('Generar Combinaciones'),
            ],
          ),
        ),
      ],
      child: FloatingActionButton.extended(
        heroTag: 'producto_variantes_fab',
        onPressed: null,
        icon: const Icon(Icons.add),
        label: const Text('Variantes'),
      ),
     
    );
  }

  void _showGenerarCombinacionesDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => GenerarCombinacionesDialog(
        productoId: widget.productoId,
        productoNombre: widget.productoNombre,
        atributosDisponibles: _atributosDisponibles,
        onSave: (data) {
          Navigator.of(dialogContext).pop();
          if (_empresaId != null) {
            context.read<ProductoVarianteCubit>().generarCombinaciones(
                  productoId: widget.productoId,
                  empresaId: _empresaId!,
                  data: data,
                );
          }
        },
      ),
    );
  }

  List<ProductoVariante> _getVariantes(ProductoVarianteState state) {
    if (state is ProductoVarianteLoaded) {
      return state.variantes;
    } else if (state is ProductoVarianteOperationSuccess) {
      return state.variantes;
    }
    return [];
  }

  void _showVarianteDialog(ProductoVariante? variante) {
    if (_empresaId == null) return;
    showDialog(
      context: context,
      builder: (dialogContext) => MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => locator<PrecioNivelCubit>()),
          BlocProvider(create: (_) => locator<VarianteAtributoCubit>()),
        ],
        child: ProductoVarianteFormDialog(
          productoId: widget.productoId,
          productoNombre: widget.productoNombre,
          productoIsActive: widget.productoIsActive,
          empresaId: _empresaId!,
          variante: variante,
          atributosDisponibles: _atributosDisponibles,
          onSave: (data) async {
            if (_empresaId == null) return;

            // Cerrar el dialog primero para evitar race conditions
            // ("setState after dispose" si el cubit emite mientras el dialog está cerrando)
            Navigator.of(dialogContext).pop();

            if (variante == null) {
              context.read<ProductoVarianteCubit>().crearVariante(
                    productoId: widget.productoId,
                    empresaId: _empresaId!,
                    data: data,
                  );
            } else {
              context.read<ProductoVarianteCubit>().actualizarVariante(
                    varianteId: variante.id,
                    productoId: widget.productoId,
                    empresaId: _empresaId!,
                    data: data,
                  );
            }
          },
        ),
      ),
    );
  }

  void _confirmDelete(ProductoVariante variante) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Estás seguro de eliminar la variante "${variante.nombre}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              if (_empresaId != null) {
                context.read<ProductoVarianteCubit>().eliminarVariante(
                      varianteId: variante.id,
                      productoId: widget.productoId,
                      empresaId: _empresaId!,
                    );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  Future<void> _handlePrecioTap(ProductoVariante variante) async {
    if (_empresaId == null || _sedeId == null) return;

    try {
      final getStockUseCase = locator<GetStockVarianteEnSedeUseCase>();
      final result = await getStockUseCase(
        varianteId: variante.id,
        sedeId: _sedeId!,
      );

      if (!mounted) return;

      if (result is Success<ProductoStock>) {
        final stock = result.data;

        showDialog(
          context: context,
          builder: (dialogContext) => MultiBlocProvider(
            providers: [
              BlocProvider(
                create: (_) => locator<ConfigurarPreciosCubit>(),
              ),
            ],
            child: ConfigurarPreciosDialog(
              stock: stock,
              empresaId: _empresaId!,
            ),
          ),
        ).then((result) {
          if (result == true && mounted) {
            _loadData();
          }
        });
      } else if (result is Error<ProductoStock>) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar stock: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showStockDialog(ProductoVariante variante) async {
    if (_empresaId == null || _sedeId == null) return;

    try {
      final getStockUseCase = locator<GetStockVarianteEnSedeUseCase>();
      final result = await getStockUseCase(
        varianteId: variante.id,
        sedeId: _sedeId!,
      );

      if (!mounted) return;

      if (result is Success<ProductoStock>) {
        final stock = result.data;

        showDialog(
          context: context,
          builder: (dialogContext) => BlocProvider(
            create: (_) => locator<AjustarStockCubit>(),
            child: AjustarStockDialog(
              stock: stock,
              empresaId: _empresaId!,
            ),
          ),
        ).then((result) {
          if (result == true && mounted) {
            _loadData();
          }
        });
      } else if (result is Error<ProductoStock>) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar stock: ${result.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _VarianteCard extends StatelessWidget {
  final ProductoVariante variante;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onUpdateStock;
  final VoidCallback onPrecioTap;

  const _VarianteCard({
    required this.variante,
    required this.onEdit,
    required this.onDelete,
    required this.onUpdateStock,
    required this.onPrecioTap,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: AppColors.blueborder,
      gradient: AppGradients.blueWhiteBlue(),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.only( left: 14, right: 14, bottom: 5, top: 5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(variante.nombre),
                      const SizedBox(height: 4),
                      AppLabelText(variante.sku)
                    ],
                  ),
                ),
                CustomActionMenu(
                  yNudge: 33,
                  menuWidth: 100,
                  borderRadius: 8,
                  itemHeight: 30,
                  items: [
                    ActionMenuItem(
                      type: ActionMenuType.edit,
                      label: 'Editar',
                      icon: Icons.edit_outlined,
                      color: AppColors.blue1,
                    ),
                    ActionMenuItem(
                      type: ActionMenuType.precio,
                      label: 'Precio',
                      icon: Icons.attach_money,
                      color: AppColors.blue1,
                    ),
                    ActionMenuItem(
                      type: ActionMenuType.stock,
                      label: 'Stock',
                      icon: Icons.inventory,
                      color: AppColors.green,
                    ),
                    ActionMenuItem(
                      type: ActionMenuType.delete,
                      label: 'Eliminar',
                      icon: Icons.delete_outlined,
                      color: AppColors.red,
                    ),
                  ],
                    onSelected: (ActionMenuType value) {
                    switch (value) {
                      case ActionMenuType.edit:
                        onEdit();
                        break;
                      case ActionMenuType.precio:
                        onPrecioTap();
                        break;
                      case ActionMenuType.stock:
                        onUpdateStock();
                        break;
                      case ActionMenuType.delete:
                        onDelete();
                        break;
                      default:
                        break;
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (variante.atributosValores.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: variante.atributosValores.map((atributoValor) {
                  return InfoChip(
                    icon: Icons.label, 
                    fontSize: 9,
                    text: '${atributoValor.atributo.nombre}: ${atributoValor.valor}',
                    backgroundColor: AppColors.white,
                    borderColor: AppColors.blue1,
                    borderRadius: 4,
                    contentPadding: EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                  );
                }).toList(),
              ),
              const SizedBox(height: 4),
            ],
            const Divider(),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppLabelText('Precio'),
                    Builder(builder: (context) {
                      final stocks = variante.stocksPorSede;
                      final stockInfo = stocks != null && stocks.isNotEmpty
                          ? (stocks.where((s) => s.precioConfigurado && s.precio != null).firstOrNull ?? stocks.first)
                          : null;
                      return Text(
                      'S/${(stockInfo?.precioEfectivo ?? 0.0).toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                    );
                    }),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppLabelText('Stock'),
                    Row(
                      children: [
                        Icon(
                          _getStockIcon(),
                          size: 16,
                          color: _getStockColor(),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${variante.stockTotal}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: _getStockColor(),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  IconData _getStockIcon() {
    if (variante.stockTotal == 0) return Icons.remove_circle;
    return Icons.check_circle;
  }

  Color _getStockColor() {
    if (variante.stockTotal == 0) return Colors.red;
    return Colors.green;
  }
}
