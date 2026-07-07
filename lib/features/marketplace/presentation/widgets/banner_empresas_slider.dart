import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injection_container.dart';
import '../../data/datasources/marketplace_remote_datasource.dart';
import '../../data/models/banner_marketplace_model.dart';

/// Slider de banners promocionales de empresas (home del marketplace).
/// Va PINNEADO bajo los chips de categorías (siempre visible). Los banners
/// los carga y pasa la página (para incluir el sliver solo si hay alguno).
/// Fondo: color elegido por la empresa + Lottie opcional del catálogo.
/// Tap → página pública de la empresa (/vendedor/:subdominio).
/// Métricas de publicidad: registra IMPRESIÓN la primera vez que cada banner
/// se muestra (carga inicial + rotación) y TAP al tocarlo.
class BannerEmpresasSlider extends StatefulWidget {
  const BannerEmpresasSlider({super.key, required this.banners});

  final List<BannerMarketplaceModel> banners;

  static const double bannerHeight = 50;

  /// Alto del sliver pinneado (banner + respiro vertical).
  static const double sliverHeight = 50;

  @override
  State<BannerEmpresasSlider> createState() => _BannerEmpresasSliderState();
}

class _BannerEmpresasSliderState extends State<BannerEmpresasSlider> {
  final _datasource = locator<MarketplaceRemoteDataSource>();

  /// Ids ya contados como impresión en esta sesión del widget (dedup).
  final Set<String> _impresionados = {};

  @override
  void initState() {
    super.initState();
    if (widget.banners.isNotEmpty) _registrarImpresion(0);
  }

  void _registrarImpresion(int index) {
    if (index < 0 || index >= widget.banners.length) return;
    final banner = widget.banners[index];
    if (_impresionados.add(banner.id)) {
      _datasource.registrarBannerImpresion(banner.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: CarouselSlider.builder(
        itemCount: banners.length,
        options: CarouselOptions(
          height: BannerEmpresasSlider.bannerHeight,
          viewportFraction: 1.0,
          autoPlay: banners.length > 1,
          autoPlayInterval: const Duration(seconds: 5),
          autoPlayAnimationDuration: const Duration(milliseconds: 600),
          enableInfiniteScroll: banners.length > 1,
          onPageChanged: (index, _) => _registrarImpresion(index),
        ),
        itemBuilder: (context, index, _) => BannerMarketplaceCard(
          banner: banners[index],
          onTap: () => _datasource.registrarBannerTap(banners[index].id),
        ),
      ),
    );
  }
}

class BannerMarketplaceCard extends StatelessWidget {
  const BannerMarketplaceCard({super.key, required this.banner, this.onTap});

  final BannerMarketplaceModel banner;

  /// Callback extra al tocar (métricas). El preview no lo pasa.
  final VoidCallback? onTap;

  static Color? parseHex(String? hex) {
    if (hex == null) return null;
    final value = int.tryParse(hex.replaceFirst('#', ''), radix: 16);
    return value != null ? Color(0xFF000000 | value) : null;
  }

