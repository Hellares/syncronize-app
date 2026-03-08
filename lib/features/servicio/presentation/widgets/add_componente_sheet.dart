import 'package:flutter/material.dart';
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

  // Fields for component
  final _marcaController = TextEditingController();
  final _modeloController = TextEditingController();
  final _serieController = TextEditingController();
  final _descripcionController = TextEditingController();

  // Fields for action details
  final _costoAccionController = TextEditingController();
  final _tiempoAccionController = TextEditingController();
  final _costoRepuestosController = TextEditingController();
  final _resultadoAccionController = TextEditingController();
  final _observacionesController = TextEditingController();
  final _garantiaMesesController = TextEditingController();
  bool _pruebaRealizada = false;

  // Fields for new TipoComponente
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
          padding: const EdgeInsets.all(16),
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                  key: _formKey,
                  child: ListView(
                    controller: scrollController,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Agregar Componente',
                              style: Theme.of(context).textTheme.titleLarge),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // === SECTION 1: Tipo de Componente ===
                      Text('1. Tipo de componente',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      if (_tipos.isNotEmpty && !_crearNuevoTipo) ...[
                        DropdownButtonFormField<TipoComponente>(
                          decoration: const InputDecoration(
                            labelText: 'Seleccionar tipo *',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: _tipos
                              .map((t) => DropdownMenuItem(
                                    value: t,
                                    child: Text(
                                        '${t.nombre} (${_categoriaLabels[t.categoria] ?? t.categoria})'),
                                  ))
                              .toList(),
                          onChanged: (tipo) {
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
                          validator: (v) =>
                              !_crearNuevoTipo && v == null ? 'Requerido' : null,
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _crearNuevoTipo = true;
                              _selectedTipo = null;
                              _marcasDisponibles = [];
                              _modelosDisponibles = [];
                            }),
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Crear nuevo tipo'),
                          ),
                        ),
                      ] else ...[
                        // Create new TipoComponente inline
                        TextFormField(
                          controller: _nombreTipoController,
                          decoration: const InputDecoration(
                            labelText: 'Nombre del tipo *',
                            hintText: 'Ej: Pantalla, Disco Duro, Teclado...',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) => _crearNuevoTipo &&
                                  (v == null || v.trim().isEmpty)
                              ? 'Ingresa un nombre'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Categoria *',
                            border: OutlineInputBorder(),
                          ),
                          value: _categoriaTipo,
                          items: _categorias
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(_categoriaLabels[c] ?? c),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _categoriaTipo = v);
                          },
                        ),
                        if (_tipos.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () =>
                                  setState(() => _crearNuevoTipo = false),
                              icon: const Icon(Icons.list, size: 18),
                              label: const Text('Seleccionar tipo existente'),
                            ),
                          ),
                        ],
                      ],
                      const Divider(height: 32),

                      // === SECTION 2: Componente (Marca / Modelo / Serie) ===
                      Text('2. Componente',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text(
                        'Si ya existe un componente con la misma marca y modelo se reutilizara automaticamente.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),

                      // --- Marca ---
                      if (!_crearNuevoTipo && _marcasDisponibles.isNotEmpty && !_marcaManual) ...[
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Marca',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: _marcasDisponibles
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
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
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _marcaManual = true;
                              _selectedMarca = null;
                              _modeloManual = true;
                              _selectedModelo = null;
                              _modelosDisponibles = [];
                            }),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Ingresar marca nueva', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _marcaController,
                          decoration: const InputDecoration(
                            labelText: 'Marca',
                            hintText: 'Ej: Samsung, HP, Lenovo...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (!_crearNuevoTipo && _marcasDisponibles.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                _marcaManual = false;
                                _marcaController.clear();
                              }),
                              icon: const Icon(Icons.list, size: 16),
                              label: const Text('Seleccionar marca existente', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),

                      // --- Modelo ---
                      if (!_crearNuevoTipo && _modelosDisponibles.isNotEmpty && !_modeloManual) ...[
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            labelText: 'Modelo',
                            border: OutlineInputBorder(),
                          ),
                          isExpanded: true,
                          items: _modelosDisponibles
                              .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                              .toList(),
                          onChanged: (modelo) {
                            setState(() => _selectedModelo = modelo);
                          },
                        ),
                        const SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => setState(() {
                              _modeloManual = true;
                              _selectedModelo = null;
                            }),
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Ingresar modelo nuevo', style: TextStyle(fontSize: 12)),
                          ),
                        ),
                      ] else ...[
                        TextFormField(
                          controller: _modeloController,
                          decoration: const InputDecoration(
                            labelText: 'Modelo',
                            hintText: 'Ej: Galaxy S24, ProBook 450...',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        if (!_crearNuevoTipo && _modelosDisponibles.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                _modeloManual = false;
                                _modeloController.clear();
                              }),
                              icon: const Icon(Icons.list, size: 16),
                              label: const Text('Seleccionar modelo existente', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ],
                      const SizedBox(height: 12),

                      // --- Serie (siempre manual) ---
                      TextFormField(
                        controller: _serieController,
                        decoration: InputDecoration(
                          labelText: 'Numero de serie (opcional)',
                          hintText: 'Solo si es una pieza unica',
                          helperText: 'Si ingresas serie se creara un registro nuevo',
                          helperStyle: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const Divider(height: 32),

                      // === SECTION 3: Accion ===
                      Text('3. Accion sobre el componente',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),

                      DropdownButtonFormField<String>(
                        decoration: const InputDecoration(
                          labelText: 'Accion a realizar *',
                          border: OutlineInputBorder(),
                        ),
                        value: _tipoAccion,
                        items: _tiposAccion
                            .map((a) => DropdownMenuItem(
                                  value: a,
                                  child: Text(_tipoAccionLabels[a] ?? a),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _tipoAccion = v);
                        },
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descripcionController,
                        decoration: const InputDecoration(
                          labelText: 'Descripcion (opcional)',
                          hintText: 'Detalle de lo que se debe hacer...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),

                      // Cost and time row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costoAccionController,
                              decoration: const InputDecoration(
                                labelText: 'Costo accion (S/)',
                                prefixText: 'S/ ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _tiempoAccionController,
                              decoration: const InputDecoration(
                                labelText: 'Tiempo (min)',
                                suffixText: 'min',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Repuestos and warranty row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _costoRepuestosController,
                              decoration: const InputDecoration(
                                labelText: 'Costo repuestos (S/)',
                                prefixText: 'S/ ',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _garantiaMesesController,
                              decoration: const InputDecoration(
                                labelText: 'Garantia (meses)',
                                suffixText: 'meses',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _resultadoAccionController,
                        decoration: const InputDecoration(
                          labelText: 'Resultado de la accion',
                          hintText: 'Detalle del resultado...',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _observacionesController,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),

                      SwitchListTile(
                        title: const Text('Prueba realizada'),
                        subtitle: const Text('Se realizo prueba del componente'),
                        value: _pruebaRealizada,
                        onChanged: (v) => setState(() => _pruebaRealizada = v),
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 16),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _submit,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.add),
                          label: Text(_isSubmitting
                              ? 'Agregando...'
                              : 'Agregar Componente'),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
        );
      },
    );
  }
}
