/// Banner promocional de una empresa en el slider del home del marketplace.
/// Solo llegan banners de empresas con la característica premium vigente.
class BannerMarketplaceModel {
  final String id;
  final String texto;
  final String colorFondo; // hex "#RRGGBB" elegido por la empresa
  final String? lottieUrl; // fondo animado opcional (catálogo de la plataforma)
  final String empresaId;
  final String nombreEmpresa; // nombre comercial (fallback razón social)
  final String? logo;
  final String? subdominio; // para navegar a /vendedor/:subdominio

  const BannerMarketplaceModel({
    required this.id,
    required this.texto,
    required this.colorFondo,
    this.lottieUrl,
    required this.empresaId,
    required this.nombreEmpresa,
    this.logo,
    this.subdominio,
  });

  factory BannerMarketplaceModel.fromJson(Map<String, dynamic> json) {
    return BannerMarketplaceModel(
      id: json['id'] as String? ?? '',
      texto: json['texto'] as String? ?? '',
      colorFondo: json['colorFondo'] as String? ?? '#1565C0',
      lottieUrl: json['lottieUrl'] as String?,
      empresaId: json['empresaId'] as String? ?? '',
      nombreEmpresa: json['nombreEmpresa'] as String? ?? '',
      logo: json['logo'] as String?,
      subdominio: json['subdominio'] as String?,
    );
  }
}
