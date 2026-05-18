import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/producto_stock.dart';
import '../../domain/repositories/producto_stock_repository.dart';
import '../widgets/gestionar_liquidacion_dialog.dart';

/// Lista de productos en liquidación activa por empresa/sede.
/// Permite gestionar (editar/desactivar) cada liquidación directamente.
class LiquidacionesPage extends StatefulWidget {
  const LiquidacionesPage({super.key});

  @override
  State<LiquidacionesPage> createState() => _LiquidacionesPageState();
}

class _LiquidacionesPageState extends State<LiquidacionesPage> {
  final ProductoStockRepository _repo = locator<ProductoStockRepository>();
  List<Sede> _sedes = [];
  String? _sedeId;
  List<Map<String, dynamic>> _items = [];
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
      if (_sedes.length == 1) _sedeId = _sedes.first.id;
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _repo.listarLiquidaciones(sedeId: _sedeId, page: 1, limit: 100);
    if (!mounted) return;
    if (result is Success<Map<String, dynamic>>) {
      setState(() {
        _items = ((result.data['data'] as List?) ?? const [])
            .cast<Map<String, dynamic>>();
        _loading = false;
      });
    } else if (result is Error<Map<String, dynamic>>) {
      setState(() {
        _error = result.message;
        _loading = false;
      });
    }
  }

  /// Prisma Decimal se serializa como String en JSON (no como num). Castear
  /// directo a num? rompe con _TypeError. Aceptamos num, String y null.
  double? _parseDecimal(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  ProductoStock _hydrate(Map<String, dynamic> json) {
    // Reconstruir entity desde el response del backend.
    return ProductoStock(
      id: json['id'] as String,
      sedeId: json['sedeId'] as String,
      productoId: json['productoId'] as String?,
      varianteId: json['varianteId'] as String?,
      empresaId: json['empresaId'] as String? ?? '',
      stockActual: (json['stockActual'] ?? 0) as int,
      precio: _parseDecimal(json['precio']),
      precioCosto: _parseDecimal(json['precioCosto']),
      enLiquidacion: json['enLiquidacion'] as bool? ?? true,
      precioLiquidacion: _parseDecimal(json['precioLiquidacion']),
      motivoLiquidacion:
          MotivoLiquidacionX.fromApi(json['motivoLiquidacion'] as String?),
      observacionesLiquidacion: json['observacionesLiquidacion'] as String?,
      fechaInicioLiquidacion: json['fechaInicioLiquidacion'] != null
          ? DateTime.parse(json['fechaInicioLiquidacion'] as String)
          : null,
      fechaFinLiquidacion: json['fechaFinLiquidacion'] != null
          ? DateTime.parse(json['fechaFinLiquidacion'] as String)
          : null,
      liquidacionAutorizadaPorId: json['liquidacionAutorizadaPorId'] as String?,
      creadoEn: DateTime.parse(json['creadoEn'] as String),
      actualizadoEn: DateTime.parse(json['actualizadoEn'] as String),
      sede: json['sede'] != null
          ? SedeStock(
              id: json['sede']['id'] as String,
              nombre: json['sede']['nombre'] as String,
            )
          : null,
      producto: json['producto'] != null
          ? ProductoStockInfo(
              id: json['producto']['id'] as String,
              nombre: json['producto']['nombre'] as String,
              codigoEmpresa: json['producto']['codigoEmpresa'] as String?,
              sku: json['producto']['sku'] as String?,
            )
          : null,
      variante: json['variante'] != null
          ? VarianteStockInfo(
              id: json['variante']['id'] as String,
              nombre: json['variante']['nombre'] as String,
              sku: json['variante']['sku'] as String?,
            )
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: const SmartAppBar(
          title: 'Liquidaciones',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
          showLogo: false,
        ),
        body: Column(
          children: [
            if (_sedes.length > 1)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: DropdownButtonFormField<String?>(
                  value: _sedeId,
                  decoration: const InputDecoration(
                    labelText: 'Sede',
                    border: OutlineInputBorder(),
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas las sedes')),
                    ..._sedes.map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.nombre))),
                  ],
                  onChanged: (v) {
                    setState(() => _sedeId = v);
                    _load();
                  },
                ),
              ),
            Expanded(child: _buildList()),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
            const SizedBox(height: 8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _load, child: const Text('Reintentar')),
          ],
        ),
      );
    }
    if (_items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.local_fire_department,
                  size: 60, color: Colors.deepOrange.shade300),
              const SizedBox(height: 12),
              const Text(
                'No hay productos en liquidación',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                'Activá la liquidación desde la pantalla de precios del producto cuando quieras rematar inventario sin rotación.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: _items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          final json = _items[i];
          final stock = _hydrate(json);
          final precioBase = stock.precio ?? 0;
          final precioLiq = stock.precioLiquidacion ?? 0;
          final costo = stock.precioCosto ?? 0;
          final perdidaUnitaria = precioLiq - costo;

          return Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.deepOrange.shade100),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final updated = await showDialog<ProductoStock>(
                  context: context,
                  builder: (_) => GestionarLiquidacionDialog(stock: stock),
                );
                if (updated != null) _load();
              },
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_fire_department,
                            color: Colors.deepOrange.shade700, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            stock.nombreProducto,
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ),
                        if (stock.sede != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.blue1.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              stock.sede!.nombre,
                              style: TextStyle(
                                  fontSize: 10, color: AppColors.blue1),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _kv('Base', 'S/ ${precioBase.toStringAsFixed(2)}'),
                        _kv('Costo', 'S/ ${costo.toStringAsFixed(2)}'),
                        _kv(
                          'Liquidación',
                          'S/ ${precioLiq.toStringAsFixed(2)}',
                          color: Colors.deepOrange.shade800,
                        ),
                        _kv(
                          'Pérdida/u',
                          'S/ ${perdidaUnitaria.toStringAsFixed(2)}',
                          color: perdidaUnitaria < 0 ? Colors.red.shade700 : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.label_outline,
                            size: 12, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          stock.motivoLiquidacion?.label ?? '—',
                          style: TextStyle(
                              fontSize: 11, color: Colors.grey.shade700),
                        ),
                        const Spacer(),
                        if (stock.fechaFinLiquidacion != null)
                          Text(
                            'Vence ${DateFormatter.formatDate(stock.fechaFinLiquidacion!.toLocal())}',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
                          )
                        else
                          Text(
                            'Sin vencimiento',
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _kv(String label, String value, {Color? color}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade700)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w700, color: color),
        ),
      ],
    );
  }
}
