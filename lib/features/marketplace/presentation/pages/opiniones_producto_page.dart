import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';

class OpinionesProductoPage extends StatefulWidget {
  final String productoId;

  const OpinionesProductoPage({super.key, required this.productoId});

  @override
  State<OpinionesProductoPage> createState() => _OpinionesProductoPageState();
}

class _OpinionesProductoPageState extends State<OpinionesProductoPage> {
  final _dio = locator<DioClient>();
  final _scrollController = ScrollController();

  List<dynamic> _opiniones = [];
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;

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
      final response = await _dio.get(
        '/marketplace/productos/${widget.productoId}/opiniones',
        queryParameters: {'page': '1', 'limit': '20'},
      );
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
      final response = await _dio.get(
        '/marketplace/productos/${widget.productoId}/opiniones',
        queryParameters: {'page': '$nextPage', 'limit': '20'},
      );
      setState(() {
        _opiniones.addAll(response.data['data'] as List);
        _page = nextPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  void _mostrarCrearOpinion() {
    int selectedRating = 0;
    final comentarioCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16, right: 16, top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Escribir opinión',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 16),

                  // Estrellas
                  const Text('¿Cómo calificarías este producto?',
                      style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      return GestureDetector(
                        onTap: () => setSheetState(() => selectedRating = i + 1),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            i < selectedRating ? Icons.star : Icons.star_border,
                            size: 36,
                            color: i < selectedRating ? Colors.amber : Colors.grey[300],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),

                  // Comentario
                  TextField(
                    controller: comentarioCtrl,
                    maxLines: 4,
                    maxLength: 1000,
                    decoration: InputDecoration(
                      hintText: 'Cuenta tu experiencia con el producto (opcional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Enviar
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: Builder(
                      builder: (context) {
                        bool sending = false;
                        return StatefulBuilder(
                          builder: (context, setSendState) {
                            return ElevatedButton(
                              onPressed: (selectedRating == 0 || sending)
                                  ? null
                                  : () async {
                                      setSendState(() => sending = true);
                                      try {
                                        await _dio.post(
                                          '/marketplace/productos/${widget.productoId}/opiniones',
                                          data: {
                                            'calificacion': selectedRating,
                                            'comentario': comentarioCtrl.text.trim().isEmpty
                                                ? null
                                                : comentarioCtrl.text.trim(),
                                          },
                                        );
                                        if (mounted) {
                                          Navigator.pop(ctx);
                                          SnackBarHelper.showSuccess(
                                              this.context, 'Opinión publicada');
                                          _loadOpiniones();
                                        }
                                      } catch (e) {
                                        setSendState(() => sending = false);
                                        if (mounted) {
                                          SnackBarHelper.showError(
                                              this.context, 'Error al publicar opinión');
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.blue1,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(sending ? 'Publicando...' : 'Publicar opinión'),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final promedio = (_resumen?['promedio'] ?? 0).toDouble();
    final total = _resumen?['total'] ?? 0;
    final distribucion = _resumen?['distribucion'] as Map<String, dynamic>? ?? {};

    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Opiniones',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadOpiniones,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Resumen con distribución
                    if (total > 0) ...[
                      GradientContainer(
                        borderColor: AppColors.blueborder,
                        borderRadius: BorderRadius.circular(12),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Promedio
                            Column(
                              children: [
                                Text(
                                  promedio.toStringAsFixed(1),
                                  style: const TextStyle(
                                      fontSize: 40, fontWeight: FontWeight.w700),
                                ),
                                _buildStars(promedio, size: 18),
                                const SizedBox(height: 4),
                                Text('$total opiniones',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                              ],
                            ),
                            const SizedBox(width: 20),
                            // Distribución
                            Expanded(
                              child: Column(
                                children: List.generate(5, (i) {
                                  final star = 5 - i;
                                  final count = distribucion['$star'] ?? 0;
                                  final pct = total > 0 ? count / total : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Text('$star', style: const TextStyle(fontSize: 12)),
                                        const Icon(Icons.star, size: 12, color: Colors.amber),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: LinearProgressIndicator(
                                            value: pct,
                                            backgroundColor: Colors.grey[200],
                                            color: Colors.amber,
                                            minHeight: 8,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        SizedBox(
                                          width: 20,
                                          child: Text('$count',
                                              style: TextStyle(
                                                  fontSize: 11, color: Colors.grey[500]),
                                              textAlign: TextAlign.end),
                                        ),
                                      ],
                                    ),
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Lista de opiniones
                    if (_opiniones.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Column(
                            children: [
                              Icon(Icons.rate_review_outlined,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No hay opiniones aún',
                                  style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(
                        _opiniones.length + (_isLoadingMore ? 1 : 0),
                        (index) {
                          if (index == _opiniones.length) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          }
                          return _OpinionCard(opinion: _opiniones[index]);
                        },
                      ),

                    const SizedBox(height: 80),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarCrearOpinion,
        icon: const Icon(Icons.rate_review),
        label: const Text('Opinar'),
        backgroundColor: AppColors.blue1,
      ),
    );
  }

  Widget _buildStars(double rating, {double size = 16}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return Icon(Icons.star, size: size, color: Colors.amber);
        } else if (i < rating) {
          return Icon(Icons.star_half, size: size, color: Colors.amber);
        }
        return Icon(Icons.star_border, size: size, color: Colors.grey[300]);
      }),
    );
  }
}

class _OpinionCard extends StatelessWidget {
  final dynamic opinion;

  const _OpinionCard({required this.opinion});

  @override
  Widget build(BuildContext context) {
    final calificacion = opinion['calificacion'] as int? ?? 0;
    final comentario = opinion['comentario'] as String?;
    final nombre = opinion['nombreUsuario'] as String? ?? 'Usuario';
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
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                ...List.generate(5, (i) => Icon(
                      i < calificacion ? Icons.star : Icons.star_border,
                      size: 16,
                      color: i < calificacion ? Colors.amber : Colors.grey[300],
                    )),
                const SizedBox(width: 8),
                Text(fechaFormateada,
                    style: TextStyle(fontSize: 11, color: Colors.grey[400])),
              ],
            ),
            const SizedBox(height: 6),

            // Usuario
            Row(
              children: [
                Text(nombre,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                if (verificada) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified, size: 12, color: Colors.green[600]),
                        const SizedBox(width: 2),
                        Text('Compra verificada',
                            style: TextStyle(fontSize: 10, color: Colors.green[600])),
                      ],
                    ),
                  ),
                ],
              ],
            ),

            // Comentario
            if (comentario != null && comentario.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(comentario, style: const TextStyle(fontSize: 14)),
            ],

            // Imágenes
            if (imagenes.isNotEmpty) ...[
              const SizedBox(height: 10),
              SizedBox(
                height: 72,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: imagenes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (ctx, i) => GestureDetector(
                    onTap: () => _showImageDialog(ctx, imagenes[i]),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        imagenes[i],
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 72, height: 72,
                          color: Colors.grey[200],
                          child: const Icon(Icons.image, size: 24),
                        ),
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

  void _showImageDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
