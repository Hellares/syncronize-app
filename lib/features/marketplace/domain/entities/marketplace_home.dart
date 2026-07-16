import 'package:equatable/equatable.dart';
import 'categoria_marketplace.dart';
import 'producto_marketplace.dart';

/// Cortina del marketplace: cuando el super admin la activa, tapa toda la
/// sección de productos (home + búsqueda + grid) con un mensaje.
class CortinaMarketplace extends Equatable {
  final bool activa;
  final String? titulo;
  final String? mensaje;

  const CortinaMarketplace({
    this.activa = false,
    this.titulo,
    this.mensaje,
  });

  @override
  List<Object?> get props => [activa, titulo, mensaje];
}

/// Secciones del home del marketplace (estilo MercadoLibre).
class MarketplaceHome extends Equatable {
  final List<ProductoMarketplace> ofertas;
  final List<ProductoMarketplace> masVendidos;
  final List<ProductoMarketplace> masVistos;
  final List<CategoriaMarketplace> categorias;
  final CortinaMarketplace cortina;

  const MarketplaceHome({
    this.ofertas = const [],
    this.masVendidos = const [],
    this.masVistos = const [],
    this.categorias = const [],
    this.cortina = const CortinaMarketplace(),
  });

  @override
  List<Object?> get props =>
      [ofertas, masVendidos, masVistos, categorias, cortina];
}
