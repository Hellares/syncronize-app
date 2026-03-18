import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_loading.dart';
import 'package:syncronize/core/widgets/custom_search_field.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/widgets/floating_button_text.dart';
import '../../data/datasources/marketplace_remote_datasource.dart';
import '../widgets/producto_marketplace_card.dart';

class EmpresaPublicProfilePage extends StatefulWidget {
  final String subdominio;

  const EmpresaPublicProfilePage({super.key, required this.subdominio});

  @override
  State<EmpresaPublicProfilePage> createState() => _EmpresaPublicProfilePageState();
}

class _EmpresaPublicProfilePageState extends State<EmpresaPublicProfilePage> {
  final _dataSource = locator<MarketplaceRemoteDataSource>();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  Map<String, dynamic>? _empresa;
  List<dynamic> _productos = [];
  bool _isLoadingEmpresa = true;
  List<dynamic> _servicios = [];
  bool _isLoadingProductos = true;
  bool _isLoadingMore = false;
  String? _error;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadEmpresa();
    _loadProductos();
    _loadServicios();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadEmpresa() async {
    try {
      final data = await _dataSource.getEmpresaPublica(widget.subdominio);
      if (mounted) setState(() { _empresa = data; _isLoadingEmpresa = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoadingEmpresa = false; });
    }
  }

  Future<void> _loadProductos({String? search}) async {
    setState(() { _isLoadingProductos = true; _page = 1; });
    try {
      final data = await _dataSource.getProductosEmpresa(
        widget.subdominio,
        page: 1,
        limit: 20,
        search: search,
      );
      if (mounted) {
        setState(() {
          _productos = (data['data'] as List<dynamic>?) ?? [];
          _totalPages = (data['pagination']?['totalPages'] as int?) ?? 1;
          _isLoadingProductos = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _isLoadingProductos = false; });
    }
  }

  Future<void> _loadServicios() async {
    try {
      final data = await _dataSource.getServiciosEmpresa(widget.subdominio);
      if (mounted) {
        setState(() {
          _servicios = (data['data'] as List<dynamic>?) ?? [];
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    _isLoadingMore = true;
    final nextPage = _page + 1;
    try {
      final data = await _dataSource.getProductosEmpresa(
        widget.subdominio,
        page: nextPage,
        limit: 20,
        search: _searchController.text.isEmpty ? null : _searchController.text,
      );
      if (mounted) {
        setState(() {
          _productos.addAll((data['data'] as List<dynamic>?) ?? []);
          _page = nextPage;
          _totalPages = (data['pagination']?['totalPages'] as int?) ?? 1;
        });
      }
    } catch (_) {}
    _isLoadingMore = false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingEmpresa) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
        body: CustomLoading.small(message: 'Cargando...'),
      );
    }

    if (_error != null || _empresa == null) {
      return Scaffold(
        appBar: AppBar(backgroundColor: AppColors.blue1, foregroundColor: Colors.white),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 48, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              const Text('Empresa no encontrada'),
              const SizedBox(height: 8),
              TextButton(onPressed: () => context.pop(), child: const Text('Volver')),
            ],
          ),
        ),
      );
    }

    final e = _empresa!;
    final nombre = e['nombre'] as String? ?? '';
    final logo = e['logo'] as String?;
    final descripcion = e['descripcion'] as String?;
    final rubro = e['rubro'] as String? ?? '';
    final ubicacion = e['ubicacion'] as String? ?? '';
    final telefono = e['telefono'] as String?;
    final email = e['email'] as String?;
    final web = e['web'] as String?;
    final miembroDesde = e['miembroDesde'] as String?;
    final counts = e['_count'] as Map<String, dynamic>? ?? {};
    final totalProductos = e['totalProductos'] as int? ?? counts['productos'] as int? ?? 0;
    final totalServicios = e['totalServicios'] as int? ?? counts['servicios'] as int? ?? 0;

    // Personalización
    final personalizaciones = e['personalizaciones'] as List<dynamic>? ?? [];
    final personalizacion = personalizaciones.isNotEmpty ? personalizaciones[0] as Map<String, dynamic> : null;
    final bannerUrl = personalizacion?['bannerPrincipalUrl'] as String?;

