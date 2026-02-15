import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../../core/widgets/currency/currency_textfield.dart';
import '../../../../../core/widgets/currency/currency_formatter.dart';
import '../../../../../core/widgets/custom_switch_tile.dart';

/// Sección de ofertas del producto
/// Contiene: switch de oferta, precio de oferta y período de oferta
class ProductoOfertaSection extends StatelessWidget {
  final bool enOferta;
  final ValueChanged<bool> onEnOfertaChanged;
  final TextEditingController precioOfertaController;
  final TextEditingController precioController;
  final DateTime? fechaInicioOferta;
  final DateTime? fechaFinOferta;
  final ValueChanged<DateTime?> onFechaInicioChanged;
  final ValueChanged<DateTime?> onFechaFinChanged;

  const ProductoOfertaSection({
    super.key,
    required this.enOferta,
    required this.onEnOfertaChanged,
    required this.precioOfertaController,
    required this.precioController,
    this.fechaInicioOferta,
    this.fechaFinOferta,
    required this.onFechaInicioChanged,
    required this.onFechaFinChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.colorful,
      borderColor: Colors.orange,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_offer, color: Colors.orange, size: 16),
              const SizedBox(width: 8),
              AppSubtitle('OFERTAS'),
            ],
          ),
          CustomSwitchTile(
            title: 'Producto en Oferta',
            activeColor: Colors.orange,
            activeTrackColor: Colors.orange.shade200,
            subtitle: 'Activar precio especial para este producto',
            value: enOferta,
            onChanged: onEnOfertaChanged,
          ),
          if (enOferta) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CurrencyTextField(
                    controller: precioOfertaController,
                    label: 'Precio de Oferta *',
                    hintText: '0.00',
                    borderColor: Colors.orange,
                    enableRealTimeValidation: true,
                    validator: enOferta
                        ? (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'El precio de oferta es requerido';
                            }

                            final precioOferta = CurrencyUtilsImproved.parseToDouble(value);
                            if (precioOferta <= 0) {
                              return 'El precio debe ser mayor a 0';
                            }

                            final precioNormal = precioController.currencyValue;
                            if (precioNormal > 0 && precioOferta >= precioNormal) {
                              return 'Debe ser menor al precio normal';
                            }
                            return null;
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),
                  AppSubtitle('PERÍODO DE OFERTA (OPCIONAL)', fontSize: 10),
                  const SizedBox(height: 4),
                  _buildFechaInicioTile(context),
                  _buildFechaFinTile(context),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFechaInicioTile(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(vertical: -4),
      minVerticalPadding: 0,
      leading: const Icon(Icons.calendar_today, color: Colors.orange, size: 17),
      title: AppSubtitle(
        fechaInicioOferta == null
            ? 'Fecha de Inicio'
            : 'Desde: ${DateFormatter.formatDate(fechaInicioOferta!)}',
        fontSize: 10,
      ),
      trailing: fechaInicioOferta != null
          ? IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () => onFechaInicioChanged(null),
            )
          : null,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: fechaInicioOferta ?? DateTime.now(),
          firstDate: DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onFechaInicioChanged(date);
        }
      },
    );
  }

  Widget _buildFechaFinTile(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      visualDensity: const VisualDensity(vertical: -4),
      minVerticalPadding: 0,
      leading: const Icon(Icons.event, color: Colors.orange, size: 17),
      title: AppSubtitle(
        fechaFinOferta == null
            ? 'Fecha de Fin'
            : 'Hasta: ${DateFormatter.formatDate(fechaFinOferta!)}',
        fontSize: 10,
      ),
      trailing: fechaFinOferta != null
          ? IconButton(
              icon: const Icon(Icons.clear, size: 16),
              onPressed: () => onFechaFinChanged(null),
            )
          : null,
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: fechaFinOferta ?? fechaInicioOferta ?? DateTime.now(),
          firstDate: fechaInicioOferta ?? DateTime.now(),
          lastDate: DateTime.now().add(const Duration(days: 365)),
        );
        if (date != null) {
          onFechaFinChanged(date);
        }
      },
    );
  }
}
