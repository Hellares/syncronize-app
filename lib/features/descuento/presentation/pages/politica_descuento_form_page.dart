import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../../../core/theme/gradient_background.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../../../core/widgets/custom_dropdown.dart';
import '../../../../core/widgets/custom_switch_tile.dart';
import '../../../../core/widgets/date/custom_date.dart';
import '../../../auth/presentation/widgets/custom_text.dart';
import '../../../auth/presentation/widgets/custom_button.dart';
import '../../domain/entities/politica_descuento.dart';
import '../bloc/politica_form/politica_form_cubit.dart';
import '../bloc/politica_form/politica_form_state.dart';

class PoliticaDescuentoFormPage extends StatelessWidget {
  final String? politicaId;

  const PoliticaDescuentoFormPage({
    super.key,
    this.politicaId,
  });

  bool get isEditing => politicaId != null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<PoliticaFormCubit>(),
      child: _PoliticaFormView(
        politicaId: politicaId,
        isEditing: isEditing,
      ),
    );
  }
}

class _PoliticaFormView extends StatefulWidget {
  final String? politicaId;
  final bool isEditing;

  const _PoliticaFormView({
    this.politicaId,
    required this.isEditing,
  });

  @override
  State<_PoliticaFormView> createState() => _PoliticaFormViewState();
}

