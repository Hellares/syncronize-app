/// Arma el catálogo de productos en PDF: una grilla de dos columnas con foto,
/// nombre, precio y las características principales de cada uno.
///
/// 🔴 En un PDF las imágenes NO pueden ser una URL: el paquete `pdf` necesita
/// los BYTES. Por eso [descargarImagenes] baja las miniaturas antes de armar
/// el documento, y lo que no se pudo bajar se dibuja como un recuadro neutro
/// en vez de romper el catálogo entero.
///
/// 🔴 El membrete lleva el NOMBRE COMERCIAL y el color que la empresa
/// configuró, no la razón social ni el azul del sistema: quien resuelve eso es
/// `resolverIdentidadComercial`, y esta hoja solo dibuja lo que le pasan.
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

/// Mezcla un color con blanco. `t` es cuánto blanco entra (0 = el color puro).
///
/// Los fondos suaves del catálogo —la caja del rótulo, el borde de la tarjeta,
/// la franja del pie— salen todos del color de la empresa. Fijarlos a un gris
/// haría que una marca roja quedara con detalles celestes.
PdfColor _tinte(PdfColor color, double t) => PdfColor(
      color.red + (1 - color.red) * t,
      color.green + (1 - color.green) * t,
      color.blue + (1 - color.blue) * t,
    );

