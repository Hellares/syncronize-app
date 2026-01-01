import '../../domain/entities/personalizacion_empresa.dart';

class PersonalizacionEmpresaModel extends PersonalizacionEmpresa {
  const PersonalizacionEmpresaModel({
    required super.id,
    required super.empresaId,
    super.webConfig,
    super.bannerPrincipalUrl,
    super.bannerPrincipalTexto,
    super.bannerColor,
    super.colorPrimario,
    super.colorSecundario,
    super.colorAcento,
    super.mostrarPrecios,
    super.productosDestacados,
    super.serviciosDestacados,
    super.mostrarContacto,
    super.mostrarRedesSociales,
    super.permitirRegistro,
    super.appConfig,
    super.appSplashScreenUrl,
    super.appColorTema,
    super.dominioPersonalizado,
  });

  factory PersonalizacionEmpresaModel.fromJson(Map<String, dynamic> json) {
    return PersonalizacionEmpresaModel(
      id: json['id'] as String,
      empresaId: json['empresaId'] as String,
      webConfig: json['webConfig'] as Map<String, dynamic>?,
      bannerPrincipalUrl: json['bannerPrincipalUrl'] as String?,
      bannerPrincipalTexto: json['bannerPrincipalTexto'] as String?,
      bannerColor: json['bannerColor'] as String? ?? '#000000',
      colorPrimario: json['colorPrimario'] as String? ?? '#007bff',
      colorSecundario: json['colorSecundario'] as String? ?? '#6c757d',
      colorAcento: json['colorAcento'] as String? ?? '#28a745',
      mostrarPrecios: json['mostrarPrecios'] as bool? ?? true,
      productosDestacados: (json['productosDestacados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      serviciosDestacados: (json['serviciosDestacados'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      mostrarContacto: json['mostrarContacto'] as bool? ?? true,
      mostrarRedesSociales: json['mostrarRedesSociales'] as bool? ?? false,
      permitirRegistro: json['permitirRegistro'] as bool? ?? true,
      appConfig: json['appConfig'] as Map<String, dynamic>?,
      appSplashScreenUrl: json['appSplashScreenUrl'] as String?,
      appColorTema: json['appColorTema'] as String? ?? '#007bff',
      dominioPersonalizado: json['dominioPersonalizado'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      // No incluir 'id' ni 'empresaId' en actualizaciones - son gestionados por el backend
      if (webConfig != null) 'webConfig': webConfig,
      if (bannerPrincipalUrl != null) 'bannerPrincipalUrl': bannerPrincipalUrl,
      if (bannerPrincipalTexto != null)
        'bannerPrincipalTexto': bannerPrincipalTexto,
      'bannerColor': bannerColor,
      'colorPrimario': colorPrimario,
      'colorSecundario': colorSecundario,
      'colorAcento': colorAcento,
      'mostrarPrecios': mostrarPrecios,
      'productosDestacados': productosDestacados,
      'serviciosDestacados': serviciosDestacados,
      'mostrarContacto': mostrarContacto,
      'mostrarRedesSociales': mostrarRedesSociales,
      'permitirRegistro': permitirRegistro,
      if (appConfig != null) 'appConfig': appConfig,
      if (appSplashScreenUrl != null) 'appSplashScreenUrl': appSplashScreenUrl,
      'appColorTema': appColorTema,
      if (dominioPersonalizado != null)
        'dominioPersonalizado': dominioPersonalizado,
    };
  }

  PersonalizacionEmpresa toEntity() => this;

  factory PersonalizacionEmpresaModel.fromEntity(
      PersonalizacionEmpresa entity) {
    return PersonalizacionEmpresaModel(
      id: entity.id,
      empresaId: entity.empresaId,
      webConfig: entity.webConfig,
      bannerPrincipalUrl: entity.bannerPrincipalUrl,
      bannerPrincipalTexto: entity.bannerPrincipalTexto,
      bannerColor: entity.bannerColor,
      colorPrimario: entity.colorPrimario,
      colorSecundario: entity.colorSecundario,
      colorAcento: entity.colorAcento,
      mostrarPrecios: entity.mostrarPrecios,
      productosDestacados: entity.productosDestacados,
      serviciosDestacados: entity.serviciosDestacados,
      mostrarContacto: entity.mostrarContacto,
      mostrarRedesSociales: entity.mostrarRedesSociales,
      permitirRegistro: entity.permitirRegistro,
      appConfig: entity.appConfig,
      appSplashScreenUrl: entity.appSplashScreenUrl,
      appColorTema: entity.appColorTema,
      dominioPersonalizado: entity.dominioPersonalizado,
    );
  }
}
