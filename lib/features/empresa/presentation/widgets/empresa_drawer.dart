import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:syncronize/core/fonts/app_fonts.dart';
import 'package:syncronize/core/fonts/app_text_widgets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/gradient_background.dart';
import '../bloc/empresa_context/empresa_context_cubit.dart';
import '../bloc/empresa_context/empresa_context_state.dart';

class EmpresaDrawer extends StatelessWidget {
  const EmpresaDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 260,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(20),
          topLeft: Radius.zero,
          bottomLeft: Radius.zero,
          bottomRight: Radius.zero,
        ),
      ),
      backgroundColor: Colors.white,
      child: BlocBuilder<EmpresaContextCubit, EmpresaContextState>(
        builder: (context, state) {
          final permissions = state is EmpresaContextLoaded
              ? state.context.permissions
              : null;
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              _buildDrawerHeader(state),
              ListTile(
                leading: const Icon(Icons.dashboard, color: AppColors.blue2,),
                title: AppSubtitle( 'Dashboard', font: AppFont.oxygenBold, fontSize: 10,),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              if (permissions?.canManageProducts ?? false)
                ListTile(
                  leading: const Icon(Icons.inventory, color: AppColors.blue2,),
                  title: const AppSubtitle('Productos',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/productos');
                  },
                ),
              if (permissions?.canManageProducts ?? false)
                ListTile(
                  leading: const Icon(Icons.inventory_2, color: AppColors.blue2,),
                  title: const AppSubtitle('Combos',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    final empresaId = state is EmpresaContextLoaded
                        ? state.context.empresa.id
                        : '';
                    context.push('/empresa/combos?empresaId=$empresaId');
                  },
                ),
              if (permissions?.canManageProducts ?? false)
                ListTile(
                  leading: const Icon(Icons.category, color: AppColors.blue2,),
                  title: const AppSubtitle('Categorías',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/categorias');
                  },
                ),
              if (permissions?.canManageProducts ?? false)
                ListTile(
                  leading: const Icon(Icons.label, color: AppColors.blue2,),
                  title: const AppSubtitle('Marcas',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/marcas');
                  },
                ),
              if (permissions?.canManageProducts ?? false)
                ListTile(
                  leading: const Icon(Icons.tune, color: AppColors.blue2,),
                  title: const AppSubtitle('Atributos',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/atributos');
                  },
                ),
              if (permissions?.canManageProducts ?? false)
                ListTile(
                  leading: const Icon(Icons.dashboard_customize, color: AppColors.blue2,),
                  title: const AppSubtitle('Plantillas de Atributos',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/plantillas');
                  },
                ),
              if (permissions?.canManageProducts ?? false)
                ListTile(
                  leading: const Icon(Icons.auto_graph, color: AppColors.blue2,),
                  title: const AppSubtitle('Configuraciones de Precio',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/configuraciones-precio');
                  },
                ),
              if (permissions?.canManageProducts ?? false)
                ListTile(
                  leading: const Icon(Icons.percent, color: AppColors.orange,),
                  title: const AppSubtitle('Ajuste Masivo de Precios',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/productos/ajuste-masivo');
                  },
                ),
              if (permissions?.canViewDiscounts ?? false)
                ListTile(
                  leading: const Icon(Icons.discount, color: AppColors.blue2,),
                  title: const AppSubtitle('Políticas de Descuento',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/descuentos');
                  },
                ),
              if (permissions?.canManageServices ?? false)
                ListTile(
                  leading: const Icon(Icons.room_service, color: AppColors.blue2,),
                  title: const AppSubtitle('Servicios',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/servicios');
                  },
                ),
              if (permissions?.canManageOrders ?? false)
                ListTile(
                  leading: const Icon(Icons.assignment, color: AppColors.blue2,),
                  title: const AppSubtitle('Órdenes de Servicio',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/ordenes');
                  },
                ),
              if (permissions?.canManageSedes ?? false)
                ListTile(
                  leading: const Icon(Icons.store, color: AppColors.blue2,),
                  title: const AppSubtitle('Sedes',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/sedes');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.people_alt, color: AppColors.blue2,),
                title: const AppSubtitle('Clientes',font: AppFont.oxygenBold, fontSize: 10),
                onTap: () {
                  Navigator.pop(context);
                  final empresaId = state is EmpresaContextLoaded
                      ? state.context.empresa.id
                      : '';
                  context.push('/empresa/clientes?empresaId=$empresaId');
                },
              ),
              if (permissions?.canManageUsers ?? false)
                ListTile(
                  leading: const Icon(Icons.people, color: AppColors.blue2,),
                  title: const AppSubtitle('Usuarios',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/usuarios');
                  },
                ),
              const Divider(),
              const ListTile(
                leading: Icon(Icons.settings, color: AppColors.blue2,),
                title: AppSubtitle('Configuración',font: AppFont.oxygenBold, fontSize: 10),
                enabled: false,
              ),
              if (permissions?.canManageSettings ?? false)
                ListTile(
                  leading: const Icon(Icons.palette, color: AppColors.blue2,),
                  title: const AppSubtitle('Personalización',font: AppFont.oxygenBold, fontSize: 10),
                  onTap: () {
                    Navigator.pop(context);
                    context.push('/empresa/personalizacion');
                  },
                ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.storefront, color: AppColors.blue2,),
                title: const AppSubtitle('Ir a Marketplace',font: AppFont.oxygenBold, fontSize: 10),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/marketplace');
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDrawerHeader(EmpresaContextState state) {
    if (state is EmpresaContextLoaded) {
      return GradientBackground(
        style: GradientStyle.gjayli,
        child: UserAccountsDrawerHeader(
          decoration: const BoxDecoration(
            color: Colors.transparent,
          ),
          accountName: AppTitle(state.context.empresa.nombre, font: AppFont.pirulentBold, fontSize: 8,),
          accountEmail: AppTitle(state.context.empresa.email ?? 'Sin email',),
          currentAccountPicture: CircleAvatar(
            backgroundColor: Colors.white,
            child: state.context.empresa.logo != null
                ? Image.network(state.context.empresa.logo!)
                : Text(
                    state.context.empresa.nombre[0].toUpperCase(),
                    style: const TextStyle(fontSize: 25),
                  ),
          ),
        ),
      );
    }

    return const DrawerHeader(
      decoration: BoxDecoration(color: AppColors.blue2),
      child: Text(
        'Menú',
        style: TextStyle(color: Colors.white, fontSize: 18),
      ),
    );
  }
}
