import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';

class AccesosRapidosSection extends StatelessWidget {
  final int colaPosCount;

  const AccesosRapidosSection({
    super.key,
    this.colaPosCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.all(10),
      child: Column(
        children: [
          // Fila 1: Operaciones
          Row(
            children: [
              _card(Icons.point_of_sale, 'Venta', AppColors.green, () => context.push('/empresa/ventas/nueva')),
              _card(Icons.receipt_long, 'Cola POS', AppColors.orange, () => context.push('/empresa/cola-pos'), badge: colaPosCount),
              _card(Icons.account_balance_wallet, 'Caja', AppColors.blue1, () => context.push('/empresa/caja')),
              _card(Icons.monitor_heart, 'Monitor Cajas', Colors.deepOrange, () => context.push('/empresa/caja/monitor')),
              _card(Icons.analytics, 'Finanzas', Colors.deepPurple, () => context.push('/empresa/resumen-financiero')),
            ],
          ),
          const SizedBox(height: 6),
          // Fila 2: Ventas & Facturación
          Row(
            children: [
              _card(Icons.shopping_bag, 'Ventas', Colors.indigo, () => context.push('/empresa/ventas')),
              _card(Icons.description, 'Facturación', Colors.teal, () => context.push('/empresa/monitor-facturacion')),
              _card(Icons.room_service, 'Servicios', Colors.blue, () => context.push('/empresa/servicios')),
              _card(Icons.inventory, 'Productos', Colors.blue.shade800, () => context.push('/empresa/productos')),
              _card(Icons.request_quote, 'Cotizaciones', Colors.purple, () => context.push('/empresa/cotizaciones')),
            ],
          ),
          const SizedBox(height: 6),
          // Fila 3: Herramientas
          Row(
            children: [
              _card(Icons.build_circle, 'Órdenes Serv.', Colors.orange.shade700, () => context.push('/empresa/ordenes-servicio')),
              _card(Icons.inventory_2, 'Monitor Prod.', Colors.deepOrange, () => context.push('/empresa/monitor-productos')),
              _card(Icons.currency_exchange, 'Tipo Cambio', Colors.green.shade700, () => context.push('/empresa/tipo-cambio')),
              _card(Icons.people, 'Clientes', Colors.amber.shade800, () => context.push('/empresa/clientes')),
              _card(Icons.settings, 'Config', Colors.grey.shade600, () => context.push('/empresa/configuracion')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _card(IconData icon, String label, Color color, VoidCallback onTap, {int badge = 0}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: _AccesoRapidoCard(
          icon: icon,
          label: label,
          color: color,
          badgeCount: badge,
          onTap: onTap,
        ),
      ),
    );
  }
}

class _AccesoRapidoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int badgeCount;
  final VoidCallback onTap;

  const _AccesoRapidoCard({
    required this.icon,
    required this.label,
    required this.color,
    this.badgeCount = 0,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 68,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white,
              color.withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 0.4),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: color),
                ),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(fontSize: 7, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                color: color.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
