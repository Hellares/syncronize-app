import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/premio_cliente.dart';

/// Datos elegidos por el GANADOR: su agencia de recojo (lo único que
/// puede indicar del premio).
class AgenciaElegida {
  final String agenciaNombre;
  final String? destinoDepartamento;
  final String? destinoProvincia;
  final String? agenciaDireccion;

  const AgenciaElegida({
    required this.agenciaNombre,
    this.destinoDepartamento,
    this.destinoProvincia,
    this.agenciaDireccion,
  });
}

/// Sheet para que el ganador indique dónde quiere recoger su premio
/// (prellenado si la tienda ya puso datos). Devuelve null si cancela.
Future<AgenciaElegida?> showElegirAgenciaSheet({
  required BuildContext context,
  required PremioCliente premio,
}) {
  return showModalBottomSheet<AgenciaElegida>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ElegirAgenciaSheet(premio: premio),
  );
}

class _ElegirAgenciaSheet extends StatefulWidget {
  final PremioCliente premio;
  const _ElegirAgenciaSheet({required this.premio});

  @override
  State<_ElegirAgenciaSheet> createState() => _ElegirAgenciaSheetState();
}

class _ElegirAgenciaSheetState extends State<_ElegirAgenciaSheet> {
  // El snackbar queda tapado por el propio sheet modal — el aviso de
  // validación va inline, debajo del campo.
  bool _faltaAgencia = false;
  late final _agenciaCtrl =
      TextEditingController(text: widget.premio.agenciaNombre ?? '');
  late final _depCtrl =
      TextEditingController(text: widget.premio.destinoDepartamento ?? '');
  late final _provCtrl =
      TextEditingController(text: widget.premio.destinoProvincia ?? '');
  late final _dirCtrl =
      TextEditingController(text: widget.premio.agenciaDireccion ?? '');

  @override
  void dispose() {
    _agenciaCtrl.dispose();
    _depCtrl.dispose();
    _provCtrl.dispose();
    _dirCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.edit_location_alt_outlined,
                      color: AppColors.blue1, size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      '¿Dónde quieres recoger tu premio?',
                      style: TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Indica la agencia que te queda más cómoda — la tienda '
                'enviará tu premio ahí.',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              CustomText(
                controller: _agenciaCtrl,
                label: 'Agencia',
                hintText: 'ej. Shalom / Olva / Marvisur',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
                onChanged: (_) {
                  if (_faltaAgencia) setState(() => _faltaAgencia = false);
                },
              ),
              if (_faltaAgencia)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Indica el nombre de la agencia para continuar',
                    style: TextStyle(
                        fontSize: 10.5, color: Colors.red.shade700),
                  ),
                ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: [
                  for (final a in const ['SHALOM', 'OLVA', 'MARVISUR'])
                    ActionChip(
                      label: Text(a, style: const TextStyle(fontSize: 10)),
                      visualDensity: VisualDensity.compact,
                      backgroundColor:
                          AppColors.blue1.withValues(alpha: 0.06),
                      side: BorderSide(
                          color: AppColors.blue1.withValues(alpha: 0.3),
                          width: 0.5),
                      onPressed: () => setState(() {
                        _agenciaCtrl.text = a;
                        _faltaAgencia = false;
                      }),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: CustomText(
                      controller: _depCtrl,
                      label: 'Departamento',
                      hintText: 'ej. San Martín',
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CustomText(
                      controller: _provCtrl,
                      label: 'Provincia / ciudad',
                      hintText: 'ej. Tarapoto',
                      borderColor: AppColors.blue1,
                      textCase: TextCase.upper,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              CustomText(
                controller: _dirCtrl,
                label: 'Dirección de la agencia (opcional)',
                hintText: 'ej. Jr. Los Pinos 123',
                borderColor: AppColors.blue1,
                textCase: TextCase.upper,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: CustomButton(
                      text: 'Cancelar',
                      isOutlined: true,
                      borderColor: Colors.grey.shade400,
                      textColor: Colors.grey.shade700,
                      enableShadows: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: CustomButton(
                      text: 'Confirmar agencia',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      onPressed: () {
                        final agencia = _agenciaCtrl.text.trim();
                        if (agencia.isEmpty) {
                          setState(() => _faltaAgencia = true);
                          return;
                        }
                        Navigator.of(context).pop(AgenciaElegida(
                          agenciaNombre: agencia,
                          destinoDepartamento: _depCtrl.text.trim(),
                          destinoProvincia: _provCtrl.text.trim(),
                          agenciaDireccion: _dirCtrl.text.trim(),
                        ));
                      },
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
