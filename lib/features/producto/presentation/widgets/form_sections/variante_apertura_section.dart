import 'package:flutter/material.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../../core/utils/unidad_presentacion.dart';
import '../../../../../core/widgets/custom_dropdown.dart';
import '../../../../../core/widgets/custom_switch.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';
import '../../../domain/entities/producto_variante.dart';

/// Sección opcional "Al abrir este bulto".
///
/// Para el caso del saco cerrado vs granel: la empresa compra sacos de 15 kg y
/// decide vender algunos cerrados y abrir otros para vender suelto. Son dos
/// variantes del mismo producto con stock propio, y abrir es una operación
/// física que mueve stock de una a la otra.
///
///     ALIMENTO PERRO ADULTO
///     ├── SACO 15KG   ← acá se configura que se abre en GRANEL, rinde 15 000
///     └── GRANEL      ← se guarda en gramos, se cobra en kilos
///
/// Ojo: esto NO es la unidad de presentación. La presentación traduce cómo se
/// MUESTRA un mismo stock; la apertura mueve stock real entre dos variantes.
class VarianteAperturaSection extends StatefulWidget {
  /// Las otras variantes del mismo producto. El destino tiene que ser una de
  /// ellas — el backend lo valida, pero acá se evita el viaje.
  final List<ProductoVariante> variantesHermanas;
  final String? selectedVarianteAperturaId;
  final TextEditingController rendimientoController;
  final ValueChanged<String?> onVarianteAperturaChanged;
  final VoidCallback onChanged;

  const VarianteAperturaSection({
    super.key,
    required this.variantesHermanas,
    required this.selectedVarianteAperturaId,
    required this.rendimientoController,
    required this.onVarianteAperturaChanged,
    required this.onChanged,
  });

  @override
  State<VarianteAperturaSection> createState() =>
      _VarianteAperturaSectionState();
}

