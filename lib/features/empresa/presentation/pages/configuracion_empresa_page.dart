import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/info_chip.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../../../../core/widgets/smart_appbar.dart';
import '../../domain/entities/configuracion_empresa.dart';
import '../bloc/configuracion_empresa/configuracion_empresa_cubit.dart';
import '../bloc/configuracion_empresa/configuracion_empresa_state.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';

class ConfiguracionEmpresaPage extends StatefulWidget {
  const ConfiguracionEmpresaPage({super.key});

  @override
  State<ConfiguracionEmpresaPage> createState() =>
      _ConfiguracionEmpresaPageState();
}

class _ConfiguracionEmpresaPageState extends State<ConfiguracionEmpresaPage> {
  final _formKey = GlobalKey<FormState>();

  final _impuestoController = TextEditingController();
  final _nombreImpuestoController = TextEditingController();
  final _simboloMonedaController = TextEditingController();
  final _diasVigenciaController = TextEditingController();
  final _condicionesController = TextEditingController();

  // Etiquetas equipo
  final _etiquetaSeccionController = TextEditingController();
  final _etiquetaTipoController = TextEditingController();
  final _etiquetaMarcaController = TextEditingController();
  final _etiquetaSerieController = TextEditingController();
  final _etiquetaCondicionController = TextEditingController();
  bool _mostrarSeccionEquipo = true;

  String _monedaPrincipal = 'PEN';
  List<String> _monedasPermitidas = ['PEN', 'USD'];

