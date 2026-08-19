import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/features/compra/domain/entities/linea_compra_draft.dart';
import 'package:syncronize/features/compra/presentation/bloc/compra_carrito/compra_carrito_cubit.dart';
import 'package:syncronize/features/producto/domain/entities/producto_list_item.dart';
import 'package:syncronize/features/producto/domain/entities/producto_variante.dart';
import 'package:syncronize/features/producto/domain/entities/stock_por_sede_info.dart';

/// Carrito de la grilla de selección de productos de una compra.
///
/// Las dos reglas que más cuestan: el costo de un producto CON variantes no
/// existe (el del padre viene mezclado desde el backend) y la presentación se
/// resuelve por variante, no por producto.
void main() {
  const sedeA = 'sede-a';
  const sedeB = 'sede-b';

  StockPorSedeInfo stock(
    String sedeId, {
    int cantidad = 0,
    double? precioCosto,
    double? precio,
  }) =>
      StockPorSedeInfo(
        sedeId: sedeId,
        sedeNombre: sedeId,
        sedeCodigo: sedeId,
        cantidad: cantidad,
        precioCosto: precioCosto,
        precio: precio,
      );

  ProductoVariante variante(
    String id, {
    String nombre = 'Variante',
    List<StockPorSedeInfo>? stocks,
    String? unidadMedidaId,
    String? unidadPresentacionId,
    String? unidadPresentacionSimbolo,
    double? factorPresentacion,
  }) =>
      ProductoVariante(
        id: id,
        productoId: 'p1',
        empresaId: 'e1',
        nombre: nombre,
        sku: id,
        codigoEmpresa: id,
        atributosValores: const [],
        stocksPorSede: stocks,
        unidadMedidaId: unidadMedidaId,
        unidadPresentacionId: unidadPresentacionId,
        unidadPresentacionSimbolo: unidadPresentacionSimbolo,
        factorPresentacion: factorPresentacion,
        isActive: true,
        orden: 0,
        creadoEn: DateTime(2026),
        actualizadoEn: DateTime(2026),
      );

  ProductoListItem producto({
    String id = 'p1',
    String nombre = 'ARROZ',
    List<StockPorSedeInfo>? stocks,
    List<ProductoVariante>? variantes,
    double? factorCompra,
    String? unidadCompraSimbolo,
    String? unidadMedidaSimbolo,
    String? unidadPresentacionSimbolo,
    double? factorPresentacion,
  }) =>
      ProductoListItem(
        id: id,
        nombre: nombre,
        codigoEmpresa: 'P-001',
        destacado: false,
        isActive: true,
        tieneVariantes: variantes != null,
        variantes: variantes,
        stocksPorSede: stocks,
        factorCompra: factorCompra,
        unidadCompraSimbolo: unidadCompraSimbolo,
        unidadMedidaSimbolo: unidadMedidaSimbolo,
        unidadPresentacionSimbolo: unidadPresentacionSimbolo,
        factorPresentacion: factorPresentacion,
      );

  group('agregar y acumular', () {
    test('tocar dos veces el mismo producto acumula, no abre otra línea', () {
      final cubit = CompraCarritoCubit();
      final p = producto(stocks: [stock(sedeA, cantidad: 5, precioCosto: 3.2)]);

      cubit.agregarProducto(p, sedeId: sedeA);
      cubit.agregarProducto(p, sedeId: sedeA);

      expect(cubit.state.totalLineas, 1);
      expect(cubit.state.lineas.single.cantidad, 2);
      expect(cubit.state.totalUnidades, 2);
    });

    test('producto y variante del mismo producto son líneas distintas', () {
      final cubit = CompraCarritoCubit();
      final v = variante('v1');
      final p = producto(variantes: [v]);

      cubit.agregarProducto(p, sedeId: sedeA);
      cubit.agregarVariante(p, v, sedeId: sedeA);

      expect(cubit.state.totalLineas, 2);
    });

    test('dos variantes del mismo producto no se pisan entre sí', () {
      final cubit = CompraCarritoCubit();
      // Mismo nombre a propósito: la identidad tiene que salir del id.
      final v1 = variante('v1', nombre: 'BOLSA');
      final v2 = variante('v2', nombre: 'BOLSA');
      final p = producto(variantes: [v1, v2]);

      cubit.agregarVariante(p, v1, sedeId: sedeA);
      cubit.agregarVariante(p, v2, sedeId: sedeA, cantidad: 3);

      expect(cubit.state.totalLineas, 2);
      expect(cubit.state.cantidadDe('p1', varianteId: 'v1'), 1);
      expect(cubit.state.cantidadDe('p1', varianteId: 'v2'), 3);
      expect(cubit.state.cantidadDeProducto('p1'), 4);
    });

    test('agregar con cantidad cero o negativa no hace nada', () {
      final cubit = CompraCarritoCubit();

      cubit.agregarProducto(producto(), sedeId: sedeA, cantidad: 0);
      cubit.agregarProducto(producto(), sedeId: sedeA, cantidad: -2);

      expect(cubit.state.estaVacio, isTrue);
    });

    test('acumular NO pisa lo que el usuario ya corrigió en la línea', () {
      final cubit = CompraCarritoCubit();
      final p = producto(stocks: [stock(sedeA, precioCosto: 3.2)]);
      cubit.agregarProducto(p, sedeId: sedeA);
      cubit.actualizarLinea('p1|', precioUnitario: 4.5);

      cubit.agregarProducto(p, sedeId: sedeA);

      expect(cubit.state.lineas.single.cantidad, 2);
      expect(cubit.state.lineas.single.precioUnitario, 4.5);
    });
  });

  group('costo al agregar', () {
    test('un producto sin variantes toma su costo de la sede', () {
      final cubit = CompraCarritoCubit();
      final p = producto(stocks: [
        stock(sedeA, cantidad: 12, precioCosto: 3.2, precio: 4.5),
        stock(sedeB, precioCosto: 9.9),
      ]);

      cubit.agregarProducto(p, sedeId: sedeA);
      final linea = cubit.state.lineas.single;

      expect(linea.precioUnitario, 3.2);
      expect(linea.costoActualSede, 3.2);
      expect(linea.precioVentaActualSede, 4.5);
      expect(linea.stockActualSede, 12);
      expect(linea.sinCosto, isFalse);
    });

    test('un producto CON variantes queda SIN costo, no toma el mezclado', () {
      // El backend arma el `stocksPorSede` del padre mezclando el residual del
      // producto con el de las variantes, y la última con precio configurado
      // pisa el costo. Ese número es de alguna variante suelta.
      final cubit = CompraCarritoCubit();
      final p = producto(
        stocks: [stock(sedeA, cantidad: 7, precioCosto: 3.2, precio: 4.5)],
        variantes: [variante('v1')],
      );

      cubit.agregarProducto(p, sedeId: sedeA);
      final linea = cubit.state.lineas.single;

      expect(linea.precioUnitario, isNull);
      expect(linea.costoActualSede, isNull);
      expect(linea.precioVentaActualSede, isNull);
      expect(linea.sinCosto, isTrue);
    });

    test('la variante toma el costo de SU fila en la sede', () {
      final cubit = CompraCarritoCubit();
      final v = variante('v1', nombre: '5kg', stocks: [
        stock(sedeA, cantidad: 4, precioCosto: 3.05, precio: 3.9),
        stock(sedeB, precioCosto: 99),
      ]);
      final p = producto(variantes: [v]);

      cubit.agregarVariante(p, v, sedeId: sedeA);
      final linea = cubit.state.lineas.single;

      expect(linea.descripcion, 'ARROZ - 5kg');
      expect(linea.precioUnitario, 3.05);
      expect(linea.precioVentaActualSede, 3.9);
      expect(linea.stockActualSede, 4);
    });

    test('lo que no vive en la sede entra sin costo y el estado lo reporta',
        () {
      final cubit = CompraCarritoCubit();
      final p = producto(stocks: [stock(sedeB, cantidad: 40, precioCosto: 3)]);

      cubit.agregarProducto(p, sedeId: sedeA);

      expect(cubit.state.lineas.single.sinCosto, isTrue);
      expect(cubit.state.hayLineasSinCosto, isTrue);
      expect(cubit.state.lineasSinCosto, hasLength(1));
    });

    test('un costo en cero cuenta como sin costo', () {
      final cubit = CompraCarritoCubit();
      final p = producto(stocks: [stock(sedeA, precioCosto: 0)]);

      cubit.agregarProducto(p, sedeId: sedeA);

      expect(cubit.state.hayLineasSinCosto, isTrue);
    });
  });

  group('presentación por variante', () {
    test('un bulto cerrado NO hereda los kilos del producto', () {
      // El producto se guarda en gramos y se lee en kilos, pero el SACO se
      // compra por unidad: pedirlo "en gramos" invita a escribir 15000 donde
      // va 1.
      final cubit = CompraCarritoCubit();
      final saco = variante('v-saco',
          nombre: 'SACO 15KG', unidadMedidaId: 'u-und');
      final p = producto(
        variantes: [saco],
        unidadMedidaSimbolo: 'g',
        unidadPresentacionSimbolo: 'kg',
        factorPresentacion: 1000,
      );

      cubit.agregarVariante(p, saco, sedeId: sedeA);

      expect(cubit.state.lineas.single.factorPresentacion, 1);
    });

    test('un granel usa la presentación de la variante', () {
      final cubit = CompraCarritoCubit();
      final granel = variante(
        'v-granel',
        nombre: 'GRANEL',
        unidadPresentacionId: 'u-kg',
        unidadPresentacionSimbolo: 'kg',
        factorPresentacion: 1000,
      );
      final p = producto(variantes: [granel], unidadMedidaSimbolo: 'g');

      cubit.agregarVariante(p, granel, sedeId: sedeA);
      final linea = cubit.state.lineas.single;

      expect(linea.factorPresentacion, 1000);
      expect(linea.unidadPresentacionSimbolo, 'kg');
    });
  });

  group('cantidad y borrado', () {
    test('decrementar baja de a uno y en el último saca la línea', () {
      final cubit = CompraCarritoCubit();
      final p = producto();
      cubit.agregarProducto(p, sedeId: sedeA, cantidad: 2);

      cubit.decrementarProducto('p1');
      expect(cubit.state.lineas.single.cantidad, 1);

      cubit.decrementarProducto('p1');
      expect(cubit.state.estaVacio, isTrue);
    });

    test('decrementar una variante no toca la línea del producto base', () {
      final cubit = CompraCarritoCubit();
      final v = variante('v1');
      final p = producto(variantes: [v]);
      cubit.agregarProducto(p, sedeId: sedeA);
      cubit.agregarVariante(p, v, sedeId: sedeA);

      cubit.decrementarVariante('p1', 'v1');

      expect(cubit.state.totalLineas, 1);
      expect(cubit.state.cantidadDe('p1'), 1);
    });

    test('el sheet fija la cantidad de una variante en unidades atómicas', () {
      // Un granel se mueve de a 1 kg: el sheet manda 1000, no 1.
      final cubit = CompraCarritoCubit();
      final granel = variante(
        'v-granel',
        unidadPresentacionId: 'u-kg',
        unidadPresentacionSimbolo: 'kg',
        factorPresentacion: 1000,
      );
      final p = producto(variantes: [granel]);

      cubit.setCantidadVariante(p, granel, sedeId: sedeA, cantidad: 1000);
      expect(cubit.state.cantidadDe('p1', varianteId: 'v-granel'), 1000);

      cubit.setCantidadVariante(p, granel, sedeId: sedeA, cantidad: 2000);
      expect(cubit.state.totalLineas, 1);
      expect(cubit.state.cantidadDe('p1', varianteId: 'v-granel'), 2000);

      cubit.setCantidadVariante(p, granel, sedeId: sedeA, cantidad: 0);
      expect(cubit.state.estaVacio, isTrue);
    });

    test('setCantidad en cero saca la línea', () {
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(producto(), sedeId: sedeA, cantidad: 5);

      cubit.setCantidad('p1|', 0);

      expect(cubit.state.estaVacio, isTrue);
    });

    test('editar una línea la deja en su lugar, no al final', () {
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(producto(id: 'p1', nombre: 'A'), sedeId: sedeA);
      cubit.agregarProducto(producto(id: 'p2', nombre: 'B'), sedeId: sedeA);

      cubit.setCantidad('p1|', 9);

      expect(cubit.state.lineas.first.productoId, 'p1');
      expect(cubit.state.lineas.first.cantidad, 9);
    });

    test('decrementar algo que no está en el carrito no rompe', () {
      final cubit = CompraCarritoCubit();

      cubit.decrementarProducto('fantasma');
      cubit.setCantidad('fantasma|', 3);

      expect(cubit.state.estaVacio, isTrue);
    });
  });

  group('entrega al formulario', () {
    test('el map lleva las claves que espera la página de compra', () {
      final cubit = CompraCarritoCubit();
      final v = variante('v1', nombre: '5kg', stocks: [
        stock(sedeA, cantidad: 4, precioCosto: 3.05),
      ]);
      final p = producto(
        variantes: [v],
        factorCompra: 50,
        unidadCompraSimbolo: 'SACO',
      );
      cubit.agregarVariante(p, v, sedeId: sedeA, cantidad: 3);

      final item = cubit.aItemsDelFormulario().single;

      expect(item['productoId'], 'p1');
      expect(item['varianteId'], 'v1');
      expect(item['descripcion'], 'ARROZ - 5kg');
      expect(item['cantidad'], 3);
      expect(item['precioUnitario'], 3.05);
      expect(item['descuento'], 0);
      expect(item['unidadCompraSimbolo'], 'SACO');
      // Sin el toggle prendido, la CONVERSIÓN no viaja: el backend
      // multiplicaría por el factor una cantidad que ya está en unidades
      // atómicas. El empaque en sí sí va, como contexto para el editor —
      // la página solo lo manda con `usaUnidadCompra` prendido.
      expect(item.containsKey('usaUnidadCompra'), isFalse);
      expect(item['factorCompra'], 50);
      expect(item.containsKey('nuevoPrecioVenta'), isFalse);
    });

    test('la línea se puede reconstruir desde el map para editarla', () {
      final cubit = CompraCarritoCubit();
      final v = variante('v1', nombre: '5kg', stocks: [
        stock(sedeA, cantidad: 4, precioCosto: 3.05, precio: 4.5),
      ]);
      final p = producto(variantes: [v], factorCompra: 50, unidadCompraSimbolo: 'SACO');
      cubit.agregarVariante(p, v, sedeId: sedeA, cantidad: 2);

      final vuelta =
          LineaCompraDraft.desdeItemMap(cubit.aItemsDelFormulario().single)!;

      expect(vuelta.clave, 'p1|v1');
      expect(vuelta.cantidad, 2);
      expect(vuelta.precioUnitario, 3.05);
      // Lo que hace falta para el costo proyectado y el aviso de bajo costo.
      expect(vuelta.costoActualSede, 3.05);
      expect(vuelta.precioVentaActualSede, 4.5);
      expect(vuelta.stockActualSede, 4);
      expect(vuelta.soportaUnidadCompra, isTrue);
    });

    test('una línea sin costo vuelve del map como SIN COSTO, no como 0', () {
      // En el map viaja 0 para no romper la tabla; adentro tiene que volver a
      // ser "no se sabe" o el editor daría por bueno un precio de cero.
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(producto(), sedeId: sedeA);

      final vuelta =
          LineaCompraDraft.desdeItemMap(cubit.aItemsDelFormulario().single)!;

      expect(vuelta.precioUnitario, isNull);
      expect(vuelta.sinCosto, isTrue);
    });

    test('un ítem personalizado no se puede editar como línea de producto', () {
      // Sin productoId no hay costo ni stock que proyectar.
      expect(
        LineaCompraDraft.desdeItemMap({
          'descripcion': 'FLETE',
          'cantidad': 1,
          'precioUnitario': 30,
        }),
        isNull,
      );
    });

    test('el empaque viaja solo con la unidad de compra prendida', () {
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(
        producto(factorCompra: 50, unidadCompraSimbolo: 'SACO'),
        sedeId: sedeA,
      );
      cubit.actualizarLinea('p1|', usaUnidadCompra: true, factorCompra: 40);

      final item = cubit.aItemsDelFormulario().single;

      expect(item['usaUnidadCompra'], isTrue);
      expect(item['factorCompra'], 40);
    });

    test('una línea sin costo viaja en 0, nunca en null', () {
      // La tabla del formulario lee el precio con `(precio as num)`: un null la
      // tira abajo con un TypeError antes de que se pueda corregir la línea.
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(producto(), sedeId: sedeA);

      final item = cubit.aItemsDelFormulario().single;

      expect(item['precioUnitario'], 0);
      expect(item['precioUnitario'], isNotNull);
    });

    test('conserva el orden en que se eligieron', () {
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(producto(id: 'p1', nombre: 'A'), sedeId: sedeA);
      cubit.agregarProducto(producto(id: 'p2', nombre: 'B'), sedeId: sedeA);
      cubit.agregarProducto(producto(id: 'p3', nombre: 'C'), sedeId: sedeA);

      final items = cubit.aItemsDelFormulario();

      expect(items.map((i) => i['descripcion']), ['A', 'B', 'C']);
    });
  });

  group('totales', () {
    test('el total suma cantidad × precio y resta el descuento', () {
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(
        producto(id: 'p1', stocks: [stock(sedeA, precioCosto: 3.2)]),
        sedeId: sedeA,
        cantidad: 2,
      );
      cubit.agregarProducto(
        producto(id: 'p2', stocks: [stock(sedeA, precioCosto: 8)]),
        sedeId: sedeA,
      );
      cubit.actualizarLinea('p2|', descuento: 1.5);

      expect(cubit.state.total, closeTo(6.4 + 8 - 1.5, 1e-9));
      expect(cubit.state.totalUnidades, 3);
    });

    test('las líneas sin costo no aportan al total', () {
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(producto(), sedeId: sedeA, cantidad: 4);

      expect(cubit.state.total, 0);
      expect(cubit.state.totalUnidades, 4);
    });

    test('limpiar deja el carrito vacío', () {
      final cubit = CompraCarritoCubit();
      cubit.agregarProducto(producto(), sedeId: sedeA);

      cubit.limpiar();

      expect(cubit.state.estaVacio, isTrue);
      expect(cubit.state.total, 0);
      expect(cubit.state.hayLineasSinCosto, isFalse);
    });
  });
}
