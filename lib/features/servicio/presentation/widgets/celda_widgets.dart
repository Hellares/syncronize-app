import 'package:flutter/material.dart';

import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/resource.dart';
import '../../../consultas_externas/domain/entities/consulta_dni.dart';
import '../../../consultas_externas/domain/entities/consulta_ruc.dart';
import '../../../consultas_externas/domain/repositories/consultas_repository.dart';
import '../constants/tipos_campo_servicio.dart';

/// Widgets para celdas de TABLA.
///
/// 🔴 GOTCHA: `Checkbox` y `DropdownButton` de Material imponen un tamaño
/// mínimo de interacción de 48px. Ni `visualDensity.compact` ni
/// `materialTapTargetSize.shrinkWrap` los bajan lo suficiente, así que
/// deformaban la celda de 34px de alto. Estos los reemplazan con control
/// total del tamaño; el área tocable es TODA la celda, que además es más
/// cómoda que un cuadradito de 18px.

/// Booleano de celda: toda la celda alterna el valor.
class CeldaBooleana extends StatelessWidget {
  final bool valor;
  final ValueChanged<bool> onChanged;

  const CeldaBooleana({
    super.key,
    required this.valor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!valor),
      child: Center(
        child: Icon(
          valor ? Icons.check_box : Icons.check_box_outline_blank,
          size: 18,
          color: valor ? AppColors.blue1 : Colors.grey.shade400,
        ),
      ),
    );
  }
}

/// Celda de DNI / CE / RUC con lupa que resuelve el nombre en RENIEC o SUNAT.
///
/// La celda guarda SOLO el número. El nombre se entrega por
/// [onNombreResuelto] y la tabla decide dónde ponerlo — así este widget no
/// necesita saber nada de columnas.
class CeldaDocumento extends StatefulWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onNombreResuelto;

  const CeldaDocumento({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onNombreResuelto,
  });

  @override
  State<CeldaDocumento> createState() => _CeldaDocumentoState();
}

class _CeldaDocumentoState extends State<CeldaDocumento> {
  bool _consultando = false;

  Future<void> _consultar() async {
    final numero = widget.controller.text.trim();
    // 8 = DNI (RENIEC), 9 = carné de extranjería, 11 = RUC (SUNAT).
    if (![8, 9, 11].contains(numero.length)) {
      _aviso('Ingresa un DNI (8), CE (9) o RUC (11 dígitos)');
      return;
    }
    setState(() => _consultando = true);
    final repo = locator<ConsultasRepository>();
    final result = numero.length == 11
        ? await repo.consultarRuc(numero)
        : numero.length == 9
            ? await repo.consultarCee(numero)
            : await repo.consultarDni(numero);
    if (!mounted) return;
    setState(() => _consultando = false);

    if (result is Success) {
      final data = (result as Success).data;
      widget.onNombreResuelto(
        data is ConsultaRuc ? data.razonSocial : (data as ConsultaDni).nombreCompleto,
      );
    } else if (result is Error) {
      _aviso((result as Error).message);
    }
  }

  void _aviso(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      style: const TextStyle(fontSize: 11),
      textAlignVertical: TextAlignVertical.center,
      keyboardType: TextInputType.number,
      decoration: kDecoracionCelda.copyWith(
        suffixIcon: _consultando
            ? const Padding(
                padding: EdgeInsets.all(4),
                child: SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(strokeWidth: 1.6),
                ),
              )
            : GestureDetector(
                onTap: _consultar,
                child: const Icon(Icons.search, size: 14, color: AppColors.blue1),
              ),
        suffixIconConstraints:
            const BoxConstraints(minWidth: 20, minHeight: 20),
      ),
      onChanged: widget.onChanged,
    );
  }
}

/// Selección de celda: abre el menú al tocar cualquier parte de la celda.
class CeldaSeleccion extends StatelessWidget {
  final String? valor;
  final List<String> opciones;
  final ValueChanged<String?> onChanged;

  const CeldaSeleccion({
    super.key,
    required this.valor,
    required this.opciones,
    required this.onChanged,
  });

  static const _limpiar = '__limpiar__';

  @override
  Widget build(BuildContext context) {
    final actual = valor != null && opciones.contains(valor) ? valor : null;

    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: (v) => onChanged(v == _limpiar ? null : v),
      itemBuilder: (_) => [
        for (final o in opciones)
          PopupMenuItem(
            value: o,
            height: 34,
            child: Text(o, style: const TextStyle(fontSize: 12)),
          ),
        if (actual != null)
          const PopupMenuItem(
            value: _limpiar,
            height: 34,
            child: Text('Vaciar',
                style: TextStyle(fontSize: 12, color: Colors.grey)),
          ),
      ],
      child: Row(
        children: [
          Expanded(
            child: Text(
              actual ?? '—',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                color: actual == null ? Colors.grey.shade400 : Colors.black87,
              ),
            ),
          ),
          Icon(Icons.arrow_drop_down, size: 14, color: Colors.grey.shade500),
        ],
      ),
    );
  }
}
