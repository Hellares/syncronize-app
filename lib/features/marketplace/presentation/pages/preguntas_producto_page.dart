import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';

class PreguntasProductoPage extends StatefulWidget {
  final String productoId;

  const PreguntasProductoPage({super.key, required this.productoId});

  @override
  State<PreguntasProductoPage> createState() => _PreguntasProductoPageState();
}

class _PreguntasProductoPageState extends State<PreguntasProductoPage> {
  final _dio = locator<DioClient>();
  final _scrollController = ScrollController();

  List<dynamic> _preguntas = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _loadPreguntas();
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

  Future<void> _loadPreguntas() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final response = await _dio.get(
        '/marketplace/productos/${widget.productoId}/preguntas',
        queryParameters: {'page': '1', 'limit': '20'},
      );
      setState(() {
        _preguntas = response.data['data'] as List;
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
        '/marketplace/productos/${widget.productoId}/preguntas',
        queryParameters: {'page': '$nextPage', 'limit': '20'},
      );
      setState(() {
        _preguntas.addAll(response.data['data'] as List);
        _page = nextPage;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
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
              _PreguntarButton(
                onSend: () async {
                  final texto = controller.text.trim();
                  if (texto.isEmpty) throw Exception('Escribe una pregunta');
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
    return Scaffold(
      appBar: SmartAppBar.withBackButton(
        title: 'Preguntas y respuestas',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _preguntas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_outlined, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text('No hay preguntas aún',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadPreguntas,
                    child: ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _preguntas.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == _preguntas.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        return _PreguntaCard(pregunta: _preguntas[index]);
                      },
                    ),
                  ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarBottomSheetPreguntar,
        icon: const Icon(Icons.help_outline),
        label: const Text('Preguntar'),
        backgroundColor: AppColors.blue1,
      ),
    );
  }
}

class _PreguntaCard extends StatelessWidget {
  final dynamic pregunta;

  const _PreguntaCard({required this.pregunta});

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pregunta
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.chat_bubble_outline, size: 18, color: Colors.grey[500]),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(texto, style: const TextStyle(fontSize: 14)),
                      const SizedBox(height: 4),
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
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.store, size: 16, color: AppColors.blue1),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          respuesta,
                          style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else
              Padding(
                padding: const EdgeInsets.only(left: 26, top: 6),
                child: Text(
                  'Esperando respuesta del vendedor...',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange[400],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PreguntarButton extends StatefulWidget {
  final Future<void> Function() onSend;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const _PreguntarButton({required this.onSend, required this.onSuccess, required this.onError});

  @override
  State<_PreguntarButton> createState() => _PreguntarButtonState();
}

class _PreguntarButtonState extends State<_PreguntarButton> {
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(_sending ? 'Enviando...' : 'Enviar pregunta'),
      ),
    );
  }
}