class _PoliticaFormViewState extends State<_PoliticaFormView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _valorDescuentoController = TextEditingController();
  final _descuentoMaximoController = TextEditingController();
  final _montoMinCompraController = TextEditingController();
  final _cantidadMaxUsosController = TextEditingController();
  final _prioridadController = TextEditingController();
  final _maxFamiliaresPorTrabajadorController = TextEditingController();
  final _markupController = TextEditingController();

  TipoDescuento _tipoDescuento = TipoDescuento.trabajador;
  TipoCalculoDescuento _tipoCalculo = TipoCalculoDescuento.porcentaje;
  EstrategiaMayor _estrategiaMayor = EstrategiaMayor.primerNivel;
  bool _aplicarATodos = false;

  /// true si el modo de cálculo es un precio especial VIP (costo / mayor),
  /// donde no se usa "valor de descuento" sino markup/estrategia.
  bool get _esModoVip =>
      _tipoCalculo == TipoCalculoDescuento.precioCosto ||
      _tipoCalculo == TipoCalculoDescuento.precioMayorDesdeUnidad;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing && widget.politicaId != null) {
      // Cargar datos de la política para editar después de que el widget esté montado
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.read<PoliticaFormCubit>().loadPolitica(widget.politicaId!);
        }
      });
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _valorDescuentoController.dispose();
    _descuentoMaximoController.dispose();
    _montoMinCompraController.dispose();
    _cantidadMaxUsosController.dispose();
    _prioridadController.dispose();
    _maxFamiliaresPorTrabajadorController.dispose();
    _markupController.dispose();
    super.dispose();
  }

  /// Actualiza los controladores con los datos de la política cargada
  void _updateFormData(PoliticaDescuento politica) {
    setState(() {
      _nombreController.text = politica.nombre;
      _descripcionController.text = politica.descripcion ?? '';
      _tipoDescuento = politica.tipoDescuento;
      _tipoCalculo = politica.tipoCalculo;
      _estrategiaMayor = politica.estrategiaMayor;
      _markupController.text =
          politica.markupSobreCosto?.toStringAsFixed(2) ?? '';
      _valorDescuentoController.text = politica.valorDescuento.toStringAsFixed(
          politica.tipoCalculo == TipoCalculoDescuento.porcentaje ? 0 : 2);
      _descuentoMaximoController.text =
          politica.descuentoMaximo?.toStringAsFixed(2) ?? '';
      _montoMinCompraController.text =
          politica.montoMinCompra?.toStringAsFixed(2) ?? '';
      _cantidadMaxUsosController.text = politica.cantidadMaxUsos?.toString() ?? '';
      _prioridadController.text = politica.prioridad.toString();
      _maxFamiliaresPorTrabajadorController.text =
          politica.maxFamiliaresPorTrabajador?.toString() ?? '';
      // Backend devuelve UTC; convertir a local para los pickers.
      _fechaInicio = politica.fechaInicio?.toLocal();
      _fechaFin = politica.fechaFin?.toLocal();
      _aplicarATodos = politica.aplicarATodos;
    });
  }


  void _submitForm() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor, completa todos los campos requeridos'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Vigencia: fechas OPCIONALES (sin fechas = política permanente).
    // Solo validamos coherencia si ambas están presentes.
    if (_fechaInicio != null &&
        _fechaFin != null &&
        _fechaFin!.isBefore(_fechaInicio!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La fecha de fin no puede ser anterior a la fecha de inicio'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // En modos VIP (costo / mayor) no se usa "valor de descuento": se manda 0
    // y el precio se resuelve por markup/estrategia + niveles en el backend.
    final valorDescuentoFinal = _esModoVip
        ? 0.0
        : double.tryParse(_valorDescuentoController.text) ?? 0.0;
    final markupFinal =
        _tipoCalculo == TipoCalculoDescuento.precioCosto &&
                _markupController.text.trim().isNotEmpty
            ? double.tryParse(_markupController.text)
            : null;
    final estrategiaFinal =
        _tipoCalculo == TipoCalculoDescuento.precioMayorDesdeUnidad
            ? _estrategiaMayor
            : null;

    if (widget.isEditing && widget.politicaId != null) {
      // Actualizar política existente
      context.read<PoliticaFormCubit>().updatePolitica(
            id: widget.politicaId!,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            tipoDescuento: _tipoDescuento,
            tipoCalculo: _tipoCalculo,
            valorDescuento: valorDescuentoFinal,
            descuentoMaximo: _descuentoMaximoController.text.isEmpty
                ? null
                : double.parse(_descuentoMaximoController.text),
            montoMinCompra: _montoMinCompraController.text.isEmpty
                ? null
                : double.parse(_montoMinCompraController.text),
            cantidadMaxUsos: _cantidadMaxUsosController.text.isEmpty
                ? null
                : int.parse(_cantidadMaxUsosController.text),
            fechaInicio: _fechaInicio,
            fechaFin: _fechaFin,
            aplicarATodos: _aplicarATodos,
            prioridad: _prioridadController.text.isEmpty
                ? null
                : int.parse(_prioridadController.text),
            maxFamiliaresPorTrabajador:
                _maxFamiliaresPorTrabajadorController.text.isEmpty
                    ? null
                    : int.parse(_maxFamiliaresPorTrabajadorController.text),
            markupSobreCosto: markupFinal,
            estrategiaMayor: estrategiaFinal,
          );
    } else {
      // Crear nueva política
      context.read<PoliticaFormCubit>().createPolitica(
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            tipoDescuento: _tipoDescuento,
            tipoCalculo: _tipoCalculo,
            valorDescuento: valorDescuentoFinal,
            descuentoMaximo: _descuentoMaximoController.text.isEmpty
                ? null
                : double.parse(_descuentoMaximoController.text),
            montoMinCompra: _montoMinCompraController.text.isEmpty
                ? null
                : double.parse(_montoMinCompraController.text),
            cantidadMaxUsos: _cantidadMaxUsosController.text.isEmpty
                ? null
                : int.parse(_cantidadMaxUsosController.text),
            fechaInicio: _fechaInicio,
            fechaFin: _fechaFin,
            aplicarATodos: _aplicarATodos,
            prioridad: _prioridadController.text.isEmpty
                ? null
                : int.parse(_prioridadController.text),
            maxFamiliaresPorTrabajador:
                _maxFamiliaresPorTrabajadorController.text.isEmpty
                    ? null
                    : int.parse(_maxFamiliaresPorTrabajadorController.text),
            markupSobreCosto: markupFinal,
            estrategiaMayor: estrategiaFinal,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<PoliticaFormCubit, PoliticaFormState>(
      listener: (context, state) {
        if (state is PoliticaFormLoadSuccess) {
          _updateFormData(state.politica);
        } else if (state is PoliticaFormCreateSuccess || state is PoliticaFormUpdateSuccess) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.isEditing
                  ? 'Política actualizada correctamente'
                  : 'Política creada correctamente'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        } else if (state is PoliticaFormError) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.transparent,
        extendBodyBehindAppBar: true,
        appBar: SmartAppBar(
          showLogo: false,
          title: widget.isEditing
              ? 'Editar Política'
              : 'Nueva Política de Descuento',
        ),
        body: GradientBackground(
          style: GradientStyle.professional,
          child: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildBasicInfoSection(),
                  const SizedBox(height: 24),
                  _buildDiscountConfigSection(),
                  const SizedBox(height: 24),
                  _buildRestrictionsSection(),
                  const SizedBox(height: 24),
                  _buildDateRangeSection(),
                  const SizedBox(height: 24),
                  _buildAdvancedSection(),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: widget.isEditing ? 'Actualizar' : 'Crear Política',
                    onPressed: _isLoading ? null : _submitForm,
                    isLoading: _isLoading,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return GradientContainer(
      gradient:AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Básica',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _nombreController,
              label: 'Politica',
              hintText: 'Nombre de la política',
              borderColor: AppColors.blue1,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'El nombre es requerido';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _descripcionController,
              label: 'Descripcion',
              hintText: 'Descripción (opcional)',
              borderColor: AppColors.blue1,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            CustomDropdown<TipoDescuento>(
              borderColor: AppColors.blue1,
              value: _tipoDescuento,
              items: TipoDescuento.values
                  .map((tipo) => DropdownItem(
                        value: tipo,
                        label: _getTipoDescuentoLabel(tipo),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tipoDescuento = value;
                  });
                }
              },
              label: 'Tipo de Descuento',
              hintText: 'Selecciona el tipo',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountConfigSection() {
    return GradientContainer(
      gradient:AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración del Descuento',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            CustomDropdown<TipoCalculoDescuento>(
              borderColor: AppColors.blue1,
              value: _tipoCalculo,
              items: TipoCalculoDescuento.values
                  .map((tipo) => DropdownItem(
                        value: tipo,
                        label: _getTipoCalculoLabel(tipo),
                      ))
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tipoCalculo = value;
                  });
                }
              },
              label: 'Tipo de Cálculo',
              hintText: 'Selecciona el tipo',
            ),
            const SizedBox(height: 16),
            // Modos %/monto: campo de valor de descuento.
            if (!_esModoVip) ...[
              CustomText(
                controller: _valorDescuentoController,
                hintText: _tipoCalculo == TipoCalculoDescuento.porcentaje
                    ? 'Porcentaje de Descuento (Ej: 15)'
                    : 'Monto Fijo de Descuento (Ej: 50.00)',
                borderColor: AppColors.blue1,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (_esModoVip) return null;
                  if (value == null || value.isEmpty) {
                    return 'El valor del descuento es requerido';
                  }
                  final number = double.tryParse(value);
                  if (number == null || number <= 0) {
                    return 'Ingresa un valor válido mayor a 0';
                  }
                  if (_tipoCalculo == TipoCalculoDescuento.porcentaje &&
                      number > 100) {
                    return 'El porcentaje no puede ser mayor a 100';
                  }
                  return null;
                },
              ),
              if (_tipoCalculo == TipoCalculoDescuento.porcentaje) ...[
                const SizedBox(height: 12),
                CustomText(
                  controller: _descuentoMaximoController,
                  hintText: 'Descuento Máximo en S/. (Ej: 100.00)',
                  borderColor: AppColors.blue1,
                  keyboardType: TextInputType.number,
                ),
              ],
            ],
            // Modo VIP: precio costo → markup opcional sobre el costo.
            if (_tipoCalculo == TipoCalculoDescuento.precioCosto) ...[
              CustomText(
                controller: _markupController,
                hintText: 'Markup sobre el costo en % (opcional, Ej: 5)',
                borderColor: AppColors.blue1,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              _buildAyuda(
                'Vende al precio de costo de la sede. Markup vacío o 0 = costo puro (margen 0).',
              ),
            ],
            // Modo VIP: mayor desde la unidad 1 → estrategia de escalón.
            if (_tipoCalculo ==
                TipoCalculoDescuento.precioMayorDesdeUnidad) ...[
              CustomDropdown<EstrategiaMayor>(
                borderColor: AppColors.blue1,
                value: _estrategiaMayor,
                items: EstrategiaMayor.values
                    .map((e) => DropdownItem(
                          value: e,
                          label: _getEstrategiaMayorLabel(e),
                        ))
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _estrategiaMayor = value);
                  }
                },
                label: 'Escalón a aplicar',
                hintText: 'Selecciona la estrategia',
              ),
              const SizedBox(height: 8),
              _buildAyuda(
                'Aplica el precio por mayor desde la primera unidad (sin esperar la cantidad mínima).',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRestrictionsSection() {
    return GradientContainer(
      gradient:AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Restricciones',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _montoMinCompraController,
              hintText: 'Monto Mínimo de Compra en S/. (Ej: 50.00)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _cantidadMaxUsosController,
              hintText: 'Cantidad Máxima de Usos (Ej: 10)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.number,
            ),
            if (_tipoDescuento == TipoDescuento.familiarTrabajador) ...[
              const SizedBox(height: 10),
              CustomText(
                controller: _maxFamiliaresPorTrabajadorController,
                hintText: 'Máximo de Familiares por Trabajador (Ej: 5)',
                borderColor: AppColors.blue1,
                keyboardType: TextInputType.number,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSection() {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vigencia',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            CustomDate(
              label: 'Fecha de Inicio',
              hintText: 'Seleccionar fecha de inicio',
              initialDate: _fechaInicio,
              onDateSelected: (date) {
                if (date == null) return;
                setState(() {
                  _fechaInicio = date;
                  // Si la fecha de fin es anterior a la nueva fecha de inicio, resetearla
                  if (_fechaFin != null && _fechaFin!.isBefore(date)) {
                    _fechaFin = null;
                  }
                });
              },
              borderColor: AppColors.blue1,
              dateFormat: 'dd/MM/yyyy',
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            ),
            const SizedBox(height: 12),
            CustomDate(
              label: 'Fecha de Fin',
              hintText: 'Seleccionar fecha de fin',
              initialDate: _fechaFin,
              onDateSelected: (date) {
                if (date == null) return;
                setState(() {
                  _fechaFin = date;
                });
              },
              borderColor: AppColors.blue1,
              dateFormat: 'dd/MM/yyyy',
              firstDate: _fechaInicio ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
            ),
            if (_fechaInicio != null && _fechaFin != null) ...[
              const SizedBox(height: 8),
              AppCaption(
                items: [
                  CaptionItem(
                    icon: Icons.event_available,
                    text: '${_fechaFin!.difference(_fechaInicio!).inDays + 1} días de vigencia',
                  ),
                ],
                color: AppColors.blue3,
                fontSize: 9,
              )
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAdvancedSection() {
    return GradientContainer(
      gradient:AppGradients.blueWhiteBlue(),
      borderColor: AppColors.blueborder,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración Avanzada',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            CustomSwitchTile(
              title: 'Aplicar a Todos',
              subtitle:
                  'Aplicar esta política a todos los usuarios automáticamente',
              value: _aplicarATodos,
              onChanged: (value) {
                setState(() {
                  _aplicarATodos = value;
                });
              },
            ),
            const SizedBox(height: 10),
            CustomText(
              controller: _prioridadController,
              hintText: 'Prioridad (mayor número = mayor prioridad)',
              borderColor: AppColors.blue1,
              keyboardType: TextInputType.number,
            ),
          ],
        ),
      ),
    );
  }

  /// Texto de ayuda bajo un campo, que envuelve en varias líneas (a diferencia
  /// de AppCaption, que es un Row sin wrap y desborda con textos largos).
  Widget _buildAyuda(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 12, color: AppColors.blue3),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 9, color: AppColors.blue3),
          ),
        ),
      ],
    );
  }

  String _getTipoDescuentoLabel(TipoDescuento tipo) {
    switch (tipo) {
      case TipoDescuento.trabajador:
        return 'Trabajador';
      case TipoDescuento.familiarTrabajador:
        return 'Familiar de Trabajador';
      case TipoDescuento.vip:
        return 'VIP';
      case TipoDescuento.promocional:
        return 'Promocional';
      case TipoDescuento.lealtad:
        return 'Lealtad';
      case TipoDescuento.cumpleanios:
        return 'Cumpleaños';
    }
  }

  String _getTipoCalculoLabel(TipoCalculoDescuento tipo) {
    switch (tipo) {
      case TipoCalculoDescuento.porcentaje:
        return 'Porcentaje (%)';
      case TipoCalculoDescuento.montoFijo:
        return 'Monto Fijo (S/.)';
      case TipoCalculoDescuento.precioCosto:
        return 'Precio Costo (VIP)';
      case TipoCalculoDescuento.precioMayorDesdeUnidad:
        return 'Mayor desde 1 unidad (VIP)';
    }
  }

  String _getEstrategiaMayorLabel(EstrategiaMayor estrategia) {
    switch (estrategia) {
      case EstrategiaMayor.primerNivel:
        return 'Primer escalón por mayor';
      case EstrategiaMayor.mejorNivel:
        return 'Mejor precio disponible';
    }
  }

}
