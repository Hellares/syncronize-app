import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/services/export_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/movimiento_stock.dart';
import '../../domain/usecases/get_historial_movimientos_usecase.dart';

/// Pagina completa de Kardex para un stock especifico.
/// Muestra historial de movimientos con filtros, resumen y lista detallada.
class KardexPage extends StatefulWidget {
  final String stockId;
  final String? productoNombre;

  const KardexPage({
    super.key,
    required this.stockId,
    this.productoNombre,
  });

  @override
  State<KardexPage> createState() => _KardexPageState();
}

class _KardexPageState extends State<KardexPage> {
  final _useCase = locator<GetHistorialMovimientosUseCase>();

  // Estado de datos
  bool _isLoading = true;
  String? _errorMessage;
  KardexData? _kardexData;

  // Filtros
  bool _filtersExpanded = false;
  DateTime? _fechaDesde;
  DateTime? _fechaHasta;
  TipoMovimientoStock? _tipoFiltro;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _useCase(
      stockId: widget.stockId,
      limit: 200,
      tipo: _tipoFiltro?.apiValue,
      fechaDesde: _fechaDesde?.toIso8601String(),
      fechaHasta: _fechaHasta?.toIso8601String(),
    );

    if (!mounted) return;

    if (result is Success<KardexData>) {
      setState(() {
        _kardexData = result.data;
        _isLoading = false;
      });
    } else if (result is Error) {
      setState(() {
        _errorMessage = (result as Error).message;
        _isLoading = false;
      });
    }
  }

  void _clearFilters() {
    setState(() {
      _fechaDesde = null;
      _fechaHasta = null;
      _tipoFiltro = null;
    });
    _loadData();
  }

  Future<void> _pickDate(BuildContext context, bool isDesde) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isDesde
          ? (_fechaDesde ?? now.subtract(const Duration(days: 30)))
          : (_fechaHasta ?? now),
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
      locale: const Locale('es', 'PE'),
    );
    if (picked != null && mounted) {
      setState(() {
        if (isDesde) {
          _fechaDesde = picked;
        } else {
          _fechaHasta = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Kardex',
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Exportar Excel',
              onPressed: () async {
                try {
                  final exportService = locator<ExportService>();
                  await exportService.exportAndShare(
                    context: context,
                    endpoint: '/producto-stock/${widget.stockId}/movimientos/export',
                    queryParams: {
                      if (_tipoFiltro != null) 'tipo': _tipoFiltro!.apiValue,
                      if (_fechaDesde != null) 'fechaDesde': _fechaDesde!.toIso8601String(),
                      if (_fechaHasta != null) 'fechaHasta': _fechaHasta!.toIso8601String(),
                    },
                    fileName: 'kardex_${widget.productoNombre ?? widget.stockId}.xlsx',
                  );
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Error al exportar'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              onPressed: _loadData,
              tooltip: 'Actualizar',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: CustomScrollView(
            slivers: [
              // Nombre del producto
              if (widget.productoNombre != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    child: Text(
                      widget.productoNombre!,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),

              // Seccion de filtros
              SliverToBoxAdapter(child: _buildFiltersSection()),

              // Contenido principal
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_errorMessage != null)
                SliverFillRemaining(child: _buildErrorWidget())
              else if (_kardexData != null) ...[
                // Resumen
                SliverToBoxAdapter(child: _buildResumenCard()),
                // Lista de movimientos
                _buildMovimientosList(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTROS
  // ============================================================

  Widget _buildFiltersSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GradientContainer(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _filtersExpanded = !_filtersExpanded),
              child: Row(
                children: [
                  const Icon(Icons.filter_list, size: 18, color: AppColors.blue3),
                  const SizedBox(width: 8),
                  const Text(
                    'Filtros',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: AppColors.blue3,
                    ),
                  ),
                  const Spacer(),
                  if (_fechaDesde != null ||
                      _fechaHasta != null ||
                      _tipoFiltro != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Activos',
                        style: TextStyle(fontSize: 10, color: AppColors.blue),
                      ),
                    ),
                  const SizedBox(width: 4),
                  Icon(
                    _filtersExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 20,
                    color: AppColors.blue3,
                  ),
                ],
              ),
            ),
            if (_filtersExpanded) ...[
              const SizedBox(height: 12),
              // Fecha desde y hasta
              Row(
                children: [
                  Expanded(
                    child: _DateButton(
                      label: 'Desde',
                      date: _fechaDesde,
                      onTap: () => _pickDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DateButton(
                      label: 'Hasta',
                      date: _fechaHasta,
                      onTap: () => _pickDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tipo de movimiento
              DropdownButtonFormField<TipoMovimientoStock?>(
                initialValue: _tipoFiltro,
                decoration: InputDecoration(
                  labelText: 'Tipo de movimiento',
                  labelStyle: const TextStyle(fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  isDense: true,
                ),
                isExpanded: true,
                style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                items: [
                  const DropdownMenuItem<TipoMovimientoStock?>(
                    value: null,
                    child: Text('Todos', style: TextStyle(fontSize: 13)),
                  ),
                  ...TipoMovimientoStock.values.map(
                    (t) => DropdownMenuItem<TipoMovimientoStock?>(
                      value: t,
                      child: Text(t.label, style: const TextStyle(fontSize: 13)),
                    ),
                  ),
                ],
                onChanged: (val) => setState(() => _tipoFiltro = val),
              ),
              const SizedBox(height: 10),
              // Botones
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _clearFilters,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child: const Text('Limpiar', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _loadData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      child:
                          const Text('Aplicar', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // RESUMEN
  // ============================================================

  Widget _buildResumenCard() {
    if (_kardexData == null) return const SizedBox.shrink();

    final movimientos = _kardexData!.movimientos;
    int totalEntradas = 0;
    int totalSalidas = 0;

    for (final m in movimientos) {
      if (m.cantidad > 0) {
        totalEntradas += m.cantidad;
      } else {
        totalSalidas += m.cantidad.abs();
      }
    }

    final balance = totalEntradas - totalSalidas;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: GradientContainer(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.blue3,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ResumenStat(
                    label: 'Entradas',
                    value: '+$totalEntradas',
                    color: Colors.green,
                    icon: Icons.arrow_downward,
                  ),
                ),
                Expanded(
                  child: _ResumenStat(
                    label: 'Salidas',
                    value: '-$totalSalidas',
                    color: Colors.red,
                    icon: Icons.arrow_upward,
                  ),
                ),
                Expanded(
                  child: _ResumenStat(
                    label: 'Balance',
                    value: '${balance >= 0 ? '+' : ''}$balance',
                    color: balance >= 0 ? Colors.green : Colors.red,
                    icon: Icons.balance,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '${movimientos.length} movimientos',
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // LISTA DE MOVIMIENTOS
  // ============================================================

  Widget _buildMovimientosList() {
    final movimientos = _kardexData?.movimientos ?? [];

    if (movimientos.isEmpty) {
      return SliverFillRemaining(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'No hay movimientos registrados',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final movimiento = movimientos[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MovimientoCard(movimiento: movimiento),
            );
          },
          childCount: movimientos.length,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR
  // ============================================================

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error desconocido',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================================================
// WIDGETS INTERNOS
// ================================================================

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const _DateButton({
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                date != null
                    ? DateFormat('dd/MM/yyyy').format(date!)
                    : label,
                style: TextStyle(
                  fontSize: 12,
                  color: date != null ? AppColors.textPrimary : Colors.grey,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResumenStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _ResumenStat({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _MovimientoCard extends StatelessWidget {
  final MovimientoStock movimiento;

  const _MovimientoCard({required this.movimiento});

  @override
  Widget build(BuildContext context) {
    final tipo = movimiento.tipo;
    final color = tipo.color;

    return GradientContainer(
      padding: const EdgeInsets.all(12),
      borderColor: color.withValues(alpha: 0.4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icono a la izquierda
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              tipo.icon,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),

          // Contenido central
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tipo label
                Text(
                  tipo.label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                // Motivo
                if (movimiento.motivo != null &&
                    movimiento.motivo!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    movimiento.motivo!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                // Documento referencia
                if (movimiento.documentoReferencia != null) ...[
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.description, size: 12, color: Colors.blue[700]),
                      const SizedBox(width: 4),
                      Text(
                        movimiento.documentoReferencia!,
                        style: TextStyle(
                          color: Colors.blue[700],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 4),
                // Stock antes -> despues
                Text(
                  'Stock: ${movimiento.cantidadAnterior} -> ${movimiento.cantidadNueva}',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                // Fecha + usuario
                Row(
                  children: [
                    Icon(Icons.access_time, size: 11, color: Colors.grey[500]),
                    const SizedBox(width: 3),
                    Text(
                      DateFormatter.formatDateTime(movimiento.creadoEn),
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                    if (movimiento.usuarioNombre != null) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.person, size: 11, color: Colors.grey[500]),
                      const SizedBox(width: 3),
                      Flexible(
                        child: Text(
                          movimiento.usuarioNombre!,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
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

          // Cantidad a la derecha
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${movimiento.cantidad > 0 ? '+' : ''}${movimiento.cantidad}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
              Text(
                'unidades',
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
