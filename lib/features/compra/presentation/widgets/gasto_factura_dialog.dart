import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/utils/resource.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/styled_dialog.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import 'package:syncronize/features/categoria_gasto/domain/entities/categoria_gasto.dart';
import 'package:syncronize/features/categoria_gasto/domain/usecases/get_categorias_gasto_usecase.dart';

/// Estado editable del diálogo, compartido entre el contenido (que tiene los
/// campos) y el botón Guardar (que vive afuera, en `actions`).
///
/// `error` es un notifier y no un `setState` porque el botón está fuera del
/// widget del formulario: es la única forma de que un monto inválido pinte el
/// mensaje SIN cerrar el diálogo.
class _GastoDraft {
  _GastoDraft.desde(Map<String, dynamic>? inicial)
    : concepto = inicial?['concepto'] as String? ?? '',
      monto = (inicial?['monto'] as num?)?.toDouble(),
      prorratea = inicial?['prorratea'] as bool? ?? true,
      criterio = inicial?['criterio'] as String? ?? 'VALOR',
      categoriaGastoId = inicial?['categoriaGastoId'] as String?,
      categoriaNombre = inicial?['categoriaNombre'] as String?;

  String concepto;
  double? monto;
  bool prorratea;

  /// 'VALOR' (proporcional a la plata de cada línea) o 'CANTIDAD' (por
  /// unidades). Los strings son los del enum `CriterioProrrateo` del backend.
  String criterio;

  /// Categoría del catálogo de gastos. Opcional: sin ella el gasto se
  /// registra igual y cae en "Sin categoría" en el reporte.
  String? categoriaGastoId;

  /// Solo para mostrar en la lista sin volver a pedir el catálogo.
  String? categoriaNombre;

  final ValueNotifier<String?> error = ValueNotifier(null);

  String? validar() {
    if (concepto.trim().isEmpty) return 'Ponele un concepto al gasto';
    final m = monto;
    if (m == null || m <= 0) return 'El monto tiene que ser mayor a 0';
    return null;
  }

  Map<String, dynamic> aGasto() => {
    'concepto': concepto.trim(),
    // El DTO del backend valida máximo 2 decimales: un 10.999 tecleado
    // volvía como 400 recién al guardar la compra entera.
    'monto': (monto! * 100).round() / 100,
    'prorratea': prorratea,
    'criterio': criterio,
    // Va SIEMPRE, incluso en null: guardar reemplaza la lista ENTERA de
    // gastos, así que omitirlo le borraría la categoría al gasto editado.
    'categoriaGastoId': categoriaGastoId,
    // Solo para pintar la lista; `gastoAPayload` lo deja afuera.
    'categoriaNombre': categoriaNombre,
  };
}

/// El gasto tal como lo espera el backend.
///
/// 🔴 Elige los campos UNO POR UNO a propósito: el DTO corre con
/// `forbidNonWhitelisted`, así que una clave de más —el nombre de la
/// categoría, que el mapa lleva para poder mostrarlo— devuelve un 400 que
/// parece un bug del formulario. Lo usan las tres altas: compra standalone,
/// recepción desde OC y la edición desde el detalle.
Map<String, dynamic> gastoAPayload(Map<String, dynamic> g) => {
  'concepto': g['concepto'],
  'monto': g['monto'],
  'prorratea': g['prorratea'] ?? true,
  'criterio': g['criterio'] ?? 'VALOR',
  'categoriaGastoId': g['categoriaGastoId'],
};

/// Alta/edición de un gasto de la factura del proveedor: flete, movilidad,
/// embalaje, interés por pago diferido.
///
/// Devuelve `{concepto, monto, prorratea}`, o null si se canceló. Lo usan las
/// DOS pantallas que tocan gastos —el alta de la compra y el detalle de una
/// compra en BORRADOR—, para que la decisión de prorratear se explique igual
/// en las dos.
Future<Map<String, dynamic>?> mostrarDialogoGastoFactura(
  BuildContext context, {
  Map<String, dynamic>? inicial,
}) async {
  final draft = _GastoDraft.desde(inicial);

  final gasto = await StyledDialog.show<Map<String, dynamic>>(
    context,
    accentColor: AppColors.blue1,
    backgroundColor: Colors.white,
    icon: Icons.local_shipping_outlined,
    titulo: inicial == null ? 'Agregar gasto' : 'Editar gasto',
    subtitulo: 'Flete, movilidad, embalaje o cargos del proveedor',
    content: [_GastoFacturaForm(draft: draft)],
    actions: [
      Expanded(
        child: TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ),
      ),
      Expanded(
        child: CustomButton(
          text: 'Guardar',
          icon: const Icon(Icons.check, size: 14, color: Colors.white),
          backgroundColor: AppColors.blue1,
          textColor: Colors.white,
          onPressed: () {
            // 🔴 Validar ANTES de cerrar: antes el diálogo se cerraba igual y
            // el aviso salía en un snackbar con lo tecleado ya perdido.
            final error = draft.validar();
            if (error != null) {
              draft.error.value = error;
              return;
            }
            Navigator.pop(context, draft.aGasto());
          },
        ),
      ),
    ],
  );

  draft.error.dispose();
  return gasto;
}

