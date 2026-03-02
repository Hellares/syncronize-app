import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import '../../domain/entities/lote.dart';

class LoteDetailPage extends StatelessWidget {
  final String empresaId;
  final Lote lote;

  const LoteDetailPage({
    super.key,
    required this.empresaId,
    required this.lote,
  });

  Color _estadoColor() {
    switch (lote.estado) {
      case EstadoLote.ACTIVO:
        return Colors.green;
      case EstadoLote.AGOTADO:
        return Colors.grey;
      case EstadoLote.VENCIDO:
        return Colors.red;
      case EstadoLote.BLOQUEADO:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(lote.codigo),
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              color: _estadoColor().withValues(alpha: 0.08),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: _estadoColor().withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      lote.estadoTexto,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _estadoColor(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (lote.nombreProducto.isNotEmpty)
                    Text(
                      lote.nombreProducto,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  if (lote.codigoProducto.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      lote.codigoProducto,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Stock
            _buildSection('Stock', [
              _buildInfoRow('Cantidad Inicial', '${lote.cantidadInicial}'),
              _buildInfoRow('Cantidad Actual', '${lote.cantidadActual}'),
              _buildInfoRow('Reservada', '${lote.cantidadReservada}'),
              _buildInfoRow('Disponible', '${lote.cantidadDisponible}'),
              _buildInfoRow(
                  'Consumido', '${lote.porcentajeConsumido.toStringAsFixed(1)}%'),
            ]),

            // Barra de progreso de consumo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  LinearProgressIndicator(
                    value: lote.porcentajeConsumido / 100,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      lote.porcentajeConsumido > 80
                          ? Colors.red
                          : lote.porcentajeConsumido > 50
                              ? Colors.orange
                              : Colors.green,
                    ),
                  ),
                ],
              ),
            ),

            _buildSection('Costo', [
              _buildInfoRow('Precio Costo',
                  '${lote.moneda} ${lote.precioCosto.toStringAsFixed(2)}'),
              _buildInfoRow('Moneda', lote.moneda),
            ]),

            _buildSection('Fechas', [
              _buildInfoRow(
                  'Fecha Ingreso', dateFormat.format(lote.fechaIngreso)),
              if (lote.fechaProduccion != null)
                _buildInfoRow('Fecha Producción',
                    dateFormat.format(lote.fechaProduccion!)),
              if (lote.fechaVencimiento != null)
                _buildInfoRow(
                  'Fecha Vencimiento',
                  dateFormat.format(lote.fechaVencimiento!),
                  valueColor: lote.proximoAVencer ? Colors.red : null,
                ),
            ]),

            _buildSection('Información', [
              if (lote.numeroLote != null)
                _buildInfoRow('N° Lote Fabricante', lote.numeroLote!),
              if (lote.nombreProveedor != null)
                _buildInfoRow('Proveedor', lote.nombreProveedor!),
              _buildInfoRow(
                  'Creado', dateFormat.format(lote.creadoEn)),
              _buildInfoRow(
                  'Actualizado', dateFormat.format(lote.actualizadoEn)),
            ]),

            if (lote.observaciones != null &&
                lote.observaciones!.isNotEmpty)
              _buildSection('Observaciones', [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(lote.observaciones!),
                ),
              ]),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...children,
        const Divider(),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
