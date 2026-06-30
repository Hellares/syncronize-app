import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'cached_video_controller.dart';

/// Reproductor de video del producto a pantalla completa, con sonido y
/// controles (play/pausa, barra de progreso). Se abre desde el mini-player
/// flotante [ProductoVideoFloating].
class ProductoVideoFullscreen extends StatefulWidget {
  final String videoUrl;

  /// Posición desde la que continuar (la del mini-player al expandir).
  final Duration? startAt;

  /// Controlador del mini-player a reusar (evita re-descargar el video). Si es
  /// null o no está inicializado, el fullscreen crea el suyo desde la red.
  final VideoPlayerController? sharedController;

  /// Poster (thumbnail) a mostrar mientras el video carga.
  final String? posterUrl;

  const ProductoVideoFullscreen({
    super.key,
    required this.videoUrl,
    this.startAt,
    this.sharedController,
    this.posterUrl,
  });

  @override
  State<ProductoVideoFullscreen> createState() =>
      _ProductoVideoFullscreenState();
}

class _ProductoVideoFullscreenState extends State<ProductoVideoFullscreen>
    with WidgetsBindingObserver {
  VideoPlayerController? _controller;
  bool _ready = false;
  bool _showControls = true;

  /// True solo si este widget creó el controlador (fallback). En ese caso lo
  /// libera al salir; si es compartido con el mini, NO lo dispone.
  bool _ownsController = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  Future<void> _init() async {
    // Reusar el controlador del mini si vino inicializado.
    final shared = widget.sharedController;
    if (shared != null && shared.value.isInitialized) {
      _controller = shared;
      _ownsController = false;
      await shared.setVolume(1);
      await shared.setLooping(true);
      await shared.play();
      if (mounted) setState(() => _ready = true);
      return;
    }

    // Fallback: crear un controlador propio (cache-first: archivo local si ya
    // está cacheado, si no red + cachea para la próxima).
    _ownsController = true;
    final c = await buildCachedVideoController(widget.videoUrl);
    _controller = c;
    try {
      await c.initialize();
      if (widget.startAt != null) await c.seekTo(widget.startAt!);
      await c.setVolume(1);
      await c.setLooping(true);
      await c.play();
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_ownsController) {
      _controller?.dispose();
    } else {
      // Controlador compartido: lo dejamos muteado para el mini al volver.
      _controller?.setVolume(0);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final c = _controller;
    if (c == null || !_ready) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      c.pause();
    } else if (state == AppLifecycleState.resumed) {
      c.setVolume(1);
      c.play();
    }
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    // El AnimatedBuilder sobre el controlador refresca los controles; no hace
    // falta setState aquí.
    c.value.isPlaying ? c.pause() : c.play();
  }

  @override
  Widget build(BuildContext context) {
    final c = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Poster mientras el video carga (sensación de carga instantánea).
            if (!_ready &&
                widget.posterUrl != null &&
                widget.posterUrl!.isNotEmpty)
              Positioned.fill(
                child: CachedNetworkImage(
                  imageUrl: widget.posterUrl!,
                  fit: BoxFit.contain,
                  placeholder: (_, __) => const SizedBox.shrink(),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            Center(
              child: _ready && c != null
                  ? AspectRatio(
                      aspectRatio:
                          c.value.aspectRatio == 0 ? 16 / 9 : c.value.aspectRatio,
                      child: VideoPlayer(c),
                    )
                  : const CircularProgressIndicator(color: Colors.white),
            ),

            // Controles centrales y barra de progreso. El AnimatedBuilder
            // escucha al controlador y reconstruye SOLO este subárbol por tick
            // (no todo el Scaffold ni el VideoPlayer).
            if (_showControls && _ready && c != null)
              AnimatedBuilder(
                animation: c,
                builder: (context, _) => Stack(
                  children: [
                    Center(
                      child: GestureDetector(
                        onTap: _togglePlay,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.45),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            c.value.isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            size: 44,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 28,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VideoProgressIndicator(
                            c,
                            allowScrubbing: true,
                            colors: const VideoProgressColors(
                              playedColor: Colors.white,
                              bufferedColor: Colors.white38,
                              backgroundColor: Colors.white24,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _fmt(c.value.position),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                              Text(
                                _fmt(c.value.duration),
                                style: const TextStyle(
                                    color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

            // Cerrar (siempre visible)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 12,
              child: GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
