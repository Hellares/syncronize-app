import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/utils/resource.dart';
import '../../../../core/widgets/snack_bar_helper.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../domain/entities/empresa_list_item.dart';
import '../../domain/usecases/get_user_empresas_usecase.dart';
import '../../domain/usecases/switch_empresa_usecase.dart';

/// Página inteligente de selección de empresa
/// Maneja automáticamente los casos:
/// - 0 empresas: Redirige a crear empresa
/// - 1 empresa: Selecciona automáticamente y va al dashboard
/// - 2+ empresas: Muestra selector
class EmpresaSelectionPage extends StatefulWidget {
  const EmpresaSelectionPage({super.key});

  @override
  State<EmpresaSelectionPage> createState() => _EmpresaSelectionPageState();
}

class _EmpresaSelectionPageState extends State<EmpresaSelectionPage> {
  final _getUserEmpresasUseCase = locator<GetUserEmpresasUseCase>();
  final _switchEmpresaUseCase = locator<SwitchEmpresaUseCase>();
  final _localStorage = locator<LocalStorageService>();

  bool _isLoading = true;
  List<EmpresaListItem> _empresas = [];
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _loadEmpresas();
  }

  Future<void> _loadEmpresas() async {
    setState(() => _isLoading = true);

    final result = await _getUserEmpresasUseCase();

    if (!mounted) return;

    if (result is Success<List<EmpresaListItem>>) {
      final empresas = (result).data;

      setState(() {
        _empresas = empresas;
        _isLoading = false;
      });

      // Manejar casos automáticamente
      if (empresas.isEmpty) {
        // No tiene empresas → Redirigir a crear
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            context.pushReplacement('/create-empresa');
          }
        });
      } else if (empresas.length == 1) {
        // Tiene solo una → Seleccionar automáticamente
        _selectEmpresa(empresas.first);
      }
      // Si tiene 2+, mostrar selector (no hacer nada, el build lo muestra)
    } else {
      setState(() => _isLoading = false);
      SnackBarHelper.showError(
        context,
        'Error al cargar empresas',
      );
    }
  }

  Future<void> _selectEmpresa(EmpresaListItem empresa) async {
    if (_isSelecting) return;

    setState(() => _isSelecting = true);

    final result = await _switchEmpresaUseCase(
      empresaId: empresa.id,
      subdominio: empresa.subdominio,
    );

    if (!mounted) return;

    if (result is Success) {
      // Asegurar que el tenantId se guardó correctamente con el nombre
      await _localStorage.setString(StorageConstants.tenantId, empresa.id);
      await _localStorage.setString(StorageConstants.tenantName, empresa.nombre);
      await _localStorage.setString(StorageConstants.loginMode, 'management');

      // Verificar mounted después de las operaciones async
      if (!mounted) return;

      // Navegar al dashboard
      context.go('/empresa/dashboard');
    } else if (result is Error) {
      setState(() => _isSelecting = false);
      SnackBarHelper.showError(
        context,
        (result).message,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Mis Empresas'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Si tiene 2+ empresas, mostrar selector
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona una Empresa'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/marketplace'),
        ),
      ),
      body: Column(
        children: [
          // Header informativo
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).primaryColor.withValues(alpha: 0.1),
                  Theme.of(context).primaryColor.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.business_center,
                      color: Theme.of(context).primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tus Empresas',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          Text(
                            'Selecciona la empresa que deseas gestionar',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.grey.shade600,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista de empresas
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _empresas.length,
              itemBuilder: (context, index) {
                final empresa = _empresas[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                      child: empresa.logo != null
                          ? ClipOval(
                              child: Image.network(
                                empresa.logo!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Icon(
                                  Icons.business,
                                  color: Theme.of(context).primaryColor,
                                  size: 28,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.business,
                              color: Theme.of(context).primaryColor,
                              size: 28,
                            ),
                    ),
                    title: Text(
                      empresa.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (empresa.ruc != null)
                          Text('RUC: ${empresa.ruc}'),
                        const SizedBox(height: 4),
                        Chip(
                          label: Text(
                            empresa.estadoSuscripcion,
                            style: const TextStyle(fontSize: 11),
                          ),
                          padding: EdgeInsets.zero,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: empresa.isSubscriptionActive
                              ? Colors.green.shade100
                              : Colors.orange.shade100,
                        ),
                      ],
                    ),
                    trailing: _isSelecting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.arrow_forward_ios, size: 18),
                    onTap: _isSelecting ? null : () => _selectEmpresa(empresa),
                  ),
                );
              },
            ),
          ),

          // Botón para crear nueva empresa
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () {
                context.push('/create-empresa');
              },
              icon: const Icon(Icons.add_business),
              label: const Text('Crear Nueva Empresa'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