  @override
  Widget build(BuildContext context) {
    final fondo = parseHex(banner.colorFondo) ?? const Color(0xFF1565C0);
    // Color de texto elegido por la empresa; si no, contraste automático.
    final texto = parseHex(banner.colorTexto) ??
        (fondo.computeLuminance() > 0.5 ? Colors.black87 : Colors.white);
    final brillo = parseHex(banner.colorBrillo);

    final tieneAccion = banner.subdominio != null ||
        (banner.link != null && banner.link!.isNotEmpty);

    return GestureDetector(
      onTap: !tieneAccion
          ? null
          : () {
              onTap?.call();
              if (banner.subdominio != null) {
                context.push('/vendedor/${banner.subdominio}');
              } else if (banner.link!.startsWith('/')) {
                context.push(banner.link!);
              } else {
                launchUrl(Uri.parse(banner.link!),
                    mode: LaunchMode.externalApplication);
              }
            },
      child: SizedBox(
        width: double.infinity,
        height: BannerEmpresasSlider.bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: fondo),
            if (banner.lottieUrl != null)
              LottieFondoView(
                url: banner.lottieUrl!,
                config: banner.lottieConfig,
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (banner.logo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: CachedNetworkImage(
                        imageUrl: banner.logo!,
                        width: 32,
                        height: 32,
                        fit: BoxFit.cover,
                        memCacheWidth: 120,
                        errorWidget: (_, __, ___) =>
                            Icon(Icons.storefront, size: 28, color: texto),
                      ),
                    )
                  else
                    Icon(Icons.storefront, size: 28, color: texto),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TextoPromoAnimado(
                          texto: banner.texto,
                          brillo: brillo,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            color: texto,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          banner.nombreEmpresa,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w500,
                            color: texto.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      size: 18, color: texto.withValues(alpha: 0.7)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fondo Lottie del catálogo: acepta URL http o ruta de asset local, y tanto
/// .json como .lottie (dotLottie = ZIP con la animación adentro).
/// `config` (viene del catálogo, editable sin APK) controla la presentación:
/// {fit: "cover"|"contain", alignment: "centerLeft"|"center"|"centerRight",
///  widthFactor: 0-1 (fracción del ancho del banner), opacity: 0-1}.
class LottieFondoView extends StatelessWidget {
  const LottieFondoView({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.config,
  });

  final String url;
  final BoxFit fit;
  final Map<String, dynamic>? config;

  /// Decoder para archivos .lottie: abre el ZIP y toma el primer JSON de
  /// `animations/` (formato estándar dotLottie).
  static Future<LottieComposition?> _dotLottie(List<int> bytes) {
    return LottieComposition.decodeZip(bytes, filePicker: (files) {
      for (final f in files) {
        if (f.name.startsWith('animations/') && f.name.endsWith('.json')) {
          return f;
        }
      }
      return null;
    });
  }

  static Alignment _alignment(String? nombre) {
    switch (nombre) {
      case 'topLeft':
        return Alignment.topLeft;
      case 'topRight':
        return Alignment.topRight;
      case 'centerLeft':
        return Alignment.centerLeft;
      case 'centerRight':
        return Alignment.centerRight;
      case 'bottomLeft':
        return Alignment.bottomLeft;
      case 'bottomRight':
        return Alignment.bottomRight;
      default:
        return Alignment.center;
    }
  }

  @override
  Widget build(BuildContext context) {
    final decoder = url.toLowerCase().endsWith('.lottie') ? _dotLottie : null;
    final cfg = config;
    final efFit = cfg?['fit'] == 'contain'
        ? BoxFit.contain
        : (cfg?['fit'] == 'cover' ? BoxFit.cover : fit);
    final alignment = _alignment(cfg?['alignment'] as String?);

    Widget lottie = url.startsWith('http')
        ? Lottie.network(
            url,
            fit: efFit,
            alignment: alignment,
            repeat: true,
            decoder: decoder,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          )
        : Lottie.asset(
            url,
            fit: efFit,
            alignment: alignment,
            repeat: true,
            decoder: decoder,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );

    // Tamaño: fracción del ancho disponible, anclada a `alignment`.
    final widthFactor = (cfg?['widthFactor'] as num?)?.toDouble();
    if (widthFactor != null && widthFactor > 0 && widthFactor < 1) {
      lottie = Align(
        alignment: alignment,
        child: FractionallySizedBox(
          widthFactor: widthFactor,
          heightFactor: 1,
          child: lottie,
        ),
      );
    }

    final opacity = (cfg?['opacity'] as num?)?.toDouble();
    if (opacity != null && opacity >= 0 && opacity < 1) {
      lottie = Opacity(opacity: opacity, child: lottie);
    }

    return lottie;
  }
}

/// Texto de la promo animado: SIEMPRE corre en marquee (tipo letrero LED)
/// con el destello/shimmer encima. La medición usa el textScaler del device
/// para que el bucle sea continuo sin cortes.
class _TextoPromoAnimado extends StatelessWidget {
  const _TextoPromoAnimado({
    required this.texto,
    required this.style,
    this.brillo,
  });

  final String texto;
  final TextStyle style;
  final Color? brillo; // color de la luz elegido por la empresa

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: texto, style: style),
          maxLines: 1,
          textDirection: TextDirection.ltr,
          textScaler: MediaQuery.textScalerOf(context),
        )..layout();

        return _Shimmer(
          color: style.color ?? Colors.white,
          brillo: brillo ?? _Shimmer.brilloDefault,
          child: _MarqueeTexto(
            texto: texto,
            style: style,
            anchoTexto: painter.width,
            anchoVisible: constraints.maxWidth,
          ),
        );
      },
    );
  }
}

/// Destello periódico que recorre el texto (banda brillante cada ~3.5s).
class _Shimmer extends StatefulWidget {
  const _Shimmer({
    required this.color,
    required this.brillo,
    required this.child,
  });

