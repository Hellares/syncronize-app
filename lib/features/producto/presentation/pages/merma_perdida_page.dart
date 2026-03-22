import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/widgets/producto_sede_selector/producto_sede_selector.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../domain/entities/movimiento_stock.dart';

/// Page showing waste/loss (merma y perdida) summary and allowing to register new ones.
class MermaPerdidaPage extends StatefulWidget {
  const MermaPerdidaPage({super.key});

  @override
  State<MermaPerdidaPage> createState() => _MermaPerdidaPageState();
}

class _MermaPerdidaPageState extends State<MermaPerdidaPage> {
  final DioClient _dio = locator<DioClient>();

  List<Sede> _sedes = [];
  String? _selectedSedeId;
  String _empresaId = '';

  Map<String, dynamic> _resumen = {};
  List<Map<String, dynamic>> _movimientos = [];
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
        _empresaId = state.context.empresa.id;
        if (_sedes.length == 1) {
          _selectedSedeId = _sedes.first.id;
          _loadData(_selectedSedeId!);
        }
      });
    }
  }

  Future<void> _loadData(String sedeId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final response = await _dio.get(
        '/producto-stock/reportes/mermas',
        queryParameters: {'sedeId': sedeId},
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _resumen = (data['resumen'] as Map<String, dynamic>?) ?? {};
          final movs = data['movimientos'];
          if (movs is List) {
            _movimientos = movs.cast<Map<String, dynamic>>();
          } else {
            _movimientos = [];
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Error al cargar datos de mermas';
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showRegistrarSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _RegistrarMermaSheet(
        empresaId: _empresaId,
        sedeId: _selectedSedeId,
        sedes: _sedes,
        dio: _dio,
        onSuccess: () {
          if (_selectedSedeId != null) {
            _loadData(_selectedSedeId!);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(title: 'Merma y Perdida'),
        floatingActionButton: _selectedSedeId != null
            ? FloatingActionButton(
                backgroundColor: AppColors.blue1,
                onPressed: _showRegistrarSheet,
                child: const Icon(Icons.add, color: Colors.white),
              )
            : null,
        body: RefreshIndicator(
          onRefresh: () async {
            if (_selectedSedeId != null) {
              await _loadData(_selectedSedeId!);
            }
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSedeSelector(),
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
              else if (_selectedSedeId != null) ...[
                _buildResumenCard(),
                const SizedBox(height: 16),
                _buildMovimientosList(),
              ],
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
                setState(() => _selectedSedeId = val);
                _loadData(val);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildResumenCard() {
    final tipos = <_ResumenItem>[
      _ResumenItem(
        label: 'Merma',
        icon: Icons.broken_image,
        color: Colors.orange,
        cantidad: _resumen['merma']?['cantidad'] ?? 0,
      ),
      _ResumenItem(
        label: 'Perdida',
        icon: Icons.search_off,
        color: Colors.red,
        cantidad: _resumen['perdida']?['cantidad'] ?? 0,
      ),
      _ResumenItem(
        label: 'Baja',
        icon: Icons.delete_forever,
        color: Colors.grey,
        cantidad: _resumen['baja']?['cantidad'] ?? 0,
      ),
      _ResumenItem(
        label: 'Donacion',
        icon: Icons.volunteer_activism,
        color: Colors.green,
        cantidad: _resumen['donacion']?['cantidad'] ?? 0,
      ),
    ];

    return GradientContainer(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de Mermas y Perdidas',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.blue3,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 2.5,
            children: tipos.map((item) {
              return Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(item.icon, size: 20, color: item.color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.label,
                            style: TextStyle(
                              fontSize: 11,
                              color: item.color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            '${item.cantidad} unidades',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMovimientosList() {
    if (_movimientos.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Icon(Icons.inbox, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'No hay movimientos de merma/perdida registrados',
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Movimientos recientes (${_movimientos.length})',
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.blue3,
          ),
        ),
        const SizedBox(height: 10),
        ..._movimientos.map((m) => _buildMovimientoCard(m)),
      ],
    );
  }

  Widget _buildMovimientoCard(Map<String, dynamic> m) {
    final tipo = m['tipo'] as String? ?? '';
    final cantidad = m['cantidad'] ?? 0;
    final motivo = m['motivo'] as String? ?? '-';
    final productoNombre = m['productoNombre'] as String? ??
        (m['producto'] is Map
            ? (m['producto'] as Map)['nombre'] as String?
            : null) ??
        'Producto';
    final fecha = m['createdAt'] as String? ?? m['fecha'] as String? ?? '';
    String fechaFormatted = '';
    if (fecha.isNotEmpty) {
      try {
        final dt = DateTime.parse(fecha);
        fechaFormatted = DateFormat('dd/MM/yyyy HH:mm').format(dt);
      } catch (_) {
        fechaFormatted = fecha;
      }
    }

    Color tipoColor;
    IconData tipoIcon;
    if (tipo.contains('MERMA')) {
      tipoColor = Colors.orange;
      tipoIcon = Icons.broken_image;
    } else if (tipo.contains('PERDIDA') || tipo.contains('ROBO')) {
      tipoColor = Colors.red;
      tipoIcon = Icons.search_off;
    } else if (tipo.contains('BAJA')) {
      tipoColor = Colors.grey;
      tipoIcon = Icons.delete_forever;
    } else if (tipo.contains('DONACION')) {
      tipoColor = Colors.green;
      tipoIcon = Icons.volunteer_activism;
    } else {
      tipoColor = Colors.blueGrey;
      tipoIcon = Icons.remove_circle_outline;
    }

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
              color: tipoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(tipoIcon, size: 18, color: tipoColor),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productoNombre,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  motivo,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (fechaFormatted.isNotEmpty)
                  Text(
                    fechaFormatted,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: tipoColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$cantidad',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: tipoColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenItem {
  final String label;
  final IconData icon;
  final Color color;
  final int cantidad;

  const _ResumenItem({
    required this.label,
    required this.icon,
    required this.color,
    required this.cantidad,
  });
}

/// Bottom sheet to register a new merma/perdida
class _RegistrarMermaSheet extends StatefulWidget {
  final String empresaId;
  final String? sedeId;
  final List<Sede> sedes;
  final DioClient dio;
  final VoidCallback onSuccess;

  const _RegistrarMermaSheet({
    required this.empresaId,
    required this.sedeId,
    required this.sedes,
    required this.dio,
    required this.onSuccess,
  });

  @override
  State<_RegistrarMermaSheet> createState() => _RegistrarMermaSheetState();
}

class _RegistrarMermaSheetState extends State<_RegistrarMermaSheet> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _motivoController = TextEditingController();
  final _observacionesController = TextEditingController();

  String? _selectedProductoStockId;
  String? _selectedProductoNombre;
  String? _selectedSedeId;

  bool _saving = false;

  // Tipo options mapping to TipoMovimientoStock
  static const _tipoOptions = <String, TipoMovimientoStock>{
    'Merma': TipoMovimientoStock.ajusteMerma,
    'Perdida': TipoMovimientoStock.ajustePerdida,
    'Baja': TipoMovimientoStock.salidaBaja,
    'Donacion': TipoMovimientoStock.salidaDonacion,
  };

  String _selectedTipo = 'Merma';

  @override
  void initState() {
    super.initState();
    _selectedSedeId = widget.sedeId;
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _motivoController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _registrar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductoStockId == null) {
      SnackBarHelper.showError(context, 'Seleccione un producto');
      return;
    }

    final cantidad = int.tryParse(_cantidadController.text) ?? 0;
    if (cantidad <= 0) {
      SnackBarHelper.showError(context, 'Ingrese una cantidad valida');
      return;
    }

    setState(() => _saving = true);

    try {
      final tipo = _tipoOptions[_selectedTipo]!;
      await widget.dio.put(
        '/producto-stock/$_selectedProductoStockId/ajustar',
        data: {
          'tipo': tipo.apiValue,
          'cantidad': -cantidad,
          'motivo': _motivoController.text.trim(),
          if (_observacionesController.text.trim().isNotEmpty)
            'observaciones': _observacionesController.text.trim(),
        },
      );

      if (mounted) {
        SnackBarHelper.showSuccess(context, 'Merma/Perdida registrada');
        widget.onSuccess();
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarHelper.showError(context, 'Error al registrar');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Registrar Merma / Perdida',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),

              // Product selector
              ProductoSedeSelector(
                empresaId: widget.empresaId,
                sedeIdInicial: _selectedSedeId,
                mostrarSelectorSede: widget.sedes.length > 1,
                label: 'Producto *',
                hintText: 'Buscar producto...',
                onProductoSeleccionado: ({
                  required producto,
                  required sedeId,
                  variante,
                }) {
                  // We need the productoStock ID. The selector gives us the producto.
                  // We need to find the stock entry for this product + sede.
                  _findProductoStockId(producto.id, sedeId, variante?.id);
                  setState(() {
                    _selectedProductoNombre = producto.nombre;
                    _selectedSedeId = sedeId;
                  });
                },
              ),
              if (_selectedProductoNombre != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Seleccionado: $_selectedProductoNombre',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Tipo dropdown
              CustomDropdown<String>(
                label: 'Tipo *',
                value: _selectedTipo,
                items: _tipoOptions.keys
                    .map((t) => DropdownItem(value: t, label: t))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedTipo = val);
                },
              ),
              const SizedBox(height: 12),

              // Cantidad
              CustomText(
                label: 'Cantidad *',
                controller: _cantidadController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return 'Ingrese la cantidad';
                  }
                  if ((int.tryParse(val) ?? 0) <= 0) {
                    return 'Debe ser mayor a 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Motivo
              CustomText(
                label: 'Motivo *',
                controller: _motivoController,
                maxLines: 2,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'El motivo es obligatorio';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),

              // Observaciones
              CustomText(
                label: 'Observaciones (opcional)',
                controller: _observacionesController,
                maxLines: 2,
              ),
              const SizedBox(height: 20),

              // Submit
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: 'Registrar',
                  isLoading: _saving,
                  onPressed: _saving ? null : _registrar,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _findProductoStockId(
      String productoId, String sedeId, String? varianteId) async {
    try {
      final path = varianteId != null
          ? '/producto-stock/producto/$productoId/sede/$sedeId?varianteId=$varianteId'
          : '/producto-stock/producto/$productoId/sede/$sedeId';
      final response = await widget.dio.get(path);
      final data = response.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _selectedProductoStockId =
              (data['id'] ?? data['_id'] ?? '').toString();
        });
      }
    } catch (_) {
      // Stock entry may not exist
      setState(() => _selectedProductoStockId = null);
    }
  }
}
