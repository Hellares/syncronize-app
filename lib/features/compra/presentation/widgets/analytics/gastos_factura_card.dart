import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../../domain/entities/compra_analytics.dart';

/// Cuánto costó TRAER la mercadería: flete, movilidad, embalaje, intereses.
///
/// 🔴 No confundir con "Tendencia de Gastos", que suma el total de las
/// compras. Ese dice cuánta plata pusiste en mercadería; éste, cuánto pagaste
/// aparte para tenerla en el almacén.
class GastosFacturaCard extends StatelessWidget {
  const GastosFacturaCard({
    super.key,
    required this.reporte,
    this.moneda = 'S/',
    this.onVerDetalle,
  });

  final GastosFacturaReporte reporte;
  final String moneda;

  /// Si viene, la cabecera ofrece ir a la pantalla dedicada, donde se puede
  /// filtrar por proveedor y por rango. En esa pantalla se pasa null: ya se
  /// está ahí.
  final VoidCallback? onVerDetalle;

  String _m(double v) => '$moneda ${v.toStringAsFixed(2)}';

  @override
  Widget build(BuildContext context) {
    final r = reporte.resumen;

    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 17, color: Colors.orange.shade800),
                const SizedBox(width: 7),
                Expanded(
                  child: AppSubtitle(
                    'Gastos de factura',
                    font: AppFont.amazonEmberMedium,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (onVerDetalle != null)
                  InkWell(
                    onTap: onVerDetalle,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AppSubtitle(
                            'Ver detalle',
                            font: AppFont.amazonEmberMedium,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.blue1,
                          ),
                          const Icon(Icons.chevron_right,
                              size: 14, color: AppColors.blue1),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            AppSubtitle(
              'Flete, movilidad, embalaje: lo que costó traer la mercadería',
              fontSize: 9,
              maxLines: 2,
              color: Colors.grey.shade600,
            ),
            const SizedBox(height: 10),

            if (reporte.vacio)
              _buildVacio()
            else ...[
              _buildTotal(r),
              const SizedBox(height: 10),
              _buildCortes(r),
              if (reporte.sinCategoria > 0) ...[
                const SizedBox(height: 8),
                _buildAvisoSinCategoria(),
              ],
              _buildGrupo(
                'Por categoría',
                reporte.porCategoria,
                total: r.total,
              ),
              _buildGrupo(
                'Por período',
                reporte.porPeriodo,
                total: r.total,
                ordenNatural: true,
              ),
              _buildGrupo(
                'Por proveedor',
                reporte.porProveedor,
                total: r.total,
                maximo: 5,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 14, color: Colors.grey.shade400),
          const SizedBox(width: 6),
          Expanded(
            child: AppSubtitle(
              'Todavía no hay gastos cargados en compras confirmadas. Se '
              'agregan al crear la compra, en "Gastos de la factura".',
              fontSize: 9.5,
              maxLines: 3,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotal(GastosFacturaResumen r) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          _m(r.total),
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.orange.shade800,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: AppSubtitle(
              // El número con el que se decide si vale la pena negociar el
              // flete con el proveedor.
              '${r.porcentajeSobreCompras.toStringAsFixed(1)}% de lo comprado '
              '(${_m(r.totalComprado)})',
              fontSize: 9.5,
              maxLines: 2,
              color: Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  /// Al costo vs financiero. Van separados porque contablemente no son lo
  /// mismo: el flete entra al costo del inventario y el interés por pagar a
  /// 30 días no. Sumarlos en un solo total miente el margen.
  Widget _buildCortes(GastosFacturaResumen r) {
    Widget corte(String titulo, String detalle, double monto, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.25), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppSubtitle(
                titulo,
                font: AppFont.amazonEmberMedium,
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              Text(
                _m(monto),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade800,
                ),
              ),
              AppSubtitle(
                detalle,
                fontSize: 8.5,
                maxLines: 2,
                color: Colors.grey.shade600,
              ),
            ],
          ),
        ),
      );
    }

    // 🔴 `stretch` necesita que la Row tenga altura conocida, y acá la Column
    // que la contiene es de altura libre: sin IntrinsicHeight los hijos
    // reciben h=Infinity y revienta en performLayout. El analyzer no lo ve.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          corte('Al costo', 'Sube el precio de los productos', r.alCosto,
              Colors.green.shade700),
          const SizedBox(width: 8),
          corte('Financiero', 'Intereses y recargos, aparte del costo',
              r.financiero, Colors.blueGrey.shade600),
        ],
      ),
    );
  }

  Widget _buildAvisoSinCategoria() {
    return Row(
      children: [
        Icon(Icons.label_off_outlined, size: 13, color: Colors.amber.shade800),
        const SizedBox(width: 5),
        Expanded(
          child: AppSubtitle(
            '${_m(reporte.sinCategoria)} sin categoría: hasta clasificarlos, '
            'el corte por tipo queda incompleto.',
            fontSize: 9,
            maxLines: 2,
            color: Colors.amber.shade900,
          ),
        ),
      ],
    );
  }

  /// Una lista con barra proporcional. Es más legible que un pie para pocas
  /// filas y no necesita leyenda: cada barra lleva su nombre al lado.
  Widget _buildGrupo(
    String titulo,
    List<GastoAgrupado> filas, {
    required double total,
    int? maximo,
    bool ordenNatural = false,
  }) {
    if (filas.isEmpty) return const SizedBox.shrink();

    final visibles = maximo != null && filas.length > maximo
        ? filas.take(maximo).toList()
        : filas;
    final restantes = filas.length - visibles.length;
    final mayor = filas.fold<double>(
      0,
      (max, f) => f.total > max ? f.total : max,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSubtitle(
            titulo,
            font: AppFont.amazonEmberMedium,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.grey.shade700,
          ),
          const SizedBox(height: 6),
          ...visibles.map((f) => _buildFila(f, mayor, total, ordenNatural)),
          if (restantes > 0)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: AppSubtitle(
                'y $restantes más',
                fontSize: 9,
                color: Colors.grey.shade500,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFila(
    GastoAgrupado f,
    double mayor,
    double total,
    bool ordenNatural,
  ) {
    // El balde de "sin clasificar" se pinta distinto para que moleste hasta
    // que se clasifique.
    final sinClasificar = f.id == null && !ordenNatural;
    final color = sinClasificar ? Colors.amber.shade700 : AppColors.blue1;
    final proporcion = mayor > 0 ? (f.total / mayor).clamp(0.0, 1.0) : 0.0;
    final porcentaje = total > 0 ? f.total / total * 100 : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppSubtitle(
                  f.nombre,
                  fontSize: 10,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                _m(f.total),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade900,
                ),
              ),
              const SizedBox(width: 5),
              SizedBox(
                width: 34,
                child: Text(
                  '${porcentaje.toStringAsFixed(0)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: proporcion,
              minHeight: 4,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}
