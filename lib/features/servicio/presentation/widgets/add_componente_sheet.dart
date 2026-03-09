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
  List<String> _marcasDisponibles = [];
  List<String> _modelosDisponibles = [];

  TipoComponente? _selectedTipo;
  String? _selectedMarca;
  String? _selectedModelo;
  String _tipoAccion = 'DIAGNOSTICAR';

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

  bool _marcaManual = false;
  bool _modeloManual = false;

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

  Future<void> _loadMarcas(String tipoComponenteId) async {
    final repo = locator<ComponenteRepository>();
    final result = await repo.getMarcas(tipoComponenteId: tipoComponenteId);
    if (!mounted) return;

    setState(() {
      if (result is Success<List<String>>) {
        _marcasDisponibles = result.data;
      } else {
        _marcasDisponibles = [];
      }
      _selectedMarca = null;
      _selectedModelo = null;
      _modelosDisponibles = [];
      _marcaManual = _marcasDisponibles.isEmpty;
      _modeloManual = true;
      _marcaController.clear();
      _modeloController.clear();
    });
  }

  Future<void> _loadModelos(String tipoComponenteId, String marca) async {
    final repo = locator<ComponenteRepository>();
    final result = await repo.getModelos(
      tipoComponenteId: tipoComponenteId,
      marca: marca,
    );
    if (!mounted) return;

    setState(() {
      if (result is Success<List<String>>) {
        _modelosDisponibles = result.data;
      } else {
        _modelosDisponibles = [];
      }
      _selectedModelo = null;
      _modeloManual = _modelosDisponibles.isEmpty;
      _modeloController.clear();
    });
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

    // Step 2: Resolve Componente via find-or-create
    final marca = _marcaManual
        ? (_marcaController.text.isNotEmpty ? _marcaController.text.trim() : null)
        : _selectedMarca;
    final modelo = _modeloManual
        ? (_modeloController.text.isNotEmpty ? _modeloController.text.trim() : null)
        : _selectedModelo;
    final serie = _serieController.text.isNotEmpty
        ? _serieController.text.trim()
        : null;

    final compRepo = locator<ComponenteRepository>();
    final compResult = await compRepo.findOrCreateComponente(
      tipoComponenteId: tipoComponenteId!,
      marca: marca,
      modelo: modelo,
      numeroSerie: serie,
    );

    if (!mounted) return;

    String? componenteId;
    if (compResult is Success<Componente>) {
      componenteId = compResult.data.id;
    } else if (compResult is Error) {
      setState(() => _isSubmitting = false);
      _showError((compResult as Error).message);
      return;
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
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                                setState(() {
                                  _selectedTipo = tipo;
                                  _selectedMarca = null;
                                  _selectedModelo = null;
                                  _marcasDisponibles = [];
                                  _modelosDisponibles = [];
                                  _marcaManual = false;
                                  _modeloManual = true;
                                });
                                if (tipo != null) _loadMarcas(tipo.id);
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
                                _marcasDisponibles = [];
                                _modelosDisponibles = [];
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
                        subtitle: 'Si ya existe se reutilizara automaticamente',
                        children: [
                          // --- Marca ---
                          if (!_crearNuevoTipo && _marcasDisponibles.isNotEmpty && !_marcaManual) ...[
                            CustomDropdown<String>(
                              label: 'Marca',
                              hintText: 'Selecciona marca',
                              value: _selectedMarca,
                              items: _marcasDisponibles.map((m) => DropdownItem<String>(
                                value: m, label: m,
                              )).toList(),
                              onChanged: (marca) {
                                setState(() {
                                  _selectedMarca = marca;
                                  _selectedModelo = null;
                                  _modelosDisponibles = [];
                                  _modeloManual = false;
                                });
                                if (marca != null && _selectedTipo != null) {
                                  _loadModelos(_selectedTipo!.id, marca);
                                }
                              },
                              borderColor: AppColors.blue1,
                            ),
                            const SizedBox(height: 4),
                            _actionLink(
                              icon: Icons.edit,
                              label: 'Ingresar marca nueva',
                              onTap: () => setState(() {
                                _marcaManual = true;
                                _selectedMarca = null;
                                _modeloManual = true;
                                _selectedModelo = null;
                                _modelosDisponibles = [];
                              }),
                            ),
                          ] else ...[
                            CustomText(
                              controller: _marcaController,
                              label: 'Marca',
                              hintText: 'Ej: Samsung, HP, Lenovo...',
                              prefixIcon: const Icon(Icons.branding_watermark_outlined, size: 18),
                              borderColor: AppColors.blue1,
                              colorIcon: AppColors.blue1,
                            ),
                            if (!_crearNuevoTipo && _marcasDisponibles.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _actionLink(
                                icon: Icons.list,
                                label: 'Seleccionar marca existente',
                                onTap: () => setState(() {
                                  _marcaManual = false;
                                  _marcaController.clear();
                                }),
                              ),
                            ],
                          ],
                          const SizedBox(height: 12),

                          // --- Modelo ---
                          if (!_crearNuevoTipo && _modelosDisponibles.isNotEmpty && !_modeloManual) ...[
                            CustomDropdown<String>(
                              label: 'Modelo',
                              hintText: 'Selecciona modelo',
                              value: _selectedModelo,
                              items: _modelosDisponibles.map((m) => DropdownItem<String>(
                                value: m, label: m,
                              )).toList(),
                              onChanged: (modelo) {
                                setState(() => _selectedModelo = modelo);
                              },
                              borderColor: AppColors.blue1,
                            ),
                            const SizedBox(height: 4),
                            _actionLink(
                              icon: Icons.edit,
                              label: 'Ingresar modelo nuevo',
                              onTap: () => setState(() {
                                _modeloManual = true;
                                _selectedModelo = null;
                              }),
                            ),
                          ] else ...[
                            CustomText(
                              controller: _modeloController,
                              label: 'Modelo',
                              hintText: 'Ej: Galaxy S24, ProBook 450...',
                              prefixIcon: const Icon(Icons.devices, size: 18),
                              borderColor: AppColors.blue1,
                              colorIcon: AppColors.blue1,
                            ),
                            if (!_crearNuevoTipo && _modelosDisponibles.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              _actionLink(
                                icon: Icons.list,
                                label: 'Seleccionar modelo existente',
                                onTap: () => setState(() {
                                  _modeloManual = false;
                                  _modeloController.clear();
                                }),
                              ),
                            ],
                          ],
                          const SizedBox(height: 12),

                          // --- Serie ---
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
                            'Si ingresas serie se creara un registro nuevo',
                            fontSize: 9,
                            color: Colors.grey.shade500,
                          ),
                        ],
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
