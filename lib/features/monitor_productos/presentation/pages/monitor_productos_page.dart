import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../bloc/monitor_productos_cubit.dart';
import '../bloc/monitor_productos_state.dart';
import '../../domain/entities/monitor_productos.dart';

class MonitorProductosPage extends StatelessWidget {
  const MonitorProductosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<MonitorProductosCubit>()..loadMonitor(),
      child: const _MonitorProductosView(),
    );
  }
}

class _MonitorProductosView extends StatefulWidget {
  const _MonitorProductosView();

  @override
  State<_MonitorProductosView> createState() => _MonitorProductosViewState();
}

class _MonitorProductosViewState extends State<_MonitorProductosView> {
  String? _selectedSedeId;
  String? _expandedAlerta;
  final Set<String> _selectedIds = {};

  void _onSedeChanged(String? sedeId) {
    setState(() {
      _selectedSedeId = sedeId;
      _expandedAlerta = null;
      _selectedIds.clear();
    });
    context.read<MonitorProductosCubit>().loadMonitor(sedeId: sedeId);
  }

  void _toggleAlerta(String key) {
    setState(() {
      _expandedAlerta = _expandedAlerta == key ? null : key;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<ProductoAlerta> items) {
    setState(() {
      if (_selectedIds.length == items.length) {
        _selectedIds.clear();
      } else {
        _selectedIds
          ..clear()
          ..addAll(items.map((e) => e.id));
      }
    });
  }

  List<ProductoAlerta> _getAlertItems(AlertasProductos alertas) {
    switch (_expandedAlerta) {
      case 'sinPrecio':
        return alertas.sinPrecio;
      case 'sinPrecioCosto':
        return alertas.sinPrecioCosto;
      case 'sinUbicacion':
        return alertas.sinUbicacion;
      case 'sinImagen':
        return alertas.sinImagen;
      case 'stockCero':
        return alertas.stockCero;
      case 'bajoMinimo':
        return alertas.bajoMinimo;
      case 'marketplaceSinImagen':
        return alertas.marketplaceSinImagen;
      case 'precioSinIgv':
        return alertas.precioSinIgv;
      case 'sinBarcode':
        return alertas.sinBarcode;
      default:
        return [];
    }
  }

  Future<void> _executeBulkAction(BuildContext context) async {
    if (_selectedIds.isEmpty) return;
    final cubit = context.read<MonitorProductosCubit>();
    final ids = _selectedIds.toList();

    switch (_expandedAlerta) {
      case 'precioSinIgv':
        final ok = await cubit.bulkPrecioIgv(ids, true);
        if (ok && mounted) {
          _showSnackBar('Precios actualizados con IGV');
          setState(() => _selectedIds.clear());
        }
        break;
      case 'marketplaceSinImagen':
      case 'sinImagen':
        // These don't have a bulk action, just info
        break;
      case 'sinUbicacion':
        final ubicacion = await _showUbicacionDialog(context);
        if (ubicacion != null && ubicacion.isNotEmpty) {
          final ok = await cubit.bulkUbicacion(ids, ubicacion);
          if (ok && mounted) {
            _showSnackBar('Ubicación asignada');
            setState(() => _selectedIds.clear());
          }
        }
        break;
      default:
        break;
    }
  }

  Future<String?> _showUbicacionDialog(BuildContext context) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Asignar Ubicación'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Ubicación',
            hintText: 'Ej: Estante A-01',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Asignar'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Monitor de Productos',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: GradientBackground(
        child: BlocBuilder<MonitorProductosCubit, MonitorProductosState>(
          builder: (context, state) {
            if (state is MonitorProductosLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state is MonitorProductosError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(state.message, textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: () => context.read<MonitorProductosCubit>().loadMonitor(sedeId: _selectedSedeId),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              );
            }
            if (state is MonitorProductosLoaded) {
              return RefreshIndicator(
                onRefresh: () => context.read<MonitorProductosCubit>().loadMonitor(sedeId: _selectedSedeId),
                color: AppColors.blue1,
                child: Stack(
                  children: [
                    ListView(
                      padding: EdgeInsets.only(
                        left: 12,
                        right: 12,
                        top: 12,
                        bottom: _selectedIds.isNotEmpty ? 80 : 12,
                      ),
                      children: [
                        _buildSedeSelector(context),
                        const SizedBox(height: 12),
                        _buildResumen(state.data.estadisticas),
                        const SizedBox(height: 16),
                        const AppSubtitle('Alertas', fontSize: 16, color: AppColors.blue1),
                        const SizedBox(height: 8),
                        _buildAlertasGrid(state.data.alertas),
                        if (_expandedAlerta != null) ...[
                          const SizedBox(height: 12),
                          _buildExpandedAlertSection(state.data.alertas),
                        ],
                        const SizedBox(height: 16),
                        // Marketplace management button
                        GradientContainer(
                          borderColor: Colors.purple.withValues(alpha: 0.3),
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.purple.withValues(alpha: 0.05)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.storefront, color: Colors.purple),
                            title: Text(
                              'Gestionar Marketplace',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.purple.shade700),
                            ),
                            subtitle: Text(
                              '${state.data.estadisticas.visibleMarketplace} visibles / ${state.data.estadisticas.noVisibleMarketplace} ocultos',
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.purple),
                            onTap: () => _showMarketplaceSheet(context),
                          ),
                        ),
                        const SizedBox(height: 80),
                      ],
                    ),
                    if (_selectedIds.isNotEmpty)
                      _buildBulkActionBar(context),
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

  void _showMarketplaceSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _MarketplaceSheet(
        onChanged: () {
          context.read<MonitorProductosCubit>().loadMonitor(sedeId: _selectedSedeId);
        },
      ),
    );
  }

  Widget _buildSedeSelector(BuildContext context) {
    return BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
      builder: (context, state) {
        if (state is! EmpresaContextLoaded) return const SizedBox.shrink();
        final sedes = state.context.sedes;
        if (sedes.length <= 1) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedSedeId,
              isExpanded: true,
              hint: const Text('Todas las sedes', style: TextStyle(fontSize: 13)),
              icon: const Icon(Icons.store, size: 20, color: AppColors.blue1),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Todas las sedes', style: TextStyle(fontSize: 13)),
                ),
                ...sedes.map((s) => DropdownMenuItem<String?>(
                      value: s.id,
                      child: Text(s.nombre, style: const TextStyle(fontSize: 13)),
                    )),
              ],
              onChanged: _onSedeChanged,
            ),
          ),
        );
      },
    );
  }

  Widget _buildResumen(EstadisticasProductos stats) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 72,
                        height: 72,
                        child: CircularProgressIndicator(
                          value: stats.porcentajeCatalogoCompleto / 100,
                          strokeWidth: 7,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            stats.porcentajeCatalogoCompleto >= 80
                                ? Colors.green
                                : stats.porcentajeCatalogoCompleto >= 50
                                    ? Colors.orange
                                    : Colors.red,
                          ),
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${stats.porcentajeCatalogoCompleto.toStringAsFixed(0)}%',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Completo',
                            style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppSubtitle(
                        '${stats.totalProductos} productos',
                        fontSize: 15,
                        color: AppColors.blue1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${stats.listosParaVenta} listos para venta',
                        style: TextStyle(fontSize: 11, color: Colors.green.shade700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: [
                _MiniStatCard(
                  label: 'Con Stock',
                  count: stats.conStock,
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _MiniStatCard(
                  label: 'Con Precio',
                  count: stats.conPrecio,
                  icon: Icons.attach_money,
                  color: Colors.teal,
                ),
                _MiniStatCard(
                  label: 'Con Ubicación',
                  count: stats.conUbicacion,
                  icon: Icons.location_on,
                  color: Colors.blue,
                ),
                _MiniStatCard(
                  label: 'Marketplace',
                  count: stats.visibleMarketplace,
                  icon: Icons.storefront,
                  color: Colors.purple,
                ),
                _MiniStatCard(
                  label: 'Con Imagen',
                  count: stats.conImagen,
                  icon: Icons.image,
                  color: Colors.indigo,
                ),
                _MiniStatCard(
                  label: 'En Oferta',
                  count: stats.enOferta,
                  icon: Icons.local_offer,
                  color: Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertasGrid(AlertasProductos alertas) {
    final alertItems = [
      _AlertData('sinPrecio', 'Sin Precio', alertas.sinPrecio.length, Icons.money_off, Colors.red),
      _AlertData('sinPrecioCosto', 'Sin Precio Costo', alertas.sinPrecioCosto.length, Icons.money_off_csred, Colors.red.shade700),
      _AlertData('sinUbicacion', 'Sin Ubicación', alertas.sinUbicacion.length, Icons.location_off, Colors.orange),
      _AlertData('sinImagen', 'Sin Imagen', alertas.sinImagen.length, Icons.image_not_supported, Colors.amber.shade800),
      _AlertData('stockCero', 'Stock en Cero', alertas.stockCero.length, Icons.remove_shopping_cart, Colors.red.shade900),
      _AlertData('bajoMinimo', 'Bajo Mínimo', alertas.bajoMinimo.length, Icons.trending_down, Colors.deepOrange),
      _AlertData('marketplaceSinImagen', 'MKP Sin Imagen', alertas.marketplaceSinImagen.length, Icons.storefront, Colors.purple),
      _AlertData('precioSinIgv', 'Precio Sin IGV', alertas.precioSinIgv.length, Icons.receipt_long, Colors.brown),
      _AlertData('sinBarcode', 'Sin Código Barras', alertas.sinBarcode.length, Icons.qr_code_2, Colors.indigo),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: alertItems
          .map((a) => _AlertCard(
                title: a.title,
                count: a.count,
                icon: a.icon,
                color: a.color,
                isExpanded: _expandedAlerta == a.key,
                onTap: () => _toggleAlerta(a.key),
              ))
          .toList(),
    );
  }

  Widget _buildExpandedAlertSection(AlertasProductos alertas) {
    final items = _getAlertItems(alertas);
    if (items.isEmpty) {
      return GradientContainer(
        borderColor: Colors.green.shade200,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: Column(
              children: [
                Icon(Icons.check_circle_outline, size: 40, color: Colors.green.shade400),
                const SizedBox(height: 8),
                Text('Sin alertas', style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
              ],
            ),
          ),
        ),
      );
    }

    final hasBulkAction = _expandedAlerta == 'sinUbicacion' ||
        _expandedAlerta == 'precioSinIgv';

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Column(
        children: [
          if (hasBulkAction)
            Padding(
              padding: const EdgeInsets.only(left: 8, right: 14, top: 8),
              child: Row(
                children: [
                  Checkbox(
                    value: _selectedIds.length == items.length && items.isNotEmpty,
                    tristate: true,
                    onChanged: (_) => _selectAll(items),
                    activeColor: AppColors.blue1,
                  ),
                  Text(
                    'Seleccionar todos (${items.length})',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            itemCount: items.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
            itemBuilder: (context, index) {
              final item = items[index];
              return _ProductoAlertaTile(
                item: item,
                isSelected: _selectedIds.contains(item.id),
                showCheckbox: hasBulkAction,
                onToggle: () => _toggleSelection(item.id),
                expandedAlerta: _expandedAlerta,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBulkActionBar(BuildContext context) {
    String actionLabel;
    IconData actionIcon;

    switch (_expandedAlerta) {
      case 'sinUbicacion':
        actionLabel = 'Asignar Ubicación';
        actionIcon = Icons.location_on;
        break;
      case 'precioSinIgv':
        actionLabel = 'Marcar Incluye IGV';
        actionIcon = Icons.receipt_long;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedIds.length} seleccionados',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.blue1),
                ),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () => _executeBulkAction(context),
                icon: Icon(actionIcon, size: 18),
                label: Text(actionLabel, style: const TextStyle(fontSize: 13)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.blue1,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Mini Stat Card ──────────────────────────────────────────────────────────

class _MiniStatCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.label,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                '$count',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.8)),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ── Alert Card ──────────────────────────────────────────────────────────────

class _AlertData {
  final String key;
  final String title;
  final int count;
  final IconData icon;
  final Color color;

  const _AlertData(this.key, this.title, this.count, this.icon, this.color);
}

class _AlertCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AlertCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isExpanded ? color.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isExpanded ? color : Colors.grey.shade200,
            width: isExpanded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: count > 0 ? color.withValues(alpha: 0.15) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: count > 0 ? color : Colors.grey),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: count > 0 ? color : Colors.grey,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$count producto${count != 1 ? 's' : ''}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (count > 0)
              Icon(
                isExpanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: color,
              ),
          ],
        ),
      ),
    );
  }
}

// ── Producto Alerta Tile ────────────────────────────────────────────────────

class _ProductoAlertaTile extends StatelessWidget {
  final ProductoAlerta item;
  final bool isSelected;
  final bool showCheckbox;
  final VoidCallback onToggle;
  final String? expandedAlerta;

  const _ProductoAlertaTile({
    required this.item,
    required this.isSelected,
    required this.showCheckbox,
    required this.onToggle,
    this.expandedAlerta,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: showCheckbox ? onToggle : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            if (showCheckbox)
              Checkbox(
                value: isSelected,
                onChanged: (_) => onToggle(),
                activeColor: AppColors.blue1,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.nombre,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (item.codigoEmpresa != null && item.codigoEmpresa!.isNotEmpty) ...[
                        Text(
                          item.codigoEmpresa!,
                          style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                        ),
                        const SizedBox(width: 8),
                      ],
                      if (item.sedeNombre != null) ...[
                        Icon(Icons.store, size: 10, color: Colors.grey.shade500),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            item.sedeNombre!,
                            style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Stock: ${item.stockActual}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: item.stockActual > 0 ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                ),
                if (item.precio != null)
                  Text(
                    'S/ ${item.precio!.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                if (item.ubicacion != null && item.ubicacion!.isNotEmpty)
                  Text(
                    item.ubicacion!,
                    style: TextStyle(fontSize: 10, color: Colors.blue.shade600),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet for managing marketplace visibility
class _MarketplaceSheet extends StatefulWidget {
  final VoidCallback onChanged;
  const _MarketplaceSheet({required this.onChanged});

  @override
  State<_MarketplaceSheet> createState() => _MarketplaceSheetState();
}

class _MarketplaceSheetState extends State<_MarketplaceSheet> {
  final DioClient _dio = locator<DioClient>();
  List<Map<String, dynamic>> _productos = [];
  bool _loading = true;
  final Set<String> _selectedIds = {};
  bool _selectMode = false;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    setState(() => _loading = true);
    try {
      final response = await _dio.get('/producto-stock/marketplace-productos');
      if (mounted) {
        setState(() {
          _productos = (response.data as List<dynamic>).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleSingle(String productoId, bool visible) async {
    try {
      await _dio.patch('/producto-stock/bulk/marketplace', data: {
        'productoIds': [productoId],
        'visible': visible,
      });
      _loadProductos();
      widget.onChanged();
    } catch (_) {}
  }

  Future<void> _bulkToggle(bool visible) async {
    if (_selectedIds.isEmpty) return;
    try {
      await _dio.patch('/producto-stock/bulk/marketplace', data: {
        'productoIds': _selectedIds.toList(),
        'visible': visible,
      });
      setState(() {
        _selectedIds.clear();
        _selectMode = false;
      });
      _loadProductos();
      widget.onChanged();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final visibles = _productos.where((p) => p['visibleMarketplace'] == true).length;
    final ocultos = _productos.length - visibles;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollController) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.storefront, color: Colors.purple, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text('Gestionar Marketplace',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    ),
                    if (!_selectMode)
                      TextButton.icon(
                        onPressed: () => setState(() => _selectMode = true),
                        icon: const Icon(Icons.checklist, size: 16),
                        label: const Text('Seleccionar', style: TextStyle(fontSize: 11)),
                      )
                    else
                      TextButton(
                        onPressed: () => setState(() { _selectMode = false; _selectedIds.clear(); }),
                        child: const Text('Cancelar', style: TextStyle(fontSize: 11)),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _chip('Visibles: $visibles', Colors.green),
                    const SizedBox(width: 8),
                    _chip('Ocultos: $ocultos', Colors.red),
                    const SizedBox(width: 8),
                    _chip('Total: ${_productos.length}', Colors.grey),
                  ],
                ),
              ],
            ),
          ),
          if (_selectMode && _selectedIds.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.purple.shade50,
              child: Row(
                children: [
                  Text('${_selectedIds.length} seleccionados',
                      style: TextStyle(fontSize: 12, color: Colors.purple.shade700, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => _bulkToggle(true),
                    icon: Icon(Icons.visibility, size: 14, color: Colors.green.shade700),
                    label: Text('Mostrar', style: TextStyle(fontSize: 11, color: Colors.green.shade700)),
                  ),
                  TextButton.icon(
                    onPressed: () => _bulkToggle(false),
                    icon: Icon(Icons.visibility_off, size: 14, color: Colors.red.shade700),
                    label: Text('Ocultar', style: TextStyle(fontSize: 11, color: Colors.red.shade700)),
                  ),
                ],
              ),
            ),
          const Divider(height: 1),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: ListView.separated(
                controller: scrollController,
                itemCount: _productos.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                itemBuilder: (ctx, index) {
                  final p = _productos[index];
                  final visible = p['visibleMarketplace'] == true;
                  final id = p['id'] as String;

                  return ListTile(
                    dense: true,
                    leading: _selectMode
                        ? Checkbox(
                            value: _selectedIds.contains(id),
                            activeColor: Colors.purple,
                            onChanged: (v) {
                              setState(() {
                                if (v == true) _selectedIds.add(id);
                                else _selectedIds.remove(id);
                              });
                            },
                          )
                        : Icon(
                            visible ? Icons.visibility : Icons.visibility_off,
                            size: 20,
                            color: visible ? Colors.green : Colors.grey,
                          ),
                    title: Text(
                      p['nombre'] as String? ?? '',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${p['codigoEmpresa'] ?? ''} • Stock: ${p['stockActual'] ?? 0}${p['precio'] != null ? ' • S/ ${(p['precio'] as num).toStringAsFixed(2)}' : ''}',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    trailing: _selectMode
                        ? null
                        : Switch(
                            value: visible,
                            activeColor: Colors.green,
                            onChanged: (v) => _toggleSingle(id, v),
                          ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}
