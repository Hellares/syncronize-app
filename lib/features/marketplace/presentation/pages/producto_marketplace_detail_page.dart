import 'dart:ui' show ImageFilter;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../data/datasources/marketplace_remote_datasource.dart';
import '../widgets/favorito_button.dart';
import '../widgets/preguntas_producto_section.dart';
import '../widgets/opiniones_producto_section.dart';
import '../widgets/draggable_video_overlay.dart';
import '../widgets/oferta_countdown_banner.dart';
import '../widgets/variante_selector.dart';
import '../../../../core/widgets/floating_button_text.dart';
import '../../../../core/widgets/custom_button.dart';

class ProductoMarketplaceDetailPage extends StatefulWidget {
  final String productoId;

  const ProductoMarketplaceDetailPage({super.key, required this.productoId});

  @override
  State<ProductoMarketplaceDetailPage> createState() => _ProductoMarketplaceDetailPageState();
}

class _ProductoMarketplaceDetailPageState extends State<ProductoMarketplaceDetailPage> {
  final _dataSource = locator<MarketplaceRemoteDataSource>();
  Map<String, dynamic>? _producto;
  bool _isLoading = true;
  String? _error;
  int _currentImageIndex = 0;
  bool _videoDismissed = false;
  final _pageController = PageController();

  /// Variante elegida en el selector (null = ninguna aún, o producto sin variantes).
  Map<String, dynamic>? _selectedVariante;

  /// Cantidad a agregar al carrito (1..stock disponible).
  int _cantidad = 1;

  // ── Estilo compartido (Temu-like sobre la marca azul) ──────────────────────
  static const Color _star = Color(0xFFFFB300);

