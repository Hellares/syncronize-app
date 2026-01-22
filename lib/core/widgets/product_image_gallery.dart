// lib/features/product/presentation/widgets/product_image_gallery.dart

import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/utils/video_url_helper.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';

class ProductImageGallery extends StatefulWidget {
  /// La lista de URLs de las imágenes a mostrar.
  final List<String> images;

  /// URL del video (opcional). Si se proporciona, aparecerá primero en el slider.
  final String? videoUrl;

  /// La altura fija del carrusel de imágenes.
  /// Si es null, usará el 40% de la altura de la pantalla.
  final double? height;

  /// El border radius para las esquinas del carrusel.
  final BorderRadius borderRadius;

  /// Un tag único para la animación Hero.
  /// Si se proporciona, la imagen al tocarla hará una transición suave
  /// a la vista de pantalla completa.
  final String? heroTag;

  const ProductImageGallery({
    super.key,
    required this.images,
    this.videoUrl,
    this.height,
    this.borderRadius = const BorderRadius.all(Radius.circular(0)),
    this.heroTag,
  });

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late final PageController _pageController;
  late final ValueNotifier<int> _imageIndexNotifier;
  int _currentImageIndex = 0;

  // Controladores para diferentes tipos de video
  VideoPlayerController? _videoController;
  YoutubePlayerController? _youtubeController;
  WebViewController? _webViewController;

