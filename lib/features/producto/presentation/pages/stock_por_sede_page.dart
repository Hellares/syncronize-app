import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/smart_appbar.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/theme/gradient_background.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_cubit.dart';
import '../../../sede/presentation/bloc/sede_list/sede_list_state.dart';
import '../bloc/stock_por_sede/stock_por_sede_cubit.dart';
import '../bloc/stock_por_sede/stock_por_sede_state.dart';
import '../bloc/ajustar_stock/ajustar_stock_cubit.dart';
import '../widgets/stock_card.dart';
import '../widgets/ajustar_stock_dialog.dart';
import '../widgets/historial_movimientos_bottom_sheet.dart';

class StockPorSedePage extends StatefulWidget {
  final String? sedeId; // Si es null, muestra selector de sede

  const StockPorSedePage({
    super.key,
    this.sedeId,
  });

  @override
  State<StockPorSedePage> createState() => _StockPorSedePageState();
}

class _StockPorSedePageState extends State<StockPorSedePage> {
  final _scrollController = ScrollController();
  String? _selectedSedeId;
  String? _empresaId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _selectedSedeId = widget.sedeId;
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.9) {
      context.read<StockPorSedeCubit>().loadMore();
    }
  }

  void _loadInitialData() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;

      // Cargar sedes si no hay sede seleccionada
      if (_selectedSedeId == null) {
        context.read<SedeListCubit>().loadSedes(_empresaId!);
      } else {
        _loadStock();
      }
    }
  }

  void _loadStock() {
    if (_selectedSedeId != null && _empresaId != null) {
      context.read<StockPorSedeCubit>().loadStockPorSede(
            sedeId: _selectedSedeId!,
            empresaId: _empresaId!,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: AppColors.white,
        title: 'Inventario por Sede',
        actions: [
          if (_selectedSedeId != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => context.read<StockPorSedeCubit>().reload(),
            ),
        ],
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Selector de sede
            _buildSedeSelector(),

            // Lista de stock
            Expanded(
              child: _selectedSedeId == null
                  ? _buildSedeSelectionPrompt()
                  : _buildStockList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSedeSelector() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: BlocBuilder<SedeListCubit, SedeListState>(
        builder: (context, state) {
          if (state is SedeListLoading) {
            return const Padding(
              padding: EdgeInsets.all(16),
              child: 
              Center(
                child: SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 1,)
                )
              ),
            );
          }

          if (state is SedeListLoaded) {
            final sedes = state.sedes.where((s) => s.isActive).toList();

            if (sedes.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'No hay sedes disponibles',
                  textAlign: TextAlign.center,
                ),
              );
            }

            return DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedSedeId,
                isExpanded: true,
                hint: Text('Seleccione una sede'),
                items: sedes.map((sede) {
                  return DropdownMenuItem(
                    value: sede.id,
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(sede.nombre),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSedeId = value;
                  });
                  _loadStock();
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildSedeSelectionPrompt() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.store, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Seleccione una sede',
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'para ver su inventario',
            style: TextStyle(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildStockList() {
    return BlocBuilder<StockPorSedeCubit, StockPorSedeState>(
      builder: (context, state) {
        if (state is StockPorSedeLoading) {
          return const CustomLoading();
        }

        if (state is StockPorSedeError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    state.message,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadStock,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is StockPorSedeLoaded) {
          if (state.stocks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay productos en esta sede',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              if (mounted) {
                context.read<StockPorSedeCubit>().reload();
              }
            },
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: state.stocks.length +
                  (state.hasMore ? 1 : 0), // +1 para el loading indicator
              itemBuilder: (context, index) {
                if (index >= state.stocks.length) {
                  // Loading indicator al final
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                final stock = state.stocks[index];
                return StockCard(
                  stock: stock,
                  onAjustar: () => _showAjustarDialog(stock),
                  onHistorial: () => HistorialMovimientosBottomSheet.show(
                    context,
                    stock,
                  ),
                );
              },
            ),
          );
        }

        return const SizedBox.shrink();
      },
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
      // Si se ajustó correctamente, recargar la lista
      if (result == true && mounted) {
        context.read<StockPorSedeCubit>().reload();
      }
    });
  }
}
