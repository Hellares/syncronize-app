import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_container.dart';

class MensajesOrdenWidget extends StatefulWidget {
  final String? ordenId;
  final String? citaId;
  final bool esCliente;

  /// Notifier global para refrescar mensajes desde push notifications
  static final refreshNotifier = ValueNotifier<int>(0);
  static void triggerRefresh() => refreshNotifier.value++;

  const MensajesOrdenWidget({
    super.key,
    this.ordenId,
    this.citaId,
    required this.esCliente,
  }) : assert(ordenId != null || citaId != null);

  @override
  State<MensajesOrdenWidget> createState() => _MensajesOrdenWidgetState();
}

class _MensajesOrdenWidgetState extends State<MensajesOrdenWidget> {
  final _dio = locator<DioClient>();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  List<dynamic> _mensajes = [];
  bool _isLoading = true;
  bool _isSending = false;

  String get _basePath {
    if (widget.citaId != null) {
      return widget.esCliente
          ? '${ApiConstants.citas}/mis-citas/${widget.citaId}/mensajes'
          : '${ApiConstants.citas}/${widget.citaId}/mensajes';
    }
    return widget.esCliente
        ? '${ApiConstants.ordenesServicio}/mis-ordenes/${widget.ordenId}/mensajes'
        : '${ApiConstants.ordenesServicio}/${widget.ordenId}/mensajes';
  }

  @override
  void initState() {
    super.initState();
    _loadMensajes();
    MensajesOrdenWidget.refreshNotifier.addListener(_onPushRefresh);
  }

  void _onPushRefresh() {
    _loadMensajes();
  }

  @override
  void dispose() {
    MensajesOrdenWidget.refreshNotifier.removeListener(_onPushRefresh);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadMensajes() async {
    try {
      final response = await _dio.get(_basePath);
      if (mounted) {
        setState(() {
          _mensajes = response.data as List;
          _isLoading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enviarMensaje() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _controller.clear();

    try {
      final response = await _dio.post(_basePath, data: {'contenido': texto});
      if (mounted) {
        setState(() {
          _mensajes.add(response.data);
          _isSending = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        _controller.text = texto;
        setState(() => _isSending = false);
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      borderRadius: BorderRadius.circular(12),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.chat_bubble_outline, size: 18, color: AppColors.blue1),
              const SizedBox(width: 6),
              const Text('Mensajes',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              const Spacer(),
              InkWell(
                onTap: _loadMensajes,
                child: Icon(Icons.refresh, size: 18, color: Colors.grey[500]),
              ),
            ],
          ),
          const Divider(),

          // Messages list
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            )
          else if (_mensajes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.forum_outlined, size: 32, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    Text(
                      'No hay mensajes aún',
                      style: TextStyle(fontSize: 13, color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.esCliente
                          ? 'Escribe para comunicarte con el técnico'
                          : 'Escribe para comunicarte con el cliente',
                      style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 350),
              child: ListView.builder(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: _mensajes.length,
                itemBuilder: (context, index) {
                  final msg = _mensajes[index];
                  final esMio = widget.esCliente
                      ? (msg['esCliente'] == true)
                      : (msg['esCliente'] == false);
                  return _MessageBubble(
                    mensaje: msg,
                    esMio: esMio,
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Input
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Escribe un mensaje...',
                    hintStyle: TextStyle(fontSize: 12, color: Colors.grey[400]),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: AppColors.blue1),
                    ),
                  ),
                  maxLines: 3,
                  minLines: 1,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _enviarMensaje(),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.blue1,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: _isSending ? null : _enviarMensaje,
                  icon: _isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  color: Colors.white,
                  constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final dynamic mensaje;
  final bool esMio;

  const _MessageBubble({required this.mensaje, required this.esMio});

  @override
  Widget build(BuildContext context) {
    final contenido = mensaje['contenido'] as String? ?? '';
    final creadoEn = mensaje['creadoEn'] as String?;
    final usuario = mensaje['usuario'] as Map<String, dynamic>?;
    final persona = usuario?['persona'] as Map<String, dynamic>?;
    final nombre = persona != null
        ? '${persona['nombres'] ?? ''}'.trim()
        : '';

    String hora = '';
    if (creadoEn != null) {
      try {
        final date = DateTime.parse(creadoEn).toLocal();
        hora = DateFormat('dd/MM HH:mm').format(date);
      } catch (_) {}
    }

    return Align(
      alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: esMio
              ? AppColors.blue1.withValues(alpha: 0.1)
              : Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(12),
            topRight: const Radius.circular(12),
            bottomLeft: esMio ? const Radius.circular(12) : Radius.zero,
            bottomRight: esMio ? Radius.zero : const Radius.circular(12),
          ),
          border: Border.all(
            color: esMio
                ? AppColors.blue1.withValues(alpha: 0.2)
                : Colors.grey.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment:
              esMio ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            if (nombre.isNotEmpty)
              Text(
                nombre,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: esMio ? AppColors.blue1 : Colors.grey[600],
                ),
              ),
            const SizedBox(height: 2),
            Text(contenido, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              hora,
              style: TextStyle(fontSize: 10, color: Colors.grey[400]),
            ),
          ],
        ),
      ),
    );
  }
}
