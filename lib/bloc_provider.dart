import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';
import 'package:syncronize/core/constants/storage_constants.dart';
import 'package:syncronize/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/producto_detail/producto_detail_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/producto_variante/producto_variante_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/producto_atributo/producto_atributo_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/configuracion_precio/configuracion_precio_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart';
import 'package:syncronize/features/combo/presentation/bloc/combo_cubit.dart';
import 'package:syncronize/features/cliente/presentation/bloc/cliente_list/cliente_list_cubit.dart';
import 'package:syncronize/features/cliente/presentation/bloc/cliente_form/cliente_form_cubit.dart';
import 'package:syncronize/features/descuento/presentation/bloc/politica_list/politica_list_cubit.dart';
import 'package:syncronize/features/descuento/presentation/bloc/politica_form/politica_form_cubit.dart';
import 'package:syncronize/features/descuento/presentation/bloc/asignar_usuarios/asignar_usuarios_cubit.dart';

/// Lista centralizada de todos los BLoCs globales de la aplicación
List<BlocProvider> blocProviders = [
  // Auth BLoC - Maneja el estado de autenticación global
  BlocProvider<AuthBloc>(
    create: (context) {
      final bloc = locator<AuthBloc>();
      // Diferir el evento para no bloquear la primera renderización
      Future.microtask(() => bloc.add(const CheckAuthStatusEvent()));
      return bloc;
    },
    lazy: false, // Crear inmediatamente pero sin bloquear
  ),

  // Empresa Context Cubit - Maneja el estado del contexto de la empresa seleccionada
  BlocProvider<EmpresaContextCubit>(
    create: (context) {
      final cubit = locator<EmpresaContextCubit>();
      // Cargar contexto automáticamente después del auth check
      // Esto garantiza que el tenantId esté disponible en localStorage
      // ANTES de que el usuario navegue a cualquier página
      Future.microtask(() {
        final localStorage = locator<LocalStorageService>();
        final tenantId = localStorage.getString(StorageConstants.tenantId);

        // Solo cargar si ya existe un tenantId (usuario ya seleccionó empresa)
        if (tenantId != null && tenantId.isNotEmpty) {
          cubit.loadEmpresaContext();
        }
      });
      return cubit;
    },
    lazy: false, // Crear inmediatamente para evitar race conditions
  ),

  // Producto List Cubit - Maneja la lista de productos
  BlocProvider<ProductoListCubit>(
    create: (context) => locator<ProductoListCubit>(),
    lazy: true,
  ),

  // Producto Detail Cubit - Maneja el detalle de un producto
  BlocProvider<ProductoDetailCubit>(
    create: (context) => locator<ProductoDetailCubit>(),
    lazy: true,
  ),

  // Categorias Empresa Cubit - Maneja las categorías de la empresa
  BlocProvider<CategoriasEmpresaCubit>(
    create: (context) => locator<CategoriasEmpresaCubit>(),
    lazy: true,
  ),

  // Marcas Empresa Cubit - Maneja las marcas de la empresa
  BlocProvider<MarcasEmpresaCubit>(
    create: (context) => locator<MarcasEmpresaCubit>(),
    lazy: true,
  ),

  // Producto Variante Cubit - Maneja las variantes de productos
  BlocProvider<ProductoVarianteCubit>(
    create: (context) => locator<ProductoVarianteCubit>(),
    lazy: true,
  ),

  // Producto Atributo Cubit - Maneja los atributos de productos
  BlocProvider<ProductoAtributoCubit>(
    create: (context) => locator<ProductoAtributoCubit>(),
    lazy: true,
  ),

  // Atributo Plantilla Cubit - Maneja las plantillas de atributos predefinidas
  BlocProvider<AtributoPlantillaCubit>(
    create: (context) => locator<AtributoPlantillaCubit>(),
    lazy: true,
  ),

  // Configuracion Precio Cubit - Maneja las configuraciones de precios por volumen
  BlocProvider<ConfiguracionPrecioCubit>(
    create: (context) => locator<ConfiguracionPrecioCubit>(),
    lazy: true,
  ),

  // Combo Cubit - Maneja los combos/kits de productos
  BlocProvider<ComboCubit>(
    create: (context) => locator<ComboCubit>(),
    lazy: true,
  ),

  // Cliente List Cubit - Maneja la lista de clientes
  BlocProvider<ClienteListCubit>(
    create: (context) => locator<ClienteListCubit>(),
    lazy: true,
  ),

  // Cliente Form Cubit - Maneja el formulario de registro de clientes
  BlocProvider<ClienteFormCubit>(
    create: (context) => locator<ClienteFormCubit>(),
    lazy: true,
  ),

  // Politica List Cubit - Maneja la lista de políticas de descuento
  BlocProvider<PoliticaListCubit>(
    create: (context) => locator<PoliticaListCubit>(),
    lazy: true,
  ),

  // Politica Form Cubit - Maneja el formulario de políticas de descuento
  BlocProvider<PoliticaFormCubit>(
    create: (context) => locator<PoliticaFormCubit>(),
    lazy: true,
  ),

  // Asignar Usuarios Cubit - Maneja la asignación de usuarios a políticas
  BlocProvider<AsignarUsuariosCubit>(
    create: (context) => locator<AsignarUsuariosCubit>(),
    lazy: true,
  ),
];
