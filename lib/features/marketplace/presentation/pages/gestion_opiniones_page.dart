import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';

class GestionOpinionesPage extends StatefulWidget {
  const GestionOpinionesPage({super.key});

  @override
  State<GestionOpinionesPage> createState() => _GestionOpinionesPageState();
}

class _GestionOpinionesPageState extends State<GestionOpinionesPage> {
  final _dio = locator<DioClient>();
  final _scrollController = ScrollController();

  List<dynamic> _opiniones = [];
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  String? _filtro;

  @override
  void initState() {
    super.initState();
    _loadOpiniones();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _page < _totalPages) {
      _loadMore();
    }
  }

  Future<void> _loadOpiniones() async {
    setState(() => _isLoading = true);
    try {
      final params = <String, String>{'page': '1', 'limit': '20'};
      if (_filtro != null) params['filtro'] = _filtro!;
      final response = await _dio.get('/opiniones-producto', queryParameters: params);
      setState(() {
        _opiniones = response.data['data'] as List;
        _resumen = response.data['resumen'] as Map<String, dynamic>?;
        _totalPages = response.data['totalPages'] ?? 1;
        _page = 1;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final params = <String, String>{'page': '$nextPage', 'limit': '20'};
      if (_filtro != null) params['filtro'] = _filtro!;
      final response = await _dio.get('/opiniones-producto', queryParameters: params);
      setState(() {
        _opiniones.addAll(response.data['data'] as List);
        _page = nextPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _cambiarFiltro(String? filtro) {
    if (_filtro == filtro) return;
    setState(() => _filtro = filtro);
    _loadOpiniones();
  }

  @override
  Widget build(BuildContext context) {
    final promedio = (_resumen?['promedio'] ?? 0).toDouble();
    final total = _resumen?['total'] ?? 0;

    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Opiniones de clientes',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Resumen + filtros
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Resumen
                  if (!_isLoading && total > 0)
                    GradientContainer(
                      borderColor: AppColors.blueborder,
                      borderRadius: BorderRadius.circular(10),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 28),
                          const SizedBox(width: 8),
                          Text(
                            promedio.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '$total opiniones',
                            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),

                  // Filtros por estrellas
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _StarFilter(
                          label: 'Todas',
                          selected: _filtro == null,
                          onTap: () => _cambiarFiltro(null),
                        ),
                        ...List.generate(5, (i) {
                          final star = 5 - i;
                          return _StarFilter(
                            label: '$star',
                            icon: Icons.star,
                            selected: _filtro == '$star',
                            onTap: () => _cambiarFiltro('$star'),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _opiniones.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.rate_review_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No hay opiniones',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadOpiniones,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _opiniones.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _opiniones.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                );
                              }
                              return _OpinionEmpresaCard(opinion: _opiniones[index]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StarFilter extends StatelessWidget {
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback onTap;

  const _StarFilter({
    required this.label,
    this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? Colors.amber.withValues(alpha: 0.15) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? Colors.amber : Colors.grey[300]!,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 14, color: Colors.amber),
                const SizedBox(width: 2),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.amber[800] : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OpinionEmpresaCard extends StatelessWidget {
  final dynamic opinion;

  const _OpinionEmpresaCard({required this.opinion});

  @override
  Widget build(BuildContext context) {
    final calificacion = opinion['calificacion'] as int? ?? 0;
    final comentario = opinion['comentario'] as String?;
    final nombre = opinion['nombreUsuario'] as String? ?? 'Usuario';
    final productoNombre = opinion['productoNombre'] as String? ?? '';
    final verificada = opinion['verificada'] == true;
    final imagenes = opinion['imagenes'] as List? ?? [];
    final fecha = opinion['creadoEn'] as String?;

    String fechaFormateada = '';
    if (fecha != null) {
      try {
        fechaFormateada = DateFormat('dd/MM/yyyy').format(DateTime.parse(fecha).toLocal());
      } catch (_) {}
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Producto
            Row(
              children: [
                Icon(Icons.inventory_2, size: 14, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(productoNombre,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ),
                Text(fechaFormateada,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 6),

            // Estrellas + usuario
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                      i < calificacion ? Icons.star : Icons.star_border,
                      size: 16,
                      color: i < calificacion ? Colors.amber : Colors.grey[300],
                    )),
                const SizedBox(width: 8),
                Text(nombre, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                if (verificada) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.verified, size: 14, color: Colors.green[600]),
                ],
              ],
            ),

            if (comentario != null && comentario.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comentario, style: const TextStyle(fontSize: 14)),
            ],

            if (imagenes.isNotEmpty) ...[
              const SizedBox(height: 8),
              SizedBox(
                height: 56,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagenes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 6),
                  itemBuilder: (_, i) => ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.network(
                      imagenes[i], width: 56, height: 56, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 56, height: 56, color: Colors.grey[200],
                        child: const Icon(Icons.image, size: 20),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
