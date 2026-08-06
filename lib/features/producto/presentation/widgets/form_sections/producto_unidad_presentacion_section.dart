import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import '../../../../../core/fonts/app_text_widgets.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/gradient_container.dart';
import '../../../../../core/utils/unidad_presentacion.dart';
import '../../../../../core/widgets/custom_switch.dart';
import '../../../../auth/presentation/widgets/custom_text.dart';
import '../../../../catalogo/presentation/bloc/unidades_medida/unidades_medida_cubit.dart';
import '../../../../catalogo/presentation/bloc/unidades_medida/unidades_medida_state.dart';
import '../../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../../empresa/presentation/widgets/unidad_medida_dropdown.dart';

/// Sección opcional "Unidad de Presentación".
///
/// Cómo se le HABLA al cliente cuando la unidad de venta es demasiado chica
/// para mostrarla. Un alimento a granel necesita guardarse en GRAMOS —para que
/// el stock entero aguante los 22 000 de un saco y la balanza escriba enteros—
/// pero nadie cotiza ni cobra en gramos: el precio queda en S/0.008 y el
/// producto es, literalmente, incargable.
///
/// Con la presentación configurada (kg = 1000 g) se sigue guardando en gramos
/// y se muestra, se cobra y se imprime en kilos. NO cambia stock, costo ni
/// movimientos.
///
/// Gemela de [ProductoUnidadCompraSection] salvo por una regla propia: el
/// factor tiene que ser MAYOR a 1, porque la presentación existe para agrupar.
class ProductoUnidadPresentacionSection extends StatefulWidget {
  /// Unidad de VENTA, para validar que la presentación sea distinta y para
  /// poder mostrar la vista previa ("se guarda en g, se cobra en kg").
  final String? selectedUnidadMedidaId;
  final String? selectedUnidadPresentacionId;
  final TextEditingController factorPresentacionController;
  final ValueChanged<String?> onUnidadPresentacionChanged;
  final VoidCallback onChanged;

  const ProductoUnidadPresentacionSection({
    super.key,
    required this.selectedUnidadMedidaId,
    required this.selectedUnidadPresentacionId,
    required this.factorPresentacionController,
    required this.onUnidadPresentacionChanged,
    required this.onChanged,
  });

  @override
  State<ProductoUnidadPresentacionSection> createState() =>
      _ProductoUnidadPresentacionSectionState();
}

