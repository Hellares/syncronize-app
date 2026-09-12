import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../compra/data/datasources/compra_remote_datasource.dart';
import '../../../compra/domain/entities/compra.dart';

/// Vender una compra entera al costo de SUS lotes.
///
/// 🔑 El caso: se le compró a un proveedor puntual para un cliente puntual.
/// Sin esto, el carrito se arma a mano producto por producto y el consumo
/// FEFO termina sacando la mercadería de la compra MÁS VIEJA — se le cobra el
/// costo equivocado al cliente y se descuenta la caja de otro.
///
/// Devuelve la compra elegida, con sus detalles y lotes cargados. Quien la
/// recibe arma el carrito (`VentaRapidaCubit.cargarCompra`).
class VenderCompraSheet extends StatefulWidget {
  final String empresaId;
  final String? sedeId;

  const VenderCompraSheet({
    super.key,
    required this.empresaId,
    this.sedeId,
  });

  static Future<Compra?> mostrar(
    BuildContext context, {
    required String empresaId,
    String? sedeId,
  }) {
    return showModalBottomSheet<Compra>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => VenderCompraSheet(empresaId: empresaId, sedeId: sedeId),
    );
  }

  @override
  State<VenderCompraSheet> createState() => _VenderCompraSheetState();
}

class _VenderCompraSheetState extends State<VenderCompraSheet> {
  List<Compra>? _compras;
  String _buscando = '';
  String? _abriendo;
  String? _error;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final lista = await locator<CompraRemoteDataSource>().getCompras(
        empresaId: widget.empresaId,
        sedeId: widget.sedeId,
        estado: 'CONFIRMADA',
      );
      if (!mounted) return;
      setState(() => _compras = lista);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _compras = const [];
        _error = 'No se pudieron cargar las compras';
      });
    }
  }

  Future<void> _abrir(Compra c) async {
    setState(() {
      _abriendo = c.id;
      _error = null;
    });
    try {
      final compra = await locator<CompraRemoteDataSource>()
          .getCompra(empresaId: widget.empresaId, id: c.id);
      if (!mounted) return;
      // ¿Queda algo? Lo que se vendió ya no está en el lote.
      final conStock = (compra.detalles ?? const []).any((d) {
        final lote = d.lote;
        if (lote == null) return false;
        return ((lote['cantidadActual'] as num?)?.toInt() ?? 0) > 0;
      });
      if (!conStock) {
        setState(() {
          _abriendo = null;
          _error =
              'Esta compra ya no tiene mercadería en stock: sus lotes se agotaron.';
        });
        return;
      }
      Navigator.of(context).pop(compra);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _abriendo = null;
        _error = 'No se pudo abrir la compra';
      });
    }
  }

  List<Compra> get _visibles {
    final q = _buscando.trim().toLowerCase();
    final todas = _compras ?? const [];
    if (q.isEmpty) return todas;
    return todas
        .where((c) =>
            c.codigo.toLowerCase().contains(q) ||
            c.nombreProveedor.toLowerCase().contains(q))
        .toList();
  }

  String _fecha(DateTime d) {
    final l = d.toLocal();
    return '${l.day.toString().padLeft(2, '0')}/${l.month.toString().padLeft(2, '0')}/${l.year.toString().substring(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final alto = MediaQuery.of(context).size.height * 0.8;
    final visibles = _visibles;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: alto),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vender una compra',
                    style: TextStyle(
                        fontWeight: FontWeight.w700, color: Color(0xFF043261)),
                  ),
                  const Text(
                    'Trae sus productos al costo de esos lotes. Para lo que se '
                    'compró por encargo: el cliente paga lo que costó SU '
                    'mercadería.',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    autofocus: true,
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: 'Código o proveedor…',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                    ),
                    style: const TextStyle(fontSize: 13),
                    onChanged: (v) => setState(() => _buscando = v),
                  ),
                ],
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Text(
                  _error!,
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600),
                ),
              ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Flexible(
              child: _compras == null
                  ? const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  : visibles.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              _buscando.isNotEmpty
                                  ? 'Ninguna compra coincide.'
                                  : 'Sin compras confirmadas.',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ),
                        )
                      : ListView.separated(
                          shrinkWrap: true,
                          itemCount: visibles.length,
                          separatorBuilder: (_, __) =>
                              const Divider(height: 1),
                          itemBuilder: (_, i) {
                            final c = visibles[i];
                            final doc = [
                              c.serieDocumentoProveedor,
                              c.numeroDocumentoProveedor,
                            ].whereType<String>().where((s) => s.isNotEmpty).join('-');
                            return ListTile(
                              dense: true,
                              enabled: _abriendo == null,
                              title: Text(
                                c.nombreProveedor,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF043261)),
                              ),
                              subtitle: Text(
                                [
                                  c.codigo,
                                  _fecha(c.fechaRecepcion),
                                  if (doc.isNotEmpty) doc,
                                ].join(' · '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 10, color: Colors.grey),
                              ),
                              // En la moneda de la compra: el total en soles
                              // convertido con el TC de hoy mentiría — el de
                              // la compra está congelado.
                              trailing: _abriendo == c.id
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text(
                                      '${c.moneda == 'USD' ? '\$' : 'S/'} ${c.total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700),
                                    ),
                              onTap: () => _abrir(c),
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