/// Los campos del gasto.
///
/// 🔴 Es un StatefulWidget y no un StatefulBuilder con controllers del
/// llamador: así los controllers se destruyen cuando el diálogo termina de
/// desmontarse. Creados afuera y dispuestos apenas `await` devuelve, la
/// animación de salida seguía reconstruyendo los campos por varios frames y
/// reventaba con "used after being disposed".
/// Ver feedback_textcontroller_dispose_tras_dialog.
class _GastoFacturaForm extends StatefulWidget {
  const _GastoFacturaForm({required this.draft});

  final _GastoDraft draft;

  @override
  State<_GastoFacturaForm> createState() => _GastoFacturaFormState();
}

class _GastoFacturaFormState extends State<_GastoFacturaForm> {
  late final TextEditingController _conceptoCtrl;
  late final TextEditingController _montoCtrl;

  List<CategoriaGasto> _categorias = const [];
  bool _cargandoCategorias = true;

  @override
  void initState() {
    super.initState();
    final draft = widget.draft;
    _conceptoCtrl = TextEditingController(text: draft.concepto);
    _montoCtrl = TextEditingController(
      text: draft.monto != null ? draft.monto!.toStringAsFixed(2) : '',
    );
    _cargarCategorias();
  }

  /// Solo EGRESO: un gasto de factura nunca es un ingreso, y ofrecer el
  /// catálogo entero haría elegir entre categorías que no aplican.
  ///
  /// Si falla, el diálogo sigue usable sin categoría en vez de bloquear la
  /// carga del gasto: la categoría es opcional del lado del backend.
  Future<void> _cargarCategorias() async {
    final result = await locator<GetCategoriasGastoUseCase>()(tipo: 'EGRESO');
    if (!mounted) return;
    setState(() {
      if (result is Success<List<CategoriaGasto>>) _categorias = result.data;
      _cargandoCategorias = false;
    });
  }

  @override
  void dispose() {
    _conceptoCtrl.dispose();
    _montoCtrl.dispose();
    super.dispose();
  }

  void _limpiarError() {
    if (widget.draft.error.value != null) widget.draft.error.value = null;
  }

