import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/pedido_marketplace.dart';
import '../bloc/mis_pedidos_cubit.dart';
import 'pedido_detail_page.dart';

enum MisPedidosModo { pedidos, compras }

class MisPedidosPage extends StatelessWidget {
  final MisPedidosModo modo;

  const MisPedidosPage({super.key, this.modo = MisPedidosModo.pedidos});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<MisPedidosCubit>()..loadPedidos(),
      child: _MisPedidosView(modo: modo),
    );
  }
}

class _MisPedidosView extends StatefulWidget {
  final MisPedidosModo modo;
  const _MisPedidosView({required this.modo});

  @override
  State<_MisPedidosView> createState() => _MisPedidosViewState();
}

class _MisPedidosViewState extends State<_MisPedidosView> {
  EstadoPedidoMarketplace? _selectedFilter;

  bool get _esCompras => widget.modo == MisPedidosModo.compras;

  // Estados activos (pedidos en proceso)
  static const _estadosActivos = {
    EstadoPedidoMarketplace.pendientePago,
    EstadoPedidoMarketplace.pagoEnviado,
    EstadoPedidoMarketplace.pagoValidado,
    EstadoPedidoMarketplace.enPreparacion,
    EstadoPedidoMarketplace.pagoRechazado,
  };

  // Estados completados (compras)
  static const _estadosCompras = {
    EstadoPedidoMarketplace.enviado,
    EstadoPedidoMarketplace.entregado,
  };

  List<PedidoMarketplace> _filtrarPorModo(List<PedidoMarketplace> pedidos) {
    final estados = _esCompras ? _estadosCompras : _estadosActivos;
    return pedidos.where((p) => estados.contains(p.estado)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.minimal,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: _esCompras ? 'Mis Compras' : 'Mis Pedidos'),
        body: Column(
          children: [
            // === FILTROS ===
            _buildFilterChips(),
            // === LISTA DE PEDIDOS ===
            Expanded(
              child: BlocBuilder<MisPedidosCubit, MisPedidosState>(
                builder: (context, state) {
                  if (state is MisPedidosLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is MisPedidosError) {
                    return _buildErrorState(context, state.message);
                  }
                  if (state is MisPedidosLoaded) {
                    final pedidos = _filtrarPorModo(state.pedidos);
                    if (pedidos.isEmpty) {
                      return _buildEmptyState();
                    }
                    return RefreshIndicator(
                      onRefresh: () => context.read<MisPedidosCubit>().reload(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: pedidos.length,
                        itemBuilder: (context, index) {
                          return _buildPedidoCard(context, pedidos[index]);
                        },
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = _esCompras
        ? <_FilterOption>[
            const _FilterOption(label: 'Todos', estado: null),
            const _FilterOption(label: 'Enviado', estado: EstadoPedidoMarketplace.enviado),
            const _FilterOption(label: 'Entregado', estado: EstadoPedidoMarketplace.entregado),
          ]
        : <_FilterOption>[
            const _FilterOption(label: 'Todos', estado: null),
            const _FilterOption(label: 'Pendiente', estado: EstadoPedidoMarketplace.pendientePago),
            const _FilterOption(label: 'Pago enviado', estado: EstadoPedidoMarketplace.pagoEnviado),
            const _FilterOption(label: 'En preparación', estado: EstadoPedidoMarketplace.enPreparacion),
          ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter.estado;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: AppText(
                filter.label,
                size: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.white : AppColors.blue3,
              ),
              selected: isSelected,
              onSelected: (_) {
                setState(() => _selectedFilter = filter.estado);
                context
                    .read<MisPedidosCubit>()
                    .filterByEstado(filter.estado);
              },
              selectedColor: AppColors.blue1,
              backgroundColor: AppColors.white,
              checkmarkColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? AppColors.blue1 : AppColors.greyLight,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPedidoCard(BuildContext context, PedidoMarketplace pedido) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PedidoDetailPage(pedidoId: pedido.id),
            ),
          );
          if (mounted) {
            context.read<MisPedidosCubit>().reload();
          }
        },
        child: GradientContainer(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cabecera: empresa + estado
              Row(
                children: [
                  // Logo empresa
                  if (pedido.empresa.logo != null &&
                      pedido.empresa.logo!.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        pedido.empresa.logo!,
                        width: 36,
                        height: 36,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildEmpresaPlaceholder(),
                      ),
                    )
                  else
                    _buildEmpresaPlaceholder(),
                  const SizedBox(width: 10),
                  // Nombre empresa + codigo
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText(
                          pedido.empresa.nombre,
                          fontWeight: FontWeight.w600,
                          size: 13,
                        ),
                        AppText(
                          pedido.codigo,
                          size: 11,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    ),
                  ),
                  // Estado chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: pedido.estadoColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: AppText(
                      pedido.estadoLabel,
                      size: 10,
                      fontWeight: FontWeight.w600,
                      color: pedido.estadoColor,
                    ),
                  ),
                ],
              ),
              const Divider(height: 16),
              // Items resumen
              ...pedido.detalles.take(3).map(
                    (detalle) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Expanded(
                            child: AppText(
                              '${detalle.descripcion} x${detalle.cantidad}',
                              size: 12,
                              color: AppColors.textSecondary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          AppText(
                            'S/ ${detalle.subtotal.toStringAsFixed(2)}',
                            size: 12,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
              if (pedido.detalles.length > 3)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AppText(
                    '+${pedido.detalles.length - 3} producto(s) mas',
                    size: 11,
                    color: AppColors.blue1,
                  ),
                ),
              const SizedBox(height: 8),
              // Total + fecha
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText(
                    _formatDate(pedido.creadoEn),
                    size: 11,
                    color: AppColors.textSecondary,
                  ),
                  AppText(
                    'S/ ${pedido.total.toStringAsFixed(2)}',
                    fontWeight: FontWeight.bold,
                    size: 15,
                    color: AppColors.blue1,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmpresaPlaceholder() {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.blue1.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.store, size: 20, color: AppColors.blue1),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 64,
            color: AppColors.grey.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          const AppText(
            'No tienes pedidos aun',
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(height: 8),
          const AppText(
            'Tus pedidos del marketplace apareceran aqui',
            size: 13,
            color: AppColors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.red),
          const SizedBox(height: 12),
          AppText(message, size: 14, color: AppColors.textSecondary, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => context.read<MisPedidosCubit>().reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year;
    return '$day/$month/$year';
  }
}

class _FilterOption {
  final String label;
  final EstadoPedidoMarketplace? estado;

  const _FilterOption({required this.label, required this.estado});
}
