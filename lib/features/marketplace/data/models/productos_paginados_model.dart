import '../../domain/entities/productos_paginados.dart';
import 'producto_marketplace_model.dart';

class ProductosPaginadosModel {
  final List<ProductoMarketplaceModel> productos;
  final int total;
  final int page;
  final int totalPages;

  const ProductosPaginadosModel({
    required this.productos,
    required this.total,
    required this.page,
    required this.totalPages,
  });

  factory ProductosPaginadosModel.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List<dynamic>? ?? const [];
    return ProductosPaginadosModel(
      productos: data
          .map((e) => ProductoMarketplaceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int? ?? 0,
      page: json['page'] as int? ?? 1,
      totalPages: json['totalPages'] as int? ?? 1,
    );
  }

  ProductosPaginados toEntity() => ProductosPaginados(
        productos: productos.map((p) => p.toEntity()).toList(),
        total: total,
        page: page,
        totalPages: totalPages,
      );
}
