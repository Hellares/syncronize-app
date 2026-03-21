import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../di/injection_container.dart';
import '../fonts/app_text_widgets.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_button.dart';
import '../../features/auth/presentation/widgets/custom_text.dart';
import '../services/autorizacion_service.dart';

/// Shows an authorization dialog that validates admin credentials.
/// Returns [AutorizacionResult] on success, null on cancel.
Future<AutorizacionResult?> showAutorizacionDialog(
  BuildContext context, {
  required String operacion,
  String titulo = 'Autorizacion requerida',
  String descripcion = 'Un administrador debe autorizar esta operacion',
}) async {
  return showModalBottomSheet<AutorizacionResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => _AutorizacionSheet(
      operacion: operacion,
      titulo: titulo,
      descripcion: descripcion,
    ),
  );
}

class _AutorizacionSheet extends StatefulWidget {
  final String operacion;
  final String titulo;
  final String descripcion;

  const _AutorizacionSheet({
    required this.operacion,
    required this.titulo,
    required this.descripcion,
  });

  @override
  State<_AutorizacionSheet> createState() => _AutorizacionSheetState();
}

class _AutorizacionSheetState extends State<_AutorizacionSheet> {
  final _dniController = TextEditingController();
  final _passwordController = TextEditingController();
  final _motivoController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _dniController.dispose();
    _passwordController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _autorizar() async {
    if (_dniController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Ingresa DNI y contrasena');
      return;
    }

    setState(() { _isLoading = true; _error = null; });

    try {
      final service = locator<AutorizacionService>();
      final result = await service.autorizar(
        dni: _dniController.text.trim(),
        password: _passwordController.text,
        operacion: widget.operacion,
        motivo: _motivoController.text.isNotEmpty ? _motivoController.text.trim() : null,
      );

      if (mounted) Navigator.of(context).pop(result);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString().contains('Unauthorized') || e.toString().contains('401')
              ? 'Credenciales incorrectas o sin permisos'
              : 'Error al autorizar';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 100),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              // Header
              Row(
                children: [
                  Icon(Icons.shield, size: 24, color: Colors.orange[700]),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppSubtitle(widget.titulo, fontSize: 16),
                        Text(widget.descripcion, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // DNI
              CustomText(
                controller: _dniController,
                label: 'DNI del administrador',
                hintText: '12345678',
                borderColor: Colors.orange[700]!,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(8)],
              ),
              const SizedBox(height: 12),
              // Password
              CustomText(
                controller: _passwordController,
                label: 'Contrasena',
                borderColor: Colors.orange[700]!,
                obscureText: true,
              ),
              const SizedBox(height: 12),
              // Motivo
              CustomText(
                controller: _motivoController,
                label: 'Motivo (opcional)',
                hintText: 'Razon de la anulacion',
                borderColor: AppColors.blue1,
                maxLines: 2,
              ),
              // Error
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: TextStyle(fontSize: 12, color: Colors.red[700])),
              ],
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Autorizar',
                      isLoading: _isLoading,
                      backgroundColor: Colors.orange[700]!,
                      height: 44,
                      icon: const Icon(Icons.shield, size: 16),
                      onPressed: _isLoading ? null : _autorizar,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
