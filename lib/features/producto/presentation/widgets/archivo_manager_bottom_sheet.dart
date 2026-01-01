import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncronize/core/services/storage_service.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

import '../../../../core/fonts/app_text_widgets.dart';

/// Bottom Sheet para gestionar archivos de una entidad (producto o variante)
/// Permite subir imágenes (cámara/galería) y PDFs directamente
class ArchivoManagerBottomSheet extends StatefulWidget {
  final String entidadId;
  final String entidadNombre;
  final String entidadTipo; // 'PRODUCTO' o 'PRODUCTO_VARIANTE'
  final String empresaId;
  final StorageService storageService;
  final List<ArchivoItem> archivosExistentes;

  const ArchivoManagerBottomSheet({
    super.key,
    required this.entidadId,
    required this.entidadNombre,
    required this.entidadTipo,
    required this.empresaId,
    required this.storageService,
    this.archivosExistentes = const [],
  });

  @override
  State<ArchivoManagerBottomSheet> createState() => _ArchivoManagerBottomSheetState();
}

class _ArchivoManagerBottomSheetState extends State<ArchivoManagerBottomSheet> {
  static const int _maxArchivos = 10;

  late final StorageService _storageService;
  final List<ArchivoItem> _archivos = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  DateTime _lastProgressUpdate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _storageService = widget.storageService;
    // Cargar archivos existentes
    _archivos.addAll(widget.archivosExistentes);
  }

  @override
  Widget build(BuildContext context) {
    final hasLocalFiles = _archivos.any((a) => a.isLocal);
    final localFilesCount = _archivos.where((a) => a.isLocal).length;
    final isLimitReached = _archivos.length >= _maxArchivos;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Header
          _buildHeader(context),

          const Divider(height: 1),

          // Botones de acción
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(child: _buildActionButton(
                  icon: Icons.camera_alt,
                  label: 'Cámara',
                  color: Colors.blue,
                  onTap: (_isUploading || isLimitReached) ? null : () => _pickFromCamera(),
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton(
                  icon: Icons.photo_library,
                  label: 'Galería',
                  color: Colors.green,
                  onTap: (_isUploading || isLimitReached) ? null : () => _pickFromGallery(),
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildActionButton(
                  icon: Icons.picture_as_pdf,
                  label: 'PDF',
                  color: Colors.red,
                  onTap: (_isUploading || isLimitReached) ? null : () => _pickPDF(),
                )),
              ],
            ),
          ),

          // Contador de archivos
          if (_archivos.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.attach_file, size: 14, color: Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${_archivos.length}/$_maxArchivos archivo${_archivos.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 9,
                      color: isLimitReached ? Colors.red[700] : Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (hasLocalFiles) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_upload, size: 10, color: Colors.orange[700]),
                          const SizedBox(width: 4),
                          Text(
                            '$localFilesCount pendiente${localFilesCount > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

          // Mensaje de límite alcanzado
          if (isLimitReached)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 16, color: Colors.red[700]),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Límite alcanzado. Elimina archivos para agregar más.',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Grid de archivos
          Expanded(
            child: _archivos.isEmpty
                ? _buildEmptyState()
                : _buildArchivosGrid(),
          ),

          // Botón de subir (solo si hay archivos locales)
          if (hasLocalFiles && !_isUploading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _uploadLocalFiles,
                  icon: const Icon(Icons.cloud_upload),
                  label: Text('Subir $localFilesCount archivo${localFilesCount > 1 ? 's' : ''}'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue1,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ),

          // Indicador de subida
          if (_isUploading)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  LinearProgressIndicator(
                    value: _uploadProgress,
                    backgroundColor: Colors.grey[200],
                    color: AppColors.blue1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Subiendo archivos... ${(_uploadProgress * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16, left: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.blue1.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.folder_open, color: AppColors.blue1, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSubtitle(
                  'GESTIONAR ARCHIVOS',
                ),
                Text(
                  widget.entidadNombre,
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close, size: 19,),
            tooltip: 'Cerrar',
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final isEnabled = onTap != null;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: isEnabled ? color.withValues(alpha: 0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isEnabled ? color.withValues(alpha: 0.3) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isEnabled ? color : Colors.grey[400],
              size: 18,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isEnabled ? color : Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_upload_outlined,
            size: 64,
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Sin archivos',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecciona archivos usando\nlos botones de arriba',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildArchivosGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: _archivos.length,
      itemBuilder: (context, index) {
        return _buildArchivoItem(_archivos[index], index);
      },
    );
  }

  Widget _buildArchivoItem(ArchivoItem archivo, int index) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Thumbnail/Preview con tap para visualizar
        GestureDetector(
          onTap: archivo.tipoArchivo == TipoArchivo.imagen
              ? () => _showImageViewer(archivo)
              : null,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: archivo.isLocal
                    ? Colors.orange.withValues(alpha: 0.5)
                    : Colors.grey[300]!,
                width: archivo.isLocal ? 2 : 1,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(11),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildThumbnail(archivo),
                  // Overlay sutil para imágenes (indica que es clickeable)
                  if (archivo.tipoArchivo == TipoArchivo.imagen)
                    Positioned.fill(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _showImageViewer(archivo),
                          borderRadius: BorderRadius.circular(11),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(11),
                              color: Colors.black.withValues(alpha: 0.0),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 32,
                                shadows: [
                                  Shadow(
                                    color: Colors.black54,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Badge de tipo/estado
        Positioned(
          top: 6,
          left: 6,
          child: _buildBadge(archivo),
        ),

        // Badge de orden
        if (!archivo.isLocal)
          Positioned(
            bottom: 6,
            right: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '#${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Botón eliminar
        Positioned(
          top: 6,
          right: 6,
          child: GestureDetector(
            onTap: () => _confirmDelete(archivo),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.9),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(ArchivoItem archivo) {
    if (archivo.tipoArchivo == TipoArchivo.imagen) {
      if (archivo.file != null) {
        // Imagen local
        return Image.file(
          archivo.file!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(archivo),
        );
      } else if (archivo.urlThumbnail != null || archivo.url != null) {
        // Imagen del servidor
        return Image.network(
          archivo.urlThumbnail ?? archivo.url!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) => _buildPlaceholder(archivo),
        );
      }
    }

    return _buildPlaceholder(archivo);
  }

  Widget _buildPlaceholder(ArchivoItem archivo) {
    IconData icon;
    Color color;

    switch (archivo.tipoArchivo) {
      case TipoArchivo.pdf:
        icon = Icons.picture_as_pdf;
        color = Colors.red;
        break;
      case TipoArchivo.imagen:
        icon = Icons.image;
        color = Colors.blue;
        break;
      default:
        icon = Icons.insert_drive_file;
        color = Colors.grey;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          if (archivo.nombreOriginal != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                archivo.nombreOriginal!,
                style: const TextStyle(fontSize: 8),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(ArchivoItem archivo) {
    String label;
    Color backgroundColor;
    IconData icon;

    if (archivo.isLocal) {
      label = 'Local';
      backgroundColor = Colors.orange;
      icon = Icons.cloud_upload;
    } else {
      switch (archivo.tipoArchivo) {
        case TipoArchivo.pdf:
          label = 'PDF';
          backgroundColor = Colors.red;
          icon = Icons.picture_as_pdf;
          break;
        case TipoArchivo.imagen:
          label = 'IMG';
          backgroundColor = Colors.blue;
          icon = Icons.image;
          break;
        default:
          label = 'FILE';
          backgroundColor = Colors.grey;
          icon = Icons.insert_drive_file;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 8),
          const SizedBox(width: 3),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // Métodos de selección de archivos
  Future<void> _pickFromCamera() async {
    if (_archivos.length >= _maxArchivos) {
      _showError('Ya alcanzaste el límite de $_maxArchivos archivos');
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _archivos.add(ArchivoItem(
            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
            file: File(photo.path),
            nombreOriginal: photo.name,
            tipoArchivo: TipoArchivo.imagen,
            isLocal: true,
          ));
        });
      }
    } catch (e) {
      _showError('Error al tomar foto: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    if (_archivos.length >= _maxArchivos) {
      _showError('Ya alcanzaste el límite de $_maxArchivos archivos');
      return;
    }

    try {
      final picker = ImagePicker();
      final List<XFile> photos = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (photos.isNotEmpty) {
        final espacioDisponible = _maxArchivos - _archivos.length;
        final fotosAgregar = photos.take(espacioDisponible).toList();

        if (photos.length > espacioDisponible) {
          _showError('Solo se agregaron $espacioDisponible de ${photos.length} imágenes (límite: $_maxArchivos)');
        }

        setState(() {
          for (int i = 0; i < fotosAgregar.length; i++) {
            final photo = fotosAgregar[i];
            _archivos.add(ArchivoItem(
              id: 'local_${DateTime.now().millisecondsSinceEpoch}_$i',
              file: File(photo.path),
              nombreOriginal: photo.name,
              tipoArchivo: TipoArchivo.imagen,
              isLocal: true,
            ));
          }
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imágenes: $e');
    }
  }

  Future<void> _pickPDF() async {
    if (_archivos.length >= _maxArchivos) {
      _showError('Ya alcanzaste el límite de $_maxArchivos archivos');
      return;
    }

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final espacioDisponible = _maxArchivos - _archivos.length;
        final pdfsAgregar = result.files.take(espacioDisponible).toList();

        if (result.files.length > espacioDisponible) {
          _showError('Solo se agregaron $espacioDisponible de ${result.files.length} PDFs (límite: $_maxArchivos)');
        }

        setState(() {
          for (int i = 0; i < pdfsAgregar.length; i++) {
            final file = pdfsAgregar[i];
            if (file.path != null) {
              _archivos.add(ArchivoItem(
                id: 'local_${DateTime.now().millisecondsSinceEpoch}_$i',
                file: File(file.path!),
                nombreOriginal: file.name,
                tipoArchivo: TipoArchivo.pdf,
                isLocal: true,
              ));
            }
          }
        });
      }
    } catch (e) {
      _showError('Error al seleccionar PDFs: $e');
    }
  }

  // Subir archivos locales
  Future<void> _uploadLocalFiles() async {
    final localFiles = _archivos.where((a) => a.isLocal).toList();
    if (localFiles.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _lastProgressUpdate = DateTime.now();
    });

    try {
      for (int i = 0; i < localFiles.length; i++) {
        final archivo = localFiles[i];

        // Subir archivo con entidadId directo
        final response = await _storageService.uploadFile(
          file: archivo.file!,
          empresaId: widget.empresaId,
          entidadTipo: widget.entidadTipo,
          entidadId: widget.entidadId,
          onProgress: (progress) {
            final now = DateTime.now();
            // Solo actualizar si han pasado al menos 100ms desde la última actualización
            if (now.difference(_lastProgressUpdate).inMilliseconds >= 100) {
              setState(() {
                _uploadProgress = (i + progress) / localFiles.length;
                _lastProgressUpdate = now;
              });
            } else {
              // Actualizar el progreso sin setState para evitar rebuilds
              _uploadProgress = (i + progress) / localFiles.length;
            }
          },
        );

        // Actualizar archivo en la lista
        final index = _archivos.indexWhere((a) => a.id == archivo.id);
        if (index != -1) {
          setState(() {
            _archivos[index] = ArchivoItem(
              id: response.id,
              url: response.url,
              urlThumbnail: response.urlThumbnail,
              nombreOriginal: archivo.nombreOriginal,
              tipoArchivo: archivo.tipoArchivo,
              isLocal: false,
            );
            // Actualizar progreso final para este archivo
            _uploadProgress = (i + 1) / localFiles.length;
          });
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${localFiles.length} archivo${localFiles.length > 1 ? 's subidos' : ' subido'}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      _showError('Error al subir archivos: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
      });
    }
  }

  // Eliminar archivo
  Future<void> _confirmDelete(ArchivoItem archivo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar archivo'),
        content: Text(
          archivo.isLocal
              ? '¿Eliminar este archivo? No se ha subido aún.'
              : '¿Estás seguro de eliminar este archivo del servidor?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (archivo.isLocal) {
        // Solo eliminar de la lista
        setState(() {
          _archivos.removeWhere((a) => a.id == archivo.id);
        });
      } else {
        // Eliminar del servidor
        try {
          await _storageService.deleteFile(
            archivoId: archivo.id,
            empresaId: widget.empresaId,
          );

          setState(() {
            _archivos.removeWhere((a) => a.id == archivo.id);
          });

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Archivo eliminado'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          _showError('Error al eliminar: $e');
        }
      }
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Mostrar imagen en dialog con zoom
  void _showImageViewer(ArchivoItem archivo) {
    if (archivo.tipoArchivo != TipoArchivo.imagen) return;

    showDialog(
      context: context,
      builder: (context) => _ImageViewerDialog(
        archivo: archivo,
        onDownload: () => _downloadImage(archivo),
      ),
    );
  }

  // Descargar imagen
  Future<void> _downloadImage(ArchivoItem archivo) async {
    try {
      File? imageFile;

      if (archivo.isLocal && archivo.file != null) {
        // Imagen local - copiar a Downloads
        imageFile = archivo.file!;
      } else if (archivo.url != null) {
        // Imagen remota - descargar
        final response = await http.get(Uri.parse(archivo.url!));
        if (response.statusCode == 200) {
          final directory = await getApplicationDocumentsDirectory();
          final fileName = archivo.nombreOriginal ?? 'imagen_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final file = File('${directory.path}/$fileName');
          await file.writeAsBytes(response.bodyBytes);
          imageFile = file;
        }
      }

      if (imageFile != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imagen guardada: ${imageFile.path}'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    } catch (e) {
      _showError('Error al descargar imagen: $e');
    }
  }
}

// Modelo de archivo para el bottom sheet
class ArchivoItem {
  final String id;
  final String? url;
  final String? urlThumbnail;
  final File? file;
  final String? nombreOriginal;
  final TipoArchivo tipoArchivo;
  final bool isLocal;

  ArchivoItem({
    required this.id,
    this.url,
    this.urlThumbnail,
    this.file,
    this.nombreOriginal,
    required this.tipoArchivo,
    this.isLocal = false,
  });
}

enum TipoArchivo {
  imagen,
  pdf,
  otro,
}

// Dialog para visualizar imagen con zoom
class _ImageViewerDialog extends StatefulWidget {
  final ArchivoItem archivo;
  final VoidCallback onDownload;

  const _ImageViewerDialog({
    required this.archivo,
    required this.onDownload,
  });

  @override
  State<_ImageViewerDialog> createState() => _ImageViewerDialogState();
}

class _ImageViewerDialogState extends State<_ImageViewerDialog> {
  final TransformationController _transformationController = TransformationController();
  bool _isDownloading = false;

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.only(left: 18),
              color: widget.archivo.isLocal ? Colors.orange : AppColors.blue1,
              child: Row(
                children: [
                  const Text(
                    '🖼️',
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.archivo.isLocal ? 'Imagen Local' : 'Imagen',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Text(
                          '🔍 Pellizca para hacer zoom',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 8,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            // Imagen con zoom
            Container(
              height: 300,
              color: Colors.black,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: _buildImage(),
                ),
              ),
            ),

            // Detalles
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Nombre:', widget.archivo.nombreOriginal ?? 'Sin nombre'),
                  if (widget.archivo.isLocal)
                    _buildDetailRow('Estado:', 'Pendiente de subir'),
                ],
              ),
            ),

            // Botones de acción
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _transformationController.value = Matrix4.identity();
                      },
                      icon: const Icon(Icons.zoom_out_map, size: 14),
                      label: const Text(
                        'Reset Zoom',
                        style: TextStyle(fontSize: 9),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 33),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isDownloading ? null : _handleDownload,
                      icon: Icon(
                        _isDownloading ? Icons.downloading : Icons.download,
                        size: 14,
                      ),
                      label: Text(
                        _isDownloading ? 'Descargando...' : 'Descargar',
                        style: const TextStyle(fontSize: 9),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                        minimumSize: const Size(0, 33),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (widget.archivo.file != null) {
      // Imagen local
      return Image.file(
        widget.archivo.file!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.error_outline, size: 48),
            ),
          );
        },
      );
    } else if (widget.archivo.url != null) {
      // Imagen remota
      return Image.network(
        widget.archivo.url!,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
            color: Colors.grey.shade200,
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 300,
            color: Colors.grey.shade200,
            child: const Center(
              child: Icon(Icons.error_outline, size: 48),
            ),
          );
        },
      );
    }

    return Container(
      height: 300,
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.error_outline, size: 48),
      ),
    );
  }

  Future<void> _handleDownload() async {
    setState(() {
      _isDownloading = true;
    });

    try {
      widget.onDownload();
      // Dar un pequeño delay para que se complete la descarga
      await Future.delayed(const Duration(milliseconds: 500));
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }
}
