import 'entities/compra.dart';

/// Cómo se vuelve a abrir en el formulario una línea que YA está guardada.
///
/// Vive acá y no en la pantalla para poder testear la vuelta atrás de la
/// conversión: es la misma cuenta que hace el backend al guardar, pero al
/// revés, y equivocarla no rompe nada visible — solo cambia los números.

/// Símbolo de una unidad tal como lo resuelve el backend: el personalizado,
/// si no el local, si no el de la maestra.
String? simboloDeUnidad(Object? unidad) {
  if (unidad is! Map) return null;
  final maestra = unidad['unidadMaestra'];
  final s = (unidad['simboloPersonalizado'] ??
      unidad['simboloLocal'] ??
      (maestra is Map ? maestra['simbolo'] : null)) as String?;
  return (s != null && s.trim().isNotEmpty) ? s.trim() : null;
}

/// Rearma la línea del formulario a partir de una ya guardada.
///
/// 🔴 El backend guarda `cantidad` y `precioUnitario` SIEMPRE en unidad
/// atómica. Cuando la línea se cargó por saco, lo que el usuario escribió
/// vive en `cantidadOriginal` + `factorAplicado`: reabrirla con los números
/// atómicos mostraría "22000 a S/0.006727" donde se había escrito "1 SACO a
/// S/147.99", y bastaría con volver a guardar para que la compra cambiara de
/// forma sola.
Map<String, dynamic> itemDesdeDetalleGuardado(
  CompraDetalle d, {
  required bool precioIncluyeIgv,
}) {
  final factor = d.factorAplicado;
  final porUnidadDeCompra = d.usaUnidadCompra && factor != null && factor > 0;
  final producto = d.producto;
  final variante = d.variante;

  // La presentación se resuelve POR VARIANTE cuando la tiene: un bulto
  // cerrado se compra por unidad aunque su producto se guarde en gramos.
  final fuentePresentacion =
      (variante?['factorPresentacion'] != null) ? variante : producto;
  final factorPresentacion =
      (fuentePresentacion?['factorPresentacion'] as num?)?.toDouble();
  final simboloPresentacion =
      simboloDeUnidad(fuentePresentacion?['unidadPresentacion']);
  final simboloVenta = simboloDeUnidad(
    variante?['unidadMedida'] ?? producto?['unidadMedida'],
  );
  final factorCompra =
      factor ?? (producto?['factorCompra'] as num?)?.toDouble();
  final simboloCompra =
      d.unidadOriginalSimbolo ?? simboloDeUnidad(producto?['unidadCompra']);

  return {
    if (d.productoId != null) 'productoId': d.productoId,
    if (d.varianteId != null) 'varianteId': d.varianteId,
    // 🔴 El vínculo con la OC viaja de vuelta: guardar reemplaza los
    // detalles enteros, y sin él confirmar la compra ya no descuenta lo
    // recibido de la orden.
    if (d.ordenCompraDetalleId != null)
      'ordenCompraDetalleId': d.ordenCompraDetalleId,
    'descripcion': d.descripcion,
    'cantidad': porUnidadDeCompra
        ? (d.cantidadOriginal ?? d.cantidad).round()
        : d.cantidad,
    'precioUnitario':
        porUnidadDeCompra ? _precioPorUnidadDeCompra(d, precioIncluyeIgv) : d.precioUnitario,
    'descuento': d.descuento,
    // Viaja de vuelta o el backend lo recalcula con el 18 por defecto: una
    // línea exonerada cambiaría de impuesto sola al guardar.
    'porcentajeIGV': d.porcentajeIGV,
    if (porUnidadDeCompra) 'usaUnidadCompra': true,
    if (factorCompra != null) 'factorCompra': factorCompra,
    if (simboloCompra != null) 'unidadCompraSimbolo': simboloCompra,
    if (factorPresentacion != null) 'factorPresentacion': factorPresentacion,
    if (simboloPresentacion != null)
      'unidadPresentacionSimbolo': simboloPresentacion,
    if (simboloVenta != null) 'unidadVentaSimbolo': simboloVenta,
    if (d.nuevoPrecioVenta != null) 'nuevoPrecioVenta': d.nuevoPrecioVenta,
  };
}

/// Precio por saco/paquete, reconstruido desde la PLATA de la línea.
///
/// 🔴 No se multiplica el precio atómico por el factor: el backend lo guardó
/// redondeado a 6 decimales, así que un saco de S/147.99 volvería como
/// S/147.994 — visible en el campo, y raro. El bruto de la línea sí es exacto:
/// es `total` cuando el precio lleva el IGV adentro y `subtotal` cuando el IGV
/// va por encima (que es como entran las recepciones desde una OC).
double _precioPorUnidadDeCompra(CompraDetalle d, bool precioIncluyeIgv) {
  final cantidad = d.cantidadOriginal ?? 0;
  if (cantidad <= 0) {
    return double.parse(
        (d.precioUnitario * (d.factorAplicado ?? 1)).toStringAsFixed(6));
  }
  final bruto = precioIncluyeIgv ? d.total : d.subtotal;
  return double.parse(((bruto + d.descuento) / cantidad).toStringAsFixed(6));
}