  /// Color de la LUZ por defecto si la empresa no eligió uno.
  static const Color brilloDefault = Color(0xFF69F0AE); // verde (greenAccent)

  final Color color;
  final Color brillo;
  final Widget child;

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 3500),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<double> _stops(double t, double ancho) => [
        (t - ancho).clamp(0.0, 1.0),
        t.clamp(0.0, 1.0),
        (t + ancho).clamp(0.0, 1.0),
      ];

  @override
  Widget build(BuildContext context) {
    // Texto SIN opacidad (color pleno); el efecto lo pone solo la banda de luz.
    final base = widget.color;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 1.6 - 0.3; // -0.3 → 1.3
        return Stack(
          clipBehavior: Clip.none,
          children: [
            // Texto con la banda brillante recorriéndolo.
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback: (bounds) => LinearGradient(
                colors: [base, widget.brillo, base],
                stops: _stops(t, 0.18),
              ).createShader(bounds),
              child: widget.child,
            ),
            // Resplandor: copia blanca desenfocada del texto, visible SOLO
            // bajo la banda → halo de luz que acompaña al destello.
            Positioned.fill(
              child: IgnorePointer(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (bounds) => LinearGradient(
                    colors: [
                      Colors.transparent,
                      widget.brillo.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                    stops: _stops(t, 0.14),
                  ).createShader(bounds),
                  child: ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 2.5, sigmaY: 2.5),
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [widget.brillo, widget.brillo],
                      ).createShader(bounds),
                      child: widget.child,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Marquee: el texto desfila en bucle continuo (velocidad constante ~30 px/s).
class _MarqueeTexto extends StatefulWidget {
  const _MarqueeTexto({
    required this.texto,
    required this.style,
    required this.anchoTexto,
    required this.anchoVisible,
  });

  final String texto;
  final TextStyle style;
  final double anchoTexto;
  final double anchoVisible;

  @override
  State<_MarqueeTexto> createState() => _MarqueeTextoState();
}

class _MarqueeTextoState extends State<_MarqueeTexto>
    with SingleTickerProviderStateMixin {
  static const double _separacion = 48;
  late final AnimationController _controller;

  double get _recorrido => widget.anchoTexto + _separacion;

  @override
  void initState() {
    super.initState();
    // Duración proporcional al largo para mantener velocidad constante.
    final segundos = (_recorrido / 30).clamp(6, 40).toDouble();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (segundos * 1000).round()),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textoWidget =
        Text(widget.texto, maxLines: 1, softWrap: false, style: widget.style);
    return SizedBox(
      width: widget.anchoVisible,
      height: (widget.style.fontSize ?? 12) * 1.4,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => Transform.translate(
            offset: Offset(-_controller.value * _recorrido, 0),
            child: child,
          ),
          child: OverflowBox(
            alignment: Alignment.centerLeft,
            maxWidth: double.infinity,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                textoWidget,
                const SizedBox(width: _separacion),
                textoWidget,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
