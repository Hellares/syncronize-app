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

  static const double bannerHeight = 60;

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

  Color get _fondo {
    final hex = banner.colorFondo.replaceFirst('#', '');
    final value = int.tryParse(hex, radix: 16);
    return value != null ? Color(0xFF000000 | value) : const Color(0xFF1565C0);
  }

  @override
  Widget build(BuildContext context) {
    final fondo = _fondo;
    // Contraste automático: texto blanco sobre fondos oscuros y viceversa.
    final texto = fondo.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;

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
                        width: 40,
                        height: 40,
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
                        Text(
                          banner.texto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
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
                            fontSize: 9,
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
