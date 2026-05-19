import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/currency/currency_formatter.dart';
import 'package:syncronize/core/widgets/currency/currency_textfield.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../domain/entities/precio_nivel.dart';
import '../../data/models/precio_nivel_model.dart';

/// Diálogo para crear o editar un nivel de precio
class PrecioNivelFormDialog extends StatefulWidget {
  final double? precioBase;
  final double? precioCosto;
  final PrecioNivel? nivelToEdit;
  final List<PrecioNivel> nivelesExistentes;
  final Function(PrecioNivelDto) onSave;

  /// Si está set, fuerza el tipo de precio y oculta el selector. Útil cuando
  /// el dialog se abre desde un contexto que solo gestiona un tipo (ej. la
  /// pantalla "Configurar Precios" que solo permite niveles PRECIO_FIJO).
  final TipoPrecioNivel? lockTipoPrecio;

  const PrecioNivelFormDialog({
    super.key,
    this.precioBase,
    this.precioCosto,
    this.nivelToEdit,
    required this.nivelesExistentes,
    required this.onSave,
    this.lockTipoPrecio,
  });

  @override
  State<PrecioNivelFormDialog> createState() => _PrecioNivelFormDialogState();
}

class _PrecioNivelFormDialogState extends State<PrecioNivelFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _cantidadMinimaController = TextEditingController();
  final _cantidadMaximaController = TextEditingController();
  final _precioController = TextEditingController();
  final _porcentajeController = TextEditingController();
  final _descripcionController = TextEditingController();

  TipoPrecioNivel _tipoPrecio = TipoPrecioNivel.precioFijo;
  bool _tieneCantidadMaxima = false;

  @override
  void initState() {
    super.initState();
    if (widget.nivelToEdit != null) {
      final nivel = widget.nivelToEdit!;
      _nombreController.text = nivel.nombre;
      _cantidadMinimaController.text = nivel.cantidadMinima.toString();
      if (nivel.cantidadMaxima != null) {
        _cantidadMaximaController.text = nivel.cantidadMaxima.toString();
        _tieneCantidadMaxima = true;
      }
      _tipoPrecio = nivel.tipoPrecio;
      if (nivel.precio != null) {
        _precioController.text = nivel.precio!.toStringAsFixed(2);
      }
      if (nivel.porcentajeDesc != null) {
        _porcentajeController.text = nivel.porcentajeDesc!.toString();
      }
      if (nivel.descripcion != null) {
        _descripcionController.text = nivel.descripcion!;
      }
    } else {
      _nombreController.text = _generarNombreSugerido();
      final sugerencia = _sugerirCantidadMinimaInicial();
      if (sugerencia != null) {
        _cantidadMinimaController.text = sugerencia.toString();
      }
    }
    // Si el caller forzó un tipo, sobrescribimos lo que sea que haya quedado
    // (en edición respeta el del nivel; al crear nuevo, fuerza desde el inicio).
    if (widget.lockTipoPrecio != null) {
      _tipoPrecio = widget.lockTipoPrecio!;
    }
  }

  /// Sugerencia de cantidad mínima al crear un nivel nuevo: el siguiente
  /// número después del rango más alto registrado. Si el último nivel tiene
  /// cantidadMaxima, usa max+1; si no, usa min+1. Devuelve null si no hay
  /// niveles previos.
  int? _sugerirCantidadMinimaInicial() {
    if (widget.nivelesExistentes.isEmpty) return null;
    final ordenados = [...widget.nivelesExistentes]
      ..sort((a, b) => a.cantidadMinima.compareTo(b.cantidadMinima));
    final ultimo = ordenados.last;
    return (ultimo.cantidadMaxima ?? ultimo.cantidadMinima) + 1;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _cantidadMinimaController.dispose();
    _cantidadMaximaController.dispose();
    _precioController.dispose();
    _porcentajeController.dispose();
    _descripcionController.dispose();
    super.dispose();
  }

  String _generarNombreSugerido() {
    if (widget.lockTipoPrecio == TipoPrecioNivel.precioFijo) {
      final fijos = widget.nivelesExistentes
          .where((n) => n.tipoPrecio == TipoPrecioNivel.precioFijo)
          .length;
      if (fijos == 0) return 'Por Mayor';
      if (fijos == 1) return 'Por Cientos';
      if (fijos == 2) return 'Mayoreo';
      return 'Nivel fijo ${fijos + 1}';
    }
    final count = widget.nivelesExistentes.length;
    if (count == 0) return 'Precio Retail';
    if (count == 1) return 'Precio por Mayor';
    if (count == 2) return 'Precio Distribuidor';
    return 'Nivel ${count + 1}';
  }

  /// Detecta si la cantidad mínima propuesta (junto con la máxima opcional)
  /// solapa con algún nivel existente distinto al que se está editando.
  PrecioNivel? _detectarSolapamiento(int cantMin, int? cantMax) {
    final propMax = cantMax ?? (1 << 30);
    for (final n in widget.nivelesExistentes) {
      if (widget.nivelToEdit != null && n.id == widget.nivelToEdit!.id) {
        continue;
      }
      final eMax = n.cantidadMaxima ?? (1 << 30);
      // Dos rangos [a,b] y [c,d] solapan si a <= d && c <= b.
      final solapa = cantMin <= eMax && n.cantidadMinima <= propMax;
      if (solapa) return n;
    }
    return null;
  }

  String? _validateNombre(String? value) {
    if (value == null || value.trim().isEmpty) return 'Ingresa un nombre';
    return null;
  }

  String? _validateCantidadMinima(String? value) {
    if (value == null || value.isEmpty) return 'Requerido';
    final cantidad = int.tryParse(value);
    if (cantidad == null || cantidad < 1) return 'Mínimo 1';
    final cantMax = _tieneCantidadMaxima
        ? int.tryParse(_cantidadMaximaController.text)
        : null;
    final solape = _detectarSolapamiento(cantidad, cantMax);
    if (solape != null) {
      return 'Solapa con "${solape.nombre}"';
    }
    return null;
  }

  String? _validateCantidadMaxima(String? value) {
    if (!_tieneCantidadMaxima) return null;
    if (value == null || value.isEmpty) return 'Requerido';
    final max = int.tryParse(value);
    final min = int.tryParse(_cantidadMinimaController.text);
    if (max == null || max < 1) return 'Mínimo 1';
    if (min != null && max <= min) return 'Debe ser > $min';
    return null;
  }

  String? _validatePrecio(String? value) {
    if (_tipoPrecio != TipoPrecioNivel.precioFijo) return null;
    final precio = CurrencyUtilsImproved.parseToDouble(value ?? '');
    if (precio <= 0) return 'Ingresa el precio';
    final base = widget.precioBase;
    if (base != null && base > 0 && precio >= base) {
      return 'Debe ser < S/ ${base.toStringAsFixed(2)}';
    }
    return null;
  }

  String? _validatePorcentaje(String? value) {
    if (_tipoPrecio != TipoPrecioNivel.porcentajeDescuento) return null;
    if (value == null || value.isEmpty) return 'Ingresa el porcentaje';
    final porcentaje = double.tryParse(value);
    if (porcentaje == null || porcentaje < 0 || porcentaje > 100) {
      return 'Entre 0 y 100';
    }
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final dto = PrecioNivelDto(
      nombre: _nombreController.text.trim(),
      cantidadMinima: int.parse(_cantidadMinimaController.text),
      cantidadMaxima: _tieneCantidadMaxima
          ? int.tryParse(_cantidadMaximaController.text)
          : null,
      tipoPrecio: _tipoPrecio,
      precio: _tipoPrecio == TipoPrecioNivel.precioFijo
          ? CurrencyUtilsImproved.parseToDouble(_precioController.text)
          : null,
      porcentajeDesc: _tipoPrecio == TipoPrecioNivel.porcentajeDescuento
          ? double.tryParse(_porcentajeController.text)
          : null,
      descripcion: _descripcionController.text.trim().isEmpty
          ? null
          : _descripcionController.text.trim(),
      orden: widget.nivelToEdit?.orden ?? widget.nivelesExistentes.length,
    );

    widget.onSave(dto);
    Navigator.pop(context);
  }

  double? _calcularPrecioFinal() {
    if (widget.precioBase == null) return null;

    if (_tipoPrecio == TipoPrecioNivel.precioFijo) {
      final p = CurrencyUtilsImproved.parseToDouble(_precioController.text);
      return p > 0 ? p : null;
    } else {
      final porcentaje = double.tryParse(_porcentajeController.text);
      if (porcentaje != null) {
        return widget.precioBase! * (1 - porcentaje / 100);
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.nivelToEdit != null;
    final precioCalculado = _calcularPrecioFinal();
    final esFijo = _tipoPrecio == TipoPrecioNivel.precioFijo;
    final subtitleTipo = esFijo ? 'Precio fijo' : 'Descuento porcentual';

    return Dialog(
      child: GradientContainer(
        gradient: AppGradients.blueWhiteDialog(),
        padding: const EdgeInsets.only(left: 15, right: 15, top: 10),
        borderRadius: BorderRadius.circular(10.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con icono + título + subtítulo
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.bluechip,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      esFijo ? Icons.attach_money : Icons.percent,
                      color: AppColors.blue1,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppTitle(
                          isEditing ? 'Editar nivel' : 'Nuevo nivel',
                        ),
                        AppSubtitle(
                          subtitleTipo,
                          fontSize: 10,
                          color: AppColors.blue1,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              // Referencia precios del producto (venta + costo)
              if (widget.precioBase != null || widget.precioCosto != null) ...[
                _buildReferenciaPrecios(),
                const SizedBox(height: 12),
              ],

              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre
                    CustomText(
                      controller: _nombreController,
                      label: 'Nombre del nivel',
                      hintText: 'Ej: Por Mayor, Distribuidor',
                      borderColor: AppColors.blue1,
                      autovalidateMode: AutovalidateModeX.disabled,
                      validator: _validateNombre,
                    ),
                    const SizedBox(height: 14),

                    // Sección rango
                    Row(
                      children: [
                        Icon(Icons.numbers, size: 13, color: AppColors.blue1),
                        const SizedBox(width: 4),
                        AppSubtitle(
                          'Rango de cantidades',
                          fontSize: 11,
                          color: AppColors.textPrimary,
                        ),
                      ],
                    ),
                    // Chips de niveles existentes (read-only) para que el
                    // usuario vea desde dónde puede comenzar el nuevo nivel.
                    if (widget.nivelesExistentes.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      _buildNivelesExistentesChips(),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: CustomText(
                            controller: _cantidadMinimaController,
                            fieldType: FieldType.number,
                            label: 'Mínimo',
                            hintText: 'uds.',
                            borderColor: AppColors.blue1,
                            autovalidateMode: AutovalidateModeX.disabled,
                            validator: _validateCantidadMinima,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: CustomText(
                            controller: _cantidadMaximaController,
                            fieldType: FieldType.number,
                            label: 'Máximo',
                            hintText: 'uds.',
                            borderColor: AppColors.blue1,
                            enabled: _tieneCantidadMaxima,
                            autovalidateMode: AutovalidateModeX.disabled,
                            validator: _validateCantidadMaxima,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: Checkbox(
                            value: _tieneCantidadMaxima,
                            onChanged: (value) {
                              setState(() {
                                _tieneCantidadMaxima = value ?? false;
                                if (!_tieneCantidadMaxima) {
                                  _cantidadMaximaController.clear();
                                }
                              });
                            },
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() {
                              _tieneCantidadMaxima = !_tieneCantidadMaxima;
                              if (!_tieneCantidadMaxima) {
                                _cantidadMaximaController.clear();
                              }
                            }),
                            child: AppSubtitle(
                              'Establecer cantidad máxima',
                              fontSize: 10,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Selector de tipo (oculto si caller fija el tipo)
                    if (widget.lockTipoPrecio == null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.tune, size: 13, color: AppColors.blue1),
                          const SizedBox(width: 4),
                          AppSubtitle(
                            'Tipo de precio',
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _buildTipoSelector(),
                      const SizedBox(height: 14),
                    ] else
                      const SizedBox(height: 14),

                    // Precio fijo o porcentaje
                    if (esFijo)
                      CurrencyTextField(
                        controller: _precioController,
                        label: 'Precio unitario',
                        borderColor: AppColors.blue1,
                        validator: _validatePrecio,
                        onChanged: (_) => setState(() {}),
                      )
                    else
                      CustomText(
                        controller: _porcentajeController,
                        label: 'Porcentaje de descuento',
                        hintText: 'Ej: 10',
                        suffixText: '%',
                        borderColor: AppColors.blue1,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}')),
                        ],
                        autovalidateMode: AutovalidateModeX.disabled,
                        validator: _validatePorcentaje,
                        onChanged: (_) => setState(() {}),
                      ),

                    // Preview del precio final — label compacto pegado al input.
                    if (precioCalculado != null) ...[
                      const SizedBox(height: 4),
                      _buildPrecioFinalLabel(precioCalculado),
                      // Warning: precio final por debajo del costo → pérdida
                      if (widget.precioCosto != null &&
                          widget.precioCosto! > 0 &&
                          precioCalculado < widget.precioCosto!) ...[
                        const SizedBox(height: 6),
                        _buildPerdidaWarning(precioCalculado),
                      ],
                    ],

                    const SizedBox(height: 14),

                    // Descripción
                    CustomText(
                      controller: _descripcionController,
                      label: 'Descripción (opcional)',
                      hintText: 'Ej: 10% de descuento por compra mayor',
                      borderColor: AppColors.blue1,
                      maxLines: 2,
                      height: 56,
                      autovalidateMode: AutovalidateModeX.disabled,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // Botones
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: AppSubtitle(
                      'Cancelar',
                      fontSize: 12,
                      color: AppColors.blue1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.blue1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                    child: AppSubtitle(
                      isEditing ? 'Actualizar' : 'Crear',
                      fontSize: 12,
                      color: Colors.white,
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

  Widget _buildTipoSelector() {
    return Row(
      children: [
        Expanded(child: _buildTipoChip(TipoPrecioNivel.precioFijo)),
        const SizedBox(width: 8),
        Expanded(child: _buildTipoChip(TipoPrecioNivel.porcentajeDescuento)),
      ],
    );
  }

  Widget _buildTipoChip(TipoPrecioNivel tipo) {
    final selected = _tipoPrecio == tipo;
    final esFijo = tipo == TipoPrecioNivel.precioFijo;
    return InkWell(
      onTap: () => setState(() => _tipoPrecio = tipo),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.blue1.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? AppColors.blue1
                : AppColors.blue1.withValues(alpha: 0.25),
            width: selected ? 1.2 : 0.8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              esFijo ? Icons.attach_money : Icons.percent,
              size: 14,
              color: selected ? AppColors.blue1 : Colors.grey.shade600,
            ),
            const SizedBox(width: 6),
            AppSubtitle(
              esFijo ? 'Precio Fijo' : '% Descuento',
              fontSize: 11,
              color: selected ? AppColors.blue1 : Colors.grey.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNivelesExistentesChips() {
    final ordenados = [...widget.nivelesExistentes]
      ..sort((a, b) => a.cantidadMinima.compareTo(b.cantidadMinima));
    final editId = widget.nivelToEdit?.id;
    return SizedBox(
      height: 24,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: ordenados.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final n = ordenados[i];
          final esActual = n.id == editId;
          final rango = n.cantidadMaxima != null
              ? '${n.cantidadMinima}-${n.cantidadMaxima}'
              : '${n.cantidadMinima}+';
          final precio = n.tipoPrecio == TipoPrecioNivel.precioFijo
              ? (n.precio != null ? 'S/ ${n.precio!.toStringAsFixed(2)}' : null)
              : (n.porcentajeDesc != null
                  ? '-${n.porcentajeDesc!.toStringAsFixed(0)}%'
                  : null);
          final etiqueta = precio != null
              ? '${n.nombre} · $rango · $precio'
              : '${n.nombre} · $rango';
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: esActual
                  ? Colors.amber.shade100
                  : AppColors.bluechip.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: esActual
                    ? Colors.amber.shade400
                    : AppColors.blue1.withValues(alpha: 0.2),
                width: 0.6,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  etiqueta,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: esActual
                        ? Colors.amber.shade900
                        : AppColors.blue1,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildReferenciaPrecios() {
    final base = widget.precioBase;
    final costo = widget.precioCosto;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bluechip.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (base != null && base > 0)
            Expanded(
              child: _buildReferenciaCol(
                label: 'Precio venta',
                valor: 'S/ ${base.toStringAsFixed(2)}',
                icon: Icons.sell_outlined,
                color: AppColors.blue1,
              ),
            ),
          if (base != null && base > 0 && costo != null && costo > 0)
            Container(
              width: 1,
              height: 28,
              color: AppColors.blue1.withValues(alpha: 0.2),
              margin: const EdgeInsets.symmetric(horizontal: 8),
            ),
          if (costo != null && costo > 0)
            Expanded(
              child: _buildReferenciaCol(
                label: 'Precio costo',
                valor: 'S/ ${costo.toStringAsFixed(2)}',
                icon: Icons.shopping_cart_outlined,
                color: Colors.grey.shade700,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildReferenciaCol({
    required String label,
    required String valor,
    required IconData icon,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                valor,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPerdidaWarning(double precioFinal) {
    final perdida = (widget.precioCosto ?? 0) - precioFinal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade300, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded,
              size: 16, color: Colors.red.shade700),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pérdida de S/ ${perdida.toStringAsFixed(2)} por unidad',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.red.shade800,
                  ),
                ),
                Text(
                  'El precio fijo está por debajo del costo de compra',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.red.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrecioFinalLabel(double precio) {
    final base = widget.precioBase;
    final ahorroPct = (base != null && base > 0)
        ? ((base - precio) / base) * 100
        : null;
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Row(
        children: [
          Icon(Icons.savings_outlined,
              size: 12, color: Colors.green.shade700),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Precio final S/ ${precio.toStringAsFixed(2)}'
              '${ahorroPct != null && ahorroPct > 0 ? "  (−${ahorroPct.toStringAsFixed(1)}%)" : ""}',
              style: TextStyle(
                fontSize: 9,
                color: Colors.green.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
