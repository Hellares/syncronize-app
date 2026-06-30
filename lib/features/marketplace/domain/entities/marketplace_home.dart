import 'package:equatable/equatable.dart';
import 'categoria_marketplace.dart';
import 'producto_marketplace.dart';

/// Secciones del home del marketplace (estilo MercadoLibre).
class MarketplaceHome extends Equatable {
  final List<ProductoMarketplace> ofertas;
  final List<ProductoMarketplace> masVendidos;
  final List<ProductoMarketplace> masVistos;
  final List<CategoriaMarketplace> categorias;

  const MarketplaceHome({
    this.ofertas = const [],
    this.masVendidos = const [],
    this.masVistos = const [],
    this.categorias = const [],
  });

  @override
  List<Object?> get props => [ofertas, masVendidos, masVistos, categorias];
}
