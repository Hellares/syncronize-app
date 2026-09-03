/// Arma el catálogo de productos en PDF: una grilla de dos columnas con foto,
/// nombre, precio y las características principales de cada uno.
///
/// 🔴 En un PDF las imágenes NO pueden ser una URL: el paquete `pdf` necesita
/// los BYTES. Por eso [descargarImagenes] baja las miniaturas antes de armar
/// el documento, y lo que no se pudo bajar se dibuja como un recuadro neutro
/// en vez de romper el catálogo entero.
library;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Un renglón del catálogo, ya resuelto por la pantalla: producto o variante.
class ItemCatalogo {
  final String id;
  final String titulo;
  final String? codigo;
  final String? fotoUrl;
  final double precio;

  /// `nombre: valor` ya aplanados y en orden. La ficha del PDF muestra los
  /// primeros; la lista completa haría ilegible una tarjeta de media página.
  final List<(String, String)> caracteristicas;
  final double stock;

  /// Si entra al PDF. Arranca en `true` cuando hay stock.
  bool elegido;

  ItemCatalogo({
    required this.id,
    required this.titulo,
    required this.precio,
    required this.stock,
    this.codigo,
    this.fotoUrl,
    this.caracteristicas = const [],
    bool? elegido,
  }) : elegido = elegido ?? stock > 0;
}

/// Baja las miniaturas en tandas y devuelve `url -> bytes`.
///
/// De a [tanda] en paralelo: cien descargas simultáneas ahogan la conexión del
/// celular y el catálogo tarda MÁS que haciéndolo por partes. Lo que falla se
/// omite: una foto que no llega no puede voltear el catálogo.
Future<Map<String, Uint8List>> descargarImagenes(
  Iterable<String> urls, {
  int tanda = 5,
  void Function(int listas, int total)? onProgreso,
}) async {
  final pendientes = urls.where((u) => u.isNotEmpty).toSet().toList();
  final resultado = <String, Uint8List>{};
  var listas = 0;

  for (var i = 0; i < pendientes.length; i += tanda) {
    final grupo = pendientes.skip(i).take(tanda);
    await Future.wait(grupo.map((url) async {
      try {
        final res = await http
            .get(Uri.parse(url))
            .timeout(const Duration(seconds: 12));
        if (res.statusCode == 200 && res.bodyBytes.isNotEmpty) {
          resultado[url] = res.bodyBytes;
        }
      } catch (_) {
        // Se dibuja el recuadro neutro.
      } finally {
        listas++;
        onProgreso?.call(listas, pendientes.length);
      }
    }));
  }
  return resultado;
}

