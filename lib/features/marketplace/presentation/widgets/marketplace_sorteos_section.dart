

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class MarketplaceSorteosSection extends StatefulWidget {
  const MarketplaceSorteosSection({super.key});

  @override
  State<MarketplaceSorteosSection> createState() =>
      _MarketplaceSorteosSectionState();
}

class _MarketplaceSorteosSectionState extends State<MarketplaceSorteosSection> {
  final CarouselSliderController _controller = CarouselSliderController();
  int _currentIndex = 0;

  // ✅ URLs de imágenes (ejemplo). Cámbialas por las tuyas.
  // final List<String> _imageUrls = const [
  //   "https://res.cloudinary.com/doglf2gsy/image/upload/v1766635515/sdfsdfsdf_oczkcp.png",
  //   "https://res.cloudinary.com/doglf2gsy/image/upload/v1766635628/sdfsdfsdfs_pzjo3y.png",
  //   "https://res.cloudinary.com/doglf2gsy/image/upload/v1766635515/sdfsdfsdf_oczkcp.png",
  //   "https://res.cloudinary.com/doglf2gsy/image/upload/v1766635628/sdfsdfsdfs_pzjo3y.png",
  // ];

  final List<String> _imageUrls = const [
    "https://www.shutterstock.com/image-vector/discount-sticker-template-100-200-260nw-2231676771.jpg",
    "https://www.shutterstock.com/image-vector/1000-dollars-bonus-falling-golden-260nw-2436187179.jpg",
    "https://www.fortunegames.com/images/local/promotions/iconuk2k.jpg",
    "https://img.freepik.com/foto-gratis/fondo-dia-san-patricio-ilustracion-3d-ilusteracion-3d_1419-3165.jpg?semt=ais_incoming&w=740&q=80",
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_imageUrls.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          "No hay sorteos disponibles por ahora.",
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // (Opcional) Título
        SizedBox(height: 5,),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            "Sorteos",
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.black,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 12),

        CarouselSlider.builder(
          carouselController: _controller,
          itemCount: _imageUrls.length,
          itemBuilder: (context, index, realIndex) {
            final url = _imageUrls[index];

            return _SorteoBannerCard(
              imageUrl: url,
              title: "Sorteo #${index + 1}",
              subtitle: "Participa y gana premios increíbles",
              ctaText: "Ver sorteo",
              onTap: () {
                // TODO: navega a detalle del sorteo
                // Navigator.push(...);
              },
            );
          },
          options: CarouselOptions(
            height: 150,
            autoPlay: true,
            autoPlayInterval: const Duration(seconds: 4),
            autoPlayAnimationDuration: const Duration(milliseconds: 700),
            enlargeCenterPage: true,
            viewportFraction: 0.80,
            enableInfiniteScroll: _imageUrls.length > 1,
            onPageChanged: (index, reason) {
              setState(() => _currentIndex = index);
            },
          ),
        ),

        const SizedBox(height: 12),

        Center(
          child: AnimatedSmoothIndicator(
            activeIndex: _currentIndex,
            count: _imageUrls.length,
            effect: ExpandingDotsEffect(
              dotHeight: 8,
              dotWidth: 8,
              spacing: 6,
              dotColor: Colors.grey.shade300,
              activeDotColor: theme.colorScheme.primary,
            ),
            onDotClicked: (index) => _controller.animateToPage(index),
          ),
        ),
      ],
    );
  }
}

class _SorteoBannerCard extends StatelessWidget {
  final String imageUrl;
  final String title;
  final String subtitle;
  final String ctaText;
  final VoidCallback? onTap;

  const _SorteoBannerCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.ctaText,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagen
              Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
                errorBuilder: (context, error, stack) {
                  return Container(
                    color: Colors.grey.shade200,
                    alignment: Alignment.center,
                    child: const Icon(Icons.broken_image_outlined, size: 32),
                  );
                },
              ),

              // // Gradiente para legibilidad del texto
              // const DecoratedBox(
              //   decoration: BoxDecoration(
              //     gradient: LinearGradient(
              //       begin: Alignment.bottomCenter,
              //       end: Alignment.center,
              //       colors: [
              //         Color(0xCC000000),
              //         Color(0x00000000),
              //       ],
              //     ),
              //   ),
              // ),

              // Texto + CTA
              Positioned(
                left: 14,
                right: 14,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          ctaText,
                          style: theme.textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Colors.black
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
