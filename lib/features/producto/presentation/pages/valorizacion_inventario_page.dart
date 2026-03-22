import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/domain/entities/sede.dart';

/// Page showing total inventory valuation with breakdown by sede and top products.
class ValorizacionInventarioPage extends StatefulWidget {
  const ValorizacionInventarioPage({super.key});

  @override
  State<ValorizacionInventarioPage> createState() =>
      _ValorizacionInventarioPageState();
}

class _ValorizacionInventarioPageState
    extends State<ValorizacionInventarioPage> {
  final DioClient _dio = locator<DioClient>();
  final _currencyFormat = NumberFormat('#,##0.00', 'es_PE');

  List<Sede> _sedes = [];
  String? _selectedSedeId; // null = all sedes

  double _valorTotal = 0;
  int _stockTotal = 0;
  int _totalProductos = 0;
  List<Map<String, dynamic>> _porSede = [];
  List<Map<String, dynamic>> _topProductos = [];

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSedes();
  }

  void _loadSedes() {
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      setState(() {
        _sedes = state.context.sedes;
      });
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final queryParams = <String, dynamic>{};
      if (_selectedSedeId != null) {
        queryParams['sedeId'] = _selectedSedeId;
      }

      final response = await _dio.get(
        '/producto-stock/reportes/valorizacion',
        queryParameters: queryParams,
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        setState(() {
          _valorTotal = (data['valorGlobal'] ?? data['valorTotal'] ?? 0).toDouble();
          _stockTotal = (data['stockGlobal'] ?? data['stockTotal'] ?? 0) as int;
          _totalProductos = (data['totalSedes'] ?? data['totalProductos'] ?? 0) as int;

          final sedesData = data['porSede'];
          if (sedesData is List) {
            _porSede = sedesData.cast<Map<String, dynamic>>();
          } else {
            _porSede = [];
          }

          final topData = data['topProductos'];
          if (topData is List) {
            _topProductos = topData.cast<Map<String, dynamic>>();
          } else {
            _topProductos = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar valorizacion';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Valorizacion de Inventario',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Optional sede filter
              _buildSedeFilter(),
              const SizedBox(height: 16),

              if (_loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _error!,
                      style:
                          const TextStyle(color: Colors.red, fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else ...[
                // Grand total card
                _buildGrandTotalCard(),
                const SizedBox(height: 16),

                // Breakdown by sede
                if (_porSede.isNotEmpty && _selectedSedeId == null) ...[
                  _buildSectionTitle('Desglose por Sede'),
                  const SizedBox(height: 8),
                  ..._porSede.map((s) => _buildSedeCard(s)),
                  const SizedBox(height: 16),
                ],

                // Top 10 most valuable products
                if (_topProductos.isNotEmpty) ...[
                  _buildSectionTitle('Top Productos por Valor'),
                  const SizedBox(height: 8),
                  _buildTopProductosTable(),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSedeFilter() {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: CustomDropdown<String?>(
        label: 'Filtrar por Sede (opcional)',
        hintText: 'Todas las sedes',
        value: _selectedSedeId,
        borderColor: AppColors.blue1,
        items: [
          const DropdownItem<String?>(value: null, label: 'Todas las sedes'),
          ..._sedes.map((sede) => DropdownItem<String?>(value: sede.id, label: sede.nombre)),
        ],
        onChanged: (val) {
          setState(() => _selectedSedeId = val);
          _loadData();
        },
      ),
    );
  }

  Widget _buildGrandTotalCard() {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.attach_money, size: 30, color: AppColors.blue1),
          const SizedBox(height: 8),
          const Text(
            'Valor Total del Inventario',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'S/ ${_currencyFormat.format(_valorTotal)}',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.blue1,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(
                icon: Icons.inventory,
                label: 'Stock Total',
                value: '$_stockTotal',
                color: AppColors.blue2,
              ),
              _buildStatChip(
                icon: Icons.category,
                label: 'Productos',
                value: '$_totalProductos',
                color: Colors.teal,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 14,
        color: AppColors.blue3,
      ),
    );
  }

  Widget _buildSedeCard(Map<String, dynamic> s) {
    final nombre = s['sedeNombre'] as String? ?? 'Sede';
    final valor = (s['valorTotal'] ?? 0).toDouble();
    final stock = s['stockTotal'] ?? 0;
    final productos = s['totalProductos'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.store, size: 20, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '$productos productos',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock: $stock',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Text(
            'S/ ${_currencyFormat.format(valor)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopProductosTable() {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          // Header
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 24,
                  child: Text('#',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      )),
                ),
                const Expanded(
                  flex: 4,
                  child: Text('Producto',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      )),
                ),
                const SizedBox(
                  width: 40,
                  child: Text('Stock',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      )),
                ),
                const SizedBox(
                  width: 80,
                  child: Text('Valor',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                      )),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          // Rows
          ...List.generate(_topProductos.length, (i) {
            final p = _topProductos[i];
            final nombre = p['productoNombre'] as String? ??
                p['nombre'] as String? ??
                (p['producto'] is Map
                    ? (p['producto'] as Map)['nombre'] as String?
                    : null) ??
                'Sin nombre';
            final stock = p['stockActual'] ?? p['stock'] ?? 0;
            final valor = (p['valorTotal'] ??
                    (p['precio'] != null && p['stockActual'] != null
                        ? (p['precio'] as num) *
                            (p['stockActual'] as num)
                        : 0))
                .toDouble();
            final isEven = i % 2 == 0;

            return Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 8, vertical: 6),
              color: isEven ? Colors.transparent : Colors.grey.shade50,
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    child: Text(
                      '$stock',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Text(
                      'S/ ${_currencyFormat.format(valor)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