  /// Sección blanca full-width separada por 2px del resto (el gris del fondo se
  /// ve como una línea fina entre secciones, estilo Temu/Mercado Libre).
  Widget _card({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
  }) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: padding,
      margin: const EdgeInsets.only(bottom: 2),
      child: child,
    );
  }

  /// Igual que [_card] pero para widgets que ya traen su propio fondo/padding
  /// (las secciones de Opiniones y Preguntas).
  Widget _cardWrap(Widget child) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 2),
      child: child,
    );
  }

  @override
  void initState() {
    super.initState();
    _loadProducto();
    _registrarVisto();
  }

  void _registrarVisto() {
    Future(() async {
      try {
        final storage = locator<LocalStorageService>();
        final token = storage.getString(StorageConstants.accessToken);
        if (token == null || token.isEmpty) return;
        locator<DioClient>().post(
          '${ApiConstants.marketplaceUsuario}/vistos/${widget.productoId}',
        );
      } catch (_) {}
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadProducto() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await _dataSource.getProductoDetalle(widget.productoId);
      if (mounted) setState(() { _producto = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final showActions = _producto != null && !_isLoading && _error == null;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      // El cuerpo va detrás del AppBar para que la imagen ocupe el tope de la
      // pantalla y los íconos floten encima (estilo Temu).
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleSpacing: 0,
        automaticallyImplyLeading: false,
        leadingWidth: 52,
        leading: _circleBtn(
          icon: Icons.arrow_back_ios_new,
          tooltip: 'Volver',
          onTap: () {
            if (context.canPop()) context.pop();
          },
        ),
        actions: [
          if (showActions) ...[
            _circleWrap(
              FavoritoButton(
                productoId: widget.productoId,
                size: 19,
                inactiveColor: Colors.white,
              ),
            ),
            _circleBtn(
              icon: Icons.shopping_cart_outlined,
              tooltip: 'Mi carrito',
              onTap: () => context.push('/carrito'),
            ),
            const SizedBox(width: 6),
          ],
        ],
      ),
      body: _isLoading
          ? CustomLoading.small(message: 'Cargando...')
          : _error != null
              ? _buildError()
              : _buildContentWithVideo(),
      bottomNavigationBar: _producto != null && !_isLoading ? _buildBottomBar() : null,
    );
  }

  /// Botón circular oscuro semitransparente con ícono blanco, flotando sobre la
  /// imagen (estilo Temu: no se ve la barra del AppBar, solo estos íconos).
  Widget _circleBtn({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
        ),
        child: IconButton(
          onPressed: onTap,
          tooltip: tooltip,
          iconSize: 18,
          color: Colors.white,
          padding: EdgeInsets.zero,
          visualDensity: VisualDensity.compact,
          constraints: const BoxConstraints.tightFor(width: 36, height: 36),
          icon: Icon(icon),
        ),
      ),
    );
  }

  /// Igual que [_circleBtn] pero envolviendo un widget arbitrario (el corazón de
  /// favoritos) en el mismo círculo oscuro.
  Widget _circleWrap(Widget child) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
        ),
        child: Center(child: child),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text('No se pudo cargar el producto'),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: _loadProducto,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  /// Contenido del producto con el mini-reproductor de video flotante (si el
  /// producto tiene `videoUrl` y el usuario no lo descartó). El arrastre vive
  /// en [DraggableVideoOverlay] para no reconstruir toda la página al mover el
  /// PiP (de ahí que el arrastre sea fluido).
  Widget _buildContentWithVideo() {
    final videoUrl = (_producto?['videoUrl'] as String?)?.trim();
    final mostrarVideo =
        videoUrl != null && videoUrl.isNotEmpty && !_videoDismissed;

    if (!mostrarVideo) return _buildContent();

    final posterUrl = (_producto?['videoThumbnailUrl'] as String?)?.trim();

    return Stack(
      children: [
        _buildContent(),
        Positioned.fill(
          child: DraggableVideoOverlay(
            videoUrl: videoUrl,
            posterUrl: posterUrl,
            onClose: () => setState(() => _videoDismissed = true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent() {
    final p = _producto!;
    final nombre = p['nombre'] as String? ?? '';
    final descripcion = p['descripcion'] as String?;
    // Variantes: si el producto tiene y hay una elegida, precio/stock/oferta
    // salen de ELLA; si no, del "desde" del producto.
    final tieneVariantes = p['tieneVariantes'] as bool? ?? false;
    final variantes = (p['variantes'] as List<dynamic>?) ?? [];
    final vSel = _selectedVariante;

    final precio = (vSel != null ? vSel['precio'] : p['precio']) as num?;
    final precioOferta = (vSel != null ? vSel['precioOferta'] : p['precioOferta']) as num?;
    final enOferta = (vSel != null ? vSel['enOferta'] : p['enOferta']) as bool? ?? false;
    final ofertaFinStr = (vSel != null ? vSel['ofertaFin'] : p['ofertaFin']) as String?;
    final ofertaFin = ofertaFinStr != null ? DateTime.tryParse(ofertaFinStr) : null;
    final ofertaSede = (vSel != null ? vSel['ofertaSede'] : p['ofertaSede']) as String?;
    final sedeMap = p['sede'] as Map<String, dynamic>?;
    final ofertaSedeDir = (vSel != null || sedeMap == null)
        ? null
        : [sedeMap['direccion'], sedeMap['distrito'], sedeMap['provincia']]
            .where((e) => e != null && e.toString().trim().isNotEmpty)
            .join(', ');
    final hayStock = (vSel != null ? vSel['hayStock'] : p['hayStock']) as bool? ?? false;
    final stockActual = (vSel != null ? vSel['stockActual'] : p['stockActual']) as int? ?? 0;
    final categoria = p['categoria'] as String?;
    final marca = p['marca'] as String?;
    final calificacion = p['calificacion'] as num?;
    final totalOpiniones = p['totalOpiniones'] as int? ?? 0;
    final vendidos = p['vendidos'] as int? ?? 0;
    // Imágenes efectivas: si hay variante elegida con imágenes → las de ella; si
    // no → las del base; si el base no tiene → la 1ª variante que tenga imágenes
    // (en productos con variantes las imágenes suelen vivir en las variantes).
    List<dynamic> imagenes = (vSel?['imagenes'] as List<dynamic>?) ?? [];
    if (imagenes.isEmpty) imagenes = (p['imagenes'] as List<dynamic>?) ?? [];
    if (imagenes.isEmpty) {
      for (final v in variantes) {
        final vi = (v['imagenes'] as List<dynamic>?) ?? [];
        if (vi.isNotEmpty) { imagenes = vi; break; }
      }
    }
    final atributos = (p['atributos'] as List<dynamic>?) ?? [];
    final empresa = p['empresa'] as Map<String, dynamic>? ?? {};

    final precioFinal = enOferta && precioOferta != null ? precioOferta : precio;
    final tieneDescuento = enOferta && precioOferta != null && precio != null;
    final descuentoPct = tieneDescuento && precio > 0
        ? ((1 - precioOferta / precio) * 100).round()
        : 0;

    return RefreshIndicator(
      onRefresh: _loadProducto,
      color: AppColors.blue2,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galería full-bleed (estilo Temu)
            _buildImageGallery(imagenes),

            // ── Tarjeta principal (full-width, estilo Temu) ────────────────
            Container(
              width: double.infinity,
              color: Colors.white,
              margin: const EdgeInsets.only(bottom: 2),
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Condición y categoría
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (hayStock ? AppColors.blue2 : AppColors.red)
                              .withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          hayStock ? 'Nuevo' : 'Sin stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: hayStock ? AppColors.blue2 : AppColors.red,
                          ),
                        ),
                      ),
                      if (categoria != null) ...[
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            categoria,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ),
                      ],
                      if (stockActual > 0 && stockActual <= 5) ...[
                        const Spacer(),
                        Text(
                          '¡Últimas $stockActual!',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: Colors.orange.shade800,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nombre del producto (jerarquía más fuerte)
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: AppColors.blue1,
                    ),
                  ),

                  // Rating + vendidos (prueba social honesta)
                  _buildRatingRow(calificacion, totalOpiniones, vendidos),

                  const SizedBox(height: 8),

                  // Precio (protagonista)
                  if (precioFinal != null) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Precio + tachado (izquierda)
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Flexible(
                                child: Text(
                                  '${tieneVariantes && vSel == null ? 'Desde ' : ''}S/ ${precioFinal.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w400,
                                    fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                                    color: AppColors.blue1,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                              ),
                              if (tieneDescuento) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'S/ ${precio.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade400,
                                    decoration: TextDecoration.lineThrough,
                                    decorationColor: Colors.grey.shade400,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        // Chip de descuento, pegado a la derecha
                        if (tieneDescuento) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.greenContainer,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$descuentoPct% OFF · Ahorras S/ ${(precio - precioOferta).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.greendark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ] else
                    AppTitle('Consultar precio', fontSize: 15, color: AppColors.blue2),

                  // Trust badges (señales reales)
                  const SizedBox(height: 12),
                  _buildTrustBadges(hayStock, stockActual),
                ],
              ),
            ),

            // ── Selector de variantes (si el producto tiene) ───────────────
            if (tieneVariantes && variantes.isNotEmpty)
              _card(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
                child: VarianteSelector(
                  variantes: variantes,
                  onChanged: (v) {
                    setState(() {
                      _selectedVariante = v;
                      _currentImageIndex = 0; // la galería cambia a las imágenes de la variante
                      _cantidad = 1; // reseteamos la cantidad al cambiar de variante
                    });
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (_pageController.hasClients) _pageController.jumpToPage(0);
                    });
                  },
                ),
              ),

            // ── Cantidad ───────────────────────────────────────────────────
            if (hayStock && stockActual > 0 && (!tieneVariantes || vSel != null))
              _card(child: _buildCantidadSelector(stockActual)),

            // ── Oferta (banner + cuenta regresiva si hay fecha de fin) ─────
            if (enOferta)
              OfertaCountdownBanner(
                fin: ofertaFin,
                sedeNombre: ofertaSede,
                sedeDireccion: ofertaSedeDir,
              ),

            // ── Marca (después de la oferta) ───────────────────────────────
            if (marca != null)
              _card(
                child: Row(
                  children: [
                    Text('Marca: ', style: TextStyle(fontSize: 13, color: Colors.black87,fontWeight: FontWeight.w500)),
                    Text(marca, style: const TextStyle(fontSize: 13, color: AppColors.blue2, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),

            // ── Descripción ────────────────────────────────────────────────
            if (descripcion != null && descripcion.isNotEmpty)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Descripción'),
                    const SizedBox(height: 8),
                    Text(
                      descripcion,
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.6),
                    ),
                  ],
                ),
              ),

            // ── Características (tabla tipo Excel) ──────────────────────────
            if (atributos.isNotEmpty)
              _card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Características'),
                    const SizedBox(height: 8),
                    _buildCaracteristicasTable(atributos),
                  ],
                ),
              ),

            // Opiniones
            _cardWrap(OpinionesProductoSection(productoId: widget.productoId)),

            // Preguntas y respuestas
            _cardWrap(PreguntasProductoSection(productoId: widget.productoId)),

            // Vendido por
            _buildEmpresaCard(empresa),

            // Productos relacionados
            _buildRelacionados(),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.black87),
    );
  }

  /// Selector "Cantidad  [-] N [+]" (estilo Temu). Limita entre 1 y [maxQty].
  Widget _buildCantidadSelector(int maxQty) {
    final cantidad = _cantidad.clamp(1, maxQty);
    return Row(
      children: [
        const Text('Cantidad',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87)),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _qtyBtn(Icons.remove, cantidad > 1, () => setState(() => _cantidad = cantidad - 1)),
              Container(
                width: 42,
                alignment: Alignment.center,
                child: Text('$cantidad',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.black87)),
              ),
              _qtyBtn(Icons.add, cantidad < maxQty, () => setState(() => _cantidad = cantidad + 1)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _qtyBtn(IconData icon, bool enabled, VoidCallback onTap) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 18, color: enabled ? AppColors.blue1 : Colors.grey.shade300),
      ),
    );
  }

  /// Fila de estrellas + total de opiniones + "X vendidos". Solo se muestra si
  /// hay datos reales (no se inventa nada).
  Widget _buildRatingRow(num? calificacion, int totalOpiniones, int vendidos) {
    final hasRating = calificacion != null && totalOpiniones > 0;
    if (!hasRating && vendidos <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 7),
      child: Row(
        children: [
          if (hasRating) ...[
            _stars(calificacion.toDouble()),
            const SizedBox(width: 5),
            Text(
              calificacion.toStringAsFixed(1),
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.black87),
            ),
            const SizedBox(width: 4),
            Text('($totalOpiniones)', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
          ],
          if (hasRating && vendidos > 0)
            Text('   ·   ', style: TextStyle(fontSize: 12, color: Colors.grey.shade300)),
          if (vendidos > 0)
            Text(
              '${_fmtVendidos(vendidos)} vendidos',
              style: TextStyle(fontSize: 10, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
            ),
        ],
      ),
    );
  }

  Widget _stars(double rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final v = rating - i;
        final icon = v >= 1
            ? Icons.star_rounded
            : v >= 0.5
                ? Icons.star_half_rounded
                : Icons.star_outline_rounded;
        return Icon(icon, size: size, color: _star);
      }),
    );
  }

  String _fmtVendidos(int n) {
    if (n >= 1000) {
      final k = n / 1000;
      return '${k.toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return '$n';
  }

  Widget _buildTrustBadges(bool hayStock, int stockActual) {
    final badges = <Widget>[];
    if (hayStock) {
      badges.add(_trustBadge(Icons.local_shipping_outlined, 'Envío disponible', AppColors.greendark));
      badges.add(_trustBadge(
        Icons.inventory_2_outlined,
        stockActual > 0 ? '$stockActual en stock' : 'En stock',
        AppColors.blue2,
      ));
    } else {
      badges.add(_trustBadge(Icons.remove_shopping_cart_outlined, 'Sin stock', AppColors.red));
    }
    badges.add(_trustBadge(Icons.chat_outlined, 'Consulta al vendedor', Colors.grey.shade600));

    // Una sola fila; si no entran, FittedBox achica levemente (sin overflow ni
    // cortar texto) manteniendo los 3 chips visibles.
    return SizedBox(
      width: double.infinity,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < badges.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              badges[i],
            ],
          ],
        ),
      ),
    );
  }

  Widget _trustBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  /// Tabla tipo Excel para las características: grilla con bordes, filas
  /// alternadas (zebra) y alto de fila automático.
  Widget _buildCaracteristicasTable(List<dynamic> atributos) {
    return Table(
      border: TableBorder.all(color: Colors.grey.shade200, width: 1),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(1.4),
      },
      defaultVerticalAlignment: TableCellVerticalAlignment.middle,
      children: [
        for (int i = 0; i < atributos.length; i++)
          TableRow(
            decoration: BoxDecoration(
              color: i.isEven ? Colors.white : Colors.grey.shade50,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Text(
                  (atributos[i] as Map<String, dynamic>)['nombre'] as String? ?? '',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Text(
                  (atributos[i] as Map<String, dynamic>)['valor'] as String? ?? '',
                  style: const TextStyle(fontSize: 10, color: Colors.black87),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildRelacionados() {
    final relacionados = (_producto?['relacionados'] as List?) ?? [];
    if (relacionados.isEmpty) return const SizedBox.shrink();

    return _card(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: _sectionTitle('Productos relacionados'),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 178,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              itemCount: relacionados.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final r = relacionados[i] as Map<String, dynamic>;
                final nombre = r['nombre'] as String? ?? '';
                final imagen = r['imagen'] as String?;
                final precio = r['precio'] as num?;
                final precioOferta = r['precioOferta'] as num?;
                final enOferta = r['enOferta'] as bool? ?? false;
                final precioFinal =
                    enOferta && precioOferta != null ? precioOferta : precio;

                return GestureDetector(
                  onTap: () => context.push('/producto-detalle/${r['id']}'),
                  child: Container(
                    width: 124,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 100,
                          width: double.infinity,
                          color: Colors.grey.shade50,
                          child: imagen != null
                              ? CachedNetworkImage(
                                  imageUrl: imagen,
                                  fit: BoxFit.contain,
                                  placeholder: (_, __) =>
                                      const SizedBox.shrink(),
                                  errorWidget: (_, __, ___) => const Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.grey),
                                )
                              : const Icon(Icons.inventory_2_outlined,
                                  color: Colors.grey),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (precioFinal != null)
                                Text(
                                  'S/ ${precioFinal.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: enOferta
                                        ? AppColors.greendark
                                        : AppColors.blue1,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Text(
                                nombre,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: Colors.grey.shade700,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<dynamic> imagenes) {
    final mq = MediaQuery.of(context);
    final topInset = mq.padding.top; // alto de la barra de estado
    final h = mq.size.height * 0.56; // hero grande como Temu (~55-60%)

    if (imagenes.isEmpty) {
      return Container(
        height: h + topInset,
        width: double.infinity,
        color: Colors.white,
        alignment: Alignment.center,
        child: Padding(
          padding: EdgeInsets.only(top: topInset),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 72, color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Text('Sin imagen disponible', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    return SizedBox(
      height: h + topInset,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(child: Container(color: Colors.white)),
          PageView.builder(
            controller: _pageController,
            itemCount: imagenes.length,
            onPageChanged: (i) => setState(() => _currentImageIndex = i),
            itemBuilder: (context, index) {
              final url = (imagenes[index] as Map<String, dynamic>)['url'] as String? ?? '';
              return Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo: la misma imagen difuminada llena TODO el área (sin
                  // barras blancas, estilo Temu), incluso bajo la barra de estado.
                  ImageFiltered(
                    imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      memCacheWidth: 120, // baja resolución: el blur oculta el detalle
                      placeholder: (_, __) => Container(color: Colors.white),
                      errorWidget: (_, __, ___) => Container(color: Colors.white),
                    ),
                  ),
                  // Velo suave para que el fondo no compita con el producto.
                  Container(color: Colors.white.withValues(alpha: 0.18)),
                  // Primer plano: el producto COMPLETO (contain), bajado de la
                  // barra de estado para que no lo tape el reloj.
                  Padding(
                    padding: EdgeInsets.only(top: topInset),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.contain,
                      // Decodificar al ancho de pantalla, no a resolución completa.
                      memCacheWidth: (mq.size.width * mq.devicePixelRatio).round(),
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Contador overlay (un solo indicador, estilo Temu)
          if (imagenes.length > 1)
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_currentImageIndex + 1}/${imagenes.length}',
                  style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmpresaCard(Map<String, dynamic> empresa) {
    final nombre = empresa['nombre'] as String? ?? '';
    final logo = empresa['logo'] as String?;
    final ubicacion = empresa['ubicacion'] as String? ?? '';
    final rubro = empresa['rubro'] as String? ?? '';
    final telefono = empresa['telefono'] as String?;

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Información del vendedor'),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.blue2.withValues(alpha: 0.08),
                  child: logo != null
                      ? ClipOval(child: CachedNetworkImage(imageUrl: logo, width: 48, height: 48, fit: BoxFit.cover,
                          placeholder: (_, __) => _empresaInitial(nombre),
                          errorWidget: (_, __, ___) => _empresaInitial(nombre)))
                      : _empresaInitial(nombre),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.blue2)),
                      const SizedBox(height: 2),
                      if (rubro.isNotEmpty)
                        Text(rubro, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      if (ubicacion.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 13, color: Colors.grey.shade400),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(ubicacion, style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (telefono != null && telefono.isNotEmpty)
                  IconButton(
                    onPressed: () => _openWhatsApp(
                      telefono,
                      _producto?['nombre'] as String? ?? '',
                      null,
                      nombre,
                    ),
                    icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
                    tooltip: 'Contactar por WhatsApp',
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FloatingButtonText(
            onPressed: () {
              final subdominio = (_producto?['empresa'] as Map<String, dynamic>?)?['subdominio'] as String?;
              if (subdominio != null) context.push('/vendedor/$subdominio');
            },
            label: 'Ver página del vendedor',
            icon: Icons.storefront,
            width: double.infinity,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.blue2,
            borderColor: AppColors.blue2,
            heroTag: 'btn_vendedor',
          ),
          // Botón Cómo llegar
          if (_producto?['sede'] != null &&
              (_producto!['sede'] as Map<String, dynamic>?)?['coordenadas'] != null &&
              ((_producto!['sede'] as Map<String, dynamic>)['coordenadas'] as Map?)?.containsKey('lat') == true) ...[
            const SizedBox(height: 8),
            FloatingButtonText(
              onPressed: () {
                final sede = _producto!['sede'] as Map<String, dynamic>;
                final coords = sede['coordenadas'];
                if (coords == null) return;
                final coordsMap = coords is Map<String, dynamic> ? coords : Map<String, dynamic>.from(coords as Map);
                final lat = coordsMap['lat'];
                final lng = coordsMap['lng'] ?? coordsMap['lon'];
                if (lat != null && lng != null) {
                  final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$lat,$lng');
                  launchUrl(url, mode: LaunchMode.externalApplication);
                }
              },
              label: 'Cómo llegar',
              icon: Icons.directions,
              width: double.infinity,
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade600,
              borderColor: Colors.green.shade400,
              heroTag: 'btn_como_llegar',
            ),
            // Dirección de la sede
            if ((_producto!['sede'] as Map<String, dynamic>)['direccion'] != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.store, size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      [
                        (_producto!['sede'] as Map<String, dynamic>)['direccion'],
                        (_producto!['sede'] as Map<String, dynamic>)['distrito'],
                        (_producto!['sede'] as Map<String, dynamic>)['provincia'],
                      ].where((e) => e != null && e.toString().isNotEmpty).join(', '),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _empresaInitial(String nombre) {
    return Text(
      nombre.isNotEmpty ? nombre[0] : '?',
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
        color: AppColors.blue2,
      ),
    );
  }

  bool _addingToCart = false;

  Future<void> _agregarAlCarrito() async {
    final secureStorage = locator<SecureStorageService>();
    final token = await secureStorage.read(key: StorageConstants.accessToken);
    if (token == null || token.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para agregar al carrito')),
        );
      }
      return;
    }

    setState(() => _addingToCart = true);
    try {
      await locator<DioClient>().post(
        '/marketplace/carrito',
        data: {
          'productoId': widget.productoId,
          'cantidad': _cantidad < 1 ? 1 : _cantidad,
          if (_selectedVariante != null) 'varianteId': _selectedVariante!['id'],
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Producto agregado al carrito'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final msg = e.toString().contains('stock')
            ? 'Stock insuficiente'
            : 'Error al agregar al carrito';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _addingToCart = false);
    }
  }

  Widget _buildBottomBar() {
    final p = _producto!;
    final empresa = p['empresa'] as Map<String, dynamic>? ?? {};
    final telefono = empresa['telefono'] as String?;
    final empresaNombre = empresa['nombre'] as String? ?? '';
    final nombre = p['nombre'] as String? ?? '';
    final vSel = _selectedVariante;
    final tieneVariantes = p['tieneVariantes'] as bool? ?? false;
    final debeElegirVariante = tieneVariantes && vSel == null;
    final precio = (vSel != null ? vSel['precio'] : p['precio']) as num?;
    final precioOferta = (vSel != null ? vSel['precioOferta'] : p['precioOferta']) as num?;
    final enOferta = (vSel != null ? vSel['enOferta'] : p['enOferta']) as bool? ?? false;
    final hayStock = (vSel != null ? vSel['hayStock'] : p['hayStock']) as bool? ?? false;
    final precioFinal = enOferta && precioOferta != null ? precioOferta : precio;
    final tieneWhats = telefono != null && telefono.isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 12, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            if (precioFinal != null) ...[
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Precio', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  Text(
                    '${debeElegirVariante ? 'Desde ' : ''}S/ ${precioFinal.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      color: AppColors.blue1,
                      fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
            ],
            // CTA principal (prominente)
            Expanded(
              child: SizedBox(
                height: 45,
                child: debeElegirVariante
                    ? Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('Elegí una opción',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade600)),
                      )
                    : hayStock
                    ? CustomButton(
                        text: 'Agregar al carrito',
                        backgroundColor: AppColors.blue1,
                        textColor: Colors.white,
                        isLoading: _addingToCart,
                        onPressed: _addingToCart ? null : _agregarAlCarrito,
                        icon: const Icon(Icons.add_shopping_cart, size: 19, color: Colors.white),
                        width: double.infinity,
                        borderRadius: 8,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      )
                    : Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('Sin stock disponible',
                            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey.shade500)),
                      ),
              ),
            ),
            if (tieneWhats) ...[
              const SizedBox(width: 10),
              SizedBox(
                width: 45,
                height: 45,
                child: OutlinedButton(
                  onPressed: () => _openWhatsApp(telefono, nombre, precioFinal, empresaNombre),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: const BorderSide(color: Color(0xFF25D366), width: 1),
                  ),
                  child: const Icon(Icons.chat, color: Color(0xFF25D366), size: 22),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _openWhatsApp(String telefono, String producto, num? precio, String empresa) {
    String numero = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (numero.startsWith('9') && numero.length == 9) numero = '51$numero';

    final precioStr = precio != null ? 'S/ ${precio.toStringAsFixed(2)}' : 'sin precio definido';
    final mensaje = Uri.encodeComponent(
      'Hola $empresa, me interesa el producto:\n\n'
      '*$producto*\n'
      'Precio: $precioStr\n\n'
      'Vi este producto en Syncronize Marketplace. ¿Podrían darme más información?',
    );

    launchUrl(Uri.parse('https://wa.me/$numero?text=$mensaje'), mode: LaunchMode.externalApplication);
  }
}
