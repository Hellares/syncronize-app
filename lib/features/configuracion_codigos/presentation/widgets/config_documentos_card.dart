import 'package:flutter/material.dart';
import '../../domain/entities/configuracion_codigos.dart';

/// Card para mostrar la configuración de documentos (Facturación Electrónica)
/// Por ahora es de solo lectura, preparado para futura implementación
class ConfigDocumentosCard extends StatelessWidget {
  final ConfigDocumentos documentos;
  final bool isLoading;
  final VoidCallback onPreviewFactura;
  final VoidCallback onPreviewBoleta;
  final VoidCallback onPreviewNotaCredito;
  final VoidCallback onPreviewNotaDebito;

  const ConfigDocumentosCard({
    super.key,
    required this.documentos,
    this.isLoading = false,
    required this.onPreviewFactura,
    required this.onPreviewBoleta,
    required this.onPreviewNotaCredito,
    required this.onPreviewNotaDebito,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Aviso informativo
          Card(
            color: Colors.blue.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Configuración para Facturación Electrónica',
                          style: TextStyle(
                            color: Colors.blue.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estos códigos se usarán cuando implementes el módulo de facturación electrónica. Los códigos son internos del sistema y diferentes a las series SUNAT.',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Configuración común
          Text(
            'Configuración común',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildInfoRow('Separador', documentos.separador),
                  const Divider(),
                  _buildInfoRow(
                    'Longitud del número',
                    '${documentos.longitud} dígitos',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Tipos de documentos
          Text(
            'Tipos de documentos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Factura
          _buildDocumentoCard(
            context: context,
            titulo: 'Factura',
            icono: Icons.receipt_long,
            color: Colors.blue,
            documento: documentos.factura,
            onPreview: onPreviewFactura,
          ),

          const SizedBox(height: 12),

          // Boleta
          _buildDocumentoCard(
            context: context,
            titulo: 'Boleta',
            icono: Icons.receipt,
            color: Colors.green,
            documento: documentos.boleta,
            onPreview: onPreviewBoleta,
          ),

          const SizedBox(height: 12),

          // Nota de Crédito
          _buildDocumentoCard(
            context: context,
            titulo: 'Nota de Crédito',
            icono: Icons.add_circle_outline,
            color: Colors.orange,
            documento: documentos.notaCredito,
            onPreview: onPreviewNotaCredito,
          ),

          const SizedBox(height: 12),

          // Nota de Débito
          _buildDocumentoCard(
            context: context,
            titulo: 'Nota de Débito',
            icono: Icons.remove_circle_outline,
            color: Colors.red,
            documento: documentos.notaDebito,
            onPreview: onPreviewNotaDebito,
          ),

          const SizedBox(height: 24),

          // Nota sobre series SUNAT
          Card(
            color: Colors.amber.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nota importante',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estos códigos son para uso interno. Las series oficiales SUNAT (F001, B001, etc.) se configuran en "Configuración de Facturación".',
                          style: TextStyle(
                            color: Colors.amber.shade900,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentoCard({
    required BuildContext context,
    required String titulo,
    required IconData icono,
    required Color color,
    required ConfigDocumento documento,
    required VoidCallback onPreview,
  }) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          // Header del card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icono, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: isLoading ? null : onPreview,
                  icon: const Icon(Icons.visibility, size: 16),
                  label: const Text('Vista Previa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: color,
                    side: BorderSide(color: color),
                  ),
                ),
              ],
            ),
          ),

          // Contenido del card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildInfoRow('Prefijo', documento.codigo),
                const Divider(),
                _buildInfoRow(
                  'Último contador',
                  documento.ultimoContador.toString(),
                ),
                const Divider(),
                _buildInfoRow('Próximo código', documento.proximoCodigo),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.grey,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }
}
