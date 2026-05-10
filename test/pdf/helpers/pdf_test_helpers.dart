import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Utilidades para tests de generación de PDFs.
///
/// `package:pdf` embebe `/CreationDate`, `/ModDate` y `/ID` con timestamps
/// y aleatorios → el SHA del archivo cambia cada corrida. Por eso, en vez
/// de hashear el archivo entero, extraemos una **firma estructural**
/// determinística:
///   1. Texto contenido (descomprime FlateDecode cuando aplica).
///   2. Cantidad de páginas (`/Type /Page`).
///   3. Bucket de tamaño cada 512 bytes para tolerar variaciones menores.
class PdfTestHelpers {
  PdfTestHelpers._();

  /// Verifica estructura mínima de PDF: cabecera, EOF, tamaño razonable.
  static void expectValidPdf(Uint8List bytes) {
    expect(bytes.length, greaterThan(500),
        reason: 'PDF sospechosamente corto (${bytes.length} bytes)');
    final header = String.fromCharCodes(bytes.take(8));
    expect(header.startsWith('%PDF-'), isTrue,
        reason: 'No empieza con %PDF-: "$header"');
    final tail = String.fromCharCodes(bytes.sublist(bytes.length - 32));
    expect(tail.contains('%%EOF'), isTrue,
        reason: 'No termina con %%EOF: "$tail"');
  }

  /// Cuenta páginas buscando "/Type /Page" (excluyendo "/Pages").
  static int countPages(Uint8List bytes) {
    final raw = latin1.decode(bytes, allowInvalid: true);
    return RegExp(r'/Type\s*/Page(?!s)').allMatches(raw).length;
  }

  /// Extrae texto plano de los content streams del PDF, byte-aware.
  ///
  /// `package:pdf` usa el formato `<<dict>>stream\n<binary>\nendstream`.
  /// Para cada stream:
  /// 1. Detecta el dictionary previo (entre `<<` y `>>`).
  /// 2. Si tiene `/FlateDecode`, descomprime con ZLib.
  /// 3. Aplica regex `(...)Tj` y `[...]TJ` sobre el contenido inflado.
  static List<String> extractText(Uint8List bytes) {
    final results = <String>[];
    // Marker: `>>stream` (literal). Lo que sigue puede ser `\n` o `\r\n`.
    final streamStartMarker = utf8.encode('>>stream');
    final endMarker = utf8.encode('endstream');

    int i = 0;
    while (i < bytes.length) {
      final markerIdx = _indexOfBytes(bytes, streamStartMarker, i);
      if (markerIdx < 0) break;
      // Dict empieza en el `<<` previo
      final dictStart = _findDictStart(bytes, markerIdx);
      final dictBytes = bytes.sublist(dictStart, markerIdx + 2); // incluye `>>`
      final dict = latin1.decode(dictBytes, allowInvalid: true);
      // Stream content arranca DESPUÉS del newline post-marker.
      int contentStart = markerIdx + streamStartMarker.length;
      // Saltar \r\n o \n
      if (contentStart < bytes.length && bytes[contentStart] == 0x0D) {
        contentStart++;
      }
      if (contentStart < bytes.length && bytes[contentStart] == 0x0A) {
        contentStart++;
      }
      final endIdx = _indexOfBytes(bytes, endMarker, contentStart);
      if (endIdx < 0) break;
      // Quitar el newline previo a `endstream`
      int contentEnd = endIdx;
      if (contentEnd > 0 && bytes[contentEnd - 1] == 0x0A) contentEnd--;
      if (contentEnd > 0 && bytes[contentEnd - 1] == 0x0D) contentEnd--;
      final streamBody = bytes.sublist(contentStart, contentEnd);
      Uint8List body;
      if (dict.contains('/FlateDecode')) {
        try {
          body = Uint8List.fromList(ZLibDecoder().decodeBytes(streamBody));
        } catch (_) {
          body = streamBody;
        }
      } else {
        body = streamBody;
      }
      results.addAll(_extractTextFromStream(body));
      i = endIdx + endMarker.length;
    }
    return results;
  }

