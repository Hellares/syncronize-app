import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/floating_button_text.dart';
import '../../../../core/widgets/snack_bar_helper.dart';

class PreguntasProductoSection extends StatefulWidget {
  final String productoId;

  const PreguntasProductoSection({super.key, required this.productoId});

  @override
  State<PreguntasProductoSection> createState() => _PreguntasProductoSectionState();
}

class _PreguntasProductoSectionState extends State<PreguntasProductoSection> {
  final _dio = locator<DioClient>();

  List<dynamic> _preguntas = [];
  int _total = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPreguntas();
  }

  Future<void> _loadPreguntas() async {
    try {
      final response = await _dio.get(
        '/marketplace/productos/${widget.productoId}/preguntas',
        queryParameters: {'page': '1', 'limit': '3'},
      );
      if (mounted) {
        setState(() {
          _preguntas = response.data['data'] as List;
          _total = response.data['total'] as int? ?? 0;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _mostrarBottomSheetPreguntar() {
    final controller = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Hacé una pregunta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                'El vendedor te responderá lo antes posible',
                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Escribe tu pregunta...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
              ),
              const SizedBox(height: 12),
              _SendButton(
                onSend: () async {
                  final texto = controller.text.trim();
                  if (texto.isEmpty) return;
                  await _dio.post(
                    '/marketplace/productos/${widget.productoId}/preguntas',
                    data: {'pregunta': texto},
                  );
                },
                onSuccess: () {
                  Navigator.pop(ctx);
                  SnackBarHelper.showSuccess(ctx, 'Pregunta enviada');
                  _loadPreguntas();
                },
                onError: () {
                  SnackBarHelper.showError(ctx, 'Debes iniciar sesión para preguntar');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Preguntas y respuestas',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              if (_total > 3)
                TextButton(
                  onPressed: () => context.push(
                    '/producto-detalle/${widget.productoId}/preguntas',
                  ),
                  child: Text(
                    'Ver todas ($_total)',
                    style: TextStyle(fontSize: 13, color: AppColors.blue1),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Botón preguntar
          FloatingButtonText(
            onPressed: _mostrarBottomSheetPreguntar,
            label: 'Preguntar',
            icon: Icons.help_outline,
            width: double.infinity,
            // height: 35,
            backgroundColor: Colors.white,
            foregroundColor: AppColors.blue1,
            borderColor: AppColors.blue1,
            heroTag: 'btn_preguntar',
          ),
          const SizedBox(height: 12),

          // Últimas preguntas
          if (_preguntas.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Sé el primero en preguntar',
                style: TextStyle(fontSize: 13, color: Colors.grey[500]),
              ),
            )
          else
            ..._preguntas.map((p) => _PreguntaItem(pregunta: p)),

          if (_total > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: InkWell(
                onTap: () => context.push(
                  '/producto-detalle/${widget.productoId}/preguntas',
                ),
                child: Text(
                  'Ver todas las preguntas ($_total)',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.blue1,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PreguntaItem extends StatelessWidget {
  final dynamic pregunta;

  const _PreguntaItem({required this.pregunta});

  @override
  Widget build(BuildContext context) {
    final texto = pregunta['pregunta'] as String? ?? '';
    final respuesta = pregunta['respuesta'] as String?;
    final nombre = pregunta['nombreUsuario'] as String? ?? 'Usuario';
    final fecha = pregunta['creadoEn'] as String?;

    String fechaFormateada = '';
    if (fecha != null) {
      try {
        final date = DateTime.parse(fecha).toLocal();
        fechaFormateada = DateFormat('dd/MM/yyyy').format(date);
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pregunta
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.chat_bubble_outline, size: 16, color: Colors.grey[500]),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(texto, style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(
                      '$nombre · $fechaFormateada',
                      style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Respuesta
          if (respuesta != null) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.subdirectory_arrow_right,
                      size: 16, color: AppColors.blue1),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      respuesta,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.only(left: 24, top: 4),
              child: Text(
                'Esperando respuesta...',
                style: TextStyle(fontSize: 12, color: Colors.orange[400], fontStyle: FontStyle.italic),
              ),
            ),
          const Divider(height: 16),
        ],
      ),
    );
  }
}

class _SendButton extends StatefulWidget {
  final Future<void> Function() onSend;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const _SendButton({
    required this.onSend,
    required this.onSuccess,
    required this.onError,
  });

  @override
  State<_SendButton> createState() => _SendButtonState();
}

class _SendButtonState extends State<_SendButton> {
  bool _sending = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: ElevatedButton(
        onPressed: _sending
            ? null
            : () async {
                setState(() => _sending = true);
                try {
                  await widget.onSend();
                  if (mounted) widget.onSuccess();
                } catch (e) {
                  if (mounted) {
                    setState(() => _sending = false);
                    widget.onError();
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
        child: Text(_sending ? 'Enviando...' : 'Enviar pregunta'),
      ),
    );
  }
}
