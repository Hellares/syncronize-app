import 'package:flutter/material.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import 'package:syncronize/core/theme/app_colors.dart';
import 'package:syncronize/core/theme/app_gradients.dart';
import 'package:syncronize/core/theme/gradient_container.dart';
import 'package:syncronize/core/widgets/custom_button.dart';
import 'package:syncronize/core/widgets/custom_dropdown.dart';
import 'package:syncronize/core/widgets/custom_switch_tile.dart';
import 'package:syncronize/features/auth/presentation/widgets/custom_text.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/componente.dart';
import '../../domain/repositories/componente_repository.dart';
import '../../domain/repositories/orden_servicio_repository.dart';
import '../../domain/entities/orden_servicio.dart';

class AddComponenteSheet extends StatefulWidget {
  final String ordenId;
  final void Function(OrdenComponente componente) onAdded;

  const AddComponenteSheet({
    super.key,
    required this.ordenId,
    required this.onAdded,
  });

  @override
  State<AddComponenteSheet> createState() => _AddComponenteSheetState();
}

class _AddComponenteSheetState extends State<AddComponenteSheet> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _crearNuevoTipo = false;

  List<TipoComponente> _tipos = [];
  List<Componente> _componentes = []; // componentes registrados del tipo elegido
  List<String> _marcasDisponibles = []; // sugerencias de marca para "nuevo"

  TipoComponente? _selectedTipo;
  Componente? _componenteSeleccionado; // reutiliza uno existente (por id)
  bool _mostrarFormNuevoComp = false; // true → muestra el form de "nuevo componente"
  bool _cargandoComponentes = false;
  String _tipoAccion = 'DIAGNOSTICAR';

  final _buscarCompCtrl = TextEditingController();
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _serieController = TextEditingController();
  final _descripcionController = TextEditingController();

  final _costoAccionController = TextEditingController();
  final _tiempoAccionController = TextEditingController();
  final _costoRepuestosController = TextEditingController();
  final _resultadoAccionController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _garantiaMesesController = TextEditingController();
  bool _pruebaRealizada = false;

  final _nombreTipoController = TextEditingController();
  String _categoriaTipo = 'HARDWARE';

  static const _categorias = [
    'HARDWARE',
    'SOFTWARE',
    'PERIFERICO',
    'ACCESORIOS',
    'CONSUMIBLES',
  ];

  static const _categoriaLabels = {
    'HARDWARE': 'Hardware',
    'SOFTWARE': 'Software',
    'PERIFERICO': 'Periferico',
    'ACCESORIOS': 'Accesorios',
    'CONSUMIBLES': 'Consumibles',
  };

  static const _categoriaIcons = {
    'HARDWARE': Icons.memory,
    'SOFTWARE': Icons.code,
    'PERIFERICO': Icons.mouse,
    'ACCESORIOS': Icons.cable,
    'CONSUMIBLES': Icons.shopping_bag_outlined,
  };

  static const _tiposAccion = [
    'DIAGNOSTICAR',
    'REPARAR',
    'REEMPLAZAR',
    'LIMPIAR',
    'ACTUALIZAR',
    'INSTALAR',
    'DESMONTAR',
    'PROBAR',
    'CALIBRAR',
  ];

  static const _tipoAccionLabels = {
    'DIAGNOSTICAR': 'Diagnosticar',
    'REPARAR': 'Reparar',
    'REEMPLAZAR': 'Reemplazar',
    'LIMPIAR': 'Limpiar',
    'ACTUALIZAR': 'Actualizar',
    'INSTALAR': 'Instalar',
    'DESMONTAR': 'Desmontar',
    'PROBAR': 'Probar',
    'CALIBRAR': 'Calibrar',
  };

  static const _tipoAccionIcons = {
    'DIAGNOSTICAR': Icons.search,
    'REPARAR': Icons.build,
    'REEMPLAZAR': Icons.swap_horiz,
    'LIMPIAR': Icons.cleaning_services,
    'ACTUALIZAR': Icons.system_update,
    'INSTALAR': Icons.install_desktop,
    'DESMONTAR': Icons.handyman,
    'PROBAR': Icons.science,
    'CALIBRAR': Icons.tune,
  };

  @override
  void initState() {
    super.initState();
    _loadTipos();
  }

  @override
  void dispose() {
    _buscarCompCtrl.dispose();
    _marcaController.dispose();
    _modeloController.dispose();
    _serieController.dispose();
    _descripcionController.dispose();
    _costoAccionController.dispose();
    _tiempoAccionController.dispose();
    _costoRepuestosController.dispose();
    _resultadoAccionController.dispose();
    _observacionesController.dispose();
    _garantiaMesesController.dispose();
    _nombreTipoController.dispose();
    super.dispose();
  }

  Future<void> _loadTipos() async {
    final repo = locator<ComponenteRepository>();
    final result = await repo.getTipos();
    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (result is Success<List<TipoComponente>>) {
        _tipos = result.data;
        if (_tipos.isEmpty) {
          _crearNuevoTipo = true;
        }
      }
    });
  }

  /// Al elegir un tipo: carga sus componentes registrados (para reutilizar) y
  /// las marcas conocidas (sugerencias del form "nuevo"). Si el tipo no tiene
  /// componentes aún → va directo al form de registro.
  Future<void> _loadComponentesYMarcas(String tipoComponenteId) async {
    setState(() {
      _cargandoComponentes = true;
      _componenteSeleccionado = null;
      _mostrarFormNuevoComp = false;
      _componentes = [];
      _buscarCompCtrl.clear();
      _marcaController.clear();
      _modeloController.clear();
      _serieController.clear();
    });

    final repo = locator<ComponenteRepository>();
    final compResult =
        await repo.getComponentes(tipoComponenteId: tipoComponenteId);
    final marcasResult =
        await repo.getMarcas(tipoComponenteId: tipoComponenteId);
    if (!mounted) return;

    setState(() {
      _cargandoComponentes = false;
      _componentes =
          compResult is Success<List<Componente>> ? compResult.data : [];
      _marcasDisponibles =
          marcasResult is Success<List<String>> ? marcasResult.data : [];
      // Sin componentes registrados → form de "nuevo" directo.
      _mostrarFormNuevoComp = _componentes.isEmpty;
    });
  }

  /// Componentes filtrados por el buscador (marca/modelo/serie).
  List<Componente> get _componentesFiltrados {
    final q = _buscarCompCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _componentes;
    return _componentes.where((c) {
      final hay = [c.marca, c.modelo, c.numeroSerie, c.displayName]
          .where((e) => e != null)
          .map((e) => e!.toLowerCase())
          .join(' ');
      return hay.contains(q);
    }).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Step 1: Resolve TipoComponente
    String? tipoComponenteId;
    if (_crearNuevoTipo) {
      final nombreTipo = _nombreTipoController.text.trim();
      if (nombreTipo.isEmpty) {
        setState(() => _isSubmitting = false);
        _showError('El nombre del tipo de componente es requerido');
        return;
      }
      final compRepo = locator<ComponenteRepository>();
      final tipoResult = await compRepo.crearTipo(
        nombre: nombreTipo,
        categoria: _categoriaTipo,
      );

      if (!mounted) return;

      if (tipoResult is Success<TipoComponente>) {
        tipoComponenteId = tipoResult.data.id;
        _tipos.add(tipoResult.data);
      } else if (tipoResult is Error) {
        setState(() => _isSubmitting = false);
        _showError((tipoResult as Error).message);
        return;
      }
    } else {
      if (_selectedTipo == null) {
        setState(() => _isSubmitting = false);
        _showError('Selecciona un tipo de componente');
        return;
      }
      tipoComponenteId = _selectedTipo!.id;
    }

    // Step 2: Resolve Componente
    String? componenteId;
    if (!_mostrarFormNuevoComp && _componenteSeleccionado != null) {
      // Reutiliza un componente ya registrado (por id, sin find-or-create).
      componenteId = _componenteSeleccionado!.id;
    } else {
      // Registra/reutiliza vía find-or-create con los datos del form "nuevo".
      final marca = _marcaController.text.trim().isNotEmpty
          ? _marcaController.text.trim()
          : null;
      final modelo = _modeloController.text.trim().isNotEmpty
          ? _modeloController.text.trim()
          : null;
      final serie = _serieController.text.trim().isNotEmpty
          ? _serieController.text.trim()
          : null;

      if (marca == null && modelo == null && serie == null) {
        setState(() => _isSubmitting = false);
        _showError('Selecciona un componente o ingresa marca/modelo');
        return;
      }

      final compRepo = locator<ComponenteRepository>();
      final compResult = await compRepo.findOrCreateComponente(
        tipoComponenteId: tipoComponenteId!,
        marca: marca,
        modelo: modelo,
        numeroSerie: serie,
      );

      if (!mounted) return;

      if (compResult is Success<Componente>) {
        componenteId = compResult.data.id;
      } else if (compResult is Error) {
        setState(() => _isSubmitting = false);
        _showError((compResult as Error).message);
        return;
      }
    }

    // Step 3: Add to order
    final ordenRepo = locator<OrdenServicioRepository>();
    final data = <String, dynamic>{
      'componenteId': componenteId,
      'tipoAccion': _tipoAccion,
      if (_descripcionController.text.isNotEmpty)
        'descripcionAccion': _descripcionController.text.trim(),
      if (_costoAccionController.text.isNotEmpty)
        'costoAccion': double.tryParse(_costoAccionController.text),
      if (_tiempoAccionController.text.isNotEmpty)
        'tiempoAccion': int.tryParse(_tiempoAccionController.text),
      if (_costoRepuestosController.text.isNotEmpty)
        'costoRepuestos': double.tryParse(_costoRepuestosController.text),
      if (_resultadoAccionController.text.isNotEmpty)
        'resultadoAccion': _resultadoAccionController.text.trim(),
      'pruebaRealizada': _pruebaRealizada,
      if (_observacionesController.text.isNotEmpty)
        'observaciones': _observacionesController.text.trim(),
      if (_garantiaMesesController.text.isNotEmpty)
        'garantiaMeses': int.tryParse(_garantiaMesesController.text),
    };

    final result = await ordenRepo.addComponente(
      ordenId: widget.ordenId,
      data: data,
    );

    if (!mounted) return;

    setState(() => _isSubmitting = false);

    if (result is Success<OrdenComponente>) {
      widget.onAdded(result.data);
      Navigator.of(context).pop();
    } else if (result is Error) {
      _showError((result as Error).message);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.blue1))
              : Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Header
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.blue1.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.memory, color: AppColors.blue1, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                AppTitle('Agregar Componente', fontSize: 15, color: AppColors.blue1),
                                AppLabelText('Selecciona o crea un componente para la orden',
                                    fontSize: 10, color: Colors.grey),
                              ],
                            ),
                          ),
                          InkWell(
                            onTap: () => Navigator.pop(context),
                            borderRadius: BorderRadius.circular(20),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: Icon(Icons.close, size: 20, color: Colors.grey.shade400),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // === SECTION 1: Tipo de Componente ===
                      _buildSectionCard(
                        icon: Icons.category_outlined,
                        title: 'Tipo de componente',
                        step: '1',
                        children: [
                          if (_tipos.isNotEmpty && !_crearNuevoTipo) ...[
                            CustomDropdown<String>(
                              label: 'Seleccionar tipo',
                              hintText: 'Ej: Pantalla, Disco Duro...',
                              value: _selectedTipo?.id,
                              items: _tipos.map((t) => DropdownItem<String>(
                                value: t.id,
                                label: '${t.nombre} (${_categoriaLabels[t.categoria] ?? t.categoria})',
                                leading: Icon(
                                  _categoriaIcons[t.categoria] ?? Icons.memory,
                                  size: 16, color: AppColors.blue1,
                                ),
                              )).toList(),
                              onChanged: (id) {
                                final tipo = id != null ? _tipos.firstWhere((t) => t.id == id) : null;
                                setState(() => _selectedTipo = tipo);
                                if (tipo != null) _loadComponentesYMarcas(tipo.id);
                              },
                              borderColor: AppColors.blue1,
                            ),
                            const SizedBox(height: 6),
                            _actionLink(
                              icon: Icons.add,
                              label: 'Crear nuevo tipo',
                              onTap: () => setState(() {
                                _crearNuevoTipo = true;
                                _selectedTipo = null;
                                _componentes = [];
                                _componenteSeleccionado = null;
                                _marcasDisponibles = [];
                                _mostrarFormNuevoComp = true;
                              }),
                            ),
                          ] else ...[
                            CustomText(
                              controller: _nombreTipoController,
                              label: 'Nombre del tipo',
                              hintText: 'Ej: Pantalla, Disco Duro, Teclado...',
                              required: true,
                              prefixIcon: const Icon(Icons.label_outline, size: 18),
                              borderColor: AppColors.blue1,
                              colorIcon: AppColors.blue1,
                              validator: (v) => _crearNuevoTipo && (v == null || v.trim().isEmpty)
                                  ? 'Ingresa un nombre' : null,
                            ),
                            const SizedBox(height: 12),
                            CustomDropdown<String>(
                              label: 'Categoria',
                              hintText: 'Selecciona categoria',
                              value: _categoriaTipo,
                              items: _categorias.map((c) => DropdownItem<String>(
                                value: c,
                                label: _categoriaLabels[c] ?? c,
                                leading: Icon(
                                  _categoriaIcons[c] ?? Icons.memory,
                                  size: 16, color: AppColors.blue1,
                                ),
                              )).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _categoriaTipo = v);
                              },
                              borderColor: AppColors.blue1,
                            ),
                            if (_tipos.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              _actionLink(
                                icon: Icons.list,
                                label: 'Seleccionar tipo existente',
                                onTap: () => setState(() => _crearNuevoTipo = false),
                              ),
                            ],
                          ],
                        ],
                      ),

                      const SizedBox(height: 10),

                      // === SECTION 2: Componente ===
                      _buildSectionCard(
                        icon: Icons.devices_outlined,
                        title: 'Componente',
                        step: '2',
                        subtitle: 'Selecciona uno registrado o crea uno nuevo',
                        children: _buildComponenteSection(),
                      ),

                      const SizedBox(height: 10),

                      // === SECTION 3: Accion ===
                      _buildSectionCard(
                        icon: Icons.handyman_outlined,
                        title: 'Accion sobre el componente',
                        step: '3',
                        children: [
                          CustomDropdown<String>(
                            label: 'Accion a realizar',
                            hintText: 'Selecciona una accion',
                            value: _tipoAccion,
                            items: _tiposAccion.map((a) => DropdownItem<String>(
                              value: a,
                              label: _tipoAccionLabels[a] ?? a,
                              leading: Icon(
                                _tipoAccionIcons[a] ?? Icons.build,
                                size: 16, color: AppColors.blue1,
                              ),
                            )).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _tipoAccion = v);
                            },
                            borderColor: AppColors.blue1,
                          ),
                          const SizedBox(height: 12),
                          CustomText(
                            controller: _descripcionController,
                            label: 'Descripcion (opcional)',
                            hintText: 'Detalle de lo que se debe hacer...',
                            maxLines: 2,
                            height: null,
                            prefixIcon: const Icon(Icons.description_outlined, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                          const SizedBox(height: 12),

                          // Costos row
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  controller: _costoAccionController,
                                  label: 'Costo accion',
                                  hintText: '0.00',
                                  prefixText: 'S/ ',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                                  borderColor: AppColors.blue1,
                                  colorIcon: AppColors.blue1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomText(
                                  controller: _tiempoAccionController,
                                  label: 'Tiempo (min)',
                                  hintText: '0',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.timer_outlined, size: 18),
                                  borderColor: AppColors.blue1,
                                  colorIcon: AppColors.blue1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Repuestos + garantia row
                          Row(
                            children: [
                              Expanded(
                                child: CustomText(
                                  controller: _costoRepuestosController,
                                  label: 'Repuestos',
                                  hintText: '0.00',
                                  prefixText: 'S/ ',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.build_outlined, size: 18),
                                  borderColor: AppColors.blue1,
                                  colorIcon: AppColors.blue1,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: CustomText(
                                  controller: _garantiaMesesController,
                                  label: 'Garantia',
                                  hintText: '0',
                                  keyboardType: TextInputType.number,
                                  prefixIcon: const Icon(Icons.shield_outlined, size: 18),
                                  borderColor: AppColors.blue1,
                                  colorIcon: AppColors.blue1,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          CustomText(
                            controller: _resultadoAccionController,
                            label: 'Resultado (opcional)',
                            hintText: 'Detalle del resultado...',
                            maxLines: 2,
                            height: null,
                            prefixIcon: const Icon(Icons.check_circle_outline, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                          const SizedBox(height: 12),

                          CustomText(
                            controller: _observacionesController,
                            label: 'Observaciones (opcional)',
                            hintText: 'Notas adicionales...',
                            maxLines: 2,
                            height: null,
                            prefixIcon: const Icon(Icons.notes, size: 18),
                            borderColor: AppColors.blue1,
                            colorIcon: AppColors.blue1,
                          ),
                          const SizedBox(height: 10),

                          CustomSwitchTile(
                            title: 'Prueba realizada',
                            subtitle: 'Se realizo prueba del componente',
                            value: _pruebaRealizada,
                            onChanged: (v) => setState(() => _pruebaRealizada = v),
                            activeTrackColor: AppColors.blue1,
                          ),
                        ],
                      ),

                      const SizedBox(height: 18),

                      // Submit button
                      CustomButton(
                        text: _isSubmitting ? 'Agregando...' : 'Agregar Componente',
                        onPressed: _isSubmitting ? null : _submit,
                        backgroundColor: AppColors.blue1,
                        borderColor: AppColors.blue1,
                        textColor: Colors.white,
                        height: 44,
                        width: double.infinity,
                        isLoading: _isSubmitting,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        );
      },
    );
  }

  /// Sección 2: lista buscable de componentes registrados + form "nuevo".
  List<Widget> _buildComponenteSection() {
    // Sin tipo seleccionado (y sin crear tipo nuevo) → pedir elegir tipo antes.
    if (!_crearNuevoTipo && _selectedTipo == null) {
      return [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: AppLabelText(
            'Primero selecciona un tipo de componente',
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ];
    }

    if (_cargandoComponentes) {
      return const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.blue1),
            ),
          ),
        ),
      ];
    }

    // Modo formulario de "nuevo componente".
    if (_mostrarFormNuevoComp) {
      return _buildNuevoComponenteForm();
    }

    // Modo lista: buscador + tarjetas de componentes registrados.
    final filtrados = _componentesFiltrados;
    return [
      CustomText(
        controller: _buscarCompCtrl,
        label: 'Buscar componente',
        hintText: 'Marca, modelo o serie...',
        prefixIcon: const Icon(Icons.search, size: 18),
        borderColor: AppColors.blue1,
        colorIcon: AppColors.blue1,
        onChanged: (_) => setState(() {}),
      ),
      const SizedBox(height: 10),
      if (filtrados.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: AppLabelText(
            'Sin coincidencias. Registra un componente nuevo.',
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        )
      else
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 0.8),
            ),
            child: Column(
              children: [
                for (var i = 0; i < filtrados.length; i++) ...[
                  if (i > 0)
                    Divider(height: 1, thickness: 0.6, color: Colors.grey.shade200),
                  _buildComponenteCard(filtrados[i]),
                ],
              ],
            ),
          ),
        ),
      const SizedBox(height: 8),
      _actionLink(
        icon: Icons.add,
        label: 'Registrar nuevo componente',
        onTap: () => setState(() {
          _mostrarFormNuevoComp = true;
          _componenteSeleccionado = null;
          _marcaController.clear();
          _modeloController.clear();
          _serieController.clear();
        }),
      ),
    ];
  }

  Widget _buildComponenteCard(Componente c) {
    final seleccionado = _componenteSeleccionado?.id == c.id;
    final nombre =
        _selectedTipo?.nombre ?? c.tipoComponente?.nombre ?? c.codigo;

    final spans = <TextSpan>[];
    void addKv(String label, String value, {bool bold = false}) {
      if (spans.isNotEmpty) {
        spans.add(const TextSpan(text: '   ')); // separador entre campos
      }
      spans.add(TextSpan(
        text: '$label: ',
        style: TextStyle(
          fontSize: 10,
          color: seleccionado
              ? AppColors.blue1.withValues(alpha: 0.7)
              : Colors.grey.shade500,
          fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
        ),
      ));
      spans.add(TextSpan(
        text: value,
        style: TextStyle(
          fontSize: bold ? 11.5 : 11,
          fontWeight: bold || seleccionado ? FontWeight.w700 : FontWeight.w500,
          color: seleccionado ? AppColors.blue1 : Colors.grey.shade800,
          fontFamily: AppFonts.getFontFamily(
            bold ? AppFont.oxygenBold : AppFont.oxygenRegular,
          ),
        ),
      ));
    }

    addKv('Nombre', nombre, bold: true);
    if (c.marca != null && c.marca!.isNotEmpty) addKv('Marca', c.marca!);
    if (c.modelo != null && c.modelo!.isNotEmpty) addKv('Modelo', c.modelo!);
    if (c.numeroSerie != null && c.numeroSerie!.isNotEmpty) {
      addKv('Serie', c.numeroSerie!);
    }

    return InkWell(
      onTap: () => setState(() => _componenteSeleccionado = c),
      child: Container(
        color: seleccionado
            ? AppColors.blue1.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        child: Row(
          children: [
            Icon(
              seleccionado
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              size: 16,
              color: seleccionado ? AppColors.blue1 : Colors.grey.shade400,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(children: spans),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildNuevoComponenteForm() {
    return [
      CustomText(
        controller: _marcaController,
        label: 'Marca',
        hintText: 'Ej: Samsung, HP, Lenovo...',
        prefixIcon: const Icon(Icons.branding_watermark_outlined, size: 18),
        borderColor: AppColors.blue1,
        colorIcon: AppColors.blue1,
      ),
      // Sugerencias de marcas ya registradas para este tipo.
      if (_marcasDisponibles.isNotEmpty) ...[
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: _marcasDisponibles.map((m) {
            return ActionChip(
              label: Text(m, style: const TextStyle(fontSize: 10)),
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              visualDensity: VisualDensity.compact,
              backgroundColor: AppColors.blue1.withValues(alpha: 0.06),
              side: BorderSide(color: AppColors.blue1.withValues(alpha: 0.3)),
              onPressed: () => setState(() => _marcaController.text = m),
            );
          }).toList(),
        ),
      ],
      const SizedBox(height: 12),
      CustomText(
        controller: _modeloController,
        label: 'Modelo',
        hintText: 'Ej: Galaxy S24, ProBook 450...',
        prefixIcon: const Icon(Icons.devices, size: 18),
        borderColor: AppColors.blue1,
        colorIcon: AppColors.blue1,
      ),
      const SizedBox(height: 12),
      CustomText(
        controller: _serieController,
        label: 'Numero de serie (opcional)',
        hintText: 'Solo si es una pieza unica',
        prefixIcon: const Icon(Icons.qr_code_outlined, size: 18),
        borderColor: AppColors.blue1,
        colorIcon: AppColors.blue1,
      ),
      const SizedBox(height: 4),
      AppLabelText(
        'Si ingresas serie se creara un registro unico',
        fontSize: 9,
        color: Colors.grey.shade500,
      ),
      // Volver a la lista (solo si hay componentes registrados y no es tipo nuevo).
      if (!_crearNuevoTipo && _componentes.isNotEmpty) ...[
        const SizedBox(height: 8),
        _actionLink(
          icon: Icons.list,
          label: 'Ver componentes registrados',
          onTap: () => setState(() {
            _mostrarFormNuevoComp = false;
            _marcaController.clear();
            _modeloController.clear();
            _serieController.clear();
          }),
        ),
      ],
    ];
  }

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String step,
    String? subtitle,
    required List<Widget> children,
  }) {
    return GradientContainer(
      gradient: AppGradients.blueWhiteBlue(),
      shadowStyle: ShadowStyle.glow,
      borderColor: AppColors.blueborder,
      borderWidth: 0.6,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: AppColors.blue1,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    step,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Icon(icon, color: AppColors.blue1, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSubtitle(
                      title,
                      fontSize: 11,
                      color: AppColors.blue1,
                      font: AppFont.oxygenBold,
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _actionLink({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppColors.blue1),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.blue1,
                fontWeight: FontWeight.w600,
                fontFamily: AppFonts.getFontFamily(AppFont.oxygenRegular),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
