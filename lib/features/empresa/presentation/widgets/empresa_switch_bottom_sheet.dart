import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/di/injection_container.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/storage/secure_storage_service.dart';
import '../../../../core/constants/storage_constants.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/empresa_list_item.dart';
import '../../domain/usecases/get_user_empresas_usecase.dart';
import '../../domain/usecases/switch_empresa_usecase.dart';
import '../../../auth/domain/usecases/refresh_token_usecase.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';

/// Bottom sheet para seleccionar y cambiar de empresa
class EmpresaSwitchBottomSheet extends StatefulWidget {
  final String currentEmpresaId;

  const EmpresaSwitchBottomSheet({
    super.key,
    required this.currentEmpresaId,
  });

  @override
  State<EmpresaSwitchBottomSheet> createState() =>
      _EmpresaSwitchBottomSheetState();
}

class _EmpresaSwitchBottomSheetState extends State<EmpresaSwitchBottomSheet> {
  final _getUserEmpresasUseCase = locator<GetUserEmpresasUseCase>();
  final _switchEmpresaUseCase = locator<SwitchEmpresaUseCase>();
  final _refreshTokenUseCase = locator<RefreshTokenUseCase>();
  final _localStorage = locator<LocalStorageService>();
  final _secureStorage = locator<SecureStorageService>();

  bool _isLoading = true;
  bool _isSwitching = false;
  List<EmpresaListItem> _empresas = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadEmpresas();
  }

  Future<void> _loadEmpresas() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await _getUserEmpresasUseCase();

    if (!mounted) return;

    if (result is Success<List<EmpresaListItem>>) {
      setState(() {
        _empresas = result.data;
        _isLoading = false;
      });
    } else if (result is Error) {
      setState(() {
        _errorMessage = (result as Error).message;
        _isLoading = false;
      });
    }
  }

  Future<void> _switchToEmpresa(EmpresaListItem empresa) async {
    if (empresa.id == widget.currentEmpresaId) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isSwitching = true;
    });

    // 1. Llamar al backend para registrar el switch
    final switchResult = await _switchEmpresaUseCase(
      empresaId: empresa.id,
      subdominio: empresa.subdominio,
    );

    if (switchResult is Error) {
      if (!mounted) return;
      setState(() {
        _isSwitching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text((switchResult).message),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Refrescar tokens para obtener JWT con los roles de la nueva empresa
    final currentRefreshToken = await _secureStorage.read(
      key: StorageConstants.refreshToken,
    );

    if (currentRefreshToken == null) {
      if (!mounted) return;
      setState(() {
        _isSwitching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró el token de actualización'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final refreshResult = await _refreshTokenUseCase(
      RefreshTokenParams(refreshToken: currentRefreshToken),
    );

    if (refreshResult is Error) {
      if (!mounted) return;
      setState(() {
        _isSwitching = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al actualizar tokens: ${(refreshResult as Error).message}'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Guardar los nuevos tokens
    if (refreshResult is Success) {
      final tokens = (refreshResult as Success).data;
      await _secureStorage.write(
        key: StorageConstants.accessToken,
        value: tokens.accessToken,
      );
      await _secureStorage.write(
        key: StorageConstants.refreshToken,
        value: tokens.refreshToken,
      );
    }

    // 3. Actualizar el storage local
    await _localStorage.setString(StorageConstants.tenantId, empresa.id);
    await _localStorage.setString(StorageConstants.tenantName, empresa.nombre);
    await _localStorage.setString(StorageConstants.loginMode, 'management');

    // 4. Pequeño delay para asegurar que el storage se actualice
    await Future.delayed(const Duration(milliseconds: 100));

    // 5. Recargar el contexto de la nueva empresa
    if (!mounted) return;
    await context.read<EmpresaContextCubit>().loadEmpresaContextById(empresa.id);

    setState(() {
      _isSwitching = false;
    });

    if (!mounted) return;

    // 6. Cerrar el bottom sheet
    Navigator.pop(context);

    // 7. Mostrar confirmación
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cambiado a: ${empresa.nombre}'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.business, color: Colors.blue),
                const SizedBox(width: 12),
                const Text(
                  'Mis Empresas',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          if (_isSwitching)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Cambiando de empresa...'),
                ],
              ),
            )
          else if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )
          else if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadEmpresas,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          else if (_empresas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Text('No tienes empresas asignadas'),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _empresas.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final empresa = _empresas[index];
                final isActive = empresa.id == widget.currentEmpresaId;

                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        isActive ? Colors.blue : Colors.grey.shade300,
                    child: empresa.logo != null
                        ? Image.network(empresa.logo!)
                        : Text(
                            empresa.nombre[0].toUpperCase(),
                            style: TextStyle(
                              color: isActive ? Colors.white : Colors.grey.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  title: Text(
                    empresa.nombre,
                    style: TextStyle(
                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (empresa.primaryRole != null)
                        Text(_formatRole(empresa.primaryRole!)),
                      if (empresa.planNombre != null)
                        Text(
                          'Plan: ${empresa.planNombre}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                  trailing: isActive
                      ? const Chip(
                          label: Text(
                            'Actual',
                            style: TextStyle(fontSize: 11),
                          ),
                          backgroundColor: Colors.blue,
                          labelStyle: TextStyle(color: Colors.white),
                        )
                      : const Icon(Icons.chevron_right),
                  onTap: isActive ? null : () => _switchToEmpresa(empresa),
                  selected: isActive,
                  selectedTileColor: Colors.blue.shade50,
                );
              },
            ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    final roleMap = {
      'SUPER_ADMIN': 'Super Admin',
      'EMPRESA_ADMIN': 'Administrador',
      'SEDE_ADMIN': 'Admin de Sede',
      'CAJERO': 'Cajero',
      'VENDEDOR': 'Vendedor',
      'TECNICO': 'Técnico',
      'CONTADOR': 'Contador',
      'LECTURA': 'Solo Lectura',
    };
    return roleMap[role] ?? role;
  }
}
