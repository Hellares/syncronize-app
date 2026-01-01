import 'package:equatable/equatable.dart';

/// Entity que representa la personalización de una empresa
class PersonalizacionEmpresa extends Equatable {
  final String id;
  final String empresaId;
  final Map<String, dynamic>? webConfig;
  final String? bannerPrincipalUrl;
  final String? bannerPrincipalTexto;
  final String bannerColor;
  final String colorPrimario;
  final String colorSecundario;
  final String colorAcento;
  final bool mostrarPrecios;
  final List<String> productosDestacados;
  final List<String> serviciosDestacados;
  final bool mostrarContacto;
  final bool mostrarRedesSociales;
  final bool permitirRegistro;
  final Map<String, dynamic>? appConfig;
  final String? appSplashScreenUrl;
  final String appColorTema;
  final String? dominioPersonalizado;

  const PersonalizacionEmpresa({
    required this.id,
    required this.empresaId,
    this.webConfig,
    this.bannerPrincipalUrl,
    this.bannerPrincipalTexto,
    this.bannerColor = '#000000',
    this.colorPrimario = '#007bff',
    this.colorSecundario = '#6c757d',
    this.colorAcento = '#28a745',
    this.mostrarPrecios = true,
    this.productosDestacados = const [],
    this.serviciosDestacados = const [],
    this.mostrarContacto = true,
    this.mostrarRedesSociales = false,
    this.permitirRegistro = true,
    this.appConfig,
    this.appSplashScreenUrl,
    this.appColorTema = '#007bff',
    this.dominioPersonalizado,
  });

  @override
  List<Object?> get props => [
        id,
        empresaId,
        webConfig,
        bannerPrincipalUrl,
        bannerPrincipalTexto,
        bannerColor,
        colorPrimario,
        colorSecundario,
        colorAcento,
        mostrarPrecios,
        productosDestacados,
        serviciosDestacados,
        mostrarContacto,
        mostrarRedesSociales,
        permitirRegistro,
        appConfig,
        appSplashScreenUrl,
        appColorTema,
        dominioPersonalizado,
      ];

  PersonalizacionEmpresa copyWith({
    String? id,
    String? empresaId,
    Map<String, dynamic>? webConfig,
    String? bannerPrincipalUrl,
    String? bannerPrincipalTexto,
    String? bannerColor,
    String? colorPrimario,
    String? colorSecundario,
    String? colorAcento,
    bool? mostrarPrecios,
    List<String>? productosDestacados,
    List<String>? serviciosDestacados,
    bool? mostrarContacto,
    bool? mostrarRedesSociales,
    bool? permitirRegistro,
    Map<String, dynamic>? appConfig,
    String? appSplashScreenUrl,
    String? appColorTema,
    String? dominioPersonalizado,
  }) {
    return PersonalizacionEmpresa(
      id: id ?? this.id,
      empresaId: empresaId ?? this.empresaId,
      webConfig: webConfig ?? this.webConfig,
      bannerPrincipalUrl: bannerPrincipalUrl ?? this.bannerPrincipalUrl,
      bannerPrincipalTexto: bannerPrincipalTexto ?? this.bannerPrincipalTexto,
      bannerColor: bannerColor ?? this.bannerColor,
      colorPrimario: colorPrimario ?? this.colorPrimario,
      colorSecundario: colorSecundario ?? this.colorSecundario,
      colorAcento: colorAcento ?? this.colorAcento,
      mostrarPrecios: mostrarPrecios ?? this.mostrarPrecios,
      productosDestacados: productosDestacados ?? this.productosDestacados,
      serviciosDestacados: serviciosDestacados ?? this.serviciosDestacados,
      mostrarContacto: mostrarContacto ?? this.mostrarContacto,
      mostrarRedesSociales: mostrarRedesSociales ?? this.mostrarRedesSociales,
      permitirRegistro: permitirRegistro ?? this.permitirRegistro,
      appConfig: appConfig ?? this.appConfig,
      appSplashScreenUrl: appSplashScreenUrl ?? this.appSplashScreenUrl,
      appColorTema: appColorTema ?? this.appColorTema,
      dominioPersonalizado: dominioPersonalizado ?? this.dominioPersonalizado,
    );
  }
}
