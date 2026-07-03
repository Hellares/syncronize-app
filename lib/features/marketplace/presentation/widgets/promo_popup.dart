import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Publicidad/promoción que se muestra en un popup al entrar al marketplace.
///
/// Pensada para ser **configurable por empresa** (targeting): cada promo apunta
/// a una empresa (`empresaId`) y lleva a una ruta (`targetRoute`, p. ej. el
/// perfil público de la tienda o una categoría). Hoy los datos salen de un
/// PLACEHOLDER local ([_promosPlaceholder]); cuando exista el endpoint de
/// backend (`/marketplace/promociones`) solo se cambia [obtenerPromoActiva].
class PromoMarketplace {
  final String id;
  final String? empresaId;
  final String? empresaNombre;
  final String titulo;
  final String subtitulo;

  /// Imagen remota de la promo (si viene del backend). Si es null, se usa
  /// [lottieAsset] como visual.
  final String? imagenUrl;

  /// Animación Lottie local (placeholder / fondo transparente).
  final String? lottieAsset;

  final String ctaTexto;

  /// Ruta a la que navega el CTA (null = solo cierra).
  final String? targetRoute;

  /// Colores del degradé del encabezado.
  final List<Color> gradiente;

  const PromoMarketplace({
    required this.id,
    this.empresaId,
    this.empresaNombre,
    required this.titulo,
    required this.subtitulo,
    this.imagenUrl,
    this.lottieAsset,
    this.ctaTexto = 'Ver más',
    this.targetRoute,
    this.gradiente = const [AppColors.blue1, AppColors.blue2],
  });
}

/// Promos PLACEHOLDER (mock). Reemplazar por la respuesta del backend.
const List<PromoMarketplace> _promosPlaceholder = [
  PromoMarketplace(
    id: 'promo-demo-1',
    empresaId: null,
    empresaNombre: 'Tienda Demo',
    titulo: '¡Ofertas de la semana!',
    subtitulo: 'Descubre productos seleccionados con hasta 50% de descuento.',
    lottieAsset: 'assets/animations/logo1.json',
    ctaTexto: 'Ver ofertas',
    targetRoute: null, // TODO: apuntar a categoría/tienda cuando haya backend
    gradiente: [AppColors.blue1, AppColors.blue2],
  ),
];

/// Controla y muestra el popup de publicidad del marketplace.
class PromoPopup {
  PromoPopup._();

  // Claves de persistencia (frecuencia por día).
  static const _kFecha = 'promo_popup_fecha';
  static const _kConteo = 'promo_popup_conteo';

  /// Cuántas veces por día, como MÁXIMO, se le muestra al usuario. Configurable
  /// (el user pidió "una o dos veces por día").
  static const int maxPorDia = 2;

  static String _hoy() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  /// Obtiene la promo activa a mostrar. HOY = placeholder; MAÑANA = pegarle al
  /// endpoint `/marketplace/promociones` (filtrado por vigencia + empresas
  /// configuradas). Devuelve null si no hay ninguna.
  static Future<PromoMarketplace?> obtenerPromoActiva() async {
    if (_promosPlaceholder.isEmpty) return null;
    return _promosPlaceholder.first;
  }

  /// True si aún no se alcanzó el tope diario.
  static bool _puedeMostrar() {
    final storage = locator<LocalStorageService>();
    final fecha = storage.getString(_kFecha);
    final conteo = fecha == _hoy() ? (storage.getInt(_kConteo) ?? 0) : 0;
    return conteo < maxPorDia;
  }

  static Future<void> _registrarMostrada() async {
    final storage = locator<LocalStorageService>();
    final esHoy = storage.getString(_kFecha) == _hoy();
    final nuevo = esHoy ? (storage.getInt(_kConteo) ?? 0) + 1 : 1;
    await storage.setString(_kFecha, _hoy());
    await storage.setInt(_kConteo, nuevo);
  }

  /// Muestra el popup si corresponde (hay promo activa y no se superó el tope
  /// diario). Llamar ~3s después de entrar al marketplace.
  static Future<void> mostrarSiCorresponde(BuildContext context) async {
    if (!_puedeMostrar()) return;
    final promo = await obtenerPromoActiva();
    if (promo == null || !context.mounted) return;

    await _registrarMostrada();
    if (!context.mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: promo.titulo,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 340),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (ctx, anim, __, ___) {
        final curved = CurvedAnimation(
          parent: anim,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );
        return Opacity(
          opacity: anim.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + 0.15 * curved.value,
            child: _PromoDialog(promo: promo),
          ),
        );
      },
    );
  }
}

class _PromoDialog extends StatelessWidget {
  final PromoMarketplace promo;
  const _PromoDialog({required this.promo});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Material(
          color: Colors.transparent,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Encabezado visual (degradé + Lottie/imagen).
                    Container(
                      height: 170,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: promo.gradiente,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: promo.imagenUrl != null
                                ? Image.network(promo.imagenUrl!, fit: BoxFit.contain)
                                : (promo.lottieAsset != null
                                    ? Lottie.asset(promo.lottieAsset!, height: 110)
                                    : const Icon(Icons.local_offer_rounded,
                                        size: 64, color: Colors.white)),
                          ),
                          // Etiqueta "Publicidad".
                          Positioned(
                            top: 10,
                            left: 10,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'PUBLICIDAD',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Texto + CTA.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            promo.titulo,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            promo.subtitulo,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                              if (promo.targetRoute != null) {
                                context.push(promo.targetRoute!);
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.blue2,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              promo.ctaTexto,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (promo.empresaNombre != null) ...[
                            const SizedBox(height: 10),
                            Text(
                              'Auspiciado por ${promo.empresaNombre}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Botón cerrar (X) flotante arriba-derecha.
              Positioned(
                top: -12,
                right: -12,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded, size: 20, color: Colors.black54),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
