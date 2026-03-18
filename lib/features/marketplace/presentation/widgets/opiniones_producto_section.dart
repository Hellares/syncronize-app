import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_button_text.dart';

class OpinionesProductoSection extends StatefulWidget {
  final String productoId;

  const OpinionesProductoSection({super.key, required this.productoId});

  @override
  State<OpinionesProductoSection> createState() => _OpinionesProductoSectionState();
}

class _OpinionesProductoSectionState extends State<OpinionesProductoSection> {
  final _dio = locator<DioClient>();

  List<dynamic> _opiniones = [];
  Map<String, dynamic>? _resumen;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOpiniones();
  }

  Future<void> _loadOpiniones() async {
    try {
      final response = await _dio.get(
        '/marketplace/productos/${widget.productoId}/opiniones',
        queryParameters: {'page': '1', 'limit': '2'},
      );
      if (mounted) {
        setState(() {
          _opiniones = response.data['data'] as List;
          _resumen = response.data['resumen'] as Map<String, dynamic>?;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    final total = _resumen?['total'] ?? 0;
    final promedio = (_resumen?['promedio'] ?? 0).toDouble();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Opiniones del producto',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),

          // Resumen compacto
          if (total > 0) ...[
            Row(
              children: [
                Text(
                  promedio.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStars(promedio),
                    const SizedBox(height: 2),
                    Text(
                      '$total opinión${total > 1 ? 'es' : ''}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Últimas 2 opiniones
          if (_opiniones.isEmpty && total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sé el primero en opinar',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            )
          else
            ..._opiniones.map((o) => _OpinionCompacta(opinion: o)),

          // Ver todas
          if (total > 2)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: InkWell(
                onTap: () => context.push(
                  '/producto-detalle/${widget.productoId}/opiniones',
                ),
                child: Text(
                  'Ver todas las opiniones ($total)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.blue1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          const SizedBox(height: 8),

          // Botón opinar
          FloatingButtonText(
            onPressed: () async {
              final result = await context.push(
                '/producto-detalle/${widget.productoId}/opiniones',
              );
              if (result == true) _loadOpiniones();
            },
            label: 'Escribir una opinión',
            icon: Icons.rate_review_outlined,
            width: double.infinity,
            // height: 40,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.blue1,
            borderColor: AppColors.blue1,
            heroTag: 'btn_opinar',
          ),
        ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        if (i < rating.floor()) {
          return const Icon(Icons.star, size: 18, color: Colors.amber);
        } else if (i < rating) {
          return const Icon(Icons.star_half, size: 18, color: Colors.amber);
        }
        return Icon(Icons.star_border, size: 18, color: Colors.grey[300]);
      }),
    );
  }
}

class _OpinionCompacta extends StatelessWidget {
  final dynamic opinion;

  const _OpinionCompacta({required this.opinion});

  @override
  Widget build(BuildContext context) {
    final calificacion = opinion['calificacion'] as int? ?? 0;
    final comentario = opinion['comentario'] as String?;
    final nombre = opinion['nombreUsuario'] as String? ?? 'Usuario';
    final verificada = opinion['verificada'] == true;
    final imagenes = opinion['imagenes'] as List? ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(5, (i) => Icon(
                    i < calificacion ? Icons.star : Icons.star_border,
                    size: 14,
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
            const SizedBox(height: 4),
            Text(
              comentario,
              style: const TextStyle(fontSize: 14),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (imagenes.isNotEmpty) ...[
            const SizedBox(height: 6),
            SizedBox(
              height: 56,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: imagenes.length > 3 ? 3 : imagenes.length,
                separatorBuilder: (_, __) => const SizedBox(width: 6),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    imagenes[i],
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56, height: 56,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image, size: 20),
                    ),
                  ),
                ),
              ),
            ),
          ],
          const Divider(height: 16),
        ],
      ),
    );
  }
}
