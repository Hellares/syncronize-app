import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncronize/core/utils/date_formatter.dart';
import '../../domain/entities/transferencia_stock.dart';

/// Servicio para generar documentos PDF de transferencias de stock
class PdfTransferenciaGenerator {
  /// Genera un PDF con el detalle completo de la transferencia
  static Future<Uint8List> generarDocumento({
    required TransferenciaStock transferencia,
    required String empresaNombre,
    String? empresaRuc,
    Uint8List? logoEmpresa,
  }) async {
    final pdf = pw.Document();

    // Agregar la página principal
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (context) => [
          _buildHeader(
            empresaNombre: empresaNombre,
            empresaRuc: empresaRuc,
            logo: logoEmpresa,
          ),
          pw.SizedBox(height: 20),
          _buildTransferenciaInfo(transferencia),
          pw.SizedBox(height: 20),
          _buildSedesInfo(transferencia),
          pw.SizedBox(height: 20),
          _buildProductosTable(transferencia),
          pw.SizedBox(height: 20),
          if (transferencia.observaciones != null) ...[
            _buildObservaciones(transferencia.observaciones!),
            pw.SizedBox(height: 20),
          ],
          _buildFirmasSection(transferencia),
        ],
        footer: (context) => _buildFooter(
          transferencia,
          context.pageNumber,
          context.pagesCount,
        ),
      ),
    );

    return pdf.save();
  }

  /// Construye el encabezado del documento
  static pw.Widget _buildHeader({
    required String empresaNombre,
    String? empresaRuc,
    Uint8List? logo,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Logo y datos de empresa
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            if (logo != null)
              pw.Image(
                pw.MemoryImage(logo),
                height: 50,
                width: 120,
                fit: pw.BoxFit.contain,
              )
            else
              pw.Text(
                empresaNombre,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            if (empresaRuc != null) ...[
              pw.SizedBox(height: 4),
              pw.Text(
                'RUC: $empresaRuc',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ],
        ),
        // Título del documento
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'TRANSFERENCIA DE STOCK',
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue800,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              DateFormatter.formatDateTime(DateTime.now()),
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }

  /// Información básica de la transferencia
  static pw.Widget _buildTransferenciaInfo(TransferenciaStock transferencia) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Código: ${transferencia.codigo}',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              _buildEstadoBadge(transferencia.estado),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          _buildInfoRow('Fecha de creación',
            DateFormatter.formatDateTime(transferencia.creadoEn)),
          if (transferencia.fechaAprobacion != null)
            _buildInfoRow('Fecha de aprobación',
              DateFormatter.formatDateTime(transferencia.fechaAprobacion!)),
          if (transferencia.fechaEnvio != null)
            _buildInfoRow('Fecha de envío',
              DateFormatter.formatDateTime(transferencia.fechaEnvio!)),
          if (transferencia.fechaRecepcion != null)
            _buildInfoRow('Fecha de recepción',
              DateFormatter.formatDateTime(transferencia.fechaRecepcion!)),
          if (transferencia.motivo != null) ...[
            pw.SizedBox(height: 4),
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 4),
            _buildInfoRow('Motivo', transferencia.motivo!),
          ],
        ],
      ),
    );
  }

  /// Información de sedes
  static pw.Widget _buildSedesInfo(TransferenciaStock transferencia) {
    return pw.Row(
      children: [
        pw.Expanded(
          child: _buildSedeBox(
            'SEDE ORIGEN',
            transferencia.sedeOrigen?.nombre ?? 'N/A',
            transferencia.sedeOrigen?.codigo,
            PdfColors.orange,
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Icon(
          const pw.IconData(0xe5c8), // arrow_forward
          size: 30,
          color: PdfColors.grey400,
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: _buildSedeBox(
            'SEDE DESTINO',
            transferencia.sedeDestino?.nombre ?? 'N/A',
            transferencia.sedeDestino?.codigo,
            PdfColors.green,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSedeBox(
    String label,
    String nombre,
    String? codigo,
    PdfColor color,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: color, width: 2),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            nombre,
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (codigo != null) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              'Código: $codigo',
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ],
      ),
    );
  }

  /// Tabla de productos
  static pw.Widget _buildProductosTable(TransferenciaStock transferencia) {
    final items = transferencia.items ?? [];

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'PRODUCTOS',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          children: [
            // Encabezado
            pw.TableRow(
              decoration: const pw.BoxDecoration(
                color: PdfColors.grey300,
              ),
              children: [
                _buildTableCell('#', isHeader: true),
                _buildTableCell('Producto', isHeader: true),
                _buildTableCell('SKU/Código', isHeader: true),
                _buildTableCell('Solicitada', isHeader: true),
                _buildTableCell('Aprobada', isHeader: true),
                _buildTableCell('Enviada', isHeader: true),
                _buildTableCell('Recibida', isHeader: true),
                _buildTableCell('Estado', isHeader: true),
              ],
            ),
            // Filas de productos
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return pw.TableRow(
                decoration: pw.BoxDecoration(
                  color: index % 2 == 0 ? PdfColors.white : PdfColors.grey100,
                ),
                children: [
                  _buildTableCell('${index + 1}'),
                  _buildTableCell(item.nombreProducto),
                  _buildTableCell(item.codigoProducto ?? '-'),
                  _buildTableCell('${item.cantidadSolicitada}'),
                  _buildTableCell(item.cantidadAprobada?.toString() ?? '-'),
                  _buildTableCell(item.cantidadEnviada?.toString() ?? '-'),
                  _buildTableCell(item.cantidadRecibida?.toString() ?? '-'),
                  _buildTableCell(item.estado.descripcion, fontSize: 8),
                ],
              );
            }),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.end,
          children: [
            pw.Text(
              'TOTAL: ${transferencia.cantidadTotal} unidades',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Sección de observaciones
  static pw.Widget _buildObservaciones(String observaciones) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        border: pw.Border.all(color: PdfColors.blue200),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'OBSERVACIONES',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue800,
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            observaciones,
            style: const pw.TextStyle(fontSize: 9),
          ),
        ],
      ),
    );
  }

  /// Sección de firmas
  static pw.Widget _buildFirmasSection(TransferenciaStock transferencia) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FIRMAS Y AUTORIZACIONES',
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildFirmaBox('SOLICITADO POR', ''),
            _buildFirmaBox('APROBADO POR', ''),
          ],
        ),
        pw.SizedBox(height: 12),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
          children: [
            _buildFirmaBox('ENVIADO POR', ''),
            _buildFirmaBox('RECIBIDO POR', ''),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildFirmaBox(String label, String nombre) {
    return pw.Container(
      width: 200,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            height: 60,
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            '_______________________',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          if (nombre.isNotEmpty)
            pw.Text(
              nombre,
              style: const pw.TextStyle(fontSize: 8),
            ),
        ],
      ),
    );
  }

  /// Footer del documento
  static pw.Widget _buildFooter(
    TransferenciaStock transferencia,
    int pageNumber,
    int totalPages,
  ) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey400),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Transferencia: ${transferencia.codigo}',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Página $pageNumber de $totalPages',
            style: const pw.TextStyle(fontSize: 8),
          ),
          pw.Text(
            'Generado: ${DateFormatter.formatDateTime(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 8),
          ),
        ],
      ),
    );
  }

  // Helpers
  static pw.Widget _buildInfoRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: const pw.TextStyle(fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildEstadoBadge(EstadoTransferencia estado) {
    PdfColor color;
    switch (estado) {
      case EstadoTransferencia.pendiente:
        color = PdfColors.orange;
        break;
      case EstadoTransferencia.aprobada:
        color = PdfColors.blue;
        break;
      case EstadoTransferencia.enTransito:
        color = PdfColors.purple;
        break;
      case EstadoTransferencia.recibida:
        color = PdfColors.green;
        break;
      case EstadoTransferencia.rechazada:
        color = PdfColors.red;
        break;
      case EstadoTransferencia.cancelada:
        color = PdfColors.grey;
        break;
      default:
        color = PdfColors.grey;
    }

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: pw.BoxDecoration(
        color: color,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
      ),
      child: pw.Text(
        estado.descripcion.toUpperCase(),
        style: const pw.TextStyle(
          fontSize: 9,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, {
    bool isHeader = false,
    double fontSize = 9,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: fontSize,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
}
