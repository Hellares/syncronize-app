import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'styled_dialog.dart';
import '../../features/auth/presentation/widgets/custom_button.dart';
import '../../features/auth/presentation/widgets/custom_text.dart';

/// Dialog compartido para editar datos de contacto (teléfono, email,
/// dirección). Lo usan el detail sheet de usuarios, el de clientes y el
/// ClienteUnificadoSelector (edición inline desde nueva orden/POS).
///
/// Devuelve un mapa SOLO con los campos que cambiaron respecto a los
/// valores iniciales (campo vacío = no tocar, no limpia datos), o null
/// si se canceló / no hubo cambios.
Future<Map<String, dynamic>?> showEditarDatosContactoDialog(
  BuildContext context, {
  String? telefono,
  String? email,
  String? direccion,
  String titulo = 'Editar datos',
}) async {
  final telefonoCtrl = TextEditingController(text: telefono ?? '');
  final emailCtrl = TextEditingController(text: email ?? '');
  final direccionCtrl = TextEditingController(text: direccion ?? '');
  final formKey = GlobalKey<FormState>();

  final guardar = await StyledDialog.show<bool>(
    context,
    accentColor: AppColors.blue1,
    backgroundColor: Colors.white,
    icon: Icons.edit_outlined,
    titulo: titulo,
    content: [
      Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              controller: telefonoCtrl,
              label: 'Teléfono',
              fieldType: FieldType.number,
              maxLength: 9,
              autovalidateMode: AutovalidateModeX.disabled,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isNotEmpty && t.length != 9) {
                  return 'Debe tener 9 dígitos';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: emailCtrl,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              autovalidateMode: AutovalidateModeX.disabled,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isNotEmpty &&
                    !RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(t)) {
                  return 'Email inválido';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: direccionCtrl,
              label: 'Dirección',
            ),
          ],
        ),
      ),
    ],
    actions: [
      Expanded(
        child: Builder(
          builder: (dialogCtx) => CustomButton(
            text: 'Cancelar',
            fontSize: 12,
            backgroundColor: Colors.transparent,
            borderColor: AppColors.blue3,
            borderWidth: 0.6,
            textColor: AppColors.blue3,
            onPressed: () =>
                Navigator.of(dialogCtx, rootNavigator: true).pop(false),
          ),
        ),
      ),
      Expanded(
        child: Builder(
          builder: (dialogCtx) => CustomButton(
            text: 'Guardar',
            fontSize: 12,
            backgroundColor: AppColors.blue1,
            icon: const Icon(Icons.check, size: 14),
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.of(dialogCtx, rootNavigator: true).pop(true);
            },
          ),
        ),
      ),
    ],
  );

  if (guardar != true) return null;

  final data = <String, dynamic>{};
  final tel = telefonoCtrl.text.trim();
  final mail = emailCtrl.text.trim();
  final dir = direccionCtrl.text.trim();
  if (tel.isNotEmpty && tel != (telefono ?? '')) data['telefono'] = tel;
  if (mail.isNotEmpty && mail != (email ?? '')) data['email'] = mail;
  if (dir.isNotEmpty && dir != (direccion ?? '')) data['direccion'] = dir;

  return data.isEmpty ? null : data;
}
