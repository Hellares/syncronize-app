import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'producto_video_fullscreen.dart';
import 'video_http_headers.dart';

/// Mini-reproductor flotante (estilo Temu) que auto-reproduce el video del
/// producto en silencio y en loop. Al tocarlo abre el video a pantalla
/// completa con sonido; el botón ✕ lo descarta.
class ProductoVideoFloating extends StatefulWidget {
  final String videoUrl;

  /// Poster (thumbnail) a mostrar mientras el video inicializa.
  final String? posterUrl;
  final VoidCallback? onClose;

  /// Dimensiones del mini-player (expuestas para que el contenedor que lo
  /// hace arrastrable pueda calcular los límites de la pantalla).
  static const double width = 90;
  static const double height = 130;

  const ProductoVideoFloating({
    super.key,
    required this.videoUrl,
    this.posterUrl,
    this.onClose,
  });

  @override
  State<ProductoVideoFloating> createState() => _ProductoVideoFloatingState();
}

class _ProductoVideoFloatingState extends State<ProductoVideoFloating>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _failed = false;

  /// True mientras el fullscreen (que comparte este controlador) está abierto.
  /// Evita que el handler de ciclo de vida del mini pelee con el del fullscreen
  /// por el volumen/reproducción al volver de segundo plano.
  bool _inFullscreen = false;

  static const double _w = ProductoVideoFloating.width;
  static const double _h = ProductoVideoFloating.height;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    try {
      final headers = await videoAuthHeaders(widget.videoUrl);
      final c = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
        httpHeaders: headers,
      );
      _controller = c;
      await c.initialize();
      await c.setVolume(0); // mini siempre muteado
      await c.setLooping(true);
      await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (e) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready) return;
    // Mientras el fullscreen está abierto, él gobierna el controlador compartido.
    if (_inFullscreen) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller?.setVolume(0);
      _controller?.play();
    }
  }

  Future<void> _openFullscreen() async {
    final c = _controller;
    if (!mounted) return;
    // Comparte el mismo controlador (no re-descarga): el fullscreen lo reusa,
    // sube el volumen y, al cerrarse, lo deja muteado para el mini.
    _inFullscreen = true;
    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ProductoVideoFullscreen(
          videoUrl: widget.videoUrl,
          sharedController: c,
          startAt: c?.value.position,
          posterUrl: widget.posterUrl,
        ),
      ),
    );
    _inFullscreen = false;
    // Al volver, el mini sigue muteado y en loop.
    if (!mounted) return;
    await _controller?.setVolume(0);
    await _controller?.play();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) return const SizedBox.shrink();

    return SizedBox(
      width: _w,
      height: _h,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              const ColoredBox(color: Colors.black),

              // Poster mientras el video carga (sensación de carga instantánea).
              if (!_ready &&
                  widget.posterUrl != null &&
                  widget.posterUrl!.isNotEmpty)
                Positioned.fill(
                  child: CachedNetworkImage(
                    imageUrl: widget.posterUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => const SizedBox.shrink(),
                    errorWidget: (_, __, ___) => const SizedBox.shrink(),
                  ),
                ),

              // Video recortado tipo "cover"
              if (_ready && _controller != null)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _controller!.value.size.width,
                    height: _controller!.value.size.height,
                    child: VideoPlayer(_controller!),
                  ),
                )
              else
                const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      color: Colors.white70,
                    ),
                  ),
                ),

              // Capa táctil → fullscreen
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(onTap: _openFullscreen),
                ),
              ),

              // Etiqueta "Video"
              // Positioned(
              //   left: 6,
              //   bottom: 6,
              //   child: Container(
              //     padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              //     decoration: BoxDecoration(
              //       color: Colors.black.withValues(alpha: 0.55),
              //       borderRadius: BorderRadius.circular(6),
              //     ),
              //     child: const Row(
              //       mainAxisSize: MainAxisSize.min,
              //       children: [
              //         Icon(Icons.play_arrow_rounded, size: 11, color: Colors.white),
              //         SizedBox(width: 2),
              //         Text(
              //           'Video',
              //           style: TextStyle(
              //             fontSize: 8,
              //             color: Colors.white,
              //             fontWeight: FontWeight.w600,
              //           ),
              //         ),
              //       ],
              //     ),
              //   ),
              // ),

              // Indicador de muteado / expandir
              // Positioned(
              //   right: 6,
              //   bottom: 6,
              //   child: Container(
              //     padding: const EdgeInsets.all(3),
              //     decoration: BoxDecoration(
              //       color: Colors.black.withValues(alpha: 0.55),
              //       shape: BoxShape.circle,
              //     ),
              //     child: const Icon(Icons.volume_off_rounded, size: 12, color: Colors.white),
              //   ),
              // ),

              // Botón cerrar
              if (widget.onClose != null)
                Positioned(
                  right: 2,
                  top: 2,
                  child: GestureDetector(
                    onTap: widget.onClose,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close_rounded, size: 13, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