  static int _findDictStart(Uint8List bytes, int from) {
    // Busca "<<" hacia atrás
    for (int j = from - 2; j >= 1; j--) {
      if (bytes[j] == 0x3C && bytes[j + 1] == 0x3C) return j;
    }
    return 0;
  }

  static int _indexOfBytes(Uint8List haystack, List<int> needle, int from) {
    outer:
    for (int i = from; i <= haystack.length - needle.length; i++) {
      for (int j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  static List<String> _extractTextFromStream(Uint8List body) {
    final results = <String>[];
    final raw = latin1.decode(body, allowInvalid: true);
    // Tj: (texto) Tj
    final tj = RegExp(r'\(((?:[^()\\]|\\.)*)\)\s*Tj');
    for (final m in tj.allMatches(raw)) {
      final s = _unescape(m.group(1) ?? '');
      if (s.trim().isNotEmpty) results.add(s);
    }
    // TJ: [(a)b(c)] TJ → extraemos los strings entre paréntesis
    final tjArr = RegExp(r'\[((?:[^\[\]\\]|\\.)*?)\]\s*TJ');
    final inner = RegExp(r'\(((?:[^()\\]|\\.)*)\)');
    for (final m in tjArr.allMatches(raw)) {
      final arr = m.group(1) ?? '';
      for (final s in inner.allMatches(arr)) {
        final t = _unescape(s.group(1) ?? '');
        if (t.trim().isNotEmpty) results.add(t);
      }
    }
    return results;
  }

  /// Patrón de timestamps que el footer del PDF inserta en runtime
  /// (ej. "Generado:" + "DD/MM/YYYY" + "HH:MM"). Se filtran del hash
  /// para que la firma sea estable entre corridas.
  static final _volatilePatterns = [
    RegExp(r'^\d{1,2}/\d{1,2}/\d{2,4}$'),
    RegExp(r'^\d{1,2}:\d{2}(:\d{2})?$'),
  ];

  /// Devuelve métricas estables del PDF (sin metadata volátil).
  ///
  /// El `textHash` excluye timestamps obvios (fechas y horas que el
  /// footer del PDF inserta en runtime) para que sea reproducible.
  static Map<String, Object> structuralSignature(Uint8List bytes) {
    final pages = countPages(bytes);
    final textos = extractText(bytes);
    final norm = textos.map((t) => t.trim()).where((t) => t.isNotEmpty).toList()
      ..sort();
    final stable = norm
        .where((t) => !_volatilePatterns.any((re) => re.hasMatch(t)))
        .toList();
    final textHash = sha256
        .convert(utf8.encode(stable.join('|')))
        .toString()
        .substring(0, 16);
    return {
      'pages': pages,
      'textCount': stable.length,
      'textHash': textHash,
      'sizeBucket': bytes.length ~/ 512,
    };
  }

  /// Asserta que la firma actual coincide con la golden esperada.
  /// Si difieren, deja un mensaje claro mostrando ambos.
  static void expectSignatureMatches(
    Map<String, Object> actual,
    Map<String, Object> expected, {
    String? label,
  }) {
    final lbl = label ?? 'PDF';
    expect(actual['pages'], expected['pages'],
        reason: '$lbl: cantidad de páginas cambió');
    expect(actual['textCount'], expected['textCount'],
        reason: '$lbl: cantidad de elementos de texto cambió '
            '(actual=${actual['textCount']} expected=${expected['textCount']})');
    expect(actual['textHash'], expected['textHash'],
        reason: '$lbl: contenido textual cambió. Si el cambio es '
            'intencional, regenera el golden. '
            'actual=${actual['textHash']} expected=${expected['textHash']}');
  }

  static String _unescape(String s) {
    return s
        .replaceAll(r'\(', '(')
        .replaceAll(r'\)', ')')
        .replaceAll(r'\\', r'\')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r')
        .replaceAll(r'\t', '\t');
  }
}
