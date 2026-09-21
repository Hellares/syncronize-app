/// A quién se le compra este producto, con qué código lo identifica cada uno
/// y a cuánto salió la última vez.
///
/// Es el espejo de `ProveedoresCodigosCard` de la web. Acá es de SOLO LECTURA:
/// el código se corrige desde la web, donde hay teclado cómodo para eso; en el
/// celular lo que importa es verlo al lado de la factura.
///
/// Se esconde solo si el producto no tiene proveedores registrados —o si el
/// usuario no puede ver compras, porque el endpoint devuelve 403 y ahí viajan
/// precios de COMPRA—.
library;

import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../compra/data/datasources/compra_remote_datasource.dart';
import '../../../compra/domain/entities/proveedor_de_producto.dart';

class ProveedoresCodigosPanel extends StatefulWidget {
  final String productoId;

  const ProveedoresCodigosPanel({super.key, required this.productoId});

  @override
  State<ProveedoresCodigosPanel> createState() =>
      _ProveedoresCodigosPanelState();
}

class _ProveedoresCodigosPanelState extends State<ProveedoresCodigosPanel> {
  final _ds = locator<CompraRemoteDataSource>();

  /// null = todavía cargando; lista vacía = llegó y no hay (o no hay permiso).
  List<ProveedorDeProducto>? _filas;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final filas =
          await _ds.getProveedoresDeProducto(productoId: widget.productoId);
      if (mounted) setState(() => _filas = filas);
    } catch (_) {
      // 403 sin VIEW_COMPRAS, o la red: el panel simplemente no aparece.
      if (mounted) setState(() => _filas = const []);
    }
  }

  String _fecha(DateTime f) =>
      '${f.day.toString().padLeft(2, '0')}/${f.month.toString().padLeft(2, '0')}/${f.year % 100}';

  String _sim(String? moneda) => moneda == 'USD' ? '\$' : 'S/';

  @override
  Widget build(BuildContext context) {
    final filas = _filas;
    // Mientras carga no se reserva espacio: el panel aparece cuando hay algo
    // que mostrar, en vez de dejar un hueco que salta.
    if (filas == null || filas.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GradientContainer(
        gradient: AppGradients.blueWhiteDialog(),
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 16, color: AppColors.blue1),
                const SizedBox(width: 6),
                AppSubtitle(
                  'Proveedores y códigos',
                  fontSize: 13,
                  color: AppColors.blue1,
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${filas.length}',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            for (final f in filas) _fila(f),
          ],
        ),
      ),
    );
  }

  Widget _fila(ProveedorDeProducto f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  f.proveedorNombre.isEmpty ? 'Sin nombre' : f.proveedorNombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
                if (f.descripcionProveedor != null)
                  Text(
                    'Él lo llama: ${f.descripcionProveedor}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Lo que salió la última vez: el número con el que se compara un
          // proveedor contra otro.
          if (f.ultimoPrecio != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${_sim(f.ultimaMoneda)} ${f.ultimoPrecio!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  if (f.ultimaCompraAt != null)
                    Text(
                      _fecha(f.ultimaCompraAt!),
                      style:
                          TextStyle(fontSize: 9, color: Colors.grey.shade400),
                    ),
                ],
              ),
            ),
          // El código, que es el dato que se coteja contra la factura.
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
            decoration: BoxDecoration(
              color: f.codigoProveedor != null
                  ? AppColors.blue1.withValues(alpha: 0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              f.codigoProveedor ?? 'sin código',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                fontStyle:
                    f.codigoProveedor == null ? FontStyle.italic : null,
                color: f.codigoProveedor != null
                    ? AppColors.blue1
                    : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
