import 'package:equatable/equatable.dart';
import '../../../domain/entities/venta.dart';

abstract class VentaFormState extends Equatable {
  const VentaFormState();

  @override
  List<Object?> get props => [];
}

class VentaFormInitial extends VentaFormState {
  const VentaFormInitial();
}

class VentaFormLoading extends VentaFormState {
  const VentaFormLoading();
}

class VentaFormSuccess extends VentaFormState {
  final Venta venta;
  final String message;

  const VentaFormSuccess({required this.venta, required this.message});

  @override
  List<Object?> get props => [venta, message];
}

class VentaFormError extends VentaFormState {
  final String message;

  const VentaFormError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Estado emitido cuando el backend rechaza la venta con HTTP 409 porque
/// uno o más productos del carrito tienen un precio desactualizado (el admin
/// cambió el precio mientras el cajero tenía el producto en el carrito).
///
/// El cajero debe refrescar el carrito (recargar productos del catálogo)
/// y reintentar. La página de cobro muestra un dialog con la lista de
/// productos afectados (precio viejo → precio nuevo) para que decida.
class VentaPreciosDesactualizados extends VentaFormState {
  final String message;
  /// Cada item: {descripcion, productoId?, varianteId?, comboId?, cantidad,
  /// precioCliente, precioServer, nivelAplicado?}.
  final List<Map<String, dynamic>> divergencias;

  const VentaPreciosDesactualizados({
    required this.message,
    required this.divergencias,
  });

  @override
  List<Object?> get props => [message, divergencias];
}

/// Estado emitido cuando el backend rechaza la venta con HTTP 400 porque
/// hay líneas con margen negativo (venta bajo costo) que NO están en
/// liquidación y no fueron autorizadas por un gerente/admin.
///
/// La página debe abrir el dialog de autorización (DNI+password) y
/// reintentar la venta con `ventaBajoCostoAutorizadaPorId`.
class VentaBajoCostoNoAutorizada extends VentaFormState {
  final String message;
  final double perdidaTotal;
  /// Cada item: {descripcion, productoId?, varianteId?, cantidad,
  /// precioUnitario, precioCosto, margenUnitario, perdidaLinea}.
  final List<Map<String, dynamic>> lineas;
  /// Data original que se intentó cobrar — para reintentar con autorización.
  final Map<String, dynamic> dataOriginal;
  /// True si se intentó `crearYCobrar` (vs `crearVenta` borrador).
  final bool esCobro;

  const VentaBajoCostoNoAutorizada({
    required this.message,
    required this.perdidaTotal,
    required this.lineas,
    required this.dataOriginal,
    required this.esCobro,
  });

  @override
  List<Object?> get props => [message, perdidaTotal, lineas, esCobro];
}

class VentaConfirmada extends VentaFormState {
  final Venta venta;

  const VentaConfirmada(this.venta);

  @override
  List<Object?> get props => [venta];
}

class VentaPagoRegistrado extends VentaFormState {
  final Venta venta;

  const VentaPagoRegistrado(this.venta);

  @override
  List<Object?> get props => [venta];
}

class VentaAnulada extends VentaFormState {
  final Venta venta;

  const VentaAnulada(this.venta);

  @override
  List<Object?> get props => [venta];
}
