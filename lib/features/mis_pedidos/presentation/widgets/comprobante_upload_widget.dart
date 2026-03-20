import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/widgets/custom_button.dart';
import '../bloc/pedido_action_cubit.dart';

class ComprobanteUploadWidget extends StatefulWidget {
  final String pedidoId;
  final bool isLoading;

  const ComprobanteUploadWidget({
    super.key,
    required this.pedidoId,
    this.isLoading = false,
  });

  @override
  State<ComprobanteUploadWidget> createState() =>
      _ComprobanteUploadWidgetState();
}

class _ComprobanteUploadWidgetState extends State<ComprobanteUploadWidget> {
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al seleccionar imagen: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const AppSubtitle('Seleccionar imagen', fontSize: 16),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.blue1),
                ),
                title: const AppText('Camara', size: 14, fontWeight: FontWeight.w500),
                subtitle: const AppText('Tomar foto del comprobante', size: 12, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blue1.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.blue1),
                ),
                title: const AppText('Galeria', size: 14, fontWeight: FontWeight.w500),
                subtitle: const AppText('Seleccionar de la galeria', size: 12, color: AppColors.textSecondary),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _enviarComprobante() {
    if (_selectedImage == null) return;

    context.read<PedidoActionCubit>().subirComprobante(
          pedidoId: widget.pedidoId,
          file: _selectedImage!,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSubtitle('Subir Comprobante de Pago', fontSize: 14),
        const SizedBox(height: 10),

        // Boton para seleccionar imagen
        if (_selectedImage == null)
          GestureDetector(
            onTap: widget.isLoading ? null : _showImageSourceDialog,
            child: Container(
              height: 140,
              decoration: BoxDecoration(
                color: AppColors.blue1.withOpacity(0.04),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.blue1.withOpacity(0.3),
                  style: BorderStyle.solid,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.cloud_upload_outlined,
                    size: 40,
                    color: AppColors.blue1.withOpacity(0.6),
                  ),
                  const SizedBox(height: 8),
                  const AppText(
                    'Toca para seleccionar imagen',
                    size: 13,
                    color: AppColors.blue1,
                  ),
                  const SizedBox(height: 4),
                  const AppText(
                    'Camara o galeria',
                    size: 11,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ),
          ),

        // Vista previa de imagen seleccionada
        if (_selectedImage != null) ...[
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.file(
                  _selectedImage!,
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.contain,
                ),
              ),
              // Boton para cambiar imagen
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: widget.isLoading ? null : _showImageSourceDialog,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.edit, size: 18, color: AppColors.blue1),
                  ),
                ),
              ),
              // Boton para eliminar
              Positioned(
                top: 8,
                left: 8,
                child: GestureDetector(
                  onTap: widget.isLoading
                      ? null
                      : () => setState(() => _selectedImage = null),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close, size: 18, color: AppColors.red),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomButton(
            text: 'Enviar Comprobante',
            onPressed: widget.isLoading ? null : _enviarComprobante,
            isLoading: widget.isLoading,
            height: 48,
            borderRadius: 14,
            icon: const Icon(Icons.send_outlined, color: AppColors.white, size: 20),
          ),
        ],
      ],
    );
  }
}
