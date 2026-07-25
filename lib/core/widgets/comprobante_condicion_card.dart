import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../theme/app_colors.dart';
import '../theme/gradient_container.dart';

/// Datos de un emisor (RUC) disponible para facturar
class EmisorItem {
  final String? sedeId; // null = empresa global
  final String ruc;
  final String razonSocial;
  final String? sedeNombre;

  /// Facturación electrónica ACTIVA para este emisor (config empresa o
  /// sede). Sin ningún emisor activo, la venta solo puede emitir Ticket.
  final bool activo;

  const EmisorItem({
    this.sedeId,
    required this.ruc,
    required this.razonSocial,
    this.sedeNombre,
    this.activo = false,
  });

  String get label => sedeNombre != null
      ? '$razonSocial ($sedeNombre)'
      : razonSocial;

  factory EmisorItem.fromJson(Map<String, dynamic> json) {
    return EmisorItem(
      sedeId: json['id'] as String?,
      ruc: json['ruc'] as String? ?? '',
      razonSocial: json['razonSocial'] as String? ?? '',
      sedeNombre: json['sedeNombre'] as String?,
      activo: (json['activo'] as bool?) ?? false,
    );
  }
}

/// Card reutilizable para seleccionar tipo de comprobante, emisor y condición de pago.
class ComprobanteCondicionCard extends StatelessWidget {
  final String tipoComprobante;
  final ValueChanged<String> onComprobanteChanged;
  final String condicionPago;
  final ValueChanged<String> onCondicionChanged;
  final bool showMixto;
  /// Si false, oculta la sección "Condición de Pago" entera. Útil cuando
  /// el flujo siempre es CONTADO (ej. cobro de cotización-a-venta).
  final bool showCondicionPago;
  /// Si true, renderiza solo el contenido (sin GradientContainer propio),
  /// para embeberlo dentro de otro card.
  final bool embedded;
  // Emisor (multi-RUC)
  final List<EmisorItem>? emisores;
  final EmisorItem? emisorSeleccionado;
  final ValueChanged<EmisorItem?>? onEmisorChanged;

  /// false = la empresa NO tiene facturación electrónica configurada:
  /// solo se ofrece Ticket (nota de venta), sin Boleta/Factura.
  final bool facturacionActiva;

  const ComprobanteCondicionCard({
    super.key,
    required this.tipoComprobante,
    required this.onComprobanteChanged,
    required this.condicionPago,
    required this.onCondicionChanged,
    this.showMixto = true,
    this.showCondicionPago = true,
    this.embedded = false,
    this.emisores,
    this.emisorSeleccionado,
    this.onEmisorChanged,
    this.facturacionActiva = true,
  });

  bool get _mostrarEmisor =>
      facturacionActiva &&
      emisores != null &&
      emisores!.length > 1 &&
      tipoComprobante != 'TICKET';

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
            AppSubtitle('Tipo de Comprobante', color: AppColors.blue1),
            const SizedBox(height: 8),
            Row(
              children: [
                _comprobanteChip('TICKET', 'Ticket'),
                // Boleta/Factura solo con facturación electrónica configurada
                if (facturacionActiva) ...[
                  const SizedBox(width: 8),
                  _comprobanteChip('BOLETA', 'Boleta'),
                  const SizedBox(width: 8),
                  _comprobanteChip('FACTURA', 'Factura'),
                  // Aviso en la misma fila, a la derecha del chip Factura.
                  if (tipoComprobante == 'FACTURA') ...[
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Se requiere RUC del cliente',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 10,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ],
            ),
            // Selector de emisor (solo si hay 2+ RUCs y no es TICKET)
            if (_mostrarEmisor) ...[
              const SizedBox(height: 10),
              AppSubtitle('Emisor', color: AppColors.blue1),
              const SizedBox(height: 6),
              ...emisores!.map((e) => _emisorChip(e)),
            ],
            if (showCondicionPago) ...[
              const SizedBox(height: 12),
              AppSubtitle('Condición de Pago', color: AppColors.blue1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _chip('CONTADO', 'Contado'),
                  _chip('CREDITO', 'Credito'),
                  if (showMixto) _chip('MIXTO', 'Mixto'),
                ],
              ),
            ],
          ],
        );

    if (embedded) return content;

    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: content,
      ),
    );
  }

  Widget _emisorChip(EmisorItem emisor) {
    final selected = emisorSeleccionado?.ruc == emisor.ruc;
    return GestureDetector(
      onTap: () => onEmisorChanged?.call(emisor),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected ? AppColors.blue1 : Colors.grey.shade300,
            width: selected ? 1.5 : 0.6,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              size: 16,
              color: selected ? AppColors.blue1 : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(emisor.razonSocial,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                          color: selected ? AppColors.blue1 : Colors.grey.shade800)),
                  Text('RUC: ${emisor.ruc}${emisor.sedeNombre != null ? ' • ${emisor.sedeNombre}' : ''}',
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _comprobanteChip(String value, String label) {
    final selected = tipoComprobante == value;
    return GestureDetector(
      onTap: () => onComprobanteChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(4
          ),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey[300]!, width: 0.6),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }

  Widget _chip(String value, String label) {
    final selected = condicionPago == value;
    return GestureDetector(
      onTap: () => onCondicionChanged(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue1 : Colors.white,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: selected ? AppColors.blue1 : Colors.grey[300]!, width: 0.6),
        ),
        child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
            color: selected ? Colors.white : Colors.grey[700])),
      ),
    );
  }
}
