import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../bloc/pedidos_empresa_cubit.dart';

class PedidosMarketplaceEmpresaPage extends StatelessWidget {
  const PedidosMarketplaceEmpresaPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PedidosEmpresaCubit>()..loadPedidos(),
      child: const _PedidosView(),
    );
  }
}

class _PedidosView extends StatefulWidget {
  const _PedidosView();

  @override
  State<_PedidosView> createState() => _PedidosViewState();
}

class _PedidosViewState extends State<_PedidosView> {
  String? _filtroEstado;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Pedidos Marketplace',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: Column(
          children: [
            _buildFiltros(),
            Expanded(
              child: BlocBuilder<PedidosEmpresaCubit, PedidosEmpresaState>(
                builder: (context, state) {
                  if (state is PedidosEmpresaLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state is PedidosEmpresaError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(state.message, style: TextStyle(color: Colors.grey.shade600)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () => context.read<PedidosEmpresaCubit>().reload(),
                            child: const Text('Reintentar'),
                          ),
                        ],
                      ),
                    );
                  }
                  if (state is PedidosEmpresaLoaded) {
                    if (state.pedidos.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            Text('No hay pedidos', style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: () => context.read<PedidosEmpresaCubit>().reload(),
                      color: AppColors.blue1,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: state.pedidos.length,
                        itemBuilder: (context, index) => _PedidoCard(
                          pedido: state.pedidos[index],
                          onTap: () => _navigateToDetail(state.pedidos[index]['id'] as String),
                        ),
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

  Widget _buildFiltros() {
    final filtros = [
      {'label': 'Todos', 'value': null},
      {'label': 'Pago Enviado', 'value': 'PAGO_ENVIADO'},
      {'label': 'Validados', 'value': 'PAGO_VALIDADO'},
      {'label': 'En Preparación', 'value': 'EN_PREPARACION'},
      {'label': 'Enviados', 'value': 'ENVIADO'},
      {'label': 'Pendientes', 'value': 'PENDIENTE_PAGO'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: filtros.map((f) {
          final isSelected = _filtroEstado == f['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(f['label'] as String, style: TextStyle(fontSize: 11, color: isSelected ? Colors.white : AppColors.blue1)),
              selected: isSelected,
              selectedColor: AppColors.blue1,
              backgroundColor: Colors.white,
              checkmarkColor: Colors.white,
              side: BorderSide(color: isSelected ? AppColors.blue1 : Colors.grey.shade300),
              onSelected: (_) {
                setState(() => _filtroEstado = f['value']);
                context.read<PedidosEmpresaCubit>().loadPedidos(estado: _filtroEstado);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _navigateToDetail(String id) async {
    await context.push('/empresa/pedidos-marketplace/$id');
    if (mounted) context.read<PedidosEmpresaCubit>().reload();
  }
}

class _PedidoCard extends StatelessWidget {
  final Map<String, dynamic> pedido;
  final VoidCallback onTap;

  const _PedidoCard({required this.pedido, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final codigo = pedido['codigo'] as String? ?? '';
    final estado = pedido['estado'] as String? ?? '';
    final total = double.tryParse(pedido['total']?.toString() ?? '') ?? 0;
    final nombre = pedido['nombreComprador'] as String? ?? '';
    final detalles = pedido['detalles'] as List<dynamic>? ?? [];
    final creadoEn = pedido['creadoEn'] as String?;
    final fecha = creadoEn != null ? DateTime.tryParse(creadoEn) : null;
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 10),
      borderColor: estado == 'PAGO_ENVIADO' ? Colors.orange.shade300 : AppColors.blueborder,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppSubtitle(codigo, fontSize: 13, color: AppColors.blue1),
                  const Spacer(),
                  _EstadoChip(estado: estado),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: AppSubtitle(nombre, fontSize: 12)),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text('${detalles.length} item${detalles.length != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                  const Spacer(),
                  AppSubtitle('S/ ${total.toStringAsFixed(2)}', fontSize: 14, color: AppColors.blue1),
                ],
              ),
              if (fecha != null) ...[
                const SizedBox(height: 4),
                Text(dateFormat.format(fecha), style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              ],
              if (estado == 'PAGO_ENVIADO') ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(4)),
                  child: Text('Requiere acción', style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w600)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String estado;
  const _EstadoChip({required this.estado});

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(_getLabel(), style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _getLabel() {
    const labels = {
      'PENDIENTE_PAGO': 'Pendiente pago', 'PAGO_ENVIADO': 'Pago enviado',
      'PAGO_VALIDADO': 'Pago validado', 'EN_PREPARACION': 'En preparación',
      'ENVIADO': 'Enviado', 'ENTREGADO': 'Entregado',
      'CANCELADO': 'Cancelado', 'PAGO_RECHAZADO': 'Pago rechazado',
    };
    return labels[estado] ?? estado;
  }

  Color _getColor() {
    switch (estado) {
      case 'PENDIENTE_PAGO': return Colors.grey;
      case 'PAGO_ENVIADO': return Colors.orange;
      case 'PAGO_VALIDADO': return Colors.blue;
      case 'EN_PREPARACION': return Colors.indigo;
      case 'ENVIADO': return Colors.teal;
      case 'ENTREGADO': return Colors.green;
      case 'CANCELADO': case 'PAGO_RECHAZADO': return Colors.red;
      default: return Colors.grey;
    }
  }
}
