import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection_container.dart';
import '../../../producto/domain/entities/precio_nivel.dart';
import '../../../producto/domain/entities/producto_filtros.dart';
import '../../../producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import '../../../producto/presentation/widgets/producto_selector/producto_selector_view.dart';
import '../../../venta/domain/entities/venta_detalle_input.dart';
import '../bloc/compra_carrito/compra_carrito_cubit.dart';
import '../bloc/compra_carrito/compra_carrito_state.dart';
import '../widgets/compra_variantes_sheet.dart';
import '../widgets/quick_create_producto_dialog.dart';

/// Grilla para elegir varios productos de una compra de una sola pasada, con
/// la misma cara que Venta Rápida: buscador con escáner, filtros por atributo
/// y cards con stepper.
///
/// Devuelve al hacer pop la lista de ítems en el formato que ya consume la
/// página de Nueva Compra, o `null` si se salió sin elegir nada.
class CompraProductosPage extends StatelessWidget {
  final String empresaId;
  final String sedeId;

  /// Carrito de quien llama. Sirve para reabrir la grilla con lo que ya se
  /// había elegido; sin esto, salir y volver a entrar empieza de cero.
  final CompraCarritoCubit? carrito;

  const CompraProductosPage({
    super.key,
    required this.empresaId,
    required this.sedeId,
    this.carrito,
  });

  /// Filtros del catálogo para COMPRAR, que no son los de vender:
  ///
  /// - `mostrarTodos`: una recepción es la forma en que un producto ENTRA por
  ///   primera vez a una sede. Sin esto no aparecen los que todavía no viven
  ///   acá y se terminan creando duplicados.
  /// - `esInsumo` sin setear (todos): los insumos se compran.
  /// - `soloProductos`: un combo no se le compra a nadie, se arma.
  /// - `isActive`: un producto dado de baja no se repone.
  static const filtros = ProductoFiltros(
    isActive: true,
    mostrarTodos: true,
    soloProductos: true,
  );

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        if (carrito != null)
          BlocProvider.value(value: carrito!)
        else
          BlocProvider(create: (_) => CompraCarritoCubit()),
        BlocProvider(
          create: (_) => locator<ProductoListCubit>()
            ..loadProductos(
              empresaId: empresaId,
              sedeId: sedeId,
              filtros: filtros,
            ),
        ),
      ],
      child: _CompraProductosView(empresaId: empresaId, sedeId: sedeId),
    );
  }
}

class _CompraProductosView extends StatelessWidget {
  final String empresaId;
  final String sedeId;

  const _CompraProductosView({required this.empresaId, required this.sedeId});

  /// Crear un producto que no existe todavía, sin perder la compra a medio
  /// armar. Queda agregado al carrito, que es a lo que se venía.
  Future<void> _crearProducto(BuildContext context) async {
    final carrito = context.read<CompraCarritoCubit>();
    final listCubit = context.read<ProductoListCubit>();

    final res = await showQuickCreateProductoDialog(
      context,
      empresaId: empresaId,
      sedeId: sedeId,
    );
    if (res == null || !context.mounted) return;

    carrito.agregarProducto(res.producto, sedeId: sedeId);
    listCubit.reload();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${res.producto.nombre} creado y agregado'),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final carrito = context.read<CompraCarritoCubit>();

    return ProductoSelectorView<CompraCarritoCubit, CompraCarritoState>(
      sedeId: sedeId,
      modoCompra: true,
      filtrosBase: CompraProductosPage.filtros,
      // La grilla dibuja steppers y total a partir de este shape. El costo va
      // como `precioUnitario`, e `precioIncluyeIgv: true` porque el total del
      // AppBar suma `total` de cada línea: en false le sumaría 18% de IGV a la
      // compra, que acá no se decide (se decide en el formulario).
      snapshotBuilder: (state) => (
        items: [
          for (final linea in state.lineas)
            VentaDetalleInput(
              productoId: linea.productoId,
              varianteId: linea.varianteId,
              descripcion: linea.descripcion,
              cantidad: linea.cantidad.toDouble(),
              precioUnitario: linea.precioUnitario ?? 0,
              precioIncluyeIgv: true,
              factorPresentacion: linea.factorPresentacion,
              unidadPresentacionSimbolo: linea.unidadPresentacionSimbolo,
            ),
        ],
        comboPendienteOferta: null,
      ),
      tituloBuilder: (state) =>
          state.estaVacio ? 'Elegir productos' : 'Compra (${state.totalLineas})',
      // El ícono del carrito confirma y vuelve con las líneas. La vista ya lo
      // deshabilita solo cuando no hay nada elegido.
      onIrAlCarrito: () async =>
          Navigator.of(context).pop(carrito.aItemsDelFormulario()),
      onAgregarProducto: (producto) =>
          carrito.agregarProducto(producto, sedeId: sedeId),
      // Lo usa el escaneo cuando el código es el de una variante concreta; el
      // toque en la card pasa por `onAbrirVariantes`.
      onAgregarVariante: (producto, variante, [cantidad = 1]) =>
          carrito.agregarVariante(
        producto,
        variante,
        sedeId: sedeId,
        cantidad: cantidad,
      ),
      onDecrementarVariante: (producto, variante) =>
          carrito.decrementarVariante(producto.id, variante.id),
      onDecrementarProducto: carrito.decrementarProducto,
      onAbrirVariantes: (producto) => showCompraVariantesSheet(
        context: context,
        producto: producto,
        sedeId: sedeId,
        cantidades: {
          for (final linea in carrito.state.lineas)
            if (linea.productoId == producto.id && linea.varianteId != null)
              linea.varianteId!: linea.cantidad,
        },
        // El sheet manda la cantidad ABSOLUTA en unidades atómicas: se mueve
        // de a una unidad de presentación (1 kg = 1000 g), no de a una.
        onCantidad: (variante, cantidad) => carrito.setCantidadVariante(
          producto,
          variante,
          sedeId: sedeId,
          cantidad: cantidad,
        ),
        // El costo se carga en el mismo sheet: abrir el editor variante por
        // variante para escribir un número era el paso más tedioso de una
        // compra de 20 líneas.
        costos: {
          for (final linea in carrito.state.lineas)
            if (linea.productoId == producto.id &&
                linea.varianteId != null &&
                linea.precioCarga > 0)
              linea.varianteId!: linea.precioCarga,
        },
        onCosto: (variante, costo) =>
            carrito.setCostoVariante(producto.id, variante.id, costo),
      ),
      // Los niveles son precios de VENTA: en modo compra la vista ni siquiera
      // ofrece el sheet que los usa.
      onCargarNiveles: (_) async => const <PrecioNivel>[],
      // Un combo no se compra (`soloProductos`), así que no hay nada que
      // confirmar.
      onAceptarComboOferta: (_) {},
      atajoIcono: Icons.add_box_outlined,
      atajoTooltip: 'Crear producto nuevo',
      onAtajo: () => _crearProducto(context),
    );
  }
}
