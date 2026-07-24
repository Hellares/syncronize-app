import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../data/datasources/repartidor_remote_datasource.dart';

/// Registro PÚBLICO de repartidor freelance de Syncronize (sin cuenta
/// previa): DNI validado en RENIEC + celular (OTP por WhatsApp) + zonas.
/// Queda PENDIENTE hasta que el super admin apruebe.
class RegistroRepartidorPage extends StatefulWidget {
  const RegistroRepartidorPage({super.key});

  @override
  State<RegistroRepartidorPage> createState() => _RegistroRepartidorPageState();
}

class _RegistroRepartidorPageState extends State<RegistroRepartidorPage> {
  final _dniCtrl = TextEditingController();
  final _celularCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _zonasCtrl = TextEditingController();
  final _placaCtrl = TextEditingController();
  bool _enviando = false;

  @override
  void dispose() {
    _dniCtrl.dispose();
    _celularCtrl.dispose();
    _passwordCtrl.dispose();
    _zonasCtrl.dispose();
    _placaCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 12)),
      backgroundColor: error ? Colors.red[700] : Colors.green[700],
      behavior: SnackBarBehavior.floating,
    ));
  }

  Future<void> _registrar() async {
    final dni = _dniCtrl.text.trim();
    final celular = _celularCtrl.text.trim();
    final password = _passwordCtrl.text;
    final zonas = _zonasCtrl.text
        .split(',')
        .map((z) => z.trim())
        .where((z) => z.isNotEmpty)
        .toList();

    if (!RegExp(r'^\d{8}$').hasMatch(dni)) {
      return _snack('El DNI debe tener 8 dígitos', error: true);
    }
    if (!RegExp(r'^9\d{8}$').hasMatch(celular)) {
      return _snack('Celular inválido (9 dígitos, empieza en 9)', error: true);
    }
    if (password.length < 8) {
      return _snack('La contraseña debe tener al menos 8 caracteres',
          error: true);
    }
    if (zonas.isEmpty) {
      return _snack('Ingresa al menos una zona (ej. Chiclayo)', error: true);
    }

    setState(() => _enviando = true);
    try {
      final r = await locator<RepartidorRemoteDataSource>().registrar(
        dni: dni,
        celular: celular,
        password: password,
        zonas: zonas,
        placaVehiculo: _placaCtrl.text.trim(),
      );
      if (!mounted) return;
      final nombre = r['nombreCompleto'] as String? ?? '';
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('¡Registro recibido! 🛵'),
          content: Text(
            'Bienvenido/a $nombre.\n\n'
            'Te enviamos un código de verificación por WhatsApp al '
            '$celular.\n\nInicia sesión con tu DNI y contraseña para '
            'verificar tu celular y seguir tu solicitud — te avisaremos '
            'cuando estés aprobado.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ir a iniciar sesión'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;
      _snack(
        e.toString().replaceFirst(RegExp(r'^[A-Za-z]+Exception:\s*'), ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      style: GradientStyle.professional,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: SmartAppBar(
          title: 'Quiero ser repartidor',
          backgroundColor: AppColors.blue1,
          foregroundColor: AppColors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '🛵 Reparte con Syncronize',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Regístrate, espera tu aprobación y empieza a tomar '
                      'pedidos de delivery en tus zonas. Los productos ya '
                      'están pagados: tú cobras la tarifa de cada envío.',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 14),
                    CustomText(
                      controller: _dniCtrl,
                      label: 'DNI',
                      hintText: '8 dígitos — se valida en RENIEC',
                      borderColor: AppColors.blue1,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      controller: _celularCtrl,
                      label: 'Celular (WhatsApp)',
                      hintText: 'Recibirás un código de verificación',
                      borderColor: AppColors.blue1,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      controller: _passwordCtrl,
                      label: 'Contraseña',
                      hintText: 'Mínimo 8 caracteres',
                      borderColor: AppColors.blue1,
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      controller: _zonasCtrl,
                      label: 'Zonas donde repartes',
                      hintText: 'Separadas por coma: Chiclayo, JLO, La Victoria',
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                    const SizedBox(height: 8),
                    CustomText(
                      controller: _placaCtrl,
                      label: 'Placa de tu moto (opcional)',
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                    const SizedBox(height: 16),
                    CustomButton(
                      text: _enviando ? 'Registrando…' : 'Registrarme',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      onPressed: _enviando ? null : _registrar,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text(
                    'Ya tengo cuenta — iniciar sesión',
                    style: TextStyle(color: Colors.white, fontSize: 12),
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