  bool _isVideoInitialized = false;
  String? _videoType;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _imageIndexNotifier = ValueNotifier<int>(_currentImageIndex);
    _initializeVideo();
  }

  void _initializeVideo() {
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      // debugPrint('🎬 Iniciando video: ${widget.videoUrl}');

      // Detectar el tipo de video
      _videoType = VideoUrlHelper.detectVideoType(widget.videoUrl!);
      // debugPrint('🎬 Tipo de video detectado: $_videoType');

      try {
        switch (_videoType) {
          case VideoUrlHelper.youtube:
            _initializeYouTubePlayer();
            break;

          case VideoUrlHelper.direct:
            _initializeDirectVideoPlayer();
            break;

          default:
            // Facebook, Vimeo, Instagram, TikTok, etc.
            _initializeWebViewPlayer();
            break;
        }
      } catch (e) {
        debugPrint('❌ Error al inicializar video: $e');
      }
    } else {
      debugPrint('⚠️ No hay videoUrl o está vacío: ${widget.videoUrl}');
    }
  }

  void _initializeYouTubePlayer() {
    final videoId = VideoUrlHelper.extractYoutubeId(widget.videoUrl!);
    if (videoId == null) {
      debugPrint('❌ No se pudo extraer el ID de YouTube');
      return;
    }

    // debugPrint('✅ YouTube ID extraído: $videoId');

    _youtubeController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,  // ← Inicia en mute, el usuario puede activar audio con los controles
        loop: true,
        hideControls: false,
        controlsVisibleAtStart: true,
        enableCaption: false,
      ),
    );

    setState(() {
      _isVideoInitialized = true;
    });
  }

  void _initializeDirectVideoPlayer() {
    final uri = Uri.parse(widget.videoUrl!);
    debugPrint('🎬 Inicializando video directo: $uri');

    _videoController = VideoPlayerController.networkUrl(uri)
      ..initialize().then((_) {
        if (mounted) {
          debugPrint('✅ Video directo inicializado');
          debugPrint('📐 Aspect ratio: ${_videoController!.value.aspectRatio}');

          setState(() {
            _isVideoInitialized = true;
          });

          _videoController?.setLooping(true);
          _videoController?.setVolume(0.0);  // ← Inicia en mute
          _videoController?.play();
        }
      }).catchError((error) {
        debugPrint('❌ Error al cargar video directo: $error');
      });
  }

  void _initializeWebViewPlayer() {
    // debugPrint('🎬 Inicializando WebView para: $_videoType');

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..loadRequest(
        Uri.parse(VideoUrlHelper.getWebViewUrl(widget.videoUrl!, _videoType!)),
      );

    setState(() {
      _isVideoInitialized = true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _imageIndexNotifier.dispose();
    _videoController?.dispose();
    _youtubeController?.dispose();
    // _webViewController no necesita dispose
    super.dispose();
  }

  // Obtiene la lista total de medios (video + imágenes)
  int get _totalMediaCount {
    int count = widget.images.length;
    if (widget.videoUrl != null && widget.videoUrl!.isNotEmpty) {
      count++;
    }
    return count;
  }

  // Verifica si el índice actual es el video
  bool _isVideoIndex(int index) {
    return widget.videoUrl != null && widget.videoUrl!.isNotEmpty && index == 0;
  }

  void _openImagePreview(String url, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            _ImagePreviewDialog(
              imageUrl: url,
              index: index,
              total: widget.images.length,
              // Usamos el mismo heroTag para la animación inversa
              heroTag: widget.heroTag != null ? '${widget.heroTag}_$index' : null,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          // Una transición de desvanecimiento suave
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imagenes = widget.images;
    final totalCount = _totalMediaCount;

    // Calcula la altura: usa el 40% de la pantalla si no se especificó una altura
    final screenHeight = MediaQuery.of(context).size.height;
    final galleryHeight = widget.height ?? (screenHeight * 0.4);

    // Si no hay imágenes ni video, muestra un placeholder
    if (totalCount == 0) {
      return GradientContainer(
        borderRadius: widget.borderRadius,
        height: galleryHeight,
        shadowStyle: ShadowStyle.none,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 80,
                color: AppColors.blue1.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              AppSubtitle(
                'Sin imágenes',
                color: AppColors.blue1.withValues(alpha: 0.5),
                fontSize: 14,
              ),
            ],
          ),
        ),
      );
    }

    // Asegura que el índice sea válido
    final maxIndex = totalCount - 1;
    final safeIndex = _currentImageIndex.clamp(0, maxIndex);
    if (safeIndex != _currentImageIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _pageController.hasClients) {
          _pageController.jumpToPage(safeIndex);
        }
      });
    }

    return Column(
      children: [
        GradientContainer(
          height: galleryHeight,
          shadowStyle: ShadowStyle.colorful,
          gradient: AppGradients.blueWhiteBlue(),
          borderRadius: widget.borderRadius,
          child: ClipRRect(
            borderRadius: widget.borderRadius,
            child: PageView.builder(
              key: const PageStorageKey('producto_image_gallery'),
              controller: _pageController,
              itemCount: totalCount,
              onPageChanged: (index) {
                _currentImageIndex = index;
                _imageIndexNotifier.value = index;

                // Control de reproducción del video según el tipo
                if (_isVideoIndex(index)) {
                  // Reproducir el video al volver a él
                  _videoController?.play();
                  _youtubeController?.play();
                } else {
                  // Pausar el video al cambiar a otra página
                  _videoController?.pause();
                  _youtubeController?.pause();
                }

                // Precarga la siguiente imagen (si no es video)
                final hasVideo = widget.videoUrl != null && widget.videoUrl!.isNotEmpty;
                if (!_isVideoIndex(index + 1) && index + 1 < totalCount) {
                  final imageIndex = hasVideo ? index : index + 1;
                  if (imageIndex >= 0 && imageIndex < imagenes.length) {
                    precacheImage(NetworkImage(imagenes[imageIndex]), context);
                  }
                }
              },
              itemBuilder: (context, index) {
                // Si es el primer índice y hay video, muestra el video
                if (_isVideoIndex(index)) {
                  return _buildVideoPlayer();
                }

                // Ajusta el índice de la imagen si hay video
                final hasVideo = widget.videoUrl != null && widget.videoUrl!.isNotEmpty;
                final imageIndex = hasVideo ? index - 1 : index;

                // Validar que el índice sea válido
                if (imageIndex < 0 || imageIndex >= imagenes.length) {
                  return const SizedBox.shrink();
                }

                final url = imagenes[imageIndex];
                final tag = widget.heroTag != null ? '${widget.heroTag}_$imageIndex' : null;

                return _buildImageItem(url, imageIndex, tag);
              },
            ),
          ),
        ),
        if (totalCount > 1) ...[
          const SizedBox(height: 12),
          ValueListenableBuilder<int>(
            valueListenable: _imageIndexNotifier,
            builder: (context, current, _) {
              if (totalCount > 8) {
                return AppSubtitle(
                  '${current + 1}/$totalCount',
                  color: AppColors.blueborder.withValues(alpha: 0.85),
                  fontSize: 12,
                );
              }
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(totalCount, (i) {
                  return GestureDetector(
                    onTap: () => _pageController.animateToPage(i, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: current == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: current == i ? AppColors.blueborder : AppColors.blueborder.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildVideoPlayer() {
    if (!_isVideoInitialized) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    // Construir el reproductor según el tipo
    switch (_videoType) {
      case VideoUrlHelper.youtube:
        return _buildYouTubePlayer();

      case VideoUrlHelper.direct:
        return _buildDirectVideoPlayer();

      default:
        return _buildWebViewPlayer();
    }
  }

  Widget _buildYouTubePlayer() {
    if (_youtubeController == null) {
      return const Center(child: CircularProgressIndicator());
    }


    return Stack(
    fit: StackFit.expand,
    children: [
      // Video ocupa todo el espacio disponible
      Center(
        child: YoutubePlayer(
          controller: _youtubeController!,
          showVideoProgressIndicator: true,
          progressIndicatorColor: AppColors.red,
          progressColors: ProgressBarColors(
            playedColor: AppColors.red,
            handleColor: AppColors.red,
          ),
          aspectRatio: 16 / 9,
          width: double.infinity,
        ),
      ),
      // Indicador de YouTube
      Positioned(
        top: 12,
        right: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_filled, size: 14, color: Colors.red),
              SizedBox(width: 4),
              Text(
                'YouTube',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
  }

  Widget _buildDirectVideoPlayer() {
    if (_videoController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // Video ocupa todo el espacio con cover
        SizedBox.expand(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _videoController!.value.size.width,
              height: _videoController!.value.size.height,
              child: VideoPlayer(_videoController!),
            ),
          ),
        ),
        // Overlay con controles de play/pause
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              setState(() {
                if (_videoController!.value.isPlaying) {
                  _videoController!.pause();
                } else {
                  _videoController!.play();
                }
              });
            },
            child: Container(
              color: Colors.transparent,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _videoController!.value.isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow,
                      size: 48,
                      color: Colors.red,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        // Botón de mute/unmute
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                final isMuted = _videoController!.value.volume == 0.0;
                _videoController!.setVolume(isMuted ? 1.0 : 0.0);
              });
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _videoController!.value.volume == 0.0
                    ? Icons.volume_off
                    : Icons.volume_up,
                size: 20,
                color: Colors.red,
              ),
            ),
          ),
        ),
        // Indicador de video
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.videocam, size: 14, color: Colors.red),
                SizedBox(width: 4),
                Text(
                  'Video',
                  style: TextStyle(color: Colors.red, fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWebViewPlayer() {
    if (_webViewController == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        WebViewWidget(controller: _webViewController!),
        // Indicador según el tipo
        Positioned(
          top: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getWebViewBadgeColor(),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_getWebViewIcon(), size: 14, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _getWebViewLabel(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getWebViewBadgeColor() {
    switch (_videoType) {
      case VideoUrlHelper.facebook:
        return const Color(0xFF1877F2);
      case VideoUrlHelper.vimeo:
        return const Color(0xFF1AB7EA);
      case VideoUrlHelper.instagram:
        return const Color(0xFFE1306C);
      case VideoUrlHelper.tiktok:
        return Colors.black;
      default:
        return Colors.blue;
    }
  }

  IconData _getWebViewIcon() {
    switch (_videoType) {
      case VideoUrlHelper.facebook:
      case VideoUrlHelper.instagram:
        return Icons.public;
      default:
        return Icons.play_circle_filled;
    }
  }

  String _getWebViewLabel() {
    switch (_videoType) {
      case VideoUrlHelper.facebook:
        return 'Facebook';
      case VideoUrlHelper.vimeo:
        return 'Vimeo';
      case VideoUrlHelper.instagram:
        return 'Instagram';
      case VideoUrlHelper.tiktok:
        return 'TikTok';
      default:
        return 'Web';
    }
  }

  Widget _buildImageItem(String url, int imageIndex, String? tag) {
    return Semantics(
      label: 'Imagen ${imageIndex + 1} de ${widget.images.length}',
      child: InkWell(
        onTap: () => _openImagePreview(url, imageIndex),
        child: Hero(
          tag: tag ?? imageIndex,
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              final value = progress.expectedTotalBytes != null
                  ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                  : null;
              return Container(
                color: Colors.white.withValues(alpha: 0.35),
                alignment: Alignment.center,
                child: SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(value: value),
                ),
              );
            },
            frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
              if (wasSynchronouslyLoaded) return child;
              return AnimatedOpacity(
                opacity: frame == null ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: child,
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image_outlined, size: 64, color: Colors.grey[500]),
                    const SizedBox(height: 8),
                    AppSubtitle('No se pudo cargar', color: Colors.grey[700], fontSize: 12),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (_pageController.hasClients) {
                          _pageController.jumpToPage(_currentImageIndex);
                        }
                      },
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// Widget para el diálogo de vista previa en pantalla completa
class _ImagePreviewDialog extends StatelessWidget {
  final String imageUrl;
  final int index;
  final int total;
  final String? heroTag;

  const _ImagePreviewDialog({
    required this.imageUrl,
    required this.index,
    required this.total,
    this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo oscuro semitransparente
          Container(color: Colors.black.withValues(alpha: 0.9)),

          // Imagen con zoom
          Center(
            child: Hero(
              tag: heroTag ?? index,
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: const EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.network(imageUrl, fit: BoxFit.contain),
              ),
            ),
          ),

          // Contador de imágenes
          Positioned(
            top: 50,
            left: 20,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${index + 1}/$total',
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),

          // Botón de cerrar
          Positioned(
            top: 50,
            right: 20,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.red, size: 30),
              style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.5)),
            ),
          ),
        ],
      ),
    );
  }
}