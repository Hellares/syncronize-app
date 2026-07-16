import '../../domain/entities/marketplace_home.dart';
import 'categoria_marketplace_model.dart';
import 'producto_marketplace_model.dart';

class MarketplaceHomeModel {
  final List<ProductoMarketplaceModel> ofertas;
  final List<ProductoMarketplaceModel> masVendidos;
  final List<ProductoMarketplaceModel> masVistos;
  final List<CategoriaMarketplaceModel> categorias;
  final CortinaMarketplace cortina;

  const MarketplaceHomeModel({
    this.ofertas = const [],
    this.masVendidos = const [],
    this.masVistos = const [],
    this.categorias = const [],
    this.cortina = const CortinaMarketplace(),
  });

  static List<ProductoMarketplaceModel> _productos(dynamic raw) {
    final list = raw as List<dynamic>? ?? const [];
    return list
        .map((e) => ProductoMarketplaceModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  factory MarketplaceHomeModel.fromJson(Map<String, dynamic> json) {
    final cats = json['categorias'] as List<dynamic>? ?? const [];
    final cortinaJson = json['cortina'] as Map<String, dynamic>?;
    return MarketplaceHomeModel(
      ofertas: _productos(json['ofertas']),
      masVendidos: _productos(json['masVendidos']),
      masVistos: _productos(json['masVistos']),
      categorias: cats
          .map((e) => CategoriaMarketplaceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      cortina: CortinaMarketplace(
        activa: cortinaJson?['activa'] as bool? ?? false,
        titulo: cortinaJson?['titulo'] as String?,
        mensaje: cortinaJson?['mensaje'] as String?,
      ),
    );
  }

  MarketplaceHome toEntity() => MarketplaceHome(
        ofertas: ofertas.map((p) => p.toEntity()).toList(),
        masVendidos: masVendidos.map((p) => p.toEntity()).toList(),
        masVistos: masVistos.map((p) => p.toEntity()).toList(),
        categorias: categorias.map((c) => c.toEntity()).toList(),
        cortina: cortina,
      );
}
