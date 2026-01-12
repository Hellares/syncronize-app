import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/services/storage_service.dart';
import 'package:video_player/video_player.dart';

/// Widget para gestionar video de producto
///
/// Features:
/// - Selección de video desde galería
/// - Preview del video con controles
/// - Progreso de subida
/// - Manejo de errores con retry
class ProductoVideoManager extends StatefulWidget {
  final String empresaId;
  final String? initialVideoUrl; // URL del video existente (modo edición)
  final Function(String?) onVideoUploaded; // Callback cuando el video se sube
  final StorageService storageService; // Servicio de storage inyectado

  const ProductoVideoManager({
    super.key,
    required this.empresaId,
    this.initialVideoUrl,
    required this.onVideoUploaded,
    required this.storageService,
  });

  @override
  State<ProductoVideoManager> createState() => _ProductoVideoManagerState();
}

class _ProductoVideoManagerState extends State<ProductoVideoManager> {
  late final StorageService _storageService;

  String? _videoUrl; // URL del video subido
  File? _localVideoFile; // Video local (antes de subir)
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  bool _hasError = false;
  String? _errorMessage;
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService;
    _videoUrl = widget.initialVideoUrl;
    if (_videoUrl != null && _videoUrl!.isNotEmpty) {
      _initializeVideoPlayer(_videoUrl!);
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideoPlayer(String url) async {
    _videoController?.dispose();

    if (url.startsWith('http')) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    } else {
      return;
    }

    try {
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error inicializando video player: $e');
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();

    try {
      final XFile? pickedFile = await picker.pickVideo(
        source: ImageSource.gallery,
      );

      if (pickedFile == null) return;

      final file = File(pickedFile.path);

      // Verificar tamaño del archivo (máximo 200MB)
      final fileSizeInBytes = await file.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);

      if (fileSizeInMB > 200) {
        if (!mounted) return;
        _showError('El video es demasiado grande. Máximo 200MB permitidos.');
        return;
      }

      setState(() {
        _localVideoFile = file;
        _hasError = false;
        _errorMessage = null;
      });

      // Inicializar preview del video local
      _videoController?.dispose();
      _videoController = VideoPlayerController.file(file);
      await _videoController!.initialize();
      if (mounted) {
        setState(() {});
      }

      // Subir automáticamente
      await _uploadVideo();
    } catch (e) {
      _showError('Error al seleccionar video: $e');
    }
  }

  Future<void> _uploadVideo() async {
    if (_localVideoFile == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _hasError = false;
    });

    try {
      final response = await _storageService.uploadFile(
        file: _localVideoFile!,
        empresaId: widget.empresaId,
        entidadTipo: 'PRODUCTO',
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _uploadProgress = progress;
            });
          }
        },
      );

      setState(() {
        _videoUrl = response.url;
        _isUploading = false;
        _uploadProgress = 1.0;
      });

      // Notificar que el video se subió
      widget.onVideoUploaded(_videoUrl);

      // Actualizar preview con URL de Cloudinary
      if (_videoUrl != null) {
        await _initializeVideoPlayer(_videoUrl!);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video subido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
        _hasError = true;
        _errorMessage = e.toString();
      });

      _showError('Error al subir video: $e');
    }
  }

  Future<void> _deleteVideo() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar video'),
        content: const Text('¿Estás seguro de eliminar este video?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() {
        _videoUrl = null;
        _localVideoFile = null;
        _hasError = false;
        _errorMessage = null;
      });

      _videoController?.dispose();
      _videoController = null;

      // Notificar que el video se eliminó
      widget.onVideoUploaded(null);
    }
  }

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10, right: 16, left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            _buildContent(),
            if (_hasError) ...[
              const SizedBox(height: 8),
              _buildErrorBanner(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(Icons.videocam, color: AppColors.blue1, size: 16),
        const SizedBox(width: 6),
        AppSubtitle('Video', fontSize: 11),
        const Spacer(),
        if (_videoUrl == null && _localVideoFile == null && !_isUploading)
          IconButton.filled(
            onPressed: _pickVideo,
            icon: const Icon(Icons.add, size: 16),
            style: IconButton.styleFrom(
              backgroundColor: AppColors.blue1,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.all(8),
              minimumSize: const Size(30, 30),
            ),
            tooltip: 'Agregar video',
          ),
      ],
    );
  }

  Widget _buildContent() {
    // Si está subiendo
    if (_isUploading) {
      return _buildUploadingState();
    }

    // Si hay video (local o remoto)
    if (_videoUrl != null || _localVideoFile != null) {
      return _buildVideoPreview();
    }

    // Estado vacío
    return _buildEmptyState();
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.grey.shade50,
            Colors.grey.shade100,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam,
              size: 28,
              color: AppColors.blue1.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin video',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Agrega un video de tu producto',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadingState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        children: [
          CircularProgressIndicator(
            value: _uploadProgress,
            color: AppColors.blue1,
          ),
          const SizedBox(height: 12),
          Text(
            'Subiendo video... ${(_uploadProgress * 100).toInt()}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blue[900],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPreview() {
    return Stack(
      children: [
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _videoController != null && _videoController!.value.isInitialized
                ? Stack(
                    fit: StackFit.expand,
                    children: [
                      Center(
                        child: AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                      ),
                      // Controles de play/pause
                      Center(
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              if (_videoController!.value.isPlaying) {
                                _videoController!.pause();
                              } else {
                                _videoController!.play();
                              }
                            });
                          },
                          icon: Icon(
                            _videoController!.value.isPlaying
                                ? Icons.pause_circle_filled
                                : Icons.play_circle_filled,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.videocam,
                          size: 48,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cargando video...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ),
        // Botón de eliminar
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _deleteVideo,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
        // Badge de video local
        if (_localVideoFile != null && _videoUrl == null && !_isUploading)
          Positioned(
            bottom: 8,
            left: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_upload, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Listo para subir',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
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

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.warning, color: Colors.red[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Error al subir video',
                  style: TextStyle(
                    color: Colors.red[900],
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_errorMessage != null)
                  Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Colors.red[800],
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          TextButton(
            onPressed: _uploadVideo,
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
