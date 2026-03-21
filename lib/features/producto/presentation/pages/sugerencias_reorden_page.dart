import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/domain/entities/sede.dart';

/// Sugerencias de reorden: productos bajo stock minimo con cantidad sugerida.
class SugerenciasReordenPage extends StatefulWidget {
  const SugerenciasReordenPage({super.key});

  @override
  State<SugerenciasReordenPage> createState() =>
      _SugerenciasReordenPageState();
}

class _SugerenciasReordenPageState extends State<SugerenciasReordenPage> {
  final DioClient _dio = locator<DioClient>();
  final _currencyFormat = NumberFormat('#,##0.00', 'es_PE');

  List<Sede> _sedes = [];
  String? _selectedSedeId;

  List<Map<String, dynamic>> _items = [];
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
        '/producto-stock/reportes/sugerencias-reorden',
        queryParameters: queryParams,
      );
      final data = response.data;

      if (data is List) {
        setState(() {
          _items = data.cast<Map<String, dynamic>>();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar sugerencias de reorden';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _totalBajoMinimo => _items.length;

  double get _valorEstimadoTotal {
    double total = 0;
    for (final item in _items) {
      total += (item['valorEstimado'] ?? 0).toDouble();
    }
    return total;
  }

  Color _urgencyColor(Map<String, dynamic> item) {
    final stockActual = (item['stockActual'] ?? 0) as int;
    if (stockActual == 0) return Colors.red;
    final stockMinimo = (item['stockMinimo'] ?? 1) as int;
    final ratio = stockActual / (stockMinimo == 0 ? 1 : stockMinimo);
    if (ratio <= 0.3) return Colors.red;
    if (ratio <= 0.6) return Colors.orange;
    return Colors.amber;
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Sugerencias de Reorden'),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                _buildSummaryCard(),
                const SizedBox(height: 16),
                if (_items.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.check_circle,
                              size: 48, color: Colors.green),
                          SizedBox(height: 12),
                          Text(
                            'Todos los productos estan por encima del stock minimo',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ..._items.map((item) => _buildProductCard(item)),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filtrar por Sede (opcional)',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String?>(
            value: _selectedSedeId,
            decoration: InputDecoration(
              hintText: 'Todas las sedes',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            isExpanded: true,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('Todas las sedes',
                    style: TextStyle(fontSize: 13)),
              ),
              ..._sedes.map((sede) {
                return DropdownMenuItem<String?>(
                  value: sede.id,
                  child: Text(sede.nombre,
                      style: const TextStyle(fontSize: 13)),
                );
              }),
            ],
            onChanged: (val) {
              setState(() => _selectedSedeId = val);
              _loadData();
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return GradientContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.shopping_cart_checkout,
              size: 36, color: Colors.deepPurple),
          const SizedBox(height: 8),
          const Text(
            'Resumen de Reorden',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatChip(
                icon: Icons.warning_amber,
                label: 'Bajo Minimo',
                value: '$_totalBajoMinimo',
                color: Colors.red,
              ),
              _buildStatChip(
                icon: Icons.attach_money,
                label: 'Valor Estimado',
                value: 'S/ ${_currencyFormat.format(_valorEstimadoTotal)}',
                color: Colors.green,
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
                  fontSize: 13,
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

  Widget _buildProductCard(Map<String, dynamic> item) {
    final nombre = item['productoNombre'] as String? ?? 'Producto';
    final codigo = item['codigoProducto'] as String? ?? '';
    final sede = item['sedeNombre'] as String? ?? '';
    final stockActual = (item['stockActual'] ?? 0) as int;
    final stockMinimo = (item['stockMinimo'] ?? 0) as int;
    final cantidadSugerida = (item['cantidadSugerida'] ?? 0) as int;
    final precioCosto = item['precioCosto'] != null
        ? (item['precioCosto'] as num).toDouble()
        : null;
    final valorEstimado = (item['valorEstimado'] ?? 0).toDouble();
    final urgency = _urgencyColor(item);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: urgency, width: 4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Pedir: $cantidadSugerida',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
              ),
            ],
          ),
          if (codigo.isNotEmpty || sede.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              [if (codigo.isNotEmpty) codigo, if (sede.isNotEmpty) sede]
                  .join(' - '),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              _buildMiniStat(
                'Stock Actual',
                '$stockActual',
                Colors.red,
              ),
              const SizedBox(width: 12),
              _buildMiniStat(
                'Stock Min.',
                '$stockMinimo',
                AppColors.blue2,
              ),
              if (precioCosto != null) ...[
                const SizedBox(width: 12),
                _buildMiniStat(
                  'P. Costo',
                  'S/ ${_currencyFormat.format(precioCosto)}',
                  Colors.grey,
                ),
              ],
              const Spacer(),
              Text(
                'S/ ${_currencyFormat.format(valorEstimado)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
