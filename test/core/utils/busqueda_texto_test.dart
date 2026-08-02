import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/busqueda_texto.dart';

/// Estas pruebas fijan la **paridad con el backend**
/// (`backend/src/producto/texto-busqueda.util.ts`). El selector de productos
/// filtra local cuando ya tiene el catálogo entero y en ese caso NO consulta
/// al servidor: si acá se mira menos que allá, la búsqueda devuelve vacío y
/// el cajero concluye que el producto no existe.
void main() {
  group('normalizarTexto', () {
    test('baja a minúsculas y saca tildes', () {
      expect(normalizarTexto('Lavadora Automática'), 'lavadora automatica');
      expect(normalizarTexto('CAÑO PVC'), 'cano pvc');
      expect(normalizarTexto('Güiro'), 'guiro');
    });

    test('mismos casos que unaccent de Postgres', () {
      expect(normalizarTexto('Ñandú'), 'nandu');
      expect(normalizarTexto('Açaí'), 'acai');
    });

    test('colapsa espacios y recorta', () {
      expect(normalizarTexto('  lavadora   samsung  '), 'lavadora samsung');
    });
  });

  group('terminosBusqueda', () {
    test('parte en palabras normalizadas', () {
      expect(terminosBusqueda('Lavadora SAMSUNG'), ['lavadora', 'samsung']);
    });

    test('no repite palabras', () {
      expect(terminosBusqueda('samsung samsung'), ['samsung']);
    });

    test('vacío si no hay nada que buscar', () {
      expect(terminosBusqueda('   '), isEmpty);
      expect(terminosBusqueda(''), isEmpty);
    });
  });

  group('coincideTodosLosTerminos', () {
    // El caso que motivó todo: la marca vive en otro campo que el nombre.
    test('encuentra cruzando nombre y marca', () {
      const texto = 'LAVADORA AUTOMATICA 18KG PROD-001 SAMSUNG ELECTRO';
      expect(
        coincideTodosLosTerminos(texto, terminosBusqueda('lavadora samsung')),
        isTrue,
      );
      expect(
        coincideTodosLosTerminos(texto, terminosBusqueda('samsung lavadora')),
        isTrue,
        reason: 'el orden de las palabras no debe importar',
      );
    });

    test('buscar solo la marca alcanza', () {
      expect(
        coincideTodosLosTerminos('MEDIAS TIGRE PROD-01 CAYRA DAMA',
            terminosBusqueda('cayra')),
        isTrue,
      );
    });

    test('fragmentos: "mon te 24" encuentra MONITOR TEROS 24 PULGADAS', () {
      expect(
        coincideTodosLosTerminos(
            'MONITOR TEROS 24 PULGADAS', terminosBusqueda('mon te 24')),
        isTrue,
      );
    });

    test('exige TODAS las palabras, no alguna', () {
      expect(
        coincideTodosLosTerminos('LAVADORA AUTOMATICA LG',
            terminosBusqueda('lavadora samsung')),
        isFalse,
      );
    });

    test('ignora tildes en los dos lados', () {
      expect(
        coincideTodosLosTerminos('CAFÉ MOLIDO', terminosBusqueda('cafe')),
        isTrue,
      );
      expect(
        coincideTodosLosTerminos('CAFE MOLIDO', terminosBusqueda('café')),
        isTrue,
      );
    });

    test('sin términos no filtra nada', () {
      expect(coincideTodosLosTerminos('cualquier cosa', const []), isTrue);
    });
  });
}
