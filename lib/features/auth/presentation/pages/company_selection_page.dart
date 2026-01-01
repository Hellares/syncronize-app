import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/available_company.dart';
import '../bloc/login/login_cubit.dart';


class CompanySelectionPage extends StatelessWidget {
  final List<AvailableCompany> companies;
  final String email;
  final String password;

  const CompanySelectionPage({
    super.key,
    required this.companies,
    required this.email,
    required this.password,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecciona una Empresa'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Icon(
                    Icons.business,
                    size: 64,
                    color: Colors.blue,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Tienes acceso a ${companies.length} ${companies.length == 1 ? 'empresa' : 'empresas'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selecciona la empresa a la que deseas acceder',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                itemCount: companies.length,
                itemBuilder: (context, index) {
                  final company = companies[index];
                  return _CompanyCard(
                    company: company,
                    onTap: () => _selectCompany(context, company),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _selectCompany(BuildContext context, AvailableCompany company) {
    // Login con la empresa seleccionada
    context.read<LoginCubit>().loginWithCompany(
          email: email,
          password: password,
          subdominio: company.subdominio,
        );
  }
}

class _CompanyCard extends StatelessWidget {
  final AvailableCompany company;
  final VoidCallback onTap;

  const _CompanyCard({
    required this.company,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Logo de la empresa
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: company.logo != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          company.logo!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.business,
                              size: 32,
                              color: Colors.grey,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.business,
                        size: 32,
                        color: Colors.grey,
                      ),
              ),
              const SizedBox(width: 16),
              // Información de la empresa
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      company.nombre,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${company.subdominio}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Roles del usuario en esta empresa
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: company.roles.map((role) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getRoleColor(role).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _formatRole(role),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: _getRoleColor(role),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Icono de flecha
              Icon(
                Icons.arrow_forward_ios,
                size: 20,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'SUPER_ADMIN':
        return Colors.purple;
      case 'ADMIN_EMPRESA':
        return Colors.blue;
      case 'GERENTE':
        return Colors.orange;
      case 'VENDEDOR':
        return Colors.green;
      case 'CLIENTE':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }

  String _formatRole(String role) {
    final roleNames = {
      'SUPER_ADMIN': 'Super Admin',
      'ADMIN_EMPRESA': 'Admin',
      'GERENTE': 'Gerente',
      'VENDEDOR': 'Vendedor',
      'CLIENTE': 'Cliente',
      'USUARIO': 'Usuario',
    };
    return roleNames[role] ?? role;
  }
}