    // Productos destacados (primeros 6)
    final destacados = _productos.take(6).toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // AppBar con header de empresa
          SliverAppBar(
            expandedHeight: bannerUrl != null ? 170 : 150,
            pinned: true,
            backgroundColor: AppColors.blue1,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Stack(
                fit: StackFit.expand,
                children: [
                  // Fondo: banner o gradiente
                  if (bannerUrl != null)
                    Image.network(
                      bannerUrl,
                      fit: BoxFit.fitWidth,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, __, ___) => Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.blue1, AppColors.blue2],
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [AppColors.blue1, AppColors.blue2.withValues(alpha: 0.9)],
                        ),
                      ),
                    ),
                  // Overlay para legibilidad del texto
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: bannerUrl != null ? 0.1 : 0.0),
                          Colors.black.withValues(alpha: bannerUrl != null ? 0.6 : 0.0),
                        ],
                      ),
                    ),
                  ),
                  // Contenido
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 50, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Logo
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.white,
                                child: logo != null
                                    ? ClipOval(child: Image.network(logo, width: 58, height: 58, fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => _initial(nombre)))
                                    : _initial(nombre),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(nombre, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                    const SizedBox(height: 4),
                                    if (rubro.isNotEmpty)
                                      Text(rubro, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                                    if (ubicacion.isNotEmpty)
                                      Row(
                                        children: [
                                          const Icon(Icons.location_on, size: 13, color: Colors.white54),
                                          const SizedBox(width: 3),
                                          Expanded(child: Text(ubicacion, style: const TextStyle(fontSize: 11, color: Colors.white60), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          // Stats
                          Row(
                            children: [
                              _statChip(Icons.inventory_2, '$totalProductos productos'),
                              const SizedBox(width: 8),
                              _statChip(Icons.build_circle, '$totalServicios servicios'),
                              if (miembroDesde != null) ...[
                                const SizedBox(width: 8),
                                _statChip(Icons.verified, 'Desde ${_formatDate(miembroDesde)}'),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              ),
            ),
          ),

          // Botones de contacto
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Row(
                children: [
                  if (telefono != null && telefono.isNotEmpty)
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(telefono, nombre),
                        icon: const Icon(Icons.chat, size: 16),
                        label: const Text('WhatsApp', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF25D366),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  if (telefono != null && email != null) const SizedBox(width: 8),
                  if (email != null && email.isNotEmpty)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => launchUrl(Uri.parse('mailto:$email')),
                        icon: const Icon(Icons.email_outlined, size: 16),
                        label: const Text('Email', style: TextStyle(fontSize: 12)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.blue2,
                          side: const BorderSide(color: AppColors.blue2),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  if (web != null && web.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => launchUrl(Uri.parse(web.startsWith('http') ? web : 'https://$web'), mode: LaunchMode.externalApplication),
                      icon: const Icon(Icons.language, color: AppColors.blue2),
                      tooltip: 'Sitio web',
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Descripción
          if (descripcion != null && descripcion.isNotEmpty)
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(16),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sobre nosotros', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 8),
                    Text(descripcion, style: TextStyle(fontSize: 13, color: Colors.grey.shade700, height: 1.5)),
                  ],
                ),
              ),
            ),

          // Sedes / Ubicaciones
          ..._buildSedesSection(),

          // Productos destacados (scroll horizontal)
          if (destacados.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: const Text('Productos destacados', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                height: 250,
                padding: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: destacados.length,
                  itemBuilder: (context, index) {
                    final producto = destacados[index] as Map<String, dynamic>;
                    return SizedBox(
                      width: 160,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ProductoMarketplaceCard(
                          producto: producto,
                          compact: true,
                          onTap: () {
                            final id = producto['id'] as String?;
                            if (id != null) context.push('/producto-detalle/$id');
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Servicios (scroll horizontal)
          if (_servicios.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                child: const Text('Servicios', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              ),
            ),
            SliverToBoxAdapter(
              child: Container(
                color: Colors.white,
                height: 100,
                padding: const EdgeInsets.only(bottom: 12),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: _servicios.length,
                  itemBuilder: (context, index) {
                    final s = _servicios[index] as Map<String, dynamic>;
                    final sNombre = s['nombre'] as String? ?? '';
                    final sPrecio = s['precio'] as num?;
                    final sPrecioOferta = s['precioOferta'] as num?;
                    final sEnOferta = s['enOferta'] as bool? ?? false;
                    final sDuracion = s['duracionMinutos'] as int?;
                    final sPrecioFinal = sEnOferta && sPrecioOferta != null ? sPrecioOferta : sPrecio;

                    return Container(
                      width: 150,
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade200),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.build_circle, color: AppColors.blue2, size: 16),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  sNombre,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, height: 1.2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (sPrecioFinal != null)
                            Text(
                              'S/ ${sPrecioFinal.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                fontFamily: AppFonts.getFontFamily(AppFont.oxygenBold),
                                color: sEnOferta ? Colors.green.shade700 : Colors.black87,
                              ),
                            )
                          else
                            Text('Consultar', style: TextStyle(fontSize: 10, color: AppColors.blue2)),
                          if (sDuracion != null) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.schedule, size: 10, color: Colors.grey.shade400),
                                const SizedBox(width: 3),
                                Text(
                                  sDuracion >= 60 ? '${sDuracion ~/ 60}h ${sDuracion % 60}min' : '${sDuracion}min',
                                  style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ],

          // Buscador de productos
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text('Todos los productos', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('$totalProductos', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  CustomSearchField(
                    controller: _searchController,
                    hintText: 'Buscar en esta tienda...',
                    borderRadius: 20,
                    height: 38,
                    showClearButton: true,
                    onSubmitted: (v) => _loadProductos(search: v.isEmpty ? null : v),
                    onClear: () {
                      _searchController.clear();
                      _loadProductos();
                    },
                  ),
                ],
              ),
            ),
          ),

          // Grid de productos
          if (_isLoadingProductos)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.blue2)),
              ),
            )
          else if (_productos.isEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      AppSubtitle('No se encontraron productos', fontSize: 12, color: Colors.grey.shade500),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.all(8),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    if (index >= _productos.length) {
                      return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(strokeWidth: 2)));
                    }
                    final producto = _productos[index] as Map<String, dynamic>;
                    return ProductoMarketplaceCard(
                      producto: producto,
                      onTap: () {
                        final id = producto['id'] as String?;
                        if (id != null) context.push('/producto-detalle/$id');
                      },
                    );
                  },
                  childCount: _productos.length + (_page < _totalPages ? 1 : 0),
                ),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.58,
                  crossAxisSpacing: 6,
                  mainAxisSpacing: 6,
                ),
              ),
            ),

          // Espacio final
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  Widget _initial(String nombre) {
    return Text(
      nombre.isNotEmpty ? nombre[0] : '?',
      style: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        fontFamily: AppFonts.getFontFamily(AppFont.pirulentBold),
        color: AppColors.blue2,
      ),
    );
  }

  Widget _statChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white70),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 10, color: Colors.white70)),
        ],
      ),
    );
  }

  String _formatDate(String date) {
    try {
      final d = DateTime.parse(date);
      const meses = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
      return '${meses[d.month - 1]} ${d.year}';
    } catch (_) {
      return '';
    }
  }

  List<Widget> _buildSedesSection() {
    final sedes = (_empresa?['sedes'] as List?) ?? [];
    if (sedes.isEmpty) return [];

    return [
      SliverToBoxAdapter(
        child: Container(
          color: Colors.white,
          margin: const EdgeInsets.only(top: 8),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Nuestras ubicaciones',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
              const SizedBox(height: 12),
              ...sedes.map((sede) => _buildSedeCard(sede)),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildSedeCard(dynamic sede) {
    final nombre = sede['nombre'] as String? ?? '';
    final direccion = sede['direccion'] as String?;
    final stand = sede['stand'] as String?;
    final distrito = sede['distrito'] as String?;
    final provincia = sede['provincia'] as String?;
    final horario = sede['horarioAtencion'] as Map<String, dynamic>?;
    final imagenes = (sede['imagenes'] as List?)?.cast<String>() ?? [];
    final coordenadas = sede['coordenadas'] as Map<String, dynamic>?;
    final esPrincipal = sede['esPrincipal'] == true;
    final telefono = sede['telefono'] as String?;

    final coordLat = (coordenadas?['lat'] as num?)?.toDouble();
    final coordLng = ((coordenadas?['lng'] ?? coordenadas?['lon']) as num?)?.toDouble();

    final ubicacionTexto = [direccion, distrito, provincia]
        .where((e) => e != null && e.isNotEmpty)
        .join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: esPrincipal ? AppColors.blue1.withValues(alpha: 0.3) : Colors.grey.shade200),
      ),
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(Icons.store, size: 18, color: AppColors.blue1),
        title: Row(
          children: [
            Expanded(
              child: Text(nombre, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            ),
            if (esPrincipal)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.blue1.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Principal',
                    style: TextStyle(fontSize: 9, color: AppColors.blue1, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        subtitle: ubicacionTexto.isNotEmpty
            ? Text(ubicacionTexto, style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                maxLines: 1, overflow: TextOverflow.ellipsis)
            : null,
        children: [
          // Stand
          if (stand != null && stand.isNotEmpty)
            _sedeInfoRow(Icons.storefront, stand),

          // Teléfono
          if (telefono != null && telefono.isNotEmpty)
            _sedeInfoRow(Icons.phone, telefono),

          // Horario
          if (horario != null && horario.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.schedule, size: 14, color: AppColors.blue1),
                const SizedBox(width: 4),
                const Text('Horario', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            ...horario.entries.map((e) {
              if (e.value is! Map) return const SizedBox.shrink();
              final datos = e.value as Map;
              return Padding(
                padding: const EdgeInsets.only(left: 18, bottom: 1),
                child: Row(
                  children: [
                    SizedBox(width: 70, child: Text(_capitalizeDia(e.key),
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]))),
                    Text('${datos['inicio'] ?? ''} - ${datos['fin'] ?? ''}',
                        style: TextStyle(fontSize: 11, color: Colors.grey[700], fontWeight: FontWeight.w500)),
                  ],
                ),
              );
            }),
          ],

          // Imágenes referenciales
          if (imagenes.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.photo_library, size: 14, color: AppColors.blue1),
                const SizedBox(width: 4),
                const Text('Referencias', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagenes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => GestureDetector(
                  onTap: () => _showFullScreenImage(context, imagenes, i),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(imagenes[i], width: 90, height: 70, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(width: 90, height: 70, color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 20))),
                  ),
                ),
              ),
            ),
          ],

          // Cómo llegar
          if (coordLat != null && coordLng != null) ...[
            const SizedBox(height: 10),
            FloatingButtonText(
              onPressed: () {
                final url = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=$coordLat,$coordLng');
                launchUrl(url, mode: LaunchMode.externalApplication);
              },
              label: 'Cómo llegar',
              icon: Icons.directions,
              width: double.infinity,
              backgroundColor: Colors.white,
              foregroundColor: Colors.green.shade600,
              borderColor: Colors.green.shade400,
              heroTag: 'btn_llegar_${sede['id']}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _sedeInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        ],
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, List<String> imagenes, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            title: Text('${initialIndex + 1} / ${imagenes.length}',
                style: const TextStyle(color: Colors.white, fontSize: 14)),
          ),
          body: PageView.builder(
            controller: PageController(initialPage: initialIndex),
            itemCount: imagenes.length,
            itemBuilder: (_, i) => InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: Image.network(
                  imagenes[i],
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _capitalizeDia(String dia) {
    if (dia.isEmpty) return dia;
    return dia[0].toUpperCase() + dia.substring(1);
  }

  void _openWhatsApp(String telefono, String empresa) {
    String numero = telefono.replaceAll(RegExp(r'[^0-9]'), '');
    if (numero.startsWith('9') && numero.length == 9) numero = '51$numero';
    final mensaje = Uri.encodeComponent('Hola $empresa, vi su tienda en Syncronize Marketplace y me gustaría obtener más información.');
    launchUrl(Uri.parse('https://wa.me/$numero?text=$mensaje'), mode: LaunchMode.externalApplication);
  }
}