class _ProductoUnidadPresentacionSectionState
    extends State<ProductoUnidadPresentacionSection> {
  bool _expandido = false;

  @override
  void initState() {
    super.initState();
    _expandido = _tieneValores;
    // El controller es ChangeNotifier: al editar un producto el padre llena
    // el factor de forma asíncrona y hay que expandir cuando llegue.
    widget.factorPresentacionController.addListener(_onControllerChanged);
  }

  @override
  void didUpdateWidget(ProductoUnidadPresentacionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_expandido && _tieneValores) {
      setState(() => _expandido = true);
    }
    if (oldWidget.factorPresentacionController !=
        widget.factorPresentacionController) {
      oldWidget.factorPresentacionController
          .removeListener(_onControllerChanged);
      widget.factorPresentacionController.addListener(_onControllerChanged);
    }
  }

  @override
  void dispose() {
    widget.factorPresentacionController.removeListener(_onControllerChanged);
    super.dispose();
  }

  void _onControllerChanged() {
    // El campo alimenta la vista previa, así que hay que repintar en cada
    // tecla — no solo cuando se expande.
    if (mounted) setState(() {});
  }

  bool get _tieneValores =>
      widget.selectedUnidadPresentacionId != null ||
      widget.factorPresentacionController.text.trim().isNotEmpty;

  void _toggle() {
    setState(() {
      _expandido = !_expandido;
      if (!_expandido) {
        // Al colapsar, limpiar: semántica "este producto no usa presentación".
        widget.onUnidadPresentacionChanged(null);
        widget.factorPresentacionController.clear();
        widget.onChanged();
      }
    });
  }

  double? get _factor {
    final txt = widget.factorPresentacionController.text.trim();
    if (txt.isEmpty) return null;
    return double.tryParse(txt.replaceAll(',', '.'));
  }

  bool get _mismaUnidadConflicto =>
      widget.selectedUnidadPresentacionId != null &&
      widget.selectedUnidadPresentacionId == widget.selectedUnidadMedidaId;

  /// El backend rechaza factor <= 1. Se avisa acá para no gastar un viaje
  /// y un mensaje de error rojo genérico.
  bool get _factorInvalido {
    final f = _factor;
    return f != null && f <= 1;
  }

  @override
  Widget build(BuildContext context) {
    return GradientContainer(
      shadowStyle: ShadowStyle.neumorphic,
      borderColor: AppColors.blueborder,
      padding: const EdgeInsets.only(left: 12, right: 12, top: 4, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: AppSubtitle('UNIDAD DE PRESENTACIÓN')),
              CustomSwitch(value: _expandido, onChanged: (_) => _toggle()),
            ],
          ),
          Text(
            _expandido
                ? 'Se sigue guardando en la unidad de venta; solo cambia cómo se muestra y se cobra.'
                : 'Si guardás en una unidad chica (gramos, ml, cm) pero cobrás en otra (kilo, litro, metro), activá esta sección.',
            style: const TextStyle(
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
                  selectedUnidadId: widget.selectedUnidadPresentacionId,
                  onChanged: widget.onUnidadPresentacionChanged,
                  labelText: 'Unidad en la que cobrás (KG, LITRO, METRO…)',
                  hintText: 'Selecciona la unidad',
                );
              },
            ),
            const SizedBox(height: 8),
            CustomText(
              controller: widget.factorPresentacionController,
              borderColor: AppColors.blue1,
              label: 'Factor (cuántas unidades de venta = 1 de presentación)',
              hintText: 'Ej: 1000',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => widget.onChanged(),
            ),
            const SizedBox(height: 4),
            Text(
              'Ej: 1000 g por KG · 1000 ml por LITRO · 100 cm por METRO.',
              style: TextStyle(
                fontSize: 9,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            _buildVistaPrevia(context),
            if (_mismaUnidadConflicto)
              _buildError('La unidad de presentación debe ser distinta a la '
                  'de venta. Si ya vendés en esa unidad, dejá esto apagado.'),
            if (_factorInvalido)
              _buildError('El factor debe ser MAYOR a 1: la presentación '
                  'agrupa varias unidades de venta (1 kg = 1000 g).'),
          ],
        ],
      ),
    );
  }

  /// Vista previa en vivo. Es el punto donde se entiende el concepto (o donde
  /// se descubre que el factor está al revés): mostrar el resultado con
  /// números concretos evita cargar 0.001 en vez de 1000.
  Widget _buildVistaPrevia(BuildContext context) {
    final factor = _factor;
    if (widget.selectedUnidadPresentacionId == null ||
        factor == null ||
        factor <= 1 ||
        _mismaUnidadConflicto) {
      return const SizedBox.shrink();
    }

    // Las unidades ya están cargadas por el dropdown de arriba, así que esto
    // no dispara ninguna consulta extra: solo lee el estado del cubit.
    return BlocBuilder<UnidadMedidaCubit, UnidadMedidaState>(
      builder: (context, state) {
        if (state is! UnidadesEmpresaLoaded) return const SizedBox.shrink();

        String? simboloDe(String? id) {
          if (id == null) return null;
          for (final u in state.unidadesEmpresa) {
            if (u.id == id) return u.displayCorto;
          }
          return null;
        }

        final simVenta = simboloDe(widget.selectedUnidadMedidaId);
        final simPresentacion =
            simboloDe(widget.selectedUnidadPresentacionId);
        if (simPresentacion == null) return const SizedBox.shrink();

        // Se usa el MISMO traductor que el POS y el ticket, así lo que se
        // ve acá es literalmente lo que va a salir impreso.
        final u = UnidadPresentacion(
          factor: factor,
          simbolo: simPresentacion,
          simboloVenta: simVenta,
        );
        final unidadVenta = simVenta ?? 'unidades';

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
                  Icon(Icons.visibility_outlined,
                      size: 12, color: AppColors.blue1),
                  const SizedBox(width: 4),
                  Text(
                    'Así se va a ver',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.blue1,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _linea('Stock de ${_num(factor * 22)} $unidadVenta',
                  u.cantidadTexto(factor * 22)),
              _linea('Precio de S/0.008 por $unidadVenta',
                  u.precioTexto(0.008)),
              const SizedBox(height: 4),
              Text(
                'El stock y el costo se siguen guardando en $unidadVenta.',
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _linea(String desde, String hacia) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              desde,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade700),
            ),
          ),
          Icon(Icons.arrow_forward, size: 10, color: Colors.grey.shade500),
          const SizedBox(width: 4),
          Text(
            hacia,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: AppColors.blue1,
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
