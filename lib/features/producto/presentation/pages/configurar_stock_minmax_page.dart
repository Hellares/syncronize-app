import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/domain/entities/sede.dart';

/// Page to configure stockMinimo and stockMaximo for all products in a sede.
class ConfigurarStockMinMaxPage extends StatefulWidget {
  const ConfigurarStockMinMaxPage({super.key});

  @override
  State<ConfigurarStockMinMaxPage> createState() =>
      _ConfigurarStockMinMaxPageState();
}

class _ConfigurarStockMinMaxPageState extends State<ConfigurarStockMinMaxPage> {
  final DioClient _dio = locator<DioClient>();

  List<Sede> _sedes = [];
  String? _selectedSedeId;

  List<Map<String, dynamic>> _productos = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  /// Controllers for min/max fields indexed by productoStock id
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _maxControllers = {};

  /// Track which items have been modified
  final Set<String> _modified = {};

  @override
  void initState() {
    super.initState();
    _loadSedes();
  }

  @override
  void dispose() {
    for (final c in _minControllers.values) {
      c.dispose();
    }
    for (final c in _maxControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _loadSedes() {
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      setState(() {
        _sedes = state.context.sedes;
        if (_sedes.length == 1) {
          _selectedSedeId = _sedes.first.id;
          _loadProductos(_selectedSedeId!);
        }
      });
    }
  }

  Future<void> _loadProductos(String sedeId) async {
    setState(() {
      _loading = true;
      _productos = [];
      _error = null;
      _modified.clear();
    });

    // Dispose old controllers
    for (final c in _minControllers.values) {
      c.dispose();
    }
    for (final c in _maxControllers.values) {
      c.dispose();
    }
    _minControllers.clear();
    _maxControllers.clear();

    try {
      final response = await _dio.get('/producto-stock/sede/$sedeId');
      final data = response.data;
      final List<Map<String, dynamic>> productos;
      if (data is List) {
        productos = data.cast<Map<String, dynamic>>();
      } else if (data is Map && data['data'] is List) {
        productos = (data['data'] as List).cast<Map<String, dynamic>>();
      } else {
        productos = [];
      }

      // Initialize controllers
      for (final p in productos) {
        final id = (p['id'] ?? p['_id'] ?? '').toString();
        if (id.isEmpty) continue;
        final minVal = p['stockMinimo'] ?? 0;
        final maxVal = p['stockMaximo'] ?? 0;
        _minControllers[id] = TextEditingController(text: '$minVal');
        _maxControllers[id] = TextEditingController(text: '$maxVal');
      }

      if (mounted) {
        setState(() {
          _productos = productos;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar productos';
          _loading = false;
        });
      }
    }
  }

  Future<void> _guardarCambios() async {
    if (_selectedSedeId == null || _modified.isEmpty) return;

    setState(() => _saving = true);

    try {
      final List<Map<String, dynamic>> updates = [];

      for (final id in _modified) {
        final minText = _minControllers[id]?.text ?? '0';
        final maxText = _maxControllers[id]?.text ?? '0';
        updates.add({
          'productoStockId': id,
          'stockMinimo': int.tryParse(minText) ?? 0,
          'stockMaximo': int.tryParse(maxText) ?? 0,
        });
      }

      await _dio.patch(
        '/producto-stock/sede/$_selectedSedeId/stock-minmax-bulk',
        data: {'items': updates},
      );

      if (mounted) {
        _modified.clear();
        SnackBarHelper.showSuccess(
            context, 'Stock Min/Max actualizado correctamente');
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al guardar cambios');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Configurar Stock Min/Max'),
        body: Column(
          children: [
            // Sede selector + save button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _buildSedeSelector(),
            ),
            const SizedBox(height: 12),

            // Content
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Text(
                            _error!,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 14),
                          ),
                        )
                      : _productos.isEmpty && _selectedSedeId != null
                          ? _buildEmptyState()
                          : _buildProductosList(),
            ),

            // Save button
            if (_modified.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: CustomButton(
                  text:
                      'Guardar Cambios (${_modified.length})',
                  isLoading: _saving,
                  onPressed: _saving ? null : _guardarCambios,
                ),
              ),
          ],
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
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              isDense: true,
            ),
            isExpanded: true,
            style:
                const TextStyle(fontSize: 13, color: AppColors.textPrimary),
            items: _sedes.map((sede) {
              return DropdownMenuItem<String>(
                value: sede.id,
                child:
                    Text(sede.nombre, style: const TextStyle(fontSize: 13)),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _selectedSedeId = val;
                  _productos = [];
                });
                _loadProductos(val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProductosList() {
    return RefreshIndicator(
      onRefresh: () async {
        if (_selectedSedeId != null) {
          await _loadProductos(_selectedSedeId!);
        }
      },
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _productos.length,
        itemBuilder: (context, index) {
          return _buildProductoCard(_productos[index]);
        },
      ),
    );
  }

  Widget _buildProductoCard(Map<String, dynamic> p) {
    final id = (p['id'] ?? p['_id'] ?? '').toString();
    final nombre = p['nombre'] as String? ??
        (p['producto'] is Map
            ? (p['producto'] as Map)['nombre'] as String?
            : null) ??
        'Sin nombre';
    final stockActual = p['stockActual'] ?? p['stock'] ?? 0;

    final minController = _minControllers[id];
    final maxController = _maxControllers[id];
    if (minController == null || maxController == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _modified.contains(id)
              ? AppColors.blue1.withValues(alpha: 0.5)
              : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product name and stock
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.inventory_2,
                    size: 18, color: AppColors.blue1),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 13,
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
                  color: AppColors.blue1.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Stock: $stockActual',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Min/Max fields
          Row(
            children: [
              Expanded(
                child: CustomText(
                  label: 'Stock Minimo',
                  controller: minController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    setState(() => _modified.add(id));
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  label: 'Stock Maximo',
                  controller: maxController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) {
                    setState(() => _modified.add(id));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            const Text(
              'No hay productos en esta sede',
              style: TextStyle(
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