/// El documento. Se arma en un isolate aparte no: el `pdf` ya es rápido y
/// mandar las imágenes a otro isolate cuesta más que dibujarlas.
Future<Uint8List> construirCatalogoPdf({
  required List<ItemCatalogo> items,
  required String empresaNombre,
  required Map<String, Uint8List> imagenes,
  String? empresaTelefono,
  String? empresaRuc,
  String? sedeNombre,
  String? sedeDireccion,
  /// El logo YA descargado. Mismo criterio que las fotos: en un PDF no puede
  /// ser una URL.
  Uint8List? logo,
  bool incluirPrecio = true,
  bool incluirCaracteristicas = true,
  bool incluirCodigo = true,
  /// Tope por tarjeta. Con 3 se cortaba una SECCIÓN entera sin avisar: un
  /// producto con procesador y disco mostraba solo el procesador.
  int maxCaracteristicas = 8,
}) async {
  final doc = pw.Document();
  final azul = PdfColor.fromInt(0xFF004A94);
  final gris = PdfColor.fromInt(0xFF6B7280);
  final grisClaro = PdfColor.fromInt(0xFFF3F4F6);

  final ahora = DateTime.now();
  final fecha =
      '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}';

  pw.Widget tarjeta(ItemCatalogo it) {
    final bytes = it.fotoUrl == null ? null : imagenes[it.fotoUrl];
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColor.fromInt(0xFFD9E4F2), width: .8),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Container(
            height: 140,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: grisClaro,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: bytes == null
                ? pw.Center(
                    child: pw.Text('sin foto',
                        style: pw.TextStyle(fontSize: 7, color: gris)))
                // 🔴 `contain` y no `cover`: recortar una foto de producto le
                // come el borde --justo lo que el cliente quiere ver--. Y va
                // dentro de un `Center`: sin el, la imagen contenida se pega a
                // un lado y deja todo el hueco del otro.
                : pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(3),
                      child: pw.Image(pw.MemoryImage(bytes), fit: pw.BoxFit.contain),
                    ),
                  ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            it.titulo,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
          ),
          if (incluirCodigo && (it.codigo ?? '').isNotEmpty) ...[
            pw.SizedBox(height: 1),
            pw.Text('Cód. ${it.codigo}',
                style: pw.TextStyle(fontSize: 6.5, color: gris)),
          ],
          if (incluirPrecio) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              'S/ ${it.precio.toStringAsFixed(2)}',
              style: pw.TextStyle(
                  fontSize: 13, fontWeight: pw.FontWeight.bold, color: azul),
            ),
          ],
          if (incluirCaracteristicas && it.caracteristicas.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            for (final (nombre, valor) in it.caracteristicas.take(maxCaracteristicas))
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 1),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 2,
                      child: pw.Text(nombre,
                          style: pw.TextStyle(fontSize: 6.5, color: gris)),
                    ),
                    pw.Expanded(
                      flex: 3,
                      child: pw.Text(valor,
                          maxLines: 1,
                          style: const pw.TextStyle(fontSize: 6.5)),
                    ),
                  ],
                ),
              ),
            if (it.caracteristicas.length > maxCaracteristicas)
              pw.Text(
                'y ${it.caracteristicas.length - maxCaracteristicas} más',
                style: pw.TextStyle(fontSize: 6, color: gris),
              ),
          ],
          // Lo que se ofrece por encargo se dice, no se disimula.
          if (it.stock <= 0) ...[
            pw.SizedBox(height: 3),
            pw.Text('A pedido',
                style: pw.TextStyle(
                    fontSize: 6.5, color: PdfColor.fromInt(0xFFB45309))),
          ],
        ],
      ),
    );
  }

  final elegidos = items.where((i) => i.elegido).toList();

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 26),
      // El membrete de la cotizacion pero SIN "COTIZACION", fecha ni validez:
      // esto no es un documento con vigencia, es una lista de productos.
      header: (ctx) => ctx.pageNumber == 1
          ? _membrete(
              logo: logo,
              empresaNombre: empresaNombre,
              empresaRuc: empresaRuc,
              empresaTelefono: empresaTelefono,
              sedeNombre: sedeNombre,
              sedeDireccion: sedeDireccion,
              azul: azul,
              gris: gris,
              fecha: fecha,
            )
          : pw.SizedBox(height: 6),
      footer: (ctx) => pw.Container(
        alignment: pw.Alignment.centerRight,
        margin: const pw.EdgeInsets.only(top: 6),
        child: pw.Text(
          [
            if ((empresaTelefono ?? '').isNotEmpty) empresaTelefono,
            'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
          ].join('   ·   '),
          style: pw.TextStyle(fontSize: 7.5, color: gris),
        ),
      ),
      build: (ctx) => [
        // 🔴 Dos columnas con `Table` de anchos FLEXIBLES y no un `Wrap` con
        // ancho calculado a mano: `availableWidth` ya descuenta los margenes
        // por defecto del formato, asi que restarles ademas los propios dejaba
        // las tarjetas angostas y todo un vacio a la derecha.
        // La grilla se mete 20 pt por lado, asi cada tarjeta pierde 20 de
        // ancho. El membrete NO se toca: sigue a todo el ancho de la hoja.
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20),
          child: pw.Table(
          columnWidths: const {0: pw.FlexColumnWidth(), 1: pw.FlexColumnWidth()},
          children: [
            for (var i = 0; i < elegidos.length; i += 2)
              pw.TableRow(
                children: [
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(right: 5, bottom: 10),
                    child: tarjeta(elegidos[i]),
                  ),
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(left: 5, bottom: 10),
                    // Impar: la ultima fila deja la celda vacia en vez de
                    // estirar la tarjeta a todo el ancho.
                    child: i + 1 < elegidos.length
                        ? tarjeta(elegidos[i + 1])
                        : pw.SizedBox(),
                  ),
                ],
              ),
          ],
          ),
        ),
      ],
    ),
  );

  return doc.save();
}

/// El membrete de la empresa, igual que el de la cotización pero sin el bloque
/// de la derecha: acá no hay "COTIZACIÓN", ni código, ni fecha de emisión, ni
/// "válida hasta". Un catálogo no vence.
///
/// Debajo, un rótulo chico que dice qué es la hoja. La fecha se conserva ahí,
/// en letra chica, porque un catálogo con precios sin fecha envejece mal.
pw.Widget _membrete({
  required String empresaNombre,
  required PdfColor azul,
  required PdfColor gris,
  required String fecha,
  Uint8List? logo,
  String? empresaRuc,
  String? empresaTelefono,
  String? sedeNombre,
  String? sedeDireccion,
}) {
  final datos = <String>[
    if ((empresaRuc ?? '').isNotEmpty) 'RUC: $empresaRuc',
    if ((sedeNombre ?? '').isNotEmpty) 'Sede: $sedeNombre',
    if ((sedeDireccion ?? '').isNotEmpty) sedeDireccion!,
    if ((empresaTelefono ?? '').isNotEmpty) 'Tel: $empresaTelefono',
  ];

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.only(bottom: 8),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: azul, width: 1.2)),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Con logo va el logo; sin logo, el nombre en grande. Es lo mismo
            // que hace el membrete de la cotización.
            if (logo != null) ...[
              pw.Image(pw.MemoryImage(logo), height: 44, width: 110, fit: pw.BoxFit.contain),
              pw.SizedBox(width: 10),
            ],
            pw.Expanded(
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    empresaNombre,
                    style: pw.TextStyle(
                      fontSize: logo != null ? 11 : 15,
                      fontWeight: pw.FontWeight.bold,
                      color: azul,
                    ),
                  ),
                  for (final d in datos) ...[
                    pw.SizedBox(height: 1.5),
                    pw.Text(d, style: pw.TextStyle(fontSize: 8, color: gris)),
                  ],
                ],
              ),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text(
              'Catálogo de productos',
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: gris),
            ),
            pw.Text(fecha, style: pw.TextStyle(fontSize: 7.5, color: gris)),
          ],
        ),
      ],
    ),
  );
}

/// Cuántas imágenes hay que bajar para estos ítems.
@visibleForTesting
int fotosADescargar(List<ItemCatalogo> items) =>
    items.where((i) => i.elegido && (i.fotoUrl ?? '').isNotEmpty).length;
