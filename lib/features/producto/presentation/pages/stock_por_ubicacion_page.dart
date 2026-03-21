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

/// Page that shows stock organized by physical location (ubicacion).
/// User selects a sede, loads ubicaciones, selects one, then sees products.
class StockPorUbicacionPage extends StatefulWidget {
  const StockPorUbicacionPage({super.key});

  @override
  State<StockPorUbicacionPage> createState() => _StockPorUbicacionPageState();
}

class _StockPorUbicacionPageState extends State<StockPorUbicacionPage> {
  final DioClient _dio = locator<DioClient>();

  List<Sede> _sedes = [];
  String? _selectedSedeId;

  List<String> _ubicaciones = [];
  String? _selectedUbicacion;
  bool _loadingUbicaciones = false;

  List<Map<String, dynamic>> _productos = [];
  bool _loadingProductos = false;

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
        if (_sedes.length == 1) {
          _selectedSedeId = _sedes.first.id;
          _loadUbicaciones(_selectedSedeId!);
        }
      });
    }
  }

  Future<void> _loadUbicaciones(String sedeId) async {
    setState(() {
      _loadingUbicaciones = true;
      _ubicaciones = [];
      _selectedUbicacion = null;
      _productos = [];
      _error = null;
    });

    try {
      final response = await _dio.get('/producto-stock/sede/$sedeId/ubicaciones');
      final data = response.data;
      final List<String> ubicaciones;
      if (data is List) {
        ubicaciones = data.map((e) => e.toString()).toList();
      } else if (data is Map && data['data'] is List) {
        ubicaciones = (data['data'] as List).map((e) => e.toString()).toList();
      } else {
        ubicaciones = [];
      }

      if (mounted) {
        setState(() {
          _ubicaciones = ubicaciones;
          _loadingUbicaciones = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar ubicaciones';
          _loadingUbicaciones = false;
        });
      }
    }
  }

  Future<void> _loadProductos(String sedeId, String ubicacion) async {
    setState(() {
      _loadingProductos = true;
      _productos = [];
      _error = null;
    });

    try {
      final response = await _dio.get(
        '/producto-stock/sede/$sedeId/por-ubicacion',
        queryParameters: {'ubicacion': ubicacion},
      );
      final data = response.data;
      final List<Map<String, dynamic>> productos;
      if (data is List) {
        productos = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data['data'] is List) {
        productos = (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        productos = [];
      }

      if (mounted) {
        setState(() {
          _productos = productos;
          _loadingProductos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar productos';
          _loadingProductos = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Stock por Ubicacion'),
        body: RefreshIndicator(
          onRefresh: () async {
            if (_selectedSedeId != null && _selectedUbicacion != null) {
              await _loadProductos(_selectedSedeId!, _selectedUbicacion!);
            } else if (_selectedSedeId != null) {
              await _loadUbicaciones(_selectedSedeId!);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sede selector
              _buildSedeSelector(),
              const SizedBox(height: 16),

              // Ubicaciones
              if (_loadingUbicaciones)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (_ubicaciones.isNotEmpty)
                _buildUbicacionesSection(),

              if (_ubicaciones.isEmpty && !_loadingUbicaciones && _selectedSedeId != null)
                _buildEmptyState('No se encontraron ubicaciones para esta sede'),

              const SizedBox(height: 16),

              // Products
              if (_loadingProductos)
                const Center(child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ))
              else if (_productos.isNotEmpty)
                _buildProductosList()
              else if (_selectedUbicacion != null && !_loadingProductos)
                _buildEmptyState('No hay productos en esta ubicacion'),

              // Error
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSedeSelector() {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Seleccionar Sede',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedSedeId,
            decoration: InputDecoration(
              hintText: 'Seleccione una sede',
              hintStyle: const TextStyle(fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            isExpanded: true,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: _sedes.map((sede) {
              return DropdownMenuItem<String>(
                value: sede.id,
                child: Text(sede.nombre, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSedeId = val;
                  _selectedUbicacion = null;
                  _productos = [];
                });
                _loadUbicaciones(val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildUbicacionesSection() {
    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ubicaciones (${_ubicaciones.length})',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ubicaciones.map((ub) {
              final isSelected = _selectedUbicacion == ub;
              return ChoiceChip(
                label: Text(
                  ub,
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                selected: isSelected,
                selectedColor: AppColors.blue1,
                backgroundColor: Colors.grey.shade100,
                onSelected: (_) {
                  setState(() => _selectedUbicacion = ub);
                  if (_selectedSedeId != null) {
                    _loadProductos(_selectedSedeId!, ub);
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProductosList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Productos (${_productos.length})',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.blue3,
          ),
        ),
        const SizedBox(height: 10),
        ..._productos.map((p) => _buildProductoCard(p)),
      ],
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> p) {
    final nombre = p['nombre'] as String? ??
        (p['producto'] is Map ? (p['producto'] as Map)['nombre'] as String? : null) ??
        'Sin nombre';
    final stock = p['stock'] ?? p['cantidad'] ?? p['stockActual'] ?? 0;
    final ubicacion = p['ubicacion'] as String? ?? _selectedUbicacion ?? '-';

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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.inventory_2, size: 18, color: AppColors.blue1),
          ),
          const SizedBox(width: 10),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 12, color: Colors.brown.shade300),
                    const SizedBox(width: 4),
                    Text(
                      ubicacion,
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
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$stock',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.blue1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.location_off, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