class _VarianteAperturaSectionState extends State<VarianteAperturaSection> {
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _expandido = _tieneValores;
    widget.rendimientoController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(VarianteAperturaSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_expandido && _tieneValores) {
      setState(() => _expandido = true);
    }
    if (oldWidget.rendimientoController != widget.rendimientoController) {
      oldWidget.rendimientoController.removeListener(_onControllerChanged);
      widget.rendimientoController.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.rendimientoController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  bool get _tieneValores =>
      widget.selectedVarianteAperturaId != null ||
      widget.rendimientoController.text.trim().isNotEmpty;

  void _toggle() {
    setState(() {
      _expandido = !_expandido;
      if (!_expandido) {
        // Al colapsar se limpia: "esta variante no se abre en nada".
        widget.onVarianteAperturaChanged(null);
        widget.rendimientoController.clear();
        widget.onChanged();
      }
    });
  }

  double? get _rendimiento {
    final txt = widget.rendimientoController.text.trim();
    if (txt.isEmpty) return null;
    return double.tryParse(txt.replaceAll(',', '.'));
  }

  /// El stock se maneja en enteros: un rendimiento fraccionario deja el
  /// destino imposible de cuadrar y el backend lo rechaza.
  bool get _rendimientoFraccionario {
    final r = _rendimiento;
    if (r == null) return false;
    return (r - r.roundToDouble()).abs() > 1e-6;
  }

  ProductoVariante? get _destino {
    final id = widget.selectedVarianteAperturaId;
    if (id == null) return null;
    for (final v in widget.variantesHermanas) {
      if (v.id == id) return v;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // Sin hermanas no hay nada que elegir: un producto de una sola variante no
    // puede abrirse en otra.
    if (widget.variantesHermanas.isEmpty) return const SizedBox.shrink();

    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AppSubtitle('AL ABRIR ESTE BULTO')),
              CustomSwitch(value: _expandido, onChanged: (_) => _toggle()),
            ],
          ),
          Text(
            _expandido
                ? 'Abrir descuenta 1 de esta variante y suma el rendimiento a la otra.'
                : 'Si esta variante es un bulto cerrado (saco, caja, bidón) que se abre para vender suelto, activá esta sección.',
            style: const TextStyle(
              fontSize: 10,
              color: AppColors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (_expandido) ...[
            const SizedBox(height: 10),
            CustomDropdown<String>(
              label: 'Se convierte en',
              hintText: 'Elegí la variante suelta',
              borderColor: AppColors.blue1,
              value: widget.selectedVarianteAperturaId,
              prefixIcon: const Icon(
                Icons.arrow_forward,
                size: 16,
                color: AppColors.blue1,
              ),
              // Un producto de 6 sabores deja 11 hermanas con nombres casi
              // iguales ("Sabor CARNE / Presentación GRANEL"): sin buscador
              // hay que scrollear leyendo etiquetas que solo cambian al final.
              showSearchBox: widget.variantesHermanas.length > 5,
              items: widget.variantesHermanas
                  .map((v) => DropdownItem(
                        value: v.id,
                        label: v.nombre,
                        // La presentación es lo que delata al granel (se cobra
                        // en kg): distingue el destino correcto de un saco
                        // hermano, que se vende por unidad y no la tiene.
                        trailing: _chipPresentacion(v),
                      ))
                  .toList(),
              onChanged: (value) {
                widget.onVarianteAperturaChanged(value);
                widget.onChanged();
              },
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: widget.rendimientoController,
              borderColor: AppColors.blue1,
              label: 'Rendimiento (cuánto sale de 1 bulto)',
              hintText: 'Ej: 15000',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => widget.onChanged(),
            ),
            const SizedBox(height: 4),
            Text(
              _destino != null
                  ? 'En la unidad de VENTA de "${_destino!.nombre}". Si esa variante se guarda en gramos, un saco de 15 kg son 15000.'
                  : 'En la unidad de VENTA de la variante destino.',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            _buildVistaPrevia(),
            if (_rendimientoFraccionario)
              _buildError('El rendimiento tiene que ser un número entero: el '
                  'stock se maneja en unidades enteras. Si necesitás decimales, '
                  'usá una unidad de venta más chica en la variante destino.'),
          ],
        ],
      ),
    );
  }

  /// Etiqueta con la unidad en la que se cobra la hermana ("kg"), para poder
  /// reconocer el granel de un vistazo dentro de una lista larga. Null cuando
  /// la variante no tiene presentación propia: no hay nada que aclarar.
  Widget? _chipPresentacion(ProductoVariante v) {
    final simbolo = v.unidadPresentacionSimbolo;
    if (!v.tienePresentacionPropia || simbolo == null) return null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        simbolo,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: AppColors.blue1,
        ),
      ),
    );
  }

  /// Vista previa con números concretos. Es donde se descubre que el
  /// rendimiento está en la unidad equivocada (15 en vez de 15000).
  Widget _buildVistaPrevia() {
    final destino = _destino;
    final rendimiento = _rendimiento;
    if (destino == null || rendimiento == null || rendimiento <= 0) {
      return const SizedBox.shrink();
    }

    // Si el destino tiene presentación propia, se muestra también en ella:
    // "15000 g → 15 kg" es lo que hace entender si el número está bien.
    String enPresentacion = '';
    if (destino.tienePresentacionPropia) {
      final u = UnidadPresentacion(
        factor: destino.factorPresentacion!,
        simbolo: destino.unidadPresentacionSimbolo,
      );
      enPresentacion = ' (${u.cantidadTexto(rendimiento)})';
    }

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.blue1.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.blue1.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.open_in_full, size: 12, color: AppColors.blue1),
              const SizedBox(width: 4),
              Text(
                'Al abrir 1',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '−1 de esta variante  →  +${_num(rendimiento)}$enPresentacion en "${destino.nombre}"',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.blue1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'El costo del bulto se reparte en el destino por promedio ponderado.',
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey.shade700,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  static String _num(double v) =>
      v == v.truncateToDouble() ? v.toInt().toString() : v.toString();

  Widget _buildError(String mensaje) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, size: 12, color: Colors.red.shade700),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                mensaje,
                style: TextStyle(fontSize: 10, color: Colors.red.shade900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
