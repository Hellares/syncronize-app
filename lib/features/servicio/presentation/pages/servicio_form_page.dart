import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../domain/entities/plantilla_servicio.dart';
import '../../domain/repositories/plantilla_servicio_repository.dart';
import '../../domain/repositories/servicio_repository.dart';

class ServicioFormPage extends StatefulWidget {
  final String? servicioId;

  const ServicioFormPage({super.key, this.servicioId});

  bool get isEditing => servicioId != null;

  @override
  State<ServicioFormPage> createState() => _ServicioFormPageState();
}

class _ServicioFormPageState extends State<ServicioFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _precioController = TextEditingController();
  final _precioPorHoraController = TextEditingController();
  final _duracionMinutosController = TextEditingController();
  bool _requiereReserva = false;
  bool _requiereDeposito = false;
  bool _visibleMarketplace = true;
  bool _enOferta = false;
  final _precioOfertaController = TextEditingController();
  bool _isLoading = false;

  // Plantilla
  List<PlantillaServicio> _plantillas = [];
  String? _selectedPlantillaId;
  bool _loadingPlantillas = false;

  @override
  void initState() {
    super.initState();
    _loadPlantillas();
    if (widget.isEditing) {
      _loadServicio();
    }
  }

  Future<void> _loadPlantillas() async {
    setState(() => _loadingPlantillas = true);
    final repo = locator<PlantillaServicioRepository>();
    final result = await repo.getAll();
    if (!mounted) return;
    setState(() {
      _loadingPlantillas = false;
      if (result is Success<List<PlantillaServicio>>) {
        _plantillas = result.data;
      }
    });
  }

  Future<void> _loadServicio() async {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    setState(() => _isLoading = true);
    final repo = locator<ServicioRepository>();
    final result = await repo.getServicio(
      id: widget.servicioId!,
      empresaId: empresaState.context.empresa.id,
    );
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      if (result is Success) {
        final s = (result as Success).data;
        _nombreController.text = s.nombre;
        _descripcionController.text = s.descripcion ?? '';
        _precioController.text = s.precio?.toString() ?? '';
        _precioPorHoraController.text = s.precioPorHora?.toString() ?? '';
        _duracionMinutosController.text = s.duracionMinutos?.toString() ?? '';
        _requiereReserva = s.requiereReserva;
        _requiereDeposito = s.requiereDeposito;
        _visibleMarketplace = s.visibleMarketplace;
        _enOferta = s.enOferta;
        _precioOfertaController.text = s.precioOferta?.toString() ?? '';
        _selectedPlantillaId = s.plantillaServicioId;
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioController.dispose();
    _precioPorHoraController.dispose();
    _duracionMinutosController.dispose();
    _precioOfertaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar Servicio' : 'Nuevo Servicio'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: _nombreController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del servicio *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descripcionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _precioController,
                            decoration: const InputDecoration(
                              labelText: 'Precio',
                              border: OutlineInputBorder(),
                              prefixText: 'S/ ',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _precioPorHoraController,
                            decoration: const InputDecoration(
                              labelText: 'Precio/Hora',
                              border: OutlineInputBorder(),
                              prefixText: 'S/ ',
                            ),
                            keyboardType: TextInputType.number,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _duracionMinutosController,
                      decoration: const InputDecoration(
                        labelText: 'Duración estimada (minutos)',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),

                    // Plantilla selector
                    if (_loadingPlantillas)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      )
                    else
                      DropdownButtonFormField<String>(
                        value: _selectedPlantillaId,
                        decoration: const InputDecoration(
                          labelText: 'Plantilla de campos personalizados',
                          border: OutlineInputBorder(),
                          helperText: 'Los campos de esta plantilla se mostrarán al crear órdenes de servicio',
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Sin plantilla'),
                          ),
                          ..._plantillas.map((p) => DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  '${p.nombre}${p.campos.isNotEmpty ? " (${p.campos.length} campos)" : ""}',
                                ),
                              )),
                        ],
                        onChanged: (v) => setState(() => _selectedPlantillaId = v),
                      ),

                    if (_selectedPlantillaId != null) ...[
                      const SizedBox(height: 8),
                      _buildPlantillaPreview(),
                    ],

                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Requiere reserva'),
                      value: _requiereReserva,
                      onChanged: (v) => setState(() => _requiereReserva = v),
                    ),
                    SwitchListTile(
                      title: const Text('Requiere depósito'),
                      value: _requiereDeposito,
                      onChanged: (v) => setState(() => _requiereDeposito = v),
                    ),
                    SwitchListTile(
                      title: const Text('Visible en marketplace'),
                      value: _visibleMarketplace,
                      onChanged: (v) => setState(() => _visibleMarketplace = v),
                    ),
                    SwitchListTile(
                      title: const Text('En oferta'),
                      value: _enOferta,
                      onChanged: (v) => setState(() => _enOferta = v),
                    ),
                    if (_enOferta) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _precioOfertaController,
                        decoration: const InputDecoration(
                          labelText: 'Precio de oferta',
                          border: OutlineInputBorder(),
                          prefixText: 'S/ ',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          widget.isEditing ? 'Guardar cambios' : 'Crear servicio',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPlantillaPreview() {
    final plantilla = _plantillas.where((p) => p.id == _selectedPlantillaId).firstOrNull;
    if (plantilla == null || plantilla.campos.isEmpty) return const SizedBox.shrink();

    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Campos de "${plantilla.nombre}"',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 8),
            ...plantilla.campos.map((c) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          size: 16, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text(c.nombre, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 4),
                      Text(
                        '(${c.tipoCampo})',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade600),
                      ),
                      if (c.esRequerido) ...[
                        const SizedBox(width: 4),
                        Text('*',
                            style: TextStyle(
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.bold)),
                      ],
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is! EmpresaContextLoaded) return;

    final empresaId = empresaState.context.empresa.id;
    final repo = locator<ServicioRepository>();

    setState(() => _isLoading = true);

    final result = widget.isEditing
        ? await repo.actualizar(
            id: widget.servicioId!,
            empresaId: empresaId,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            precio: double.tryParse(_precioController.text),
            precioPorHora: double.tryParse(_precioPorHoraController.text),
            duracionMinutos: int.tryParse(_duracionMinutosController.text),
            requiereReserva: _requiereReserva,
            requiereDeposito: _requiereDeposito,
            visibleMarketplace: _visibleMarketplace,
            enOferta: _enOferta,
            precioOferta: double.tryParse(_precioOfertaController.text),
            plantillaServicioId: _selectedPlantillaId,
          )
        : await repo.crear(
            empresaId: empresaId,
            nombre: _nombreController.text.trim(),
            descripcion: _descripcionController.text.trim().isEmpty
                ? null
                : _descripcionController.text.trim(),
            precio: double.tryParse(_precioController.text),
            precioPorHora: double.tryParse(_precioPorHoraController.text),
            duracionMinutos: int.tryParse(_duracionMinutosController.text),
            requiereReserva: _requiereReserva,
            requiereDeposito: _requiereDeposito,
            visibleMarketplace: _visibleMarketplace,
            enOferta: _enOferta,
            precioOferta: double.tryParse(_precioOfertaController.text),
            plantillaServicioId: _selectedPlantillaId,
          );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result is Success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(widget.isEditing ? 'Servicio actualizado' : 'Servicio creado')),
      );
      context.pop();
    } else if (result is Error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text((result as Error).message)),
      );
    }
  }
}