  /// La categoría es lo único que después se puede sumar: `concepto` es texto
  /// libre y "MOVILIDAD" contra "MOVILIDAD LIMA A TRUJILLO" son dos cosas
  /// distintas para cualquier reporte.
  Widget _buildSelectorCategoria(_GastoDraft draft) {
    if (_cargandoCategorias) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: SizedBox(
          height: 16,
          width: 16,
          child: CircularProgressIndicator(strokeWidth: 1.6),
        ),
      );
    }

    if (_categorias.isEmpty) {
      return Row(
        children: [
          Icon(Icons.info_outline, size: 13, color: Colors.grey.shade500),
          const SizedBox(width: 5),
          Expanded(
            child: AppSubtitle(
              'Sin categorías de egreso cargadas. El gasto se guarda igual, '
              'pero no va a poder sumarse por tipo.',
              fontSize: 9,
              maxLines: 3,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      );
    }

    final seleccionada = _categorias
        .where((c) => c.id == draft.categoriaGastoId)
        .firstOrNull;

    return CustomDropdown<CategoriaGasto>(
      value: seleccionada,
      borderColor: AppColors.blue1,
      hintText: 'Categoría (opcional)',
      prefixIcon: Icon(
        seleccionada?.iconData ?? Icons.category_rounded,
        color: seleccionada?.colorValue ?? AppColors.blue1,
        size: 18,
      ),
      items: _categorias
          .map(
            (c) => DropdownItem<CategoriaGasto>(
              value: c,
              label: c.nombre,
              leading: Icon(c.iconData, size: 18, color: c.colorValue),
            ),
          )
          .toList(),
      onChanged: (value) => setState(() {
        draft.categoriaGastoId = value?.id;
        draft.categoriaNombre = value?.nombre;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final draft = widget.draft;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomText(
          controller: _conceptoCtrl,
          label: 'Concepto',
          hintText: 'Movilidad Lima-Trujillo',
          borderColor: AppColors.blue1,
          onChanged: (v) {
            draft.concepto = v;
            _limpiarError();
          },
        ),
        const SizedBox(height: 10),
        CustomText(
          controller: _montoCtrl,
          label: 'Monto',
          hintText: '30.00',
          borderColor: AppColors.blue1,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: (v) {
            draft.monto = double.tryParse(v.trim().replaceAll(',', '.'));
            _limpiarError();
          },
        ),
        ValueListenableBuilder<String?>(
          valueListenable: draft.error,
          builder: (_, error, __) => error == null
              ? const SizedBox.shrink()
              : Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 13,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: AppSubtitle(
                          error,
                          fontSize: 10,
                          maxLines: 2,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        const SizedBox(height: 10),
        _buildSelectorCategoria(draft),
        const SizedBox(height: 8),
        // La decisión que importa: un flete sube el costo real de la
        // mercadería; un interés por pagar a 30 días no.
        //
        // 🔴 El interruptor y el selector de criterio comparten UN
        // StatefulBuilder: en dos hermanos, apagar el interruptor no
        // rebuildea al otro y el selector se queda pintado.
        StatefulBuilder(
          builder: (ctx, setLocal) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => setLocal(() => draft.prorratea = !draft.prorratea),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: draft.prorratea
                        ? AppColors.blue1.withValues(alpha: 0.05)
                        : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: draft.prorratea
                          ? AppColors.blue1.withValues(alpha: 0.35)
                          : Colors.grey.shade300,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppSubtitle(
                              'Sumar al costo de los productos',
                              font: AppFont.amazonEmberMedium,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                            const SizedBox(height: 2),
                            AppSubtitle(
                              draft.prorratea
                                  ? 'Se reparte entre las líneas según su valor'
                                  : 'Solo suma al total (interés, multa, recargo)',
                              fontSize: 9,
                              maxLines: 2,
                              color: Colors.grey.shade600,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: draft.prorratea,
                        onChanged: (v) => setLocal(() => draft.prorratea = v),
                        activeThumbColor: AppColors.blue1,
                      ),
                    ],
                  ),
                ),
              ),
              // Cómo se reparte. Solo tiene sentido si el gasto sube el
              // costo, así que acompaña al interruptor en vez de vivir
              // aparte.
              if (draft.prorratea) ...[
                const SizedBox(height: 8),
                AppSubtitle(
                  '¿Cómo se reparte?',
                  font: AppFont.amazonEmberMedium,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
                const SizedBox(height: 4),
                _OpcionCriterio(
                  titulo: 'Por valor de cada línea',
                  detalle: 'Lo que más cuesta se lleva más flete',
                  seleccionado: draft.criterio == 'VALOR',
                  onTap: () => setLocal(() => draft.criterio = 'VALOR'),
                ),
                const SizedBox(height: 4),
                _OpcionCriterio(
                  titulo: 'Por cantidad de unidades',
                  detalle: 'Para cuando lo barato es lo que ocupa',
                  seleccionado: draft.criterio == 'CANTIDAD',
                  onTap: () => setLocal(() => draft.criterio = 'CANTIDAD'),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Una de las dos formas de repartir. Radio hecho a mano: el `Radio` de M3
/// impone 48px de área táctil y desalinea una lista tan compacta.
class _OpcionCriterio extends StatelessWidget {
  const _OpcionCriterio({
    required this.titulo,
    required this.detalle,
    required this.seleccionado,
    required this.onTap,
  });

  final String titulo;
  final String detalle;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: seleccionado
              ? AppColors.blue1.withValues(alpha: 0.06)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: seleccionado
                ? AppColors.blue1.withValues(alpha: 0.35)
                : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 15,
              color: seleccionado ? AppColors.blue1 : Colors.grey.shade400,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppSubtitle(
                    titulo,
                    font: AppFont.amazonEmberMedium,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                  AppSubtitle(
                    detalle,
                    fontSize: 9,
                    maxLines: 2,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
