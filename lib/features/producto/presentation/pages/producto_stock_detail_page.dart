import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/stock_todas_sedes/stock_todas_sedes_cubit.dart';
import '../bloc/stock_todas_sedes/stock_todas_sedes_state.dart';
import '../bloc/ajustar_stock/ajustar_stock_cubit.dart';
import '../widgets/stock_card.dart';
import '../widgets/ajustar_stock_dialog.dart';
import '../widgets/historial_movimientos_bottom_sheet.dart';

class ProductoStockDetailPage extends StatefulWidget {
  final String productoId;
  final String? varianteId;
  final String? productoNombre; // Para mostrar en el título

  const ProductoStockDetailPage({
    super.key,
    required this.productoId,
    this.varianteId,
    this.productoNombre,
  });

  @override
  State<ProductoStockDetailPage> createState() =>
      _ProductoStockDetailPageState();
}

class _ProductoStockDetailPageState extends State<ProductoStockDetailPage> {
  String? _empresaId;

  @override
  void initState() {
    super.initState();
    _loadStockTodasSedes();
  }

  void _loadStockTodasSedes() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      context.read<StockTodasSedesCubit>().loadStockTodasSedes(
            productoId: widget.productoId,
            empresaId: _empresaId!,
            varianteId: widget.varianteId,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: widget.productoNombre ?? 'Stock del Producto',
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStockTodasSedes,
          ),
        ],
      ),
      body: GradientBackground(
        child: BlocBuilder<StockTodasSedesCubit, StockTodasSedesState>(
          builder: (context, state) {
            if (state is StockTodasSedesLoading) {
              return const CustomLoading();
            }

            if (state is StockTodasSedesError) {
              return _buildError(state.message);
            }

            if (state is StockTodasSedesLoaded) {
              return RefreshIndicator(
                onRefresh: () async => _loadStockTodasSedes(),
                child: CustomScrollView(
                  slivers: [
                    // Resumen global
                    SliverToBoxAdapter(
                      child: _buildResumenGlobal(state),
                    ),

                    // Título de la lista
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
                        child: Text(
                          'Stock por Sede (${state.stocks.length})',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    // Lista de stocks por sede
                    if (state.stocks.isEmpty)
                      SliverFillRemaining(
                        child: _buildEmpty(),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.all(16),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final stock = state.stocks[index];
                              return StockCard(
                                stock: stock,
                                onAjustar: () => _showAjustarDialog(stock),
                                onHistorial: () =>
                                    HistorialMovimientosBottomSheet.show(
                                  context,
                                  stock,
                                ),
                              );
                            },
                            childCount: state.stocks.length,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildResumenGlobal(StockTodasSedesLoaded state) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.blue1.withValues(alpha: 0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.blue1.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.inventory_2,
                  color: AppColors.blue1,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Stock Total',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Distribuido en ${state.totalSedes} sedes',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
              Text(
                state.stockTotal.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue1,
                ),
              ),
              Text(
                state.stockTotal.toString(),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  label: 'Sedes con\nstock',
                  value: state.sedesConStock.toString(),
                  color: Colors.green,
                  icon: Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Sedes sin\nstock',
                  value: state.sedesSinStock.toString(),
                  color: Colors.red,
                  icon: Icons.cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  label: 'Total de\nsedes',
                  value: state.totalSedes.toString(),
                  color: Colors.blue,
                  icon: Icons.store,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: color),
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Este producto no tiene stock en ninguna sede',
            style: const TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadStockTodasSedes,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAjustarDialog(stock) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider(
        create: (context) => locator<AjustarStockCubit>(),
        child: AjustarStockDialog(
          stock: stock,
          empresaId: _empresaId!,
        ),
      ),
    ).then((result) {
      if (result == true) {
        _loadStockTodasSedes();
      }
    });
  }
}
