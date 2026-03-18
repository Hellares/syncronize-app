import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/snack_bar_helper.dart';

class GestionPreguntasPage extends StatefulWidget {
  const GestionPreguntasPage({super.key});

  @override
  State<GestionPreguntasPage> createState() => _GestionPreguntasPageState();
}

class _GestionPreguntasPageState extends State<GestionPreguntasPage> {
  final _dio = locator<DioClient>();
  final _scrollController = ScrollController();

  List<dynamic> _preguntas = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  int _pendientes = 0;
  String _filtro = 'pendientes';

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
    setState(() => _isLoading = true);
    try {
      final response = await _dio.get(
        '/preguntas-producto',
        queryParameters: {'filtro': _filtro, 'page': '1', 'limit': '20'},
      );
      setState(() {
        _preguntas = response.data['data'] as List;
        _totalPages = response.data['totalPages'] ?? 1;
        _pendientes = response.data['pendientes'] ?? 0;
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
        '/preguntas-producto',
        queryParameters: {'filtro': _filtro, 'page': '$nextPage', 'limit': '20'},
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

  void _cambiarFiltro(String filtro) {
    if (_filtro == filtro) return;
    setState(() => _filtro = filtro);
    _loadPreguntas();
  }

  void _mostrarResponder(Map<String, dynamic> pregunta) {
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
            left: 16, right: 16, top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                pregunta['productoNombre'] ?? '',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(pregunta['pregunta'] ?? '',
                        style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      pregunta['nombreUsuario'] ?? 'Usuario',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  hintText: 'Escribe tu respuesta...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _ResponderButton(
                onSend: () async {
                  final texto = controller.text.trim();
                  if (texto.isEmpty) throw Exception('Escribe una respuesta');
                  await _dio.post(
                    '/marketplace/productos/${pregunta['productoId']}/preguntas/${pregunta['id']}/responder',
                    data: {'respuesta': texto},
                  );
                },
                onSuccess: () {
                  Navigator.pop(ctx);
                  SnackBarHelper.showSuccess(ctx, 'Respuesta enviada');
                  _loadPreguntas();
                },
                onError: () {
                  SnackBarHelper.showError(ctx, 'Error al responder');
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
        title: 'Preguntas de clientes',
        onBack: () => context.pop(),
      ),
      body: GradientBackground(
        child: Column(
          children: [
            // Filtros
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  _FilterChip(
                    label: 'Pendientes${_pendientes > 0 ? ' ($_pendientes)' : ''}',
                    selected: _filtro == 'pendientes',
                    onTap: () => _cambiarFiltro('pendientes'),
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Respondidas',
                    selected: _filtro == 'respondidas',
                    onTap: () => _cambiarFiltro('respondidas'),
                    color: Colors.green,
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Todas',
                    selected: _filtro == 'todas',
                    onTap: () => _cambiarFiltro('todas'),
                    color: AppColors.blue1,
                  ),
                ],
              ),
            ),

            // Lista
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _preguntas.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline,
                                  size: 48, color: Colors.green[300]),
                              const SizedBox(height: 16),
                              Text(
                                _filtro == 'pendientes'
                                    ? 'No hay preguntas pendientes'
                                    : 'No hay preguntas',
                                style: TextStyle(
                                    fontSize: 16, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadPreguntas,
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount:
                                _preguntas.length + (_isLoadingMore ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _preguntas.length) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(16),
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                );
                              }
                              final p = _preguntas[index];
                              final respondida = p['respuesta'] != null;

                              return GradientContainer(
                                gradient: respondida
                                    ? AppGradients.green()
                                    : AppGradients.blueWhiteBlue(),
                                borderColor: respondida
                                    ? Colors.green.shade200
                                    : Colors.orange.shade200,
                                borderRadius: BorderRadius.circular(10),
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Producto
                                    Row(
                                      children: [
                                        Icon(Icons.inventory_2,
                                            size: 14, color: Colors.grey[500]),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            p['productoNombre'] ?? '',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[500],
                                              fontWeight: FontWeight.w500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        Text(
                                          _formatDate(p['creadoEn']),
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[400]),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),

                                    // Pregunta
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Icon(Icons.chat_bubble_outline,
                                            size: 16, color: Colors.grey[500]),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(p['pregunta'] ?? '',
                                                  style: const TextStyle(
                                                      fontSize: 14)),
                                              const SizedBox(height: 2),
                                              Text(
                                                p['nombreUsuario'] ?? 'Usuario',
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.grey[400]),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),

                                    // Respuesta o botón
                                    if (respondida) ...[
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(left: 22),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(
                                                Icons
                                                    .subdirectory_arrow_right,
                                                size: 16,
                                                color: Colors.green[600]),
                                            const SizedBox(width: 4),
                                            Expanded(
                                              child: Text(
                                                p['respuesta'],
                                                style: TextStyle(
                                                    fontSize: 14,
                                                    color:
                                                        Colors.grey[700]),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: () =>
                                              _mostrarResponder(p),
                                          icon: const Icon(Icons.reply,
                                              size: 16),
                                          label: const Text('Responder',
                                              style:
                                                  TextStyle(fontSize: 13)),
                                          style: TextButton.styleFrom(
                                            foregroundColor: AppColors.blue1,
                                          ),
                                        ),
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
        ),
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      return DateFormat('dd/MM/yyyy').format(DateTime.parse(dateStr).toLocal());
    } catch (_) {
      return '';
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.15) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : Colors.grey[300]!,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? color : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}

class _ResponderButton extends StatefulWidget {
  final Future<void> Function() onSend;
  final VoidCallback onSuccess;
  final VoidCallback onError;

  const _ResponderButton({required this.onSend, required this.onSuccess, required this.onError});

  @override
  State<_ResponderButton> createState() => _ResponderButtonState();
}

class _ResponderButtonState extends State<_ResponderButton> {
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
        child: Text(_sending ? 'Enviando...' : 'Responder'),
      ),
    );
  }
}
