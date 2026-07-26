import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/domain/entities/producto_list_item.dart';
import '../../../producto/domain/repositories/producto_repository.dart';

/// Busca un producto del catálogo para una celda de tabla.
///
/// Devuelve `{nombre, precio, codigo}`; la tabla reparte cada dato en su
/// columna. El PRECIO que se lleva es el de la sede de la orden y queda
/// CONGELADO en la tabla: una orden es un presupuesto, y si el catálogo
/// sube mañana lo cotizado no debe cambiar solo.
class BuscarProductoSheet extends StatefulWidget {
  final String empresaId;
  final String? sedeId;

  const BuscarProductoSheet({
    super.key,
    required this.empresaId,
    this.sedeId,
  });

  static Future<Map<String, String>?> show(
    BuildContext context, {
    required String empresaId,
    String? sedeId,
  }) {
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BuscarProductoSheet(empresaId: empresaId, sedeId: sedeId),
    );
  }

  @override
  State<BuscarProductoSheet> createState() => _BuscarProductoSheetState();
}

class _BuscarProductoSheetState extends State<BuscarProductoSheet> {
  final _ctrl = TextEditingController();
  Timer? _debounce;
  bool _cargando = false;
  List<ProductoListItem> _resultados = const [];
  String? _error;

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  void _alEscribir(String q) {
    // Sin debounce cada tecla dispara una petición al catálogo.
    _debounce?.cancel();
    if (q.trim().length < 2) {
      setState(() => _resultados = const []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _buscar(q));
  }

  Future<void> _buscar(String q) async {
    setState(() {
      _cargando = true;
      _error = null;
    });
    final result = await locator<ProductoRepository>().getProductos(
      empresaId: widget.empresaId,
      sedeId: widget.sedeId,
      filtros: ProductoFiltros(
        search: q.trim(),
        limit: 20,
        isActive: true,
        soloProductos: true,
      ),
    );
    if (!mounted) return;
    setState(() {
      _cargando = false;
      if (result is Success<ProductosPaginados>) {
        // `data` es List<dynamic>: se filtra por tipo en vez de castear.
        _resultados = result.data.data.whereType<ProductoListItem>().toList();
      } else if (result is Error<ProductosPaginados>) {
        _error = result.message;
      }
    });
  }

  /// Precio de venta vigente en la sede: la oferta manda sobre el normal.
  ///
  /// 🔴 Nada de `firstWhere(orElse:)` aquí: la lista llega como
  /// `List<StockPorSedeInfoModel>` aunque esté declarada de la entidad base,
  /// y Dart exige que `orElse` devuelva el tipo del RUNTIME. Devolver la
  /// entidad base explota con un TypeError en pleno build.
  double? _precioDe(ProductoListItem p) {
    final stocks = p.stocksPorSede;
    if (stocks == null || stocks.isEmpty) return null;

    var elegido = stocks.first;
    if (widget.sedeId != null) {
      for (final s in stocks) {
        if (s.sedeId == widget.sedeId) {
          elegido = s;
          break;
        }
      }
    }
    return elegido.precioOferta ?? elegido.precio;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 18, color: AppColors.blue1),
                SizedBox(width: 6),
                Text(
                  'Buscar producto',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.blue1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _ctrl,
              autofocus: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Nombre o código (mínimo 2 letras)',
                prefixIcon: const Icon(Icons.search, size: 18),
                border: const OutlineInputBorder(),
                suffixIcon: _ctrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 16),
                        onPressed: () {
                          _ctrl.clear();
                          setState(() => _resultados = const []);
                        },
                      ),
              ),
              onChanged: (v) {
                setState(() {}); // refresca el botón de limpiar
                _alEscribir(v);
              },
            ),
            const SizedBox(height: 8),
            if (_cargando)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(_error!,
                    style: TextStyle(fontSize: 12, color: AppColors.red)),
              )
            else if (_resultados.isEmpty && _ctrl.text.trim().length >= 2)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Sin resultados',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _resultados.length,
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: Colors.grey.shade200),
                  itemBuilder: (_, i) {
                    final p = _resultados[i];
                    final precio = _precioDe(p);
                    return ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: p.imagenPrincipal != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(p.imagenPrincipal!,
                                  width: 34, height: 34, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.inventory_2_outlined,
                                          size: 20)),
                            )
                          : const Icon(Icons.inventory_2_outlined, size: 20),
                      title: Text(p.nombre,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12.5)),
                      subtitle: Text(
                        p.codigoEmpresa,
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      trailing: Text(
                        precio == null
                            ? 'sin precio'
                            : 'S/ ${precio.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: precio == null
                              ? Colors.grey.shade400
                              : AppColors.blue1,
                        ),
                      ),
                      onTap: () => Navigator.pop(context, {
                        'nombre': p.nombre,
                        if (precio != null)
                          'precio': precio.toStringAsFixed(2),
                        'codigo': p.codigoEmpresa,
                      }),
                    );
                  },
                ),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
