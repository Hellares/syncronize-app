import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../data/datasources/compra_remote_datasource.dart';
import '../../data/models/reposicion_model.dart';

/// Compras proactivas: productos con stock ≤ mínimo, con cantidad sugerida y el
/// mejor proveedor (menor costo promedio histórico). Autocontenida.
class ReposicionSugeridaPage extends StatefulWidget {
  const ReposicionSugeridaPage({super.key});

  @override
  State<ReposicionSugeridaPage> createState() => _ReposicionSugeridaPageState();
}

class _ReposicionSugeridaPageState extends State<ReposicionSugeridaPage> {
  final _ds = locator<CompraRemoteDataSource>();
  bool _loading = true;
  String? _error;
  List<ReposicionItem> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final st = context.read<EmpresaContextCubit>().state;
    final empresaId = st is EmpresaContextLoaded ? st.context.empresa.id : null;
    if (empresaId == null) {
      setState(() {
        _loading = false;
        _error = 'Sin empresa seleccionada';
      });
      return;
    }
    try {
      final items = await _ds.getReposicionSugerida(empresaId: empresaId);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'No se pudo cargar la reposición';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Reposición sugerida',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loading ? null : _load,
          ),
        ],
      ),
      body: GradientBackground(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? _vacio()
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.blue1,
                        child: ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            _resumen(),
                            const SizedBox(height: 8),
                            ..._items.map((i) => _ReposicionCard(item: i)),
                          ],
                        ),
                      ),
      ),
    );
  }

  Widget _vacio() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 56, color: Colors.green.shade300),
          const SizedBox(height: 12),
          Text('Todo el stock está por encima del mínimo',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  Widget _resumen() {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(Icons.shopping_cart_checkout, color: Colors.orange.shade700),
            const SizedBox(width: 10),
            Expanded(
              child: AppSubtitle(
                '${_items.length} producto${_items.length != 1 ? 's' : ''} por reponer',
                fontSize: 13,
              ),
            ),
            TextButton.icon(
              onPressed: () => context.push('/empresa/compras/ordenes/nueva'),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Nueva OC', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReposicionCard extends StatelessWidget {
  final ReposicionItem item;
  const _ReposicionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final critico = item.stockActual <= 0;
    return GradientContainer(
      margin: const EdgeInsets.only(bottom: 8),
      borderColor: critico ? Colors.red.shade300 : AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppSubtitle(
                    item.varianteNombre != null
                        ? '${item.nombre} · ${item.varianteNombre}'
                        : item.nombre,
                    fontSize: 13,
                    color: AppColors.blue1,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: (critico ? Colors.red : Colors.orange).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Stock ${item.stockActual}/${item.stockMinimo}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: critico ? Colors.red.shade700 : Colors.orange.shade800,
                    ),
                  ),
                ),
              ],
            ),
            if (item.sedeNombre != null) ...[
              const SizedBox(height: 2),
              Text(item.sedeNombre!, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                _kpi('Sugerido', '${item.sugeridoComprar} u.', Colors.blue),
                const SizedBox(width: 16),
                if (item.ultimoCosto != null)
                  _kpi('Últ. costo', 'S/ ${item.ultimoCosto!.toStringAsFixed(2)}', Colors.blueGrey),
              ],
            ),
            if (item.mejorProveedor != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.star, size: 13, color: Colors.amber),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Mejor: ${item.mejorProveedor!.proveedor}  ·  prom S/ ${item.mejorProveedor!.costoPromedio.toStringAsFixed(2)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 11, color: Colors.teal.shade700, fontWeight: FontWeight.w600),
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

  Widget _kpi(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 9, color: Colors.grey.shade600)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
