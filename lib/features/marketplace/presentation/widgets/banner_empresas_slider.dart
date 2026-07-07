import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/di/injection_container.dart';
import '../../data/datasources/marketplace_remote_datasource.dart';
import '../../data/models/banner_marketplace_model.dart';

/// Slider de banners promocionales de empresas (home del marketplace).
/// 60px de alto, full-width. Solo llegan empresas con la característica
/// BANNER_MARKETPLACE vigente; si la lista está vacía no ocupa espacio.
/// Fondo: color elegido por la empresa + Lottie opcional del catálogo.
/// Tap → página pública de la empresa (/vendedor/:subdominio).
class BannerEmpresasSlider extends StatefulWidget {
  const BannerEmpresasSlider({super.key});

  static const double bannerHeight = 50;

  @override
  State<BannerEmpresasSlider> createState() => _BannerEmpresasSliderState();
}

class _BannerEmpresasSliderState extends State<BannerEmpresasSlider> {
  final _datasource = locator<MarketplaceRemoteDataSource>();
  List<BannerMarketplaceModel> _banners = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final banners = await _datasource.getBanners();
      if (mounted) setState(() => _banners = banners);
    } catch (_) {
      // Silencioso: el slider simplemente no aparece.
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_banners.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: CarouselSlider.builder(
        itemCount: _banners.length,
        options: CarouselOptions(
          height: BannerEmpresasSlider.bannerHeight,
          viewportFraction: 1.0,
          autoPlay: _banners.length > 1,
          autoPlayInterval: const Duration(seconds: 5),
          autoPlayAnimationDuration: const Duration(milliseconds: 600),
          enableInfiniteScroll: _banners.length > 1,
        ),
        itemBuilder: (context, index, _) =>
            BannerMarketplaceCard(banner: _banners[index]),
      ),
    );
  }
}

class BannerMarketplaceCard extends StatelessWidget {
  const BannerMarketplaceCard({super.key, required this.banner});

  final BannerMarketplaceModel banner;

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

    return GestureDetector(
      onTap: banner.subdominio == null
          ? null
          : () => context.push('/vendedor/${banner.subdominio}'),
      child: SizedBox(
        width: double.infinity,
        height: BannerEmpresasSlider.bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: fondo),
            if (banner.lottieUrl != null)
              Lottie.network(
                banner.lottieUrl!,
                fit: BoxFit.cover,
                repeat: true,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (banner.logo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: CachedNetworkImage(
                        imageUrl: banner.logo!,
                        width: 35,
                        height: 35,
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
                            fontSize: 10,
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
                            fontSize: 8,
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

/// Texto de la promo con animación: shimmer (destello que lo recorre) siempre,
/// y si no cabe en el ancho disponible se convierte en marquee (texto rodante)
/// para que se lea completo en vez de cortarse con "…".
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
        )..layout();
        final cabe = painter.width <= constraints.maxWidth;

        final child = cabe
            ? Text(texto, maxLines: 1, overflow: TextOverflow.clip, style: style)
            : _MarqueeTexto(
                texto: texto,
                style: style,
                anchoTexto: painter.width,
                anchoVisible: constraints.maxWidth,
              );

        return _Shimmer(
          color: style.color ?? Colors.white,
          brillo: brillo ?? _Shimmer.brilloDefault,
          child: child,
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
    // Base casi a brillo normal; la intensidad la pone la banda de luz.
    final base = widget.color.withValues(alpha: 0.85);
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
