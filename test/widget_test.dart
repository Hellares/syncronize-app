// Reemplaza el "Counter smoke test" de la plantilla de Flutter (que nunca
// aplicó a esta app y fallaba siempre) por tests reales del catálogo curado
// de códigos de producto SUNAT (anexos 25.1/25.2/25.3 + genéricos).

import 'package:flutter_test/flutter_test.dart';

import 'package:syncronize/features/producto/domain/entities/codigo_producto_sunat.dart';

void main() {
  group('Catálogo códigos producto SUNAT', () {
    test('todos los códigos son de 8 dígitos (formato ERR-3496)', () {
      final regex = RegExp(r'^\d{8}$');
      for (final c in kCatalogoCodigosProductoSunat) {
        expect(regex.hasMatch(c.codigo), isTrue,
            reason: 'Código inválido: ${c.codigo} (${c.descripcion})');
      }
    });

    test('incluye los genéricos exentos de ERR-3496', () {
      expect(buscarCodigoProductoSunat('00000000'), isNotNull);
      expect(buscarCodigoProductoSunat('99999999'), isNotNull);
    });

    test('incluye los códigos clave de detracción y percepción', () {
      // Carnes y despojos (pollo beneficiado) — anexo 25.2
      expect(buscarCodigoProductoSunat('50111500')?.grupo,
          GruposCodigoSunat.detraccion);
      // Gravados por renuncia a exoneración — anexo 25.2
      expect(buscarCodigoProductoSunat('11111111')?.grupo,
          GruposCodigoSunat.detraccion);
      // Bebidas no alcohólicas — anexo 25.3
      expect(buscarCodigoProductoSunat('50202300')?.grupo,
          GruposCodigoSunat.percepcion);
    });

    test('todo grupo usado está en el orden de presentación', () {
      final grupos = kCatalogoCodigosProductoSunat.map((c) => c.grupo).toSet();
      for (final g in grupos) {
        expect(GruposCodigoSunat.orden.contains(g), isTrue,
            reason: 'Grupo sin orden definido: $g');
      }
    });

    test('buscar código inexistente o vacío devuelve null', () {
      expect(buscarCodigoProductoSunat('12345678'), isNull);
      expect(buscarCodigoProductoSunat(''), isNull);
      expect(buscarCodigoProductoSunat(null), isNull);
    });
  });
}
