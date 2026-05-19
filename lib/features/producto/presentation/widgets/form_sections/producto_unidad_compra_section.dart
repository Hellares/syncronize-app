import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';
import '../../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../../empresa/presentation/widgets/unidad_medida_dropdown.dart';

/// Sección opcional "Unidad de Compra".
///
/// Permite definir una unidad distinta a la de venta (PAQUETE de 100
/// BOLSAS, KG de 1000 GR, etc.) + el factor de conversión. El módulo
/// Compras leerá estos datos para ofrecer al usuario cargar líneas en
/// unidad de compra (más rápido) y convertir automáticamente a unidad
/// atómica antes de afectar stock/precio.
///
/// La sección se autoexpande si el producto ya tiene unidadCompra
/// configurada y se mantiene compacta si no.
class ProductoUnidadCompraSection extends StatefulWidget {
  final String? selectedUnidadMedidaId; // Unidad de venta (para validar distinta)
  final String? selectedUnidadCompraId;
  final TextEditingController factorCompraController;
  final ValueChanged<String?> onUnidadCompraChanged;
  final VoidCallback onChanged;

  const ProductoUnidadCompraSection({
    super.key,
    required this.selectedUnidadMedidaId,
    required this.selectedUnidadCompraId,
    required this.factorCompraController,
    required this.onUnidadCompraChanged,
    required this.onChanged,
  });

  @override
  State<ProductoUnidadCompraSection> createState() =>
      _ProductoUnidadCompraSectionState();
}

class _ProductoUnidadCompraSectionState
    extends State<ProductoUnidadCompraSection> {
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _expandido = widget.selectedUnidadCompraId != null ||
        widget.factorCompraController.text.trim().isNotEmpty;
  }

  void _toggle() {
    setState(() {
      _expandido = !_expandido;
      if (!_expandido) {
        // Al colapsar, limpiar selección (semántica: "no usar unidad de compra").
        widget.onUnidadCompraChanged(null);
        widget.factorCompraController.clear();
        widget.onChanged();
      }
    });
  }

  bool get _mismaUnidadConflicto =>
      widget.selectedUnidadCompraId != null &&
      widget.selectedUnidadCompraId == widget.selectedUnidadMedidaId;

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 8, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AppSubtitle('UNIDAD DE COMPRA')),
              Switch(
                value: _expandido,
                onChanged: (_) => _toggle(),
                activeThumbColor: AppColors.blue1,
              ),
            ],
          ),
          Text(
            _expandido
                ? 'Definí cómo te vende el proveedor y cuántas unidades de venta trae cada una.'
                : 'Si tu proveedor te vende en otra unidad (paquete, kilo, docena…), activá esta sección.',
            style: TextStyle(
              fontSize: 10,
              color: AppColors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
          if (_expandido) ...[
            const SizedBox(height: 10),
            BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
              builder: (context, state) {
                if (state is! EmpresaContextLoaded) {
                  return const SizedBox.shrink();
                }
                return UnidadMedidaDropdown(
                  empresaId: state.context.empresa.id,
                  selectedUnidadId: widget.selectedUnidadCompraId,
                  onChanged: widget.onUnidadCompraChanged,
                  labelText: 'Unidad de compra (PAQUETE, KG, DOCENA…)',
                  hintText: 'Selecciona la unidad',
                );
              },
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: widget.factorCompraController,
              borderColor: AppColors.blue1,
              label: 'Factor (cuántas unidades de venta = 1 unidad de compra)',
              hintText: 'Ej: 100',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => widget.onChanged(),
            ),
            const SizedBox(height: 4),
            Text(
              'Ej: 100 BOLSAS por PAQUETE · 1000 GR por KG · 12 UND por DOCENA.',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (_mismaUnidadConflicto) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        size: 12, color: Colors.red.shade700),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        'La unidad de compra debe ser distinta a la de venta.',
                        style: TextStyle(
                            fontSize: 10, color: Colors.red.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