  String? _empresaId;
  String? _rubro;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      _empresaId = empresaState.context.empresa.id;
      _rubro = empresaState.context.empresa.rubro;
      context.read<ConfiguracionEmpresaCubit>().cargar(_empresaId!);
    }
  }

  @override
  void dispose() {
    _impuestoController.dispose();
    _nombreImpuestoController.dispose();
    _simboloMonedaController.dispose();
    _diasVigenciaController.dispose();
    _condicionesController.dispose();
    _etiquetaSeccionController.dispose();
    _etiquetaTipoController.dispose();
    _etiquetaMarcaController.dispose();
    _etiquetaSerieController.dispose();
    _etiquetaCondicionController.dispose();
    super.dispose();
  }

  void _populateFields(ConfiguracionEmpresa config) {
    _impuestoController.text = config.impuestoDefaultPorcentaje.toString();
    _nombreImpuestoController.text = config.nombreImpuesto;
    _simboloMonedaController.text = config.simboloMoneda;
    _diasVigenciaController.text = config.diasVigenciaCotizacion.toString();
    _condicionesController.text = config.condicionesDefault ?? '';
    _monedaPrincipal = config.monedaPrincipal;
    _monedasPermitidas = List.from(config.monedasPermitidas);

    // Etiquetas equipo: usar las guardadas o defaults por rubro
    final defaults = _defaultsPorRubro(_rubro);
    _etiquetaSeccionController.text = config.etiquetaSeccionEquipo ?? defaults['etiquetaSeccionEquipo'] ?? 'EQUIPO';
    _etiquetaTipoController.text = config.etiquetaTipoEquipo ?? defaults['etiquetaTipoEquipo'] ?? 'Tipo de equipo';
    _etiquetaMarcaController.text = config.etiquetaMarcaEquipo ?? defaults['etiquetaMarcaEquipo'] ?? 'Marca';
    _etiquetaSerieController.text = config.etiquetaNumeroSerie ?? defaults['etiquetaNumeroSerie'] ?? 'Número de serie';
    _etiquetaCondicionController.text = config.etiquetaCondicionEquipo ?? defaults['etiquetaCondicionEquipo'] ?? 'Condición del equipo';
    _mostrarSeccionEquipo = config.mostrarSeccionEquipo;
  }

  Map<String, dynamic> _defaultsPorRubro(String? rubro) {
    const defaults = {
      'TECNOLOGIA': {
        'etiquetaSeccionEquipo': 'EQUIPO',
        'etiquetaTipoEquipo': 'Tipo de equipo',
        'etiquetaMarcaEquipo': 'Marca',
        'etiquetaNumeroSerie': 'Número de serie',
        'etiquetaCondicionEquipo': 'Condición del equipo',
        'mostrarSeccionEquipo': true,
      },
      'AUTOMOTRIZ': {
        'etiquetaSeccionEquipo': 'VEHÍCULO',
        'etiquetaTipoEquipo': 'Tipo de vehículo',
        'etiquetaMarcaEquipo': 'Marca / Modelo',
        'etiquetaNumeroSerie': 'Placa',
        'etiquetaCondicionEquipo': 'Estado del vehículo',
        'mostrarSeccionEquipo': true,
      },
      'HOGAR': {
        'etiquetaSeccionEquipo': 'ELECTRODOMÉSTICO',
        'etiquetaTipoEquipo': 'Tipo de electrodoméstico',
        'etiquetaMarcaEquipo': 'Marca / Modelo',
        'etiquetaNumeroSerie': 'Número de serie',
        'etiquetaCondicionEquipo': 'Estado del equipo',
        'mostrarSeccionEquipo': true,
      },
      'CONSTRUCCION': {
        'etiquetaSeccionEquipo': 'MAQUINARIA',
        'etiquetaTipoEquipo': 'Tipo de maquinaria',
        'etiquetaMarcaEquipo': 'Marca / Modelo',
        'etiquetaNumeroSerie': 'N° serie / Placa',
        'etiquetaCondicionEquipo': 'Estado de la maquinaria',
        'mostrarSeccionEquipo': true,
      },
      'DEPORTES': {
        'etiquetaSeccionEquipo': 'ARTÍCULO',
        'etiquetaTipoEquipo': 'Tipo de artículo',
        'etiquetaMarcaEquipo': 'Marca',
        'etiquetaNumeroSerie': 'Referencia',
        'etiquetaCondicionEquipo': 'Estado del artículo',
        'mostrarSeccionEquipo': true,
      },
    };
    // Rubros sin sección equipo
    const sinEquipo = ['GASTRONOMIA', 'MODA', 'EDUCACION'];
    if (sinEquipo.contains(rubro)) {
      return {'mostrarSeccionEquipo': false};
    }
    return defaults[rubro] ?? defaults['TECNOLOGIA']!;
  }

  void _onChanged() {
    if (!_hasChanges) setState(() => _hasChanges = true);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_empresaId == null) return;

    final configState = context.read<ConfiguracionEmpresaCubit>().state;
    if (configState is! ConfiguracionEmpresaLoaded) return;

    final updated = configState.configuracion.copyWith(
      impuestoDefaultPorcentaje:
          double.tryParse(_impuestoController.text) ?? 18.0,
      nombreImpuesto: _nombreImpuestoController.text.trim(),
      monedaPrincipal: _monedaPrincipal,
      simboloMoneda: _simboloMonedaController.text.trim(),
      monedasPermitidas: _monedasPermitidas,
      diasVigenciaCotizacion:
          int.tryParse(_diasVigenciaController.text) ?? 30,
      condicionesDefault: _condicionesController.text.trim().isEmpty
          ? null
          : _condicionesController.text.trim(),
      etiquetaSeccionEquipo: _etiquetaSeccionController.text.trim(),
      etiquetaTipoEquipo: _etiquetaTipoController.text.trim(),
      etiquetaMarcaEquipo: _etiquetaMarcaController.text.trim(),
      etiquetaNumeroSerie: _etiquetaSerieController.text.trim(),
      etiquetaCondicionEquipo: _etiquetaCondicionController.text.trim(),
      mostrarSeccionEquipo: _mostrarSeccionEquipo,
    );

    await context
        .read<ConfiguracionEmpresaCubit>()
        .actualizar(_empresaId!, updated);

    setState(() => _hasChanges = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SmartAppBar(
        title: 'Configuración Fiscal',
        backgroundColor: AppColors.blue1,
        foregroundColor: Colors.white,
        actions: [
          if (_hasChanges)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _guardar,
              tooltip: 'Guardar cambios',
            ),
        ],
      ),
      body: BlocConsumer<ConfiguracionEmpresaCubit, ConfiguracionEmpresaState>(
        listener: (context, state) {
          if (state is ConfiguracionEmpresaLoaded) {
            if (!_hasChanges) _populateFields(state.configuracion);
            ScaffoldMessenger.of(context).clearSnackBars();
            if (_hasChanges == false &&
                _impuestoController.text.isNotEmpty) {
              // Solo mostrar snackbar después de guardar, no en carga inicial
            }
          }
          if (state is ConfiguracionEmpresaError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        listenWhen: (prev, curr) {
          // Mostrar éxito solo cuando pasa de Loading a Loaded (guardar)
          if (prev is ConfiguracionEmpresaLoading &&
              curr is ConfiguracionEmpresaLoaded &&
              _impuestoController.text.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Configuración guardada'),
                backgroundColor: Colors.green,
              ),
            );
          }
          return true;
        },
        builder: (context, state) {
          if (state is ConfiguracionEmpresaLoading &&
              _impuestoController.text.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ConfiguracionEmpresaError &&
              _impuestoController.text.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline,
                      size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      if (_empresaId != null) {
                        context
                            .read<ConfiguracionEmpresaCubit>()
                            .cargar(_empresaId!);
                      }
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (state is ConfiguracionEmpresaLoaded &&
              _impuestoController.text.isEmpty) {
            _populateFields(state.configuracion);
          }

          return _buildForm(state is ConfiguracionEmpresaLoading);
        },
      ),
    );
  }

  Widget _buildForm(bool saving) {
    return Stack(
      children: [
        Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Sección: Impuestos
              _SectionHeader(
                icon: Icons.receipt_long,
                title: 'Impuestos',
                subtitle: 'Configuración del impuesto aplicado a ventas',
              ),
              const SizedBox(height: 12),
              GradientContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CustomText(
                        controller: _impuestoController,
                        borderColor: AppColors.blue1,
                        label: 'Porcentaje de impuesto (%)',
                        hintText: 'Ej: 18.0',
                        prefixIcon: const Icon(Icons.percent),
                        helperText:
                            'Se aplicará como default en cotizaciones y ventas',
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'El porcentaje es requerido';
                          }
                          final val = double.tryParse(v);
                          if (val == null || val < 0 || val > 100) {
                            return 'Ingrese un valor entre 0 y 100';
                          }
                          return null;
                        },
                        onChanged: (_) => _onChanged(),
                      ),
                      const SizedBox(height: 16),
                      CustomText(
                        controller: _nombreImpuestoController,
                        borderColor: AppColors.blue1,
                        label: 'Nombre del impuesto',
                        hintText: 'Ej: IGV, IVA, ISV',
                        prefixIcon: const Icon(Icons.label),
                        helperText:
                            'Se mostrará en cotizaciones, PDFs y la app',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'El nombre es requerido'
                            : null,
                        onChanged: (_) => _onChanged(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sección: Moneda
              _SectionHeader(
                icon: Icons.attach_money,
                title: 'Moneda',
                subtitle: 'Moneda principal y monedas aceptadas',
              ),
              const SizedBox(height: 10),
              GradientContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CustomDropdown<String>(
                        label: 'Moneda principal',
                        value: _monedaPrincipal,
                        borderColor: AppColors.blue1,
                        items: const [
                          DropdownItem(value: 'PEN', label: 'PEN - Sol peruano'),
                          DropdownItem(value: 'USD', label: 'USD - Dólar americano'),
                          DropdownItem(value: 'EUR', label: 'EUR - Euro'),
                        ],
                        onChanged: (v) {
                          setState(() => _monedaPrincipal = v ?? 'PEN');
                          _onChanged();
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomText(
                        controller: _simboloMonedaController,
                        borderColor: AppColors.blue1,
                        label: 'Símbolo de moneda',
                        hintText: 'Ej: S/, \$, €',
                        prefixIcon: const Icon(Icons.currency_exchange),
                        helperText: 'Se mostrará junto a los precios',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'El símbolo es requerido'
                            : null,
                        onChanged: (_) => _onChanged(),
                      ),
                      const SizedBox(height: 16),
                      _buildMonedasPermitidasChips(),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sección: Cotizaciones
              _SectionHeader(
                icon: Icons.request_quote,
                title: 'Cotizaciones',
                subtitle: 'Valores por defecto para nuevas cotizaciones',
              ),
              const SizedBox(height: 12),
              GradientContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      CustomText(
                        controller: _diasVigenciaController,
                        borderColor: AppColors.blue1,
                        label: 'Días de vigencia',
                        hintText: 'Ej: 30',
                        prefixIcon: const Icon(Icons.calendar_today),
                        helperText:
                            'Días de validez por defecto de una cotización',
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) {
                            return 'Los días son requeridos';
                          }
                          final val = int.tryParse(v);
                          if (val == null || val < 1 || val > 365) {
                            return 'Ingrese un valor entre 1 y 365';
                          }
                          return null;
                        },
                        onChanged: (_) => _onChanged(),
                      ),
                      const SizedBox(height: 16),
                      CustomText(
                        controller: _condicionesController,
                        borderColor: AppColors.blue1,
                        label: 'Condiciones comerciales por defecto',
                        hintText:
                            'Ej: Precios no incluyen flete. Forma de pago: 50% adelanto.',
                        prefixIcon: const Icon(Icons.description),
                        maxLines: 4,
                        minLines: 2,
                        onChanged: (_) => _onChanged(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Sección: Etiquetas de Servicio
              _SectionHeader(
                icon: Icons.label_outline,
                title: 'Etiquetas de Servicio',
                subtitle: 'Personaliza los nombres de campos en ordenes de servicio',
              ),
              const SizedBox(height: 12),
              GradientContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Switch mostrar/ocultar
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const AppSubtitle('Seccion de equipo', fontSize: 12),
                                AppText(
                                  'Mostrar campos de equipo en ordenes de servicio',
                                  color: Colors.grey.shade600,
                                  size: 10,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _mostrarSeccionEquipo,
                            activeColor: AppColors.blue1,
                            onChanged: (v) {
                              setState(() => _mostrarSeccionEquipo = v);
                              _onChanged();
                            },
                          ),
                        ],
                      ),
                      if (_mostrarSeccionEquipo) ...[
                        const Divider(height: 20),
                        // Botón para restaurar defaults del rubro
                        Align(
                          alignment: Alignment.centerRight,
                          child: InkWell(
                            onTap: () {
                              final defaults = _defaultsPorRubro(_rubro);
                              setState(() {
                                _etiquetaSeccionController.text = defaults['etiquetaSeccionEquipo'] ?? 'EQUIPO';
                                _etiquetaTipoController.text = defaults['etiquetaTipoEquipo'] ?? 'Tipo de equipo';
                                _etiquetaMarcaController.text = defaults['etiquetaMarcaEquipo'] ?? 'Marca';
                                _etiquetaSerieController.text = defaults['etiquetaNumeroSerie'] ?? 'Número de serie';
                                _etiquetaCondicionController.text = defaults['etiquetaCondicionEquipo'] ?? 'Condición del equipo';
                              });
                              _onChanged();
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.refresh, size: 13, color: AppColors.blue1),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Restaurar defaults del rubro',
                                    style: TextStyle(fontSize: 10, color: AppColors.blue1, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        CustomText(
                          controller: _etiquetaSeccionController,
                          borderColor: AppColors.blue1,
                          label: 'Nombre de la seccion',
                          hintText: 'Ej: EQUIPO, VEHICULO, MAQUINARIA',
                          prefixIcon: const Icon(Icons.title),
                          onChanged: (_) => _onChanged(),
                        ),
                        const SizedBox(height: 12),
                        CustomText(
                          controller: _etiquetaTipoController,
                          borderColor: AppColors.blue1,
                          label: 'Etiqueta "Tipo"',
                          hintText: 'Ej: Tipo de equipo, Tipo de vehiculo',
                          prefixIcon: const Icon(Icons.category_outlined),
                          onChanged: (_) => _onChanged(),
                        ),
                        const SizedBox(height: 12),
                        CustomText(
                          controller: _etiquetaMarcaController,
                          borderColor: AppColors.blue1,
                          label: 'Etiqueta "Marca"',
                          hintText: 'Ej: Marca, Marca / Modelo',
                          prefixIcon: const Icon(Icons.branding_watermark_outlined),
                          onChanged: (_) => _onChanged(),
                        ),
                        const SizedBox(height: 12),
                        CustomText(
                          controller: _etiquetaSerieController,
                          borderColor: AppColors.blue1,
                          label: 'Etiqueta "Serie/Identificacion"',
                          hintText: 'Ej: N° de serie, Placa, Referencia',
                          prefixIcon: const Icon(Icons.qr_code_outlined),
                          onChanged: (_) => _onChanged(),
                        ),
                        const SizedBox(height: 12),
                        CustomText(
                          controller: _etiquetaCondicionController,
                          borderColor: AppColors.blue1,
                          label: 'Etiqueta "Condicion"',
                          hintText: 'Ej: Condicion del equipo, Estado del vehiculo',
                          prefixIcon: const Icon(Icons.info_outline),
                          onChanged: (_) => _onChanged(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botón guardar
              CustomButton(
                text: saving ? 'Guardando...' : 'Guardar cambios',
                onPressed: _hasChanges && !saving ? _guardar : null,
                enabled: _hasChanges && !saving,
                isLoading: saving,
                loadingText: 'Guardando...',
                icon: Icon(Icons.save, color: Colors.white, size: 16,),
                borderColor: AppColors.blue1,
                textColor: AppColors.white,
                width: double.infinity,
              ),
              

              const SizedBox(height: 24),

              // Info card
              GradientContainer(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.amber.shade800, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Si el porcentaje de impuesto cambia por ley, '
                          'actualícelo aquí. Las cotizaciones y documentos '
                          'nuevos usarán el valor actualizado. Los documentos '
                          'ya emitidos no se modifican.',
                          style: TextStyle(
                              fontSize: 13, color: Colors.amber.shade900),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMonedasPermitidasChips() {
    const allMonedas = ['PEN', 'USD', 'EUR'];
    return InputDecorator(
      decoration: const InputDecoration(
        labelText: 'Monedas permitidas',
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.blue1, width: 0.5),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.blue1, width: 0.5),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        border: OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.blue1, width: 0.5),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        helperText: 'Monedas disponibles en cotizaciones',
      ),
      child: Wrap(
        spacing: 8,
        children: allMonedas.map((moneda) {
          final selected = _monedasPermitidas.contains(moneda);
          return InfoChip(
            borderRadius: 6,
            text: moneda,
            selected: selected,
            showCheckmark: true,
            borderColor: AppColors.blue1,
            borderWidth: 0.5,
            selectedBackgroundColor: AppColors.blue1,
            selectedTextColor: Colors.white,
            selectedBorderColor: AppColors.blue1,
            onSelected: (value) {
              setState(() {
                if (value) {
                  _monedasPermitidas.add(moneda);
                } else {
                  if (_monedasPermitidas.length > 1) {
                    _monedasPermitidas.remove(moneda);
                  }
                }
              });
              _onChanged();
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.blue1, size: 18),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              AppSubtitle(title),
              AppText(subtitle, color: Colors.grey.shade600, size: 10,),
          ],
        ),
      ],
    );
  }
}
