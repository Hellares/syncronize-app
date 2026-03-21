import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/domain/entities/sede.dart';

/// Reporte de rotacion de productos: clasifica productos por velocidad de venta.
class ReporteRotacionPage extends StatefulWidget {
  const ReporteRotacionPage({super.key});

  @override
  State<ReporteRotacionPage> createState() => _ReporteRotacionPageState();
}

class _ReporteRotacionPageState extends State<ReporteRotacionPage> {
  final DioClient _dio = locator<DioClient>();

  List<Sede> _sedes = [];
  String? _selectedSedeId;
  int _dias = 90;
  String? _selectedClasificacion; // null = all

  int _totalProductos = 0;
  Map<String, int> _resumen = {};
  List<Map<String, dynamic>> _productos = [];

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
      final queryParams = <String, dynamic>{
        'dias': _dias.toString(),
      };
      if (_selectedSedeId != null) {
        queryParams['sedeId'] = _selectedSedeId;
      }

      final response = await _dio.get(
        '/producto-stock/reportes/rotacion',
        queryParameters: queryParams,
      );
      final data = response.data;

      if (data is Map<String, dynamic>) {
        setState(() {
          _totalProductos = (data['totalProductos'] ?? 0) as int;
          final resumenData = data['resumen'];
          if (resumenData is Map<String, dynamic>) {
            _resumen = {
              'ALTA': (resumenData['altaRotacion'] ?? 0) as int,
              'MEDIA': (resumenData['mediaRotacion'] ?? 0) as int,
              'BAJA': (resumenData['bajaRotacion'] ?? 0) as int,
              'SIN_MOVIMIENTO': (resumenData['sinMovimiento'] ?? 0) as int,
            };
          }
          final prodData = data['productos'];
          if (prodData is List) {
            _productos = prodData.cast<Map<String, dynamic>>();
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar reporte de rotacion';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Map<String, dynamic>> get _filteredProductos {
    if (_selectedClasificacion == null) return _productos;
    return _productos
        .where((p) => p['clasificacion'] == _selectedClasificacion)
        .toList();
  }

  Color _colorForClasificacion(String clasificacion) {
    switch (clasificacion) {
      case 'ALTA':
        return Colors.green;
      case 'MEDIA':
        return Colors.blue;
      case 'BAJA':
        return Colors.orange;
      case 'SIN_MOVIMIENTO':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _labelForClasificacion(String clasificacion) {
    switch (clasificacion) {
      case 'ALTA':
        return 'Alta';
      case 'MEDIA':
        return 'Media';
      case 'BAJA':
        return 'Baja';
      case 'SIN_MOVIMIENTO':
        return 'Sin Mov.';
      default:
        return clasificacion;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Rotacion de Productos'),
        body: RefreshIndicator(
          onRefresh: _loadData,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildPeriodChips(),
              const SizedBox(height: 12),
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
                const SizedBox(height: 12),
                _buildClasificacionFilter(),
                const SizedBox(height: 12),
                if (_filteredProductos.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                        'No hay productos para mostrar',
                        style: TextStyle(
                            fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ),
                  )
                else
                  ..._filteredProductos.map((p) => _buildProductCard(p)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodChips() {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Periodo de Analisis',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [30, 60, 90].map((d) {
              final selected = _dias == d;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$d dias'),
                  selected: selected,
                  onSelected: (val) {
                    if (val) {
                      setState(() => _dias = d);
                      _loadData();
                    }
                  },
                  selectedColor: AppColors.blue1.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.blue1 : AppColors.textSecondary,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
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
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.autorenew, size: 24, color: AppColors.blue1),
              const SizedBox(width: 8),
              Text(
                '$_totalProductos productos analizados',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: AppColors.blue3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildMiniCard(
                  'Alta', _resumen['ALTA'] ?? 0, Colors.green, Icons.trending_up),
              const SizedBox(width: 8),
              _buildMiniCard(
                  'Media', _resumen['MEDIA'] ?? 0, Colors.blue, Icons.trending_flat),
              const SizedBox(width: 8),
              _buildMiniCard(
                  'Baja', _resumen['BAJA'] ?? 0, Colors.orange, Icons.trending_down),
              const SizedBox(width: 8),
              _buildMiniCard(
                  'Sin Mov.', _resumen['SIN_MOVIMIENTO'] ?? 0, Colors.red, Icons.block),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCard(String label, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClasificacionFilter() {
    final options = <String?>[null, 'ALTA', 'MEDIA', 'BAJA', 'SIN_MOVIMIENTO'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final selected = _selectedClasificacion == opt;
          final label = opt == null ? 'Todos' : _labelForClasificacion(opt);
          final color = opt == null ? AppColors.blue1 : _colorForClasificacion(opt);

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                setState(() => _selectedClasificacion = opt);
              },
              selectedColor: color.withValues(alpha: 0.15),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? color : AppColors.textSecondary,
              ),
              checkmarkColor: color,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> p) {
    final nombre = p['productoNombre'] as String? ?? 'Producto';
    final sede = p['sedeNombre'] as String? ?? '';
    final stockActual = (p['stockActual'] ?? 0) as int;
    final unidadesVendidas = (p['unidadesVendidas'] ?? 0) as int;
    final clasificacion = p['clasificacion'] as String? ?? 'SIN_MOVIMIENTO';
    final color = _colorForClasificacion(clasificacion);
    final label = _labelForClasificacion(clasificacion);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.autorenew, size: 20, color: color),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (sede.isNotEmpty)
                      Text(
                        sede,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    if (sede.isNotEmpty) const SizedBox(width: 8),
                    Text(
                      'Vendidos: $unidadesVendidas',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Stock: $stockActual',
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
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
