import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../empresa/domain/entities/sede.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import 'componentes_producto_page.dart'
    show insumoTrazableTile, detalleErrorWidget;

/// Página GLOBAL de producción: lista todos los lotes fabricados de la empresa
/// (PRODUCCION_ENTRADA), con filtros por sede y búsqueda de producto, y costo
/// del lote. Al expandir un lote muestra el desglose (insumos + mano de obra).
class LotesProduccionPage extends StatefulWidget {
  const LotesProduccionPage({super.key});

  @override
  State<LotesProduccionPage> createState() => _LotesProduccionPageState();
}

class _LotesProduccionPageState extends State<LotesProduccionPage> {
  static const String _kTodasSedes = '__TODAS__';
  static const int _limit = 30;

  final DioClient _dio = locator<DioClient>();
  final _searchCtrl = TextEditingController();

  List<Sede> _sedes = const [];
  String? _sedeId; // null = todas las sedes
  String _search = '';

  bool _loading = false;
  bool _loadingMore = false;
  String? _error;
  List<Map<String, dynamic>> _lotes = [];
  int _total = 0;

  final Set<String> _expandidos = {};
  final Map<String, Map<String, dynamic>> _detalles = {};
  final Set<String> _cargandoDetalle = {};
  final Set<String> _detalleError = {};

