import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../domain/entities/transferencia_incidencia.dart';
import '../../domain/entities/transferencia_stock.dart';

/// Diálogo para crear una incidencia posterior a la recepción de una transferencia
/// Permite seleccionar el tipo de incidencia, cantidad afectada, descripción y evidencias
class CrearIncidenciaPosteriorDialog extends StatefulWidget {
  final TransferenciaStock transferencia;
  final String empresaId;

  const CrearIncidenciaPosteriorDialog({
    super.key,
    required this.transferencia,
    required this.empresaId,
  });

  @override
  State<CrearIncidenciaPosteriorDialog> createState() =>
      _CrearIncidenciaPosteriorDialogState();
}

class _CrearIncidenciaPosteriorDialogState
    extends State<CrearIncidenciaPosteriorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _cantidadController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _observacionesController = TextEditingController();

  TransferenciaStockItem? _itemSeleccionado;
  TipoIncidenciaTransferencia? _tipoSeleccionado;
  final List<EvidenciaArchivo> _evidencias = [];
  final bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Seleccionar el primer item si solo hay uno
    if (widget.transferencia.items != null &&
        widget.transferencia.items!.length == 1) {
      _itemSeleccionado = widget.transferencia.items!.first;
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _descripcionController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            _buildHeader(),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Formulario
            Expanded(
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    // Selector de producto (si hay múltiples)
                    if (widget.transferencia.items != null &&
                        widget.transferencia.items!.length > 1)
                      _buildProductoSelector(),

                    if (widget.transferencia.items != null &&
                        widget.transferencia.items!.length > 1)
                      const SizedBox(height: 16),

                    // Tipo de incidencia
                    _buildTipoSelector(),
                    const SizedBox(height: 16),

                    // Cantidad afectada
                    _buildCantidadField(),
                    const SizedBox(height: 16),

                    // Descripción
                    _buildDescripcionField(),
                    const SizedBox(height: 16),

                    // Observaciones
                    _buildObservacionesField(),
                    const SizedBox(height: 16),

                    // Sección de evidencias
                    _buildEvidenciasSection(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Botones de acción
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.warning_amber,
            color: Colors.orange,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reportar Problema',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Transferencia: ${widget.transferencia.codigo}',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }

  Widget _buildProductoSelector() {
    return DropdownButtonFormField<TransferenciaStockItem>(
      initialValue: _itemSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Producto',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.inventory_2),
      ),
      items: widget.transferencia.items!.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item.nombreProducto,
            style: const TextStyle(fontSize: 14),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _itemSeleccionado = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Selecciona un producto';
        }
        return null;
      },
    );
  }

  Widget _buildTipoSelector() {
    return DropdownButtonFormField<TipoIncidenciaTransferencia>(
      initialValue: _tipoSeleccionado,
      decoration: const InputDecoration(
        labelText: 'Tipo de Problema',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.category),
      ),
      items: TipoIncidenciaTransferencia.values.map((tipo) {
        IconData icon;
        Color color;

        switch (tipo) {
          case TipoIncidenciaTransferencia.danado:
            icon = Icons.broken_image;
            color = Colors.red;
            break;
          case TipoIncidenciaTransferencia.faltante:
            icon = Icons.remove_circle;
            color = Colors.orange;
            break;
          case TipoIncidenciaTransferencia.calidadRechazada:
            icon = Icons.thumb_down;
            color = Colors.deepOrange;
            break;
          case TipoIncidenciaTransferencia.empaqueDanado:
            icon = Icons.inventory;
            color = Colors.brown;
            break;
          case TipoIncidenciaTransferencia.excedente:
            icon = Icons.add_circle;
            color = Colors.blue;
            break;
          case TipoIncidenciaTransferencia.productoIncorrecto:
            icon = Icons.warning;
            color = Colors.purple;
            break;
        }

        return DropdownMenuItem(
          value: tipo,
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Text(
                tipo.displayName,
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _tipoSeleccionado = value;
        });
      },
      validator: (value) {
        if (value == null) {
          return 'Selecciona el tipo de problema';
        }
        return null;
      },
    );
  }

  Widget _buildCantidadField() {
    final maxCantidad = _itemSeleccionado?.cantidadRecibida ?? 0;

    return TextFormField(
      controller: _cantidadController,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(
        labelText: 'Cantidad Afectada',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.numbers),
        suffixText: 'de $maxCantidad',
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Ingresa la cantidad';
        }
        final cantidad = int.tryParse(value);
        if (cantidad == null || cantidad <= 0) {
          return 'Cantidad inválida';
        }
        if (cantidad > maxCantidad) {
          return 'No puede exceder $maxCantidad';
        }
        return null;
      },
    );
  }

  Widget _buildDescripcionField() {
    return TextFormField(
      controller: _descripcionController,
      maxLines: 3,
      decoration: const InputDecoration(
        labelText: 'Descripción del Problema',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.description),
        hintText: 'Describe detalladamente el problema encontrado...',
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'La descripción es requerida';
        }
        return null;
      },
    );
  }

  Widget _buildObservacionesField() {
    return TextFormField(
      controller: _observacionesController,
      maxLines: 2,
      decoration: const InputDecoration(
        labelText: 'Observaciones Adicionales (Opcional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.notes),
        hintText: 'Agrega observaciones adicionales si lo deseas...',
      ),
    );
  }

  Widget _buildEvidenciasSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Evidencias (Fotos/PDFs)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),

        // Botones de agregar evidencia
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickFromCamera(),
                icon: const Icon(Icons.camera_alt, size: 16),
                label: const Text('Cámara', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickFromGallery(),
                icon: const Icon(Icons.photo_library, size: 16),
                label: const Text('Galería', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _pickPDF(),
                icon: const Icon(Icons.picture_as_pdf, size: 16),
                label: const Text('PDF', style: TextStyle(fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),

        // Lista de evidencias
        if (_evidencias.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            constraints: const BoxConstraints(maxHeight: 120),
            child: ListView.builder(
              itemCount: _evidencias.length,
              itemBuilder: (context, index) {
                return _buildEvidenciaItem(_evidencias[index], index);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEvidenciaItem(EvidenciaArchivo evidencia, int index) {
    IconData icon;
    Color color;

    if (evidencia.isPDF) {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else {
      icon = Icons.image;
      color = Colors.blue;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              evidencia.nombre,
              style: const TextStyle(fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            onPressed: () {
              setState(() {
                _evidencias.removeAt(index);
              });
            },
            icon: const Icon(Icons.delete, size: 18),
            color: Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitIncidencia,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Reportar Problema'),
        ),
      ],
    );
  }

  Future<void> _pickFromCamera() async {
    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _evidencias.add(EvidenciaArchivo(
            file: File(photo.path),
            nombre: photo.name,
            isPDF: false,
          ));
        });
      }
    } catch (e) {
      _showError('Error al tomar foto: $e');
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final picker = ImagePicker();
      final List<XFile> photos = await picker.pickMultiImage(
        imageQuality: 85,
      );

      if (photos.isNotEmpty) {
        setState(() {
          for (final photo in photos) {
            _evidencias.add(EvidenciaArchivo(
              file: File(photo.path),
              nombre: photo.name,
              isPDF: false,
            ));
          }
        });
      }
    } catch (e) {
      _showError('Error al seleccionar imágenes: $e');
    }
  }

  Future<void> _pickPDF() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          for (final file in result.files) {
            if (file.path != null) {
              _evidencias.add(EvidenciaArchivo(
                file: File(file.path!),
                nombre: file.name,
                isPDF: true,
              ));
            }
          }
        });
      }
    } catch (e) {
      _showError('Error al seleccionar PDFs: $e');
    }
  }

  void _submitIncidencia() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_itemSeleccionado == null) {
      _showError('Selecciona un producto');
      return;
    }

    if (_tipoSeleccionado == null) {
      _showError('Selecciona el tipo de problema');
      return;
    }

    final resultado = IncidenciaPosteriorResult(
      itemId: _itemSeleccionado!.id,
      tipo: _tipoSeleccionado!,
      cantidadAfectada: int.parse(_cantidadController.text),
      descripcion: _descripcionController.text.trim(),
      observaciones: _observacionesController.text.trim().isEmpty
          ? null
          : _observacionesController.text.trim(),
      evidencias: _evidencias,
    );

    Navigator.pop(context, resultado);
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
}

/// Archivo de evidencia local
class EvidenciaArchivo {
  final File file;
  final String nombre;
  final bool isPDF;

  EvidenciaArchivo({
    required this.file,
    required this.nombre,
    required this.isPDF,
  });
}

/// Resultado del diálogo
class IncidenciaPosteriorResult {
  final String itemId;
  final TipoIncidenciaTransferencia tipo;
  final int cantidadAfectada;
  final String descripcion;
  final String? observaciones;
  final List<EvidenciaArchivo> evidencias;

  IncidenciaPosteriorResult({
    required this.itemId,
    required this.tipo,
    required this.cantidadAfectada,
    required this.descripcion,
    this.observaciones,
    required this.evidencias,
  });
}
