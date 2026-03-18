import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:url_launcher/url_launcher.dart';
// import 'package:share_plus/share_plus.dart'; // TODO: agregar dependencia
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../data/datasources/marketplace_remote_datasource.dart';
import '../widgets/favorito_button.dart';
import '../widgets/preguntas_producto_section.dart';
import '../widgets/opiniones_producto_section.dart';
import '../../../../core/widgets/floating_button_text.dart';

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
  final _pageController = PageController();

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
        final token = await storage.getString(StorageConstants.accessToken);
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
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: _producto != null
            ? Text(
                _producto!['nombre'] as String? ?? '',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
              )
            : null,
        actions: [
          if (_producto != null) ...[
            FavoritoButton(
              productoId: widget.productoId,
              size: 22,
            ),
            IconButton(
              icon: const Icon(Icons.share_outlined, size: 20),
              onPressed: () {
                // TODO: implementar share cuando se agregue share_plus
              },
            ),
          ],
        ],
      ),
      body: _isLoading
          ? CustomLoading.small(message: 'Cargando...')
          : _error != null
              ? _buildError()
              : _buildContent(),
      bottomNavigationBar: _producto != null && !_isLoading ? _buildBottomBar() : null,
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

  Widget _buildContent() {
    final p = _producto!;
    final nombre = p['nombre'] as String? ?? '';
    final descripcion = p['descripcion'] as String?;
    final precio = p['precio'] as num?;
    final precioOferta = p['precioOferta'] as num?;
    final enOferta = p['enOferta'] as bool? ?? false;
    final hayStock = p['hayStock'] as bool? ?? false;
    final stockActual = p['stockActual'] as int? ?? 0;
    final categoria = p['categoria'] as String?;
    final marca = p['marca'] as String?;
    final imagenes = (p['imagenes'] as List<dynamic>?) ?? [];
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
            // Galería
            _buildImageGallery(imagenes),

            // Sección principal
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Condición y categoría
                  Row(
                    children: [
                      Text(
                        hayStock ? 'Nuevo' : 'Sin stock',
                        style: TextStyle(
                          fontSize: 11,
                          color: hayStock ? Colors.grey.shade600 : Colors.red.shade600,
                        ),
                      ),
                      if (categoria != null) ...[
                        Text(' | ', style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                        Text(categoria, style: TextStyle(fontSize: 11, color: AppColors.blue2)),
                      ],
                      if (stockActual > 0 && stockActual <= 5) ...[
                        const Spacer(),
                        Text(
                          '¡Últimas $stockActual unidades!',
                          style: TextStyle(fontSize: 10, color: Colors.orange.shade700, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Nombre del producto
                  Text(
                    nombre,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4, color: Colors.black87),
                  ),

                  const SizedBox(height: 12),

                  // Precio
                  if (precioFinal != null) ...[
                    if (tieneDescuento) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            'S/ ${precio.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade500,
                              decoration: TextDecoration.lineThrough,
                              decorationColor: Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '$descuentoPct% OFF',
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.green.shade700),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                    ],
                    Text(
                      'S/ ${precioFinal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w300,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                        color: Colors.black87,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ] else
                    AppTitle('Consultar precio', fontSize: 18, color: AppColors.blue2),

                  // Envío
                  if (hayStock) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.local_shipping_outlined, size: 16, color: Colors.green.shade700),
                          const SizedBox(width: 6),
                          Text(
                            'Envío disponible',
                            style: TextStyle(fontSize: 12, color: Colors.green.shade700, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Marca
                  if (marca != null) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Text('Marca: ', style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        Text(marca, style: const TextStyle(fontSize: 13, color: AppColors.blue2, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Descripción
            if (descripcion != null && descripcion.isNotEmpty)
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 10),
                    Text(
                      descripcion,
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade700, height: 1.6),
                    ),
                  ],
                ),
              ),

            if (descripcion != null && descripcion.isNotEmpty) const SizedBox(height: 8),

            // Características
            if (atributos.isNotEmpty)
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Características', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 12),
                    ...atributos.asMap().entries.map((entry) {
                      final a = entry.value as Map<String, dynamic>;
                      final isEven = entry.key % 2 == 0;
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        color: isEven ? Colors.grey.shade50 : Colors.white,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 130,
                              child: Text(
                                a['nombre'] as String? ?? '',
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                a['valor'] as String? ?? '',
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            if (atributos.isNotEmpty) const SizedBox(height: 8),

            // Opiniones
            OpinionesProductoSection(productoId: widget.productoId),
            const SizedBox(height: 8),

            // Preguntas y respuestas
            PreguntasProductoSection(productoId: widget.productoId),
            const SizedBox(height: 8),

            // Vendido por
            _buildEmpresaCard(empresa),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<dynamic> imagenes) {
    if (imagenes.isEmpty) {
      return Container(
        height: 300,
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey.shade200),
              const SizedBox(height: 8),
              Text('Sin imagen disponible', style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
        ),
      );
    }

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          SizedBox(
            height: 300,
            child: PageView.builder(
              controller: _pageController,
              itemCount: imagenes.length,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              itemBuilder: (context, index) {
                final img = imagenes[index] as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.network(
                    img['url'] as String? ?? '',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Center(
                      child: Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey.shade300),
                    ),
                  ),
                );
              },
            ),
          ),
          if (imagenes.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_currentImageIndex + 1}/${imagenes.length}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  const SizedBox(width: 12),
                  ...List.generate(
                    imagenes.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _currentImageIndex == i ? 18 : 6,
                      height: 6,
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      decoration: BoxDecoration(
                        color: _currentImageIndex == i ? AppColors.blue2 : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Thumbnails
          if (imagenes.length > 1)
            SizedBox(
              height: 56,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                itemCount: imagenes.length,
                itemBuilder: (context, index) {
                  final img = imagenes[index] as Map<String, dynamic>;
                  final isSelected = _currentImageIndex == index;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(index,
                          duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppColors.blue2 : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.network(
                          (img['thumbnail'] ?? img['url']) as String? ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Icon(Icons.image, size: 16, color: Colors.grey.shade300),
                        ),
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

  Widget _buildEmpresaCard(Map<String, dynamic> empresa) {
    final nombre = empresa['nombre'] as String? ?? '';
    final logo = empresa['logo'] as String?;
    final ubicacion = empresa['ubicacion'] as String? ?? '';
    final rubro = empresa['rubro'] as String? ?? '';
    final telefono = empresa['telefono'] as String?;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Información del vendedor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade200),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.blue2.withValues(alpha: 0.08),
                  child: logo != null
                      ? ClipOval(child: Image.network(logo, width: 48, height: 48, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _empresaInitial(nombre)))
                      : _empresaInitial(nombre),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nombre, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.blue2)),
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

  Widget _buildBottomBar() {
    final p = _producto!;
    final empresa = p['empresa'] as Map<String, dynamic>? ?? {};
    final telefono = empresa['telefono'] as String?;
    final empresaNombre = empresa['nombre'] as String? ?? '';
    final nombre = p['nombre'] as String? ?? '';
    final precio = p['precio'] as num?;
    final precioOferta = p['precioOferta'] as num?;
    final enOferta = p['enOferta'] as bool? ?? false;
    final precioFinal = enOferta && precioOferta != null ? precioOferta : precio;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -3))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            if (precioFinal != null)
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Precio', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                    Text(
                      'S/ ${precioFinal.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                      ),
                    ),
                  ],
                ),
              )
            else
              const Expanded(child: SizedBox()),
            if (telefono != null && telefono.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () => _openWhatsApp(telefono, nombre, precioFinal, empresaNombre),
                icon: const Icon(Icons.chat, size: 18),
                label: const Text('Consultar por WhatsApp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
              ),
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