/// El documento. Se arma en un isolate aparte no: el `pdf` ya es rápido y
/// mandar las imágenes a otro isolate cuesta más que dibujarlas.
Future<Uint8List> construirCatalogoPdf({
  required List<ItemCatalogo> items,
  required String empresaNombre,
  required Map<String, Uint8List> imagenes,
  String? empresaTelefono,
  String? empresaRuc,
  String? empresaDireccion,
  String? sedeNombre,
  String? sedeDireccion,

  /// El logo YA descargado. Mismo criterio que las fotos: en un PDF no puede
  /// ser una URL.
  Uint8List? logo,

  /// El color de la marca. Null = el azul del sistema.
  PdfColor? colorPrimario,

  /// El pie configurado por la empresa ("Gracias por su preferencia").
  String? textoPie,
  bool incluirPrecio = true,
  bool incluirCaracteristicas = true,
  bool incluirCodigo = true,

  /// Tope por tarjeta. Con 3 se cortaba una SECCIÓN entera sin avisar: un
  /// producto con procesador y disco mostraba solo el procesador.
  int maxCaracteristicas = 8,
}) async {
  final doc = pw.Document();
  final marca = colorPrimario ?? const PdfColor.fromInt(0xFF004A94);
  final tinteSuave = _tinte(marca, .92);
  final tinteBorde = _tinte(marca, .78);
  final gris = PdfColor.fromInt(0xFF6B7280);
  final grisOscuro = PdfColor.fromInt(0xFF374151);
  final grisClaro = PdfColor.fromInt(0xFFF4F5F7);
  final ambar = PdfColor.fromInt(0xFFB45309);

  final ahora = DateTime.now();
  final fecha =
      '${ahora.day.toString().padLeft(2, '0')}/${ahora.month.toString().padLeft(2, '0')}/${ahora.year}';

  final elegidos = items.where((i) => i.elegido).toList();

  /// 🔴 `MemoryImage` LANZA si no reconoce los bytes, y como se construye
  /// dentro de la tarjeta, una sola foto rara —un HTML de error servido con
  /// 200, un formato que el decoder no conoce— voltea el catálogo ENTERO. Se
  /// prueba acá y lo que no se puede leer sale como "sin foto".
  pw.MemoryImage? imagen(String? url) {
    final bytes = url == null ? null : imagenes[url];
    if (bytes == null) return null;
    try {
      return pw.MemoryImage(bytes);
    } catch (_) {
      return null;
    }
  }

  pw.Widget tarjeta(ItemCatalogo it) {
    final foto = imagen(it.fotoUrl);
    final rasgos = it.caracteristicas.take(maxCaracteristicas).toList();
    final sinStock = it.stock <= 0;

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: tinteBorde, width: .8),
        borderRadius: pw.BorderRadius.circular(7),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          // La foto va al ras de los bordes de arriba: la tarjeta se lee como
          // una ficha y no como un texto con una imagen pegada encima.
          pw.Container(
            height: 140,
            width: double.infinity,
            decoration: pw.BoxDecoration(
              color: grisClaro,
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(6),
                topRight: pw.Radius.circular(6),
              ),
            ),
            child: foto == null
                ? pw.Center(
                    child: pw.Text('sin foto',
                        style: pw.TextStyle(fontSize: 7, color: gris)))
                // 🔴 `contain` y no `cover`: recortar una foto de producto le
                // come el borde --justo lo que el cliente quiere ver--. Y va
                // dentro de un `Center`: sin el, la imagen contenida se pega a
                // un lado y deja todo el hueco del otro.
                : pw.Center(
                    child: pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Image(foto, fit: pw.BoxFit.contain),
                    ),
                  ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.fromLTRB(9, 8, 9, 9),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisSize: pw.MainAxisSize.min,
              children: [
                pw.Text(
                  it.titulo,
                  maxLines: 2,
                  overflow: pw.TextOverflow.clip,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: grisOscuro,
                    lineSpacing: 1,
                  ),
                ),
                if (incluirCodigo && (it.codigo ?? '').isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Text('Cód. ${it.codigo}',
                      style: pw.TextStyle(fontSize: 6.5, color: gris)),
                ],
                if (incluirPrecio || sinStock) ...[
                  pw.SizedBox(height: 5),
                  pw.Row(
                    crossAxisAlignment: pw.CrossAxisAlignment.center,
                    children: [
                      if (incluirPrecio)
                        pw.Text(
                          'S/ ${it.precio.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 13,
                            fontWeight: pw.FontWeight.bold,
                            color: marca,
                          ),
                        ),
                      pw.Spacer(),
                      // Lo que se ofrece por encargo se dice, no se disimula.
                      if (sinStock)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: PdfColor.fromInt(0xFFFEF3C7),
                            borderRadius: pw.BorderRadius.circular(3),
                          ),
                          child: pw.Text('A pedido',
                              style: pw.TextStyle(fontSize: 6, color: ambar)),
                        ),
                    ],
                  ),
                ],
                if (incluirCaracteristicas && rasgos.isNotEmpty) ...[
                  pw.SizedBox(height: 7),
                  // Las características van en su propio bloque gris: sin eso
                  // se leían como una continuación del nombre.
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.symmetric(
                        horizontal: 6, vertical: 5),
                    decoration: pw.BoxDecoration(
                      color: grisClaro,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      mainAxisSize: pw.MainAxisSize.min,
                      children: [
                        for (var i = 0; i < rasgos.length; i++)
                          pw.Padding(
                            padding:
                                pw.EdgeInsets.only(top: i == 0 ? 0.0 : 2.5),
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Expanded(
                                  flex: 2,
                                  child: pw.Text(rasgos[i].$1,
                                      maxLines: 1,
                                      style: pw.TextStyle(
                                          fontSize: 6.5, color: gris)),
                                ),
                                pw.SizedBox(width: 4),
                                pw.Expanded(
                                  flex: 3,
                                  child: pw.Text(
                                    rasgos[i].$2,
                                    maxLines: 1,
                                    style: pw.TextStyle(
                                      fontSize: 6.5,
                                      fontWeight: pw.FontWeight.bold,
                                      color: grisOscuro,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (it.caracteristicas.length > maxCaracteristicas)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(top: 2.5),
                            child: pw.Text(
                              'y ${it.caracteristicas.length - maxCaracteristicas} más',
                              style: pw.TextStyle(fontSize: 6, color: gris),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(24, 22, 24, 26),
      // El membrete de la cotizacion pero SIN "COTIZACION", codigo ni validez:
      // esto no es un documento con vigencia, es una lista de productos. De la
      // segunda hoja en adelante queda una franja fina, que un catalogo de
      // ocho paginas sin nada arriba no se sabe de quien es.
      header: (ctx) => ctx.pageNumber == 1
          ? _membrete(
              logo: logo,
              empresaNombre: empresaNombre,
              empresaRuc: empresaRuc,
              empresaTelefono: empresaTelefono,
              empresaDireccion: empresaDireccion,
              sedeNombre: sedeNombre,
              sedeDireccion: sedeDireccion,
              marca: marca,
              tinteSuave: tinteSuave,
              gris: gris,
              grisOscuro: grisOscuro,
              fecha: fecha,
              articulos: elegidos.length,
            )
          : _franjaContinuacion(
              empresaNombre: empresaNombre,
              marca: marca,
              gris: gris,
            ),
      footer: (ctx) => pw.Container(
        margin: const pw.EdgeInsets.only(top: 8),
        padding: const pw.EdgeInsets.only(top: 5),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: tinteBorde, width: .6)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              [
                if ((textoPie ?? '').isNotEmpty) textoPie!,
                if ((empresaTelefono ?? '').isNotEmpty) 'Tel: $empresaTelefono',
              ].join('   ·   '),
              style: pw.TextStyle(fontSize: 7.5, color: gris),
            ),
            pw.Text(
              'Página ${ctx.pageNumber} de ${ctx.pagesCount}',
              style: pw.TextStyle(fontSize: 7.5, color: gris),
            ),
          ],
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
            columnWidths: const {
              0: pw.FlexColumnWidth(),
              1: pw.FlexColumnWidth()
            },
            children: [
              for (var i = 0; i < elegidos.length; i += 2)
                pw.TableRow(
                  // Las dos tarjetas de la fila terminan a la misma altura: si
                  // no, la que tiene menos caracteristicas queda corta y la
                  // grilla se ve dentada.
                  verticalAlignment: pw.TableCellVerticalAlignment.full,
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(right: 6, bottom: 12),
                      child: tarjeta(elegidos[i]),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.only(left: 6, bottom: 12),
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
/// A la derecha va el rótulo de qué es la hoja, cuántos artículos trae y la
/// fecha en chico: un catálogo con precios sin fecha envejece mal.
pw.Widget _membrete({
  required String empresaNombre,
  required PdfColor marca,
  required PdfColor tinteSuave,
  required PdfColor gris,
  required PdfColor grisOscuro,
  required String fecha,
  required int articulos,
  Uint8List? logo,
  String? empresaRuc,
  String? empresaTelefono,
  String? empresaDireccion,
  String? sedeNombre,
  String? sedeDireccion,
}) {
  // La dirección de la SEDE manda sobre la fiscal: el cliente va a la tienda,
  // no al domicilio del contribuyente.
  final direccion = (sedeDireccion ?? '').isNotEmpty
      ? sedeDireccion!
      : (empresaDireccion ?? '');
  final datos = <String>[
    if ((empresaRuc ?? '').isNotEmpty) 'RUC: $empresaRuc',
    if ((sedeNombre ?? '').isNotEmpty) 'Sede: $sedeNombre',
    if (direccion.isNotEmpty) direccion,
    if ((empresaTelefono ?? '').isNotEmpty) 'Tel: $empresaTelefono',
  ];

  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 12),
    padding: const pw.EdgeInsets.only(bottom: 9),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: marca, width: 1.4)),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Con logo va el logo Y el nombre debajo; el nombre comercial es la
        // marca y no se pierde aunque el logo la repita.
        if (logo != null) ...[
          pw.Image(pw.MemoryImage(logo),
              height: 46, width: 110, fit: pw.BoxFit.contain),
          pw.SizedBox(width: 12),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                empresaNombre,
                style: pw.TextStyle(
                  fontSize: logo != null ? 12 : 16,
                  fontWeight: pw.FontWeight.bold,
                  color: marca,
                ),
              ),
              for (final d in datos) ...[
                pw.SizedBox(height: 2),
                pw.Text(d, style: pw.TextStyle(fontSize: 8, color: gris)),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: pw.BoxDecoration(
            color: tinteSuave,
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'CATÁLOGO',
                style: pw.TextStyle(
                  fontSize: 11,
                  fontWeight: pw.FontWeight.bold,
                  color: marca,
                  letterSpacing: 1.2,
                ),
              ),
              pw.SizedBox(height: 3),
              pw.Text(
                articulos == 1 ? '1 artículo' : '$articulos artículos',
                style: pw.TextStyle(fontSize: 7.5, color: grisOscuro),
              ),
              pw.SizedBox(height: 1.5),
              pw.Text(fecha, style: pw.TextStyle(fontSize: 7.5, color: gris)),
            ],
          ),
        ),
      ],
    ),
  );
}

/// La franja de las hojas 2 en adelante: quién manda el catálogo, sin repetir
/// el membrete entero y sin comerse media hoja de productos.
pw.Widget _franjaContinuacion({
  required String empresaNombre,
  required PdfColor marca,
  required PdfColor gris,
}) {
  return pw.Container(
    margin: const pw.EdgeInsets.only(bottom: 10),
    padding: const pw.EdgeInsets.only(bottom: 4),
    decoration: pw.BoxDecoration(
      border: pw.Border(bottom: pw.BorderSide(color: marca, width: .7)),
    ),
    child: pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          empresaNombre,
          style: pw.TextStyle(
            fontSize: 8.5,
            fontWeight: pw.FontWeight.bold,
            color: marca,
          ),
        ),
        pw.Text('Catálogo de productos',
            style: pw.TextStyle(fontSize: 7.5, color: gris)),
      ],
    ),
  );
}

/// Cuántas imágenes hay que bajar para estos ítems.
@visibleForTesting
int fotosADescargar(List<ItemCatalogo> items) =>
    items.where((i) => i.elegido && (i.fotoUrl ?? '').isNotEmpty).length;
