import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/sorteo.dart';

/// Datos corregidos de la entrega (el caller llama al cubit).
class EntregaEditada {
  final ModalidadEntregaPremio modalidad;
  final String? agenciaNombre;
  final String? destinoDepartamento;
  final String? destinoProvincia;
  final String? agenciaDireccion;

  const EntregaEditada({
    required this.modalidad,
    this.agenciaNombre,
    this.destinoDepartamento,
    this.destinoProvincia,
    this.agenciaDireccion,
  });
}

/// Sheet para corregir la ENTREGA de un premio ya registrado (modalidad
/// y/o agencia) — p.ej. quedó en retiro en tienda por error. Solo se
/// ofrece en REGISTRADO/PREPARANDO (mismo guard que el backend).
/// Devuelve null si se cancela.
Future<EntregaEditada?> showEditarEntregaSheet({
  required BuildContext context,
  required SorteoPremio premio,
}) {
  return showModalBottomSheet<EntregaEditada>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditarEntregaSheet(premio: premio),
  );
}

class _EditarEntregaSheet extends StatefulWidget {
  final SorteoPremio premio;
  const _EditarEntregaSheet({required this.premio});

  @override
  State<_EditarEntregaSheet> createState() => _EditarEntregaSheetState();
}

class _EditarEntregaSheetState extends State<_EditarEntregaSheet> {
  late ModalidadEntregaPremio _modalidad = widget.premio.modalidad;
  late final _agenciaCtrl =
      TextEditingController(text: widget.premio.agenciaNombre ?? '');
  late final _destinoDepCtrl =
      TextEditingController(text: widget.premio.destinoDepartamento ?? '');
  late final _destinoProvCtrl =
      TextEditingController(text: widget.premio.destinoProvincia ?? '');
  late final _agenciaDirCtrl =
      TextEditingController(text: widget.premio.agenciaDireccion ?? '');

  @override
  void dispose() {
    _agenciaCtrl.dispose();
    _destinoDepCtrl.dispose();
    _destinoProvCtrl.dispose();
    _agenciaDirCtrl.dispose();
    super.dispose();
  }

  void _confirmar() {
    String? limpio(TextEditingController c) {
      final t = c.text.trim();
      return t.isEmpty ? null : t;
    }

    Navigator.of(context).pop(EntregaEditada(
      modalidad: _modalidad,
      agenciaNombre: limpio(_agenciaCtrl),
      destinoDepartamento: limpio(_destinoDepCtrl),
      destinoProvincia: limpio(_destinoProvCtrl),
      agenciaDireccion: limpio(_agenciaDirCtrl),
    ));
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
                  Icon(Icons.local_shipping_outlined,
                      color: AppColors.blue1, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Entrega de ${widget.premio.ganadorNombre}',
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text('Modalidad de entrega',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
              const SizedBox(height: 4),
              Row(
                children: [
                  for (final m in ModalidadEntregaPremio.values) ...[
                    Expanded(
                      child: ChoiceChip(
                        label: Text(m.label,
                            style: const TextStyle(fontSize: 10.5)),
                        selected: _modalidad == m,
                        selectedColor:
                            AppColors.blue1.withValues(alpha: 0.15),
                        onSelected: (_) => setState(() => _modalidad = m),
                      ),
                    ),
                    if (m != ModalidadEntregaPremio.values.last)
                      const SizedBox(width: 8),
                  ],
                ],
              ),
              if (_modalidad == ModalidadEntregaPremio.envioAgencia) ...[
                const SizedBox(height: 8),
                CustomText(
                  controller: _agenciaCtrl,
                  label: 'Agencia (opcional — el ganador puede elegirla)',
                  hintText: 'ej. Shalom / Olva / Marvisur',
                  borderColor: AppColors.blue1,
                  textCase: TextCase.upper,
                ),
                const SizedBox(height: 6),
                // Selección rápida de las agencias más usadas.
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
                        onPressed: () =>
                            setState(() => _agenciaCtrl.text = a),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: CustomText(
                        controller: _destinoDepCtrl,
                        label: 'Departamento',
                        hintText: 'ej. San Martín',
                        borderColor: AppColors.blue1,
                        textCase: TextCase.upper,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CustomText(
                        controller: _destinoProvCtrl,
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
                  controller: _agenciaDirCtrl,
                  label: 'Dirección de la agencia (opcional)',
                  hintText: 'ej. Jr. Los Pinos 123',
                  borderColor: AppColors.blue1,
                  textCase: TextCase.upper,
                ),
              ] else ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade200),
                  ),
                  child: const Text(
                    'El ganador recogerá su premio en la tienda. Si había '
                    'un rótulo impreso, dejará de estar vigente.',
                    style: TextStyle(fontSize: 10.5),
                  ),
                ),
              ],
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
                    child: CustomButton(
                      text: 'Guardar cambios',
                      backgroundColor: AppColors.blue1,
                      textColor: Colors.white,
                      onPressed: _confirmar,
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
