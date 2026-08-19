import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../producto/domain/entities/producto_list_item.dart';
import '../../../../producto/domain/entities/producto_variante.dart';
import '../../../domain/entities/linea_compra_draft.dart';
import 'compra_carrito_state.dart';

/// Carrito de la grilla de selección de productos de una compra.
///
/// No va por `injection_container`: no tiene dependencias y se provee con un
/// `BlocProvider` en la página, para que su vida sea exactamente la de la
/// selección y no quede un carrito colgado entre compras.
class CompraCarritoCubit extends Cubit<CompraCarritoState> {
  CompraCarritoCubit() : super(const CompraCarritoState());

  /// Agrega un producto sin variantes. Tocar dos veces el mismo producto
  /// ACUMULA cantidad en su línea; nunca abre una segunda línea igual.
  void agregarProducto(
    ProductoListItem producto, {
    required String sedeId,
    int cantidad = 1,
  }) {
    if (cantidad <= 0) return;
    _agregar(
      LineaCompraDraft.desdeProducto(
        producto,
        sedeId: sedeId,
        cantidad: cantidad,
      ),
    );
  }

  /// Agrega una variante concreta. Cada variante es su propia línea, aunque
  /// sean del mismo producto.
  void agregarVariante(
    ProductoListItem producto,
    ProductoVariante variante, {
    required String sedeId,
    int cantidad = 1,
  }) {
    if (cantidad <= 0) return;
    _agregar(
      LineaCompraDraft.desdeVariante(
        producto,
        variante,
        sedeId: sedeId,
        cantidad: cantidad,
      ),
    );
  }

  /// Suma la cantidad si la línea ya existe; si no, la agrega al final.
  ///
  /// 🔑 Al acumular se conserva la línea que YA estaba, no la nueva: el usuario
  /// pudo haberle corregido el costo o el empaque en el editor, y volver a
  /// tocar la card no puede pisar esa edición con el costo del catálogo.
  void _agregar(LineaCompraDraft nueva) {
    final existente = state.porClave(nueva.clave);
    if (existente == null) {
      emit(state.copyWith(lineas: [...state.lineas, nueva]));
      return;
    }
    _reemplazar(
      existente.copyWith(cantidad: existente.cantidad + nueva.cantidad),
    );
  }

  /// Deja la variante en exactamente [cantidad] unidades atómicas: la agrega
  /// si no estaba, la saca si es cero.
  ///
  /// Lo usa el sheet de variantes, que se mueve de a UNA unidad de
  /// presentación: para un granel en gramos, un toque son 1000 y no 1 — sumar
  /// de a un gramo no le sirve a nadie.
  void setCantidadVariante(
    ProductoListItem producto,
    ProductoVariante variante, {
    required String sedeId,
    required int cantidad,
  }) {
    final clave = '${producto.id}|${variante.id}';
    if (cantidad <= 0) {
      quitar(clave);
      return;
    }
    if (state.porClave(clave) == null) {
      _agregar(
        LineaCompraDraft.desdeVariante(
          producto,
          variante,
          sedeId: sedeId,
          cantidad: cantidad,
        ),
      );
      return;
    }
    setCantidad(clave, cantidad);
  }

  void decrementarProducto(String productoId) =>
      _decrementar('$productoId|');

  void decrementarVariante(String productoId, String varianteId) =>
      _decrementar('$productoId|$varianteId');

  void _decrementar(String clave) {
    final linea = state.porClave(clave);
    if (linea == null) return;
    if (linea.cantidad <= 1) {
      quitar(clave);
      return;
    }
    _reemplazar(linea.copyWith(cantidad: linea.cantidad - 1));
  }

  /// Fija la cantidad de una línea. En cero (o menos) la línea se va: es lo
  /// mismo que haberla sacado del carrito.
  void setCantidad(String clave, int cantidad) {
    final linea = state.porClave(clave);
    if (linea == null) return;
    if (cantidad <= 0) {
      quitar(clave);
      return;
    }
    _reemplazar(linea.copyWith(cantidad: cantidad));
  }

  /// Edición de una línea desde el editor (el ✎ de la tabla). Solo se tocan
  /// los campos que se pasan.
  void actualizarLinea(
    String clave, {
    int? cantidad,
    double? precioUnitario,
    double? descuento,
    bool? usaUnidadCompra,
    double? factorCompra,
    double? nuevoPrecioVenta,
    bool limpiarNuevoPrecioVenta = false,
  }) {
    final linea = state.porClave(clave);
    if (linea == null) return;
    if (cantidad != null && cantidad <= 0) {
      quitar(clave);
      return;
    }
    _reemplazar(
      linea.copyWith(
        cantidad: cantidad,
        precioUnitario: precioUnitario,
        descuento: descuento,
        usaUnidadCompra: usaUnidadCompra,
        factorCompra: factorCompra,
        nuevoPrecioVenta: nuevoPrecioVenta,
        limpiarNuevoPrecioVenta: limpiarNuevoPrecioVenta,
      ),
    );
  }

  void quitar(String clave) {
    emit(state.copyWith(
      lineas: state.lineas.where((linea) => linea.clave != clave).toList(),
    ));
  }

  void limpiar() => emit(const CompraCarritoState());

  /// Las líneas en el formato que ya consume la página de Nueva Compra, en el
  /// mismo orden en que se eligieron.
  List<Map<String, dynamic>> aItemsDelFormulario() =>
      state.lineas.map((linea) => linea.toItemMap()).toList();

  /// Reemplaza una línea conservando su POSICIÓN. Sacarla y volver a ponerla al
  /// final haría saltar la fila mientras se la edita.
  void _reemplazar(LineaCompraDraft linea) {
    emit(state.copyWith(
      lineas: [
        for (final actual in state.lineas)
          if (actual.clave == linea.clave) linea else actual,
      ],
    ));
  }
}
