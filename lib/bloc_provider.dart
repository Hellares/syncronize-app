import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';
import 'package:syncronize/core/constants/storage_constants.dart';
import 'package:syncronize/features/auth/presentation/bloc/auth/auth_bloc.dart';
import 'package:syncronize/features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/producto_list/producto_list_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/producto_detail/producto_detail_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/producto_variante/producto_variante_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/sede_selection/sede_selection_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/producto_atributo/producto_atributo_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/atributo_plantilla/atributo_plantilla_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/configuracion_precio/configuracion_precio_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/categorias_maestras/categorias_maestras_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/marcas_maestras/marcas_maestras_cubit.dart';
import 'package:syncronize/features/combo/presentation/bloc/combo_cubit.dart';
import 'package:syncronize/features/cliente/presentation/bloc/cliente_list/cliente_list_cubit.dart';
import 'package:syncronize/features/cliente/presentation/bloc/cliente_form/cliente_form_cubit.dart';
import 'package:syncronize/features/proveedor/presentation/bloc/proveedor_list/proveedor_list_cubit.dart';
import 'package:syncronize/features/proveedor/presentation/bloc/proveedor_form/proveedor_form_cubit.dart';
import 'package:syncronize/features/usuario/presentation/bloc/usuario_list/usuario_list_cubit.dart';
import 'package:syncronize/features/usuario/presentation/bloc/usuario_form/usuario_form_cubit.dart';
import 'package:syncronize/features/descuento/presentation/bloc/politica_list/politica_list_cubit.dart';
import 'package:syncronize/features/descuento/presentation/bloc/politica_form/politica_form_cubit.dart';
import 'package:syncronize/features/descuento/presentation/bloc/asignar_usuarios/asignar_usuarios_cubit.dart';
import 'package:syncronize/features/configuracion_codigos/presentation/bloc/configuracion_codigos_cubit.dart';
import 'package:syncronize/features/sede/presentation/bloc/sede_list/sede_list_cubit.dart';
import 'package:syncronize/features/sede/presentation/bloc/sede_form/sede_form_cubit.dart';
import 'package:syncronize/features/catalogo/presentation/bloc/unidades_medida/unidades_medida_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/stock_por_sede/stock_por_sede_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/stock_todas_sedes/stock_todas_sedes_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/ajustar_stock/ajustar_stock_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/alertas_stock/alertas_stock_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/transferencias_list/transferencias_list_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/crear_transferencia/crear_transferencia_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/gestionar_transferencia/gestionar_transferencia_cubit.dart';
import 'package:syncronize/features/producto/presentation/bloc/transferencia_detail/transferencia_detail_cubit.dart';

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

  // Sede Selection Cubit - Maneja la selección de sede para productos
  BlocProvider<SedeSelectionCubit>(
    create: (context) => locator<SedeSelectionCubit>(),
    lazy: false, // No lazy para cargar la sede guardada al inicio
  ),

  // Categorias Empresa Cubit - Maneja las categorías de la empresa
  BlocProvider<CategoriasEmpresaCubit>(
    create: (context) => locator<CategoriasEmpresaCubit>(),
    lazy: true,
  ),

  // Categorias Maestras Cubit - Maneja las categorías maestras disponibles
  BlocProvider<CategoriasMaestrasCubit>(
    create: (context) => locator<CategoriasMaestrasCubit>(),
    lazy: true,
  ),

  // Marcas Empresa Cubit - Maneja las marcas de la empresa
  BlocProvider<MarcasEmpresaCubit>(
    create: (context) => locator<MarcasEmpresaCubit>(),
    lazy: true,
  ),

  // Marcas Maestras Cubit - Maneja las marcas maestras disponibles
  BlocProvider<MarcasMaestrasCubit>(
    create: (context) => locator<MarcasMaestrasCubit>(),
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

  // Proveedor List Cubit - Maneja la lista de proveedores
  BlocProvider<ProveedorListCubit>(
    create: (context) => locator<ProveedorListCubit>(),
    lazy: true,
  ),

  // Proveedor Form Cubit - Maneja el formulario de registro de proveedores
  BlocProvider<ProveedorFormCubit>(
    create: (context) => locator<ProveedorFormCubit>(),
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

  // Usuario List Cubit - Maneja la lista de usuarios/empleados
  BlocProvider<UsuarioListCubit>(
    create: (context) => locator<UsuarioListCubit>(),
    lazy: true,
  ),

  // Usuario Form Cubit - Maneja el formulario de registro de usuarios/empleados
  BlocProvider<UsuarioFormCubit>(
    create: (context) => locator<UsuarioFormCubit>(),
    lazy: true,
  ),

  // Configuracion Codigos Cubit - Maneja la configuración de nomenclaturas
  BlocProvider<ConfiguracionCodigosCubit>(
    create: (context) => locator<ConfiguracionCodigosCubit>(),
    lazy: true,
  ),

  // Sede List Cubit - Maneja la lista de sedes
  BlocProvider<SedeListCubit>(
    create: (context) => locator<SedeListCubit>(),
    lazy: true,
  ),

  // Sede Form Cubit - Maneja el formulario de creación/edición de sedes
  BlocProvider<SedeFormCubit>(
    create: (context) => locator<SedeFormCubit>(),
    lazy: true,
  ),

  // Unidad Medida Cubit - Maneja las unidades de medida de la empresa
  BlocProvider<UnidadMedidaCubit>(
    create: (context) => locator<UnidadMedidaCubit>(),
    lazy: true,
  ),

  // Stock Por Sede Cubit - Maneja el listado de stock de una sede
  BlocProvider<StockPorSedeCubit>(
    create: (context) => locator<StockPorSedeCubit>(),
    lazy: true,
  ),

  // Stock Todas Sedes Cubit - Maneja el stock de un producto en todas las sedes
  BlocProvider<StockTodasSedesCubit>(
    create: (context) => locator<StockTodasSedesCubit>(),
    lazy: true,
  ),

  // Ajustar Stock Cubit - Maneja el formulario de ajuste de stock
  BlocProvider<AjustarStockCubit>(
    create: (context) => locator<AjustarStockCubit>(),
    lazy: true,
  ),

  // Alertas Stock Cubit - Maneja las alertas de stock bajo
  BlocProvider<AlertasStockCubit>(
    create: (context) => locator<AlertasStockCubit>(),
    lazy: true,
  ),

  // Transferencias List Cubit - Maneja la lista de transferencias entre sedes
  BlocProvider<TransferenciasListCubit>(
    create: (context) => locator<TransferenciasListCubit>(),
    lazy: true,
  ),

  // Crear Transferencia Cubit - Maneja la creación de transferencias
  BlocProvider<CrearTransferenciaCubit>(
    create: (context) => locator<CrearTransferenciaCubit>(),
    lazy: true,
  ),

  // Gestionar Transferencia Cubit - Maneja las acciones sobre transferencias
  BlocProvider<GestionarTransferenciaCubit>(
    create: (context) => locator<GestionarTransferenciaCubit>(),
    lazy: true,
  ),

  // Transferencia Detail Cubit - Maneja el detalle de una transferencia
  BlocProvider<TransferenciaDetailCubit>(
    create: (context) => locator<TransferenciaDetailCubit>(),
    lazy: true,
  ),
];