  @override
  void initState() {
    super.initState();
    final state = context.read<EmpresaContextCubit>().state;
    if (state is EmpresaContextLoaded) {
      _sedes = state.context.sedes;
    }
    _cargar(reset: true);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _cargar({bool reset = false}) async {
    if (reset) {
      setState(() {
        _loading = true;
        _error = null;
      });
    } else {
      setState(() => _loadingMore = true);
    }
    try {
      final offset = reset ? 0 : _lotes.length;
      final resp = await _dio.get(
        '/produccion/lotes',
        queryParameters: {
          if (_sedeId != null) 'sedeId': _sedeId,
          if (_search.trim().isNotEmpty) 'search': _search.trim(),
          'limit': _limit,
          'offset': offset,
        },
      );
      final data = resp.data as Map<String, dynamic>?;
      final items = ((data?['items'] as List?) ?? const [])
          .cast<Map<String, dynamic>>();
      if (!mounted) return;
      setState(() {
        if (reset) {
          _lotes = items;
        } else {
          _lotes = [..._lotes, ...items];
        }
        _total = (data?['total'] as num?)?.toInt() ?? _lotes.length;
        _loading = false;
        _loadingMore = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is DioException
            ? (e.response?.data?['message']?.toString() ?? e.message ?? 'Error')
            : e.toString();
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  void _onSearch(String q) {
    _search = q;
    _cargar(reset: true);
  }

  Future<void> _toggleExpand(Map<String, dynamic> lote) async {
    final numero = lote['numeroDocumento'] as String? ?? '';
    if (_expandidos.contains(numero)) {
      setState(() => _expandidos.remove(numero));
      return;
    }
    setState(() => _expandidos.add(numero));
    if (_detalles.containsKey(numero)) return;
    final productoId = lote['productoId'] as String?;
    if (productoId == null) return;
    await _cargarDetalle(numero, productoId);
  }

  Future<void> _cargarDetalle(String numero, String productoId) async {
    setState(() {
      _cargandoDetalle.add(numero);
      _detalleError.remove(numero);
    });
    try {
      final resp = await _dio.get(
        '/productos/$productoId/componentes/fabricaciones/$numero',
      );
      if (!mounted) return;
      setState(() {
        _detalles[numero] = resp.data as Map<String, dynamic>;
        _cargandoDetalle.remove(numero);
      });
    } catch (_) {
      if (mounted) {
        setState(() {
          _cargandoDetalle.remove(numero);
          _detalleError.add(numero);
        });
      }
    }
  }

  String _fechaCorta(String iso) {
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '—';
    String dosDig(int n) => n.toString().padLeft(2, '0');
    return '${dosDig(d.day)}/${dosDig(d.month)}/${d.year} ${dosDig(d.hour)}:${dosDig(d.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Lotes fabricados',
          backgroundColor: AppColors.blue1,
          foregroundColor: Colors.white,
          showLogo: false,
        ),
        body: Column(
          children: [
            _buildFiltros(),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltros() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        children: [
          CustomSearchField(
            controller: _searchCtrl,
            hintText: 'Buscar producto…',
            borderColor: AppColors.blue1,
            debounceDelay: const Duration(milliseconds: 400),
            onChanged: _onSearch,
            onClear: () => _onSearch(''),
          ),
          if (_sedes.length > 1) ...[
            const SizedBox(height: 8),
            CustomDropdown<String>(
              hintText: 'Sede',
              value: _sedeId ?? _kTodasSedes,
              borderColor: AppColors.blue1,
              prefixIcon:
                  Icon(Icons.store, size: 16, color: Colors.grey.shade600),
              items: [
                const DropdownItem<String>(
                  value: _kTodasSedes,
                  label: 'Todas las sedes',
                ),
                ..._sedes.map((s) =>
                    DropdownItem<String>(value: s.id, label: s.nombre)),
              ],
              onChanged: (v) {
                final nuevo = (v == null || v == _kTodasSedes) ? null : v;
                if (nuevo == _sedeId) return;
                setState(() => _sedeId = nuevo);
                _cargar(reset: true);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLista() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.red.shade400, size: 40),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => _cargar(reset: true),
                child: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }
    if (_lotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.precision_manufacturing_outlined,
                  size: 56, color: Colors.deepPurple.shade200),
              const SizedBox(height: 10),
              const Text('Sin lotes fabricados',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                _search.isNotEmpty
                    ? 'No hay resultados para "$_search".'
                    : 'Los lotes que fabriques aparecerán aquí.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }
    final hayMas = _lotes.length < _total;
    return RefreshIndicator(
      onRefresh: () => _cargar(reset: true),
      child: ListView.separated(
        padding: const EdgeInsets.all(10),
        itemCount: _lotes.length + (hayMas ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 8),
        itemBuilder: (_, i) {
          if (i >= _lotes.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: _loadingMore
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : OutlinedButton(
                        onPressed: () => _cargar(),
                        child: Text('Cargar más (${_lotes.length}/$_total)'),
                      ),
              ),
            );
          }
          return _buildLoteCard(_lotes[i]);
        },
      ),
    );
  }

  Widget _buildLoteCard(Map<String, dynamic> lote) {
    final numero = lote['numeroDocumento'] as String? ?? '';
    final producto = lote['productoNombre'] as String? ?? '—';
    final variante = lote['varianteNombre'] as String?;
    final cantidad = lote['cantidadProducida'] as num?;
    final costoLote = (lote['costoLote'] as num?)?.toDouble();
    final costoUnitario = (lote['costoUnitario'] as num?)?.toDouble();
    final fecha = lote['creadoEn'] as String?;
    final usuarioNombre = (lote['usuario'] as Map?)?['nombre'] as String? ?? '—';
    final sedeNombre = (lote['sede'] as Map?)?['nombre'] as String? ?? '—';
    final expandido = _expandidos.contains(numero);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _toggleExpand(lote),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.deepPurple.shade100, width: 0.8),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      variante != null ? '$producto · $variante' : producto,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Icon(
                    expandido
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
                    color: Colors.deepPurple.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.deepPurple.shade100,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      numero,
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade900),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fecha != null ? _fechaCorta(fecha) : '—',
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.add_circle_outline,
                      size: 14, color: Colors.green.shade700),
                  const SizedBox(width: 4),
                  Text('+$cantidad und',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade800)),
                  const Spacer(),
                  if (costoLote != null) ...[
                    Icon(Icons.payments_outlined,
                        size: 12, color: Colors.deepPurple.shade400),
                    const SizedBox(width: 4),
                    Text(
                      'S/ ${costoLote.toStringAsFixed(2)}'
                      '${costoUnitario != null ? ' · ${costoUnitario.toStringAsFixed(2)} c/u' : ''}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple.shade900),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person_outline, size: 11, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(usuarioNombre,
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                  Icon(Icons.store, size: 11, color: Colors.grey.shade600),
                  const SizedBox(width: 3),
                  Text(sedeNombre,
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade700)),
                ],
              ),
              if (expandido)
                _buildDetalle(numero, lote['productoId'] as String?),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetalle(String numero, String? productoId) {
    if (_cargandoDetalle.contains(numero)) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }
    if (_detalleError.contains(numero)) {
      return detalleErrorWidget(() {
        if (productoId != null) _cargarDetalle(numero, productoId);
      });
    }
    final detalle = _detalles[numero];
    if (detalle == null) return const SizedBox.shrink();
    final insumos = (detalle['insumosConsumidos'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insumos consumidos',
              style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.deepPurple.shade800)),
          const SizedBox(height: 6),
          ...insumos
              .map((ins) => insumoTrazableTile(ins, fechaFmt: _fechaCorta)),
          if (detalle['costoLoteTotal'] != null) ...[
            const SizedBox(height: 6),
            Divider(height: 1, color: Colors.deepPurple.shade200),
            const SizedBox(height: 6),
            _costoRow('Insumos', (detalle['costoInsumos'] as num?)?.toDouble()),
            if (((detalle['costoManoObra'] as num?) ?? 0) > 0)
              _costoRow('Mano de obra',
                  (detalle['costoManoObra'] as num?)?.toDouble()),
            _costoRow('Total lote',
                (detalle['costoLoteTotal'] as num?)?.toDouble(),
                destacar: true),
          ],
        ],
      ),
    );
  }

  Widget _costoRow(String label, double? valor, {bool destacar = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontSize: destacar ? 10.5 : 10,
                fontWeight: destacar ? FontWeight.bold : FontWeight.normal,
                color: destacar
                    ? Colors.deepPurple.shade900
                    : Colors.grey.shade700,
              )),
          Text(valor != null ? 'S/ ${valor.toStringAsFixed(2)}' : '—',
              style: TextStyle(
                fontSize: destacar ? 10.5 : 10,
                fontWeight: destacar ? FontWeight.bold : FontWeight.w600,
                color: destacar ? Colors.deepPurple.shade900 : Colors.black87,
              )),
        ],
      ),
    );
  }
}
