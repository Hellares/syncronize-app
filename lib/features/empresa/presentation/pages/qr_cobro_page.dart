import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/storage_constants.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_container.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/styled_dialog.dart';
import '../../data/datasources/empresa_remote_datasource.dart';

/// Configuración del QR de cobro (imagen estática del comercio) por método.
/// El QR se muestra en la hoja de cobro de Venta Rápida para que el cliente
/// lo escanee; el monto (con céntimos del token api-yape) se teclea aparte.
class QrCobroPage extends StatefulWidget {
  const QrCobroPage({super.key});

  @override
  State<QrCobroPage> createState() => _QrCobroPageState();
}

class _QrCobroPageState extends State<QrCobroPage> {
  final _storageService = locator<StorageService>();
  final _empresaDs = locator<EmpresaRemoteDataSource>();
  final _localStorage = locator<LocalStorageService>();
  final _picker = ImagePicker();

  bool _loading = true;
  String? _qrYapeUrl;
  String? _qrPlinUrl;
  bool _subiendoYape = false;
  bool _subiendoPlin = false;

  String? get _empresaId => _localStorage.getString(StorageConstants.tenantId);

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    final id = _empresaId;
    if (id == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final cfg = await _empresaDs.getConfiguracion(id);
      if (!mounted) return;
      setState(() {
        _qrYapeUrl = cfg.qrYapeUrl;
        _qrPlinUrl = cfg.qrPlinUrl;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Selecciona una imagen, la sube y guarda su URL en el campo del método.
  Future<void> _subir(String metodo) async {
    final id = _empresaId;
    if (id == null) return;
    final esYape = metodo == 'YAPE';
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked == null) return;
      setState(() => esYape ? _subiendoYape = true : _subiendoPlin = true);

      final archivo = await _storageService.uploadFile(
        file: File(picked.path),
        empresaId: id,
        entidadTipo: 'EMPRESA',
        entidadId: id,
        categoria: 'QR_COBRO',
      );

      final campo = esYape ? 'qrYapeUrl' : 'qrPlinUrl';
      await _empresaDs.updateConfiguracion(
        empresaId: id,
        data: {campo: archivo.url},
      );

      if (!mounted) return;
      setState(() {
        if (esYape) {
          _qrYapeUrl = archivo.url;
          _subiendoYape = false;
        } else {
          _qrPlinUrl = archivo.url;
          _subiendoPlin = false;
        }
      });
      _snack('QR de $metodo actualizado', ok: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => esYape ? _subiendoYape = false : _subiendoPlin = false);
      _snack('No se pudo subir el QR: $e', ok: false);
    }
  }

  Future<void> _quitar(String metodo) async {
    final id = _empresaId;
    if (id == null) return;
    final esYape = metodo == 'YAPE';
    final confirma = await StyledDialog.show<bool>(
      context,
      accentColor: AppColors.red,
      icon: Icons.delete_outline,
      titulo: 'Quitar QR de $metodo',
      content: [
        Text(
          '¿Seguro que quieres quitar el QR de cobro de $metodo?',
          style: const TextStyle(fontSize: 13),
        ),
      ],
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.red),
          child: const Text('Quitar'),
        ),
      ],
    );
    if (confirma != true) return;
    try {
      // Cadena vacía → el backend lo convierte a null (limpia el campo).
      await _empresaDs.updateConfiguracion(
        empresaId: id,
        data: {esYape ? 'qrYapeUrl' : 'qrPlinUrl': ''},
      );
      if (!mounted) return;
      setState(() => esYape ? _qrYapeUrl = null : _qrPlinUrl = null);
      _snack('QR de $metodo eliminado', ok: true);
    } catch (e) {
      _snack('No se pudo quitar el QR: $e', ok: false);
    }
  }

  void _snack(String msg, {required bool ok}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: ok ? Colors.green : AppColors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const SmartAppBar(title: 'QR de cobro Yape/Plin'),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const AppSubtitle(
                  'Sube el QR de tu comercio. Se mostrará en la hoja de cobro '
                  'para que el cliente lo escanee. El monto exacto (con céntimos) '
                  'se teclea aparte.',
                  fontSize: 11,
                  color: AppColors.blueGrey,
                ),
                const SizedBox(height: 16),
                _buildSlot(
                  metodo: 'YAPE',
                  url: _qrYapeUrl,
                  subiendo: _subiendoYape,
                ),
                const SizedBox(height: 14),
                _buildSlot(
                  metodo: 'PLIN',
                  url: _qrPlinUrl,
                  subiendo: _subiendoPlin,
                ),
              ],
            ),
    );
  }

  Widget _buildSlot({
    required String metodo,
    required String? url,
    required bool subiendo,
  }) {
    return GradientContainer(
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTitle('QR $metodo', fontSize: 14, color: AppColors.blue1),
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: subiendo
                    ? const Center(child: CircularProgressIndicator())
                    : url != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.contain,
                              errorWidget: (_, __, ___) => const Center(
                                child: Icon(Icons.broken_image_outlined,
                                    color: AppColors.blueGrey),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.qr_code_2,
                                size: 64, color: AppColors.blueGrey),
                          ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: url != null ? 'Cambiar' : 'Subir QR',
                    backgroundColor: AppColors.blue1,
                    textColor: AppColors.white,
                    onPressed: subiendo ? null : () => _subir(metodo),
                  ),
                ),
                if (url != null) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: CustomButton(
                      text: 'Quitar',
                      isOutlined: true,
                      borderColor: AppColors.red,
                      textColor: AppColors.red,
                      enableShadows: false,
                      onPressed: subiendo ? null : () => _quitar(metodo),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
