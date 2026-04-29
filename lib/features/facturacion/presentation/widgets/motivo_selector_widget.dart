import 'package:flutter/material.dart';
import '../../domain/entities/motivo_nota.dart';

class MotivoSelectorWidget extends StatelessWidget {
  final List<MotivoNota> motivos;
  final int? seleccionado;
  final ValueChanged<int> onChanged;

  const MotivoSelectorWidget({
    super.key,
    required this.motivos,
    required this.seleccionado,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: seleccionado,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Motivo SUNAT',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        border: OutlineInputBorder(),
      ),
      style: const TextStyle(fontSize: 12, color: Colors.black87),
      items: motivos
          .map((m) => DropdownMenuItem(
                value: m.codigo,
                child: Text(m.displayName, style: const TextStyle(fontSize: 11)),
              ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }
}
