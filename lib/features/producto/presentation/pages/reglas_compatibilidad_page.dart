import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import '../../../empresa/presentation/bloc/empresa_context/empresa_context_state.dart';
import '../../../catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import '../../domain/entities/regla_compatibilidad.dart';
import '../bloc/compatibilidad/compatibilidad_cubit.dart';
import '../bloc/compatibilidad/compatibilidad_state.dart';
import '../bloc/producto_atributo/producto_atributo_cubit.dart';
import '../widgets/regla_compatibilidad_dialog.dart';

class ReglasCompatibilidadPage extends StatefulWidget {
  const ReglasCompatibilidadPage({super.key});

  @override
  State<ReglasCompatibilidadPage> createState() =>
      _ReglasCompatibilidadPageState();
}

class _ReglasCompatibilidadPageState extends State<ReglasCompatibilidadPage> {
  @override
  void initState() {
    super.initState();
    _loadReglas();
  }

  void _loadReglas() {
    final empresaState = context.read<EmpresaContextCubit>().state;
    if (empresaState is EmpresaContextLoaded) {
      final empresaId = empresaState.context.empresa.id;
      context.read<CompatibilidadCubit>().loadReglas();
      context.read<CategoriasEmpresaCubit>().loadCategorias(empresaId);
      context.read<ProductoAtributoCubit>().loadAtributos(empresaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reglas de Compatibilidad'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Ayuda',
          ),
        ],
      ),
      body: BlocConsumer<CompatibilidadCubit, CompatibilidadState>(
        listener: (context, state) {
          if (state is CompatibilidadOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          } else if (state is CompatibilidadError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is CompatibilidadLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          List<ReglaCompatibilidad> reglas = [];
          if (state is CompatibilidadReglasLoaded) {
            reglas = state.reglas;
          } else if (state is CompatibilidadOperationSuccess) {
            reglas = state.reglas;
          }

          if (reglas.isEmpty && state is! CompatibilidadLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.rule, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay reglas de compatibilidad',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Crea reglas para validar la compatibilidad\nentre productos de diferentes categorias',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _showCreateDialog(),
                    icon: const Icon(Icons.add),
                    label: const Text('Crear regla'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => _loadReglas(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reglas.length,
              itemBuilder: (context, index) {
                final regla = reglas[index];
                return _buildReglaTile(regla);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildReglaTile(ReglaCompatibilidad regla) {
    final tipoLabel = regla.tipoValidacion == 'IGUAL'
        ? 'Debe coincidir'
        : 'Incluye en mapeo';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.link, color: Colors.blue, size: 20),
        ),
        title: Text(
          regla.nombre,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${regla.categoriaOrigenNombre ?? "Origen"} (${regla.atributoOrigenClave})',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(Icons.arrow_forward, size: 14, color: Colors.grey),
                ),
                Expanded(
                  child: Text(
                    '${regla.categoriaDestinoNombre ?? "Destino"} (${regla.atributoDestinoClave})',
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                tipoLabel,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'editar',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Editar'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'eliminar',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Eliminar', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 'editar') {
              _showEditDialog(regla);
            } else if (value == 'eliminar') {
              _confirmDelete(regla);
            }
          },
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showCreateDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CompatibilidadCubit>(),
        child: const ReglaCompatibilidadDialog(),
      ),
    );
  }

  void _showEditDialog(ReglaCompatibilidad regla) {
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: context.read<CompatibilidadCubit>(),
        child: ReglaCompatibilidadDialog(regla: regla),
      ),
    );
  }

  void _confirmDelete(ReglaCompatibilidad regla) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar regla'),
        content: Text(
            '¿Estas seguro de eliminar la regla "${regla.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.read<CompatibilidadCubit>().eliminarRegla(regla.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reglas de Compatibilidad'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Las reglas de compatibilidad permiten validar que los productos seleccionados sean compatibles entre si.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'Ejemplo:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'Si un motherboard tiene socket AM5, solo se pueden agregar CPUs con socket AM5.',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 12),
              Text(
                'Tipos de validacion:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              SizedBox(height: 4),
              Text(
                'IGUAL: El valor del atributo debe ser identico.\n'
                'INCLUYE_EN: El valor debe estar en un mapeo personalizado.',
                style: TextStyle(fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }
}
