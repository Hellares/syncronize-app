// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:dio/dio.dart' as _i361;
import 'package:flutter_secure_storage/flutter_secure_storage.dart' as _i558;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import '../../features/auth/data/datasources/auth_local_datasource.dart'
    as _i992;
import '../../features/auth/data/datasources/auth_remote_datasource.dart'
    as _i161;
import '../../features/auth/data/repositories/auth_repository_impl.dart'
    as _i153;
import '../../features/auth/domain/repositories/auth_repository.dart' as _i787;
import '../../features/auth/domain/usecases/change_password_usecase.dart'
    as _i788;
import '../../features/auth/domain/usecases/check_auth_methods_usecase.dart'
    as _i809;
import '../../features/auth/domain/usecases/check_auth_status_usecase.dart'
    as _i52;
import '../../features/auth/domain/usecases/create_empresa_usecase.dart'
    as _i612;
import '../../features/auth/domain/usecases/forgot_password_usecase.dart'
    as _i560;
import '../../features/auth/domain/usecases/get_local_user_usecase.dart'
    as _i386;
import '../../features/auth/domain/usecases/get_profile_usecase.dart' as _i568;
import '../../features/auth/domain/usecases/google_sign_in_usecase.dart'
    as _i91;
import '../../features/auth/domain/usecases/login_usecase.dart' as _i188;
import '../../features/auth/domain/usecases/logout_usecase.dart' as _i48;
import '../../features/auth/domain/usecases/refresh_token_usecase.dart'
    as _i157;
import '../../features/auth/domain/usecases/register_usecase.dart' as _i941;
import '../../features/auth/domain/usecases/resend_verification_email_usecase.dart'
    as _i698;
import '../../features/auth/domain/usecases/reset_password_usecase.dart'
    as _i474;
import '../../features/auth/domain/usecases/set_password_usecase.dart' as _i726;
import '../../features/auth/domain/usecases/verify_email_usecase.dart' as _i30;
import '../../features/auth/presentation/bloc/account_security/account_security_cubit.dart'
    as _i547;
import '../../features/auth/presentation/bloc/auth/auth_bloc.dart' as _i469;
import '../../features/auth/presentation/bloc/create_empresa/create_empresa_cubit.dart'
    as _i716;
import '../../features/auth/presentation/bloc/login/login_cubit.dart' as _i65;
import '../../features/auth/presentation/bloc/register/register_cubit.dart'
    as _i147;
import '../../features/auth/presentation/bloc/verify_email/verify_email_cubit.dart'
    as _i815;
import '../../features/catalogo/data/datasources/catalogo_local_datasource.dart'
    as _i15;
import '../../features/catalogo/data/datasources/catalogo_remote_datasource.dart'
    as _i27;
import '../../features/catalogo/data/datasources/catalogos_remote_datasource.dart'
    as _i444;
import '../../features/catalogo/data/repositories/catalogo_repository_impl.dart'
    as _i780;
import '../../features/catalogo/data/repositories/catalogos_repository_impl.dart'
    as _i22;
import '../../features/catalogo/domain/repositories/catalogo_repository.dart'
    as _i736;
import '../../features/catalogo/domain/repositories/catalogos_repository.dart'
    as _i858;
import '../../features/catalogo/domain/usecases/get_catalogo_preview_usecase.dart'
    as _i75;
import '../../features/catalogo/domain/usecases/get_categorias_empresa_usecase.dart'
    as _i835;
import '../../features/catalogo/domain/usecases/get_categorias_maestras_usecase.dart'
    as _i736;
import '../../features/catalogo/domain/usecases/get_marcas_empresa_usecase.dart'
    as _i1056;
import '../../features/catalogo/domain/usecases/get_marcas_maestras_usecase.dart'
    as _i608;
import '../../features/catalogo/presentation/bloc/catalogo_preview/catalogo_preview_cubit.dart'
    as _i365;
import '../../features/catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart'
    as _i314;
import '../../features/catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart'
    as _i658;
import '../../features/cliente/data/datasources/cliente_remote_datasource.dart'
    as _i189;
import '../../features/cliente/data/repositories/cliente_repository_impl.dart'
    as _i797;
import '../../features/cliente/domain/repositories/cliente_repository.dart'
    as _i37;
import '../../features/cliente/domain/usecases/get_cliente_usecase.dart'
    as _i479;
import '../../features/cliente/domain/usecases/get_clientes_usecase.dart'
    as _i646;
import '../../features/cliente/domain/usecases/registrar_cliente_usecase.dart'
    as _i213;
import '../../features/cliente/presentation/bloc/cliente_form/cliente_form_cubit.dart'
    as _i795;
import '../../features/cliente/presentation/bloc/cliente_list/cliente_list_cubit.dart'
    as _i210;
import '../../features/combo/data/datasources/combo_remote_datasource.dart'
    as _i532;
import '../../features/combo/data/repositories/combo_repository_impl.dart'
    as _i206;
import '../../features/combo/domain/repositories/combo_repository.dart'
    as _i200;
import '../../features/combo/domain/usecases/agregar_componente_usecase.dart'
    as _i237;
import '../../features/combo/domain/usecases/agregar_componentes_batch_usecase.dart'
    as _i378;
import '../../features/combo/domain/usecases/create_combo_usecase.dart' as _i53;
import '../../features/combo/domain/usecases/eliminar_componente_usecase.dart'
    as _i40;
import '../../features/combo/domain/usecases/get_combo_completo_usecase.dart'
    as _i209;
import '../../features/combo/domain/usecases/get_combos_usecase.dart' as _i235;
import '../../features/combo/domain/usecases/get_componentes_usecase.dart'
    as _i330;
import '../../features/combo/presentation/bloc/combo_cubit.dart' as _i1039;
import '../../features/combo/presentation/bloc/producto_selector_cubit.dart'
    as _i466;
import '../../features/descuento/data/datasources/descuento_remote_datasource.dart'
    as _i1036;
import '../../features/descuento/data/repositories/descuento_repository_impl.dart'
    as _i571;
import '../../features/descuento/domain/repositories/descuento_repository.dart'
    as _i605;
import '../../features/descuento/domain/usecases/agregar_familiar.dart'
    as _i147;
import '../../features/descuento/domain/usecases/asignar_categorias.dart'
    as _i269;
import '../../features/descuento/domain/usecases/asignar_productos.dart'
    as _i1012;
import '../../features/descuento/domain/usecases/asignar_usuarios.dart'
    as _i549;
import '../../features/descuento/domain/usecases/calcular_descuento.dart'
    as _i199;
import '../../features/descuento/domain/usecases/create_politica.dart' as _i189;
import '../../features/descuento/domain/usecases/delete_politica.dart' as _i26;
import '../../features/descuento/domain/usecases/get_politica_by_id.dart'
    as _i649;
import '../../features/descuento/domain/usecases/get_politicas_descuento.dart'
    as _i849;
import '../../features/descuento/domain/usecases/obtener_familiares.dart'
    as _i487;
import '../../features/descuento/domain/usecases/obtener_historial_uso.dart'
    as _i145;
import '../../features/descuento/domain/usecases/obtener_usuarios_asignados.dart'
    as _i873;
import '../../features/descuento/domain/usecases/remover_familiar.dart'
    as _i756;
import '../../features/descuento/domain/usecases/remover_usuario.dart' as _i539;
import '../../features/descuento/domain/usecases/update_politica.dart' as _i120;
import '../../features/descuento/presentation/bloc/asignar_productos/asignar_productos_cubit.dart'
    as _i457;
import '../../features/descuento/presentation/bloc/asignar_usuarios/asignar_usuarios_cubit.dart'
    as _i918;
import '../../features/descuento/presentation/bloc/politica_form/politica_form_cubit.dart'
    as _i471;
import '../../features/descuento/presentation/bloc/politica_list/politica_list_cubit.dart'
    as _i900;
import '../../features/empresa/data/datasources/empresa_local_datasource.dart'
    as _i936;
import '../../features/empresa/data/datasources/empresa_remote_datasource.dart'
    as _i278;
import '../../features/empresa/data/repositories/empresa_repository_impl.dart'
    as _i538;
import '../../features/empresa/domain/repositories/empresa_repository.dart'
    as _i544;
import '../../features/empresa/domain/usecases/get_empresa_context_usecase.dart'
    as _i1001;
import '../../features/empresa/domain/usecases/get_personalizacion_usecase.dart'
    as _i717;
import '../../features/empresa/domain/usecases/get_user_empresas_usecase.dart'
    as _i380;
import '../../features/empresa/domain/usecases/switch_empresa_usecase.dart'
    as _i411;
import '../../features/empresa/domain/usecases/update_personalizacion_usecase.dart'
    as _i771;
import '../../features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart'
    as _i135;
import '../../features/producto/data/datasources/configuracion_precio_remote_datasource.dart'
    as _i134;
import '../../features/producto/data/datasources/plantilla_remote_datasource.dart'
    as _i902;
import '../../features/producto/data/datasources/precio_nivel_remote_datasource.dart'
    as _i872;
import '../../features/producto/data/datasources/producto_local_datasource.dart'
    as _i966;
import '../../features/producto/data/datasources/producto_remote_datasource.dart'
    as _i1047;
import '../../features/producto/data/repositories/configuracion_precio_repository_impl.dart'
    as _i185;
import '../../features/producto/data/repositories/plantilla_repository_impl.dart'
    as _i364;
import '../../features/producto/data/repositories/precio_nivel_repository_impl.dart'
    as _i92;
import '../../features/producto/data/repositories/producto_repository_impl.dart'
    as _i469;
import '../../features/producto/domain/repositories/configuracion_precio_repository.dart'
    as _i27;
import '../../features/producto/domain/repositories/plantilla_repository.dart'
    as _i1006;
import '../../features/producto/domain/repositories/precio_nivel_repository.dart'
    as _i640;
import '../../features/producto/domain/repositories/producto_repository.dart'
    as _i398;
import '../../features/producto/domain/usecases/actualizar_producto_usecase.dart'
    as _i604;
import '../../features/producto/domain/usecases/ajuste_masivo_precios_usecase.dart'
    as _i619;
import '../../features/producto/domain/usecases/crear_producto_usecase.dart'
    as _i244;
import '../../features/producto/domain/usecases/eliminar_producto_usecase.dart'
    as _i419;
import '../../features/producto/domain/usecases/get_producto_usecase.dart'
    as _i460;
import '../../features/producto/domain/usecases/get_productos_disponibles_para_combo_usecase.dart'
    as _i787;
import '../../features/producto/domain/usecases/get_productos_usecase.dart'
    as _i202;
import '../../features/producto/presentation/bloc/ajuste_masivo/ajuste_masivo_cubit.dart'
    as _i102;
import '../../features/producto/presentation/bloc/atributo_plantilla/atributo_plantilla_cubit.dart'
    as _i123;
import '../../features/producto/presentation/bloc/configuracion_precio/configuracion_precio_cubit.dart'
    as _i840;
import '../../features/producto/presentation/bloc/precio_nivel/precio_nivel_cubit.dart'
    as _i68;
import '../../features/producto/presentation/bloc/producto_atributo/producto_atributo_cubit.dart'
    as _i935;
import '../../features/producto/presentation/bloc/producto_detail/producto_detail_cubit.dart'
    as _i743;
import '../../features/producto/presentation/bloc/producto_images/producto_images_cubit.dart'
    as _i475;
import '../../features/producto/presentation/bloc/producto_list/producto_list_cubit.dart'
    as _i227;
import '../../features/producto/presentation/bloc/producto_variante/producto_variante_cubit.dart'
    as _i693;
import '../../features/producto/presentation/bloc/variante_atributo/variante_atributo_cubit.dart'
    as _i911;
import '../../features/usuario/data/datasources/usuario_remote_datasource.dart'
    as _i32;
import '../../features/usuario/data/repositories/usuario_repository_impl.dart'
    as _i941;
import '../../features/usuario/domain/repositories/usuario_repository.dart'
    as _i662;
import '../../features/usuario/domain/usecases/get_usuario_usecase.dart'
    as _i1039;
import '../../features/usuario/domain/usecases/get_usuarios_usecase.dart'
    as _i287;
import '../../features/usuario/domain/usecases/registrar_usuario_usecase.dart'
    as _i715;
import '../../features/usuario/presentation/bloc/usuario_form/usuario_form_cubit.dart'
    as _i59;
import '../../features/usuario/presentation/bloc/usuario_list/usuario_list_cubit.dart'
    as _i71;
import '../network/dio_client.dart' as _i667;
import '../network/interceptors/auth_interceptor.dart' as _i745;
import '../network/interceptors/error_interceptor.dart' as _i511;
import '../network/interceptors/refresh_token_interceptor.dart' as _i322;
import '../network/interceptors/sanitized_logging_interceptor.dart' as _i954;
import '../network/network_info.dart' as _i932;
import '../services/error_handler_service.dart' as _i490;
import '../services/logger_service.dart' as _i141;
import '../services/storage_service.dart' as _i306;
import '../storage/local_storage_service.dart' as _i744;
import '../storage/secure_storage_service.dart' as _i666;
import '../storage/storage.dart' as _i321;
import 'register_module.dart' as _i291;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.factory<_i511.ErrorInterceptor>(() => _i511.ErrorInterceptor());
    gh.lazySingleton<_i558.FlutterSecureStorage>(
      () => registerModule.secureStorage,
    );
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i361.Dio>(() => registerModule.dio);
    gh.lazySingleton<_i141.LoggerService>(() => _i141.LoggerService());
    gh.lazySingleton<_i361.Dio>(
      () => registerModule.authDio,
      instanceName: 'authDio',
    );
    gh.lazySingleton<_i666.SecureStorageService>(
      () => _i666.SecureStorageService(gh<_i558.FlutterSecureStorage>()),
    );
    gh.lazySingleton<_i490.ErrorHandlerService>(
      () => _i490.ErrorHandlerService(gh<_i141.LoggerService>()),
    );
    gh.factory<_i322.RefreshTokenInterceptor>(
      () => _i322.RefreshTokenInterceptor(
        gh<_i321.SecureStorageService>(),
        gh<_i361.Dio>(instanceName: 'authDio'),
      ),
    );
    gh.factory<_i954.SanitizedLoggingInterceptor>(
      () => _i954.SanitizedLoggingInterceptor(gh<_i141.LoggerService>()),
    );
    gh.lazySingleton<_i744.LocalStorageService>(
      () => _i744.LocalStorageService(gh<_i460.SharedPreferences>()),
    );
    gh.lazySingleton<_i15.CatalogoLocalDataSource>(
      () => _i15.CatalogoLocalDataSource(gh<_i744.LocalStorageService>()),
    );
    gh.lazySingleton<_i936.EmpresaLocalDataSource>(
      () => _i936.EmpresaLocalDataSource(gh<_i744.LocalStorageService>()),
    );
    gh.lazySingleton<_i966.ProductoLocalDataSource>(
      () => _i966.ProductoLocalDataSource(gh<_i744.LocalStorageService>()),
    );
    gh.lazySingleton<_i932.NetworkInfo>(
      () => _i932.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i992.AuthLocalDataSource>(
      () => _i992.AuthLocalDataSourceImpl(
        gh<_i321.SecureStorageService>(),
        gh<_i321.LocalStorageService>(),
      ),
    );
    gh.factory<_i745.AuthInterceptor>(
      () => _i745.AuthInterceptor(
        gh<_i321.SecureStorageService>(),
        gh<_i321.LocalStorageService>(),
      ),
    );
    gh.factory<_i386.GetLocalUserUseCase>(
      () => _i386.GetLocalUserUseCase(gh<_i992.AuthLocalDataSource>()),
    );
    gh.lazySingleton<_i667.DioClient>(
      () => _i667.DioClient(
        authInterceptor: gh<_i745.AuthInterceptor>(),
        errorInterceptor: gh<_i511.ErrorInterceptor>(),
        refreshTokenInterceptor: gh<_i322.RefreshTokenInterceptor>(),
        sanitizedLoggingInterceptor: gh<_i954.SanitizedLoggingInterceptor>(),
      ),
    );
    gh.lazySingleton<_i444.CatalogosRemoteDataSource>(
      () => _i444.CatalogosRemoteDataSourceImpl(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i858.CatalogosRepository>(
      () => _i22.CatalogosRepositoryImpl(
        remoteDataSource: gh<_i444.CatalogosRemoteDataSource>(),
        networkInfo: gh<_i932.NetworkInfo>(),
        errorHandler: gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i75.GetCatalogoPreviewUseCase>(
      () => _i75.GetCatalogoPreviewUseCase(gh<_i858.CatalogosRepository>()),
    );
    gh.lazySingleton<_i306.StorageService>(
      () => _i306.StorageService(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i27.CatalogoRemoteDataSource>(
      () => _i27.CatalogoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i189.ClienteRemoteDataSource>(
      () => _i189.ClienteRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i532.ComboRemoteDataSource>(
      () => _i532.ComboRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i1036.DescuentoRemoteDataSource>(
      () => _i1036.DescuentoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i278.EmpresaRemoteDataSource>(
      () => _i278.EmpresaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i134.ConfiguracionPrecioRemoteDataSource>(
      () => _i134.ConfiguracionPrecioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i902.PlantillaRemoteDataSource>(
      () => _i902.PlantillaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i872.PrecioNivelRemoteDataSource>(
      () => _i872.PrecioNivelRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i1047.ProductoRemoteDataSource>(
      () => _i1047.ProductoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i32.UsuarioRemoteDataSource>(
      () => _i32.UsuarioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i37.ClienteRepository>(
      () => _i797.ClienteRepositoryImpl(
        gh<_i189.ClienteRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i544.EmpresaRepository>(
      () => _i538.EmpresaRepositoryImpl(
        gh<_i278.EmpresaRemoteDataSource>(),
        gh<_i936.EmpresaLocalDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i479.GetClienteUseCase>(
      () => _i479.GetClienteUseCase(gh<_i37.ClienteRepository>()),
    );
    gh.factory<_i646.GetClientesUseCase>(
      () => _i646.GetClientesUseCase(gh<_i37.ClienteRepository>()),
    );
    gh.factory<_i213.RegistrarClienteUseCase>(
      () => _i213.RegistrarClienteUseCase(gh<_i37.ClienteRepository>()),
    );
    gh.factory<_i210.ClienteListCubit>(
      () => _i210.ClienteListCubit(gh<_i646.GetClientesUseCase>()),
    );
    gh.lazySingleton<_i605.DescuentoRepository>(
      () =>
          _i571.DescuentoRepositoryImpl(gh<_i1036.DescuentoRemoteDataSource>()),
    );
    gh.factory<_i935.ProductoAtributoCubit>(
      () => _i935.ProductoAtributoCubit(gh<_i1047.ProductoRemoteDataSource>()),
    );
    gh.factory<_i693.ProductoVarianteCubit>(
      () => _i693.ProductoVarianteCubit(gh<_i1047.ProductoRemoteDataSource>()),
    );
    gh.factory<_i911.VarianteAtributoCubit>(
      () => _i911.VarianteAtributoCubit(gh<_i1047.ProductoRemoteDataSource>()),
    );
    gh.lazySingleton<_i736.CatalogoRepository>(
      () => _i780.CatalogoRepositoryImpl(
        gh<_i27.CatalogoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i27.ConfiguracionPrecioRepository>(
      () => _i185.ConfiguracionPrecioRepositoryImpl(
        gh<_i134.ConfiguracionPrecioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i795.ClienteFormCubit>(
      () => _i795.ClienteFormCubit(gh<_i213.RegistrarClienteUseCase>()),
    );
    gh.factory<_i475.ProductoImagesCubit>(
      () => _i475.ProductoImagesCubit(gh<_i306.StorageService>()),
    );
    gh.lazySingleton<_i1006.PlantillaRepository>(
      () => _i364.PlantillaRepositoryImpl(
        gh<_i902.PlantillaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i717.GetPersonalizacionUseCase>(
      () => _i717.GetPersonalizacionUseCase(gh<_i544.EmpresaRepository>()),
    );
    gh.factory<_i380.GetUserEmpresasUseCase>(
      () => _i380.GetUserEmpresasUseCase(gh<_i544.EmpresaRepository>()),
    );
    gh.factory<_i771.UpdatePersonalizacionUseCase>(
      () => _i771.UpdatePersonalizacionUseCase(gh<_i544.EmpresaRepository>()),
    );
    gh.lazySingleton<_i1001.GetEmpresaContextUseCase>(
      () => _i1001.GetEmpresaContextUseCase(gh<_i544.EmpresaRepository>()),
    );
    gh.lazySingleton<_i411.SwitchEmpresaUseCase>(
      () => _i411.SwitchEmpresaUseCase(gh<_i544.EmpresaRepository>()),
    );
    gh.lazySingleton<_i662.UsuarioRepository>(
      () => _i941.UsuarioRepositoryImpl(
        gh<_i32.UsuarioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i1039.GetUsuarioUseCase>(
      () => _i1039.GetUsuarioUseCase(gh<_i662.UsuarioRepository>()),
    );
    gh.factory<_i287.GetUsuariosUseCase>(
      () => _i287.GetUsuariosUseCase(gh<_i662.UsuarioRepository>()),
    );
    gh.factory<_i715.RegistrarUsuarioUseCase>(
      () => _i715.RegistrarUsuarioUseCase(gh<_i662.UsuarioRepository>()),
    );
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
      () => _i161.AuthRemoteDataSourceImpl(gh<_i667.DioClient>()),
    );
    gh.factory<_i835.GetCategoriasEmpresaUseCase>(
      () => _i835.GetCategoriasEmpresaUseCase(gh<_i736.CatalogoRepository>()),
    );
    gh.factory<_i736.GetCategoriasMaestrasUseCase>(
      () => _i736.GetCategoriasMaestrasUseCase(gh<_i736.CatalogoRepository>()),
    );
    gh.factory<_i1056.GetMarcasEmpresaUseCase>(
      () => _i1056.GetMarcasEmpresaUseCase(gh<_i736.CatalogoRepository>()),
    );
    gh.factory<_i608.GetMarcasMaestrasUseCase>(
      () => _i608.GetMarcasMaestrasUseCase(gh<_i736.CatalogoRepository>()),
    );
    gh.factory<_i314.CategoriasEmpresaCubit>(
      () =>
          _i314.CategoriasEmpresaCubit(gh<_i835.GetCategoriasEmpresaUseCase>()),
    );
    gh.lazySingleton<_i200.ComboRepository>(
      () => _i206.ComboRepositoryImpl(
        gh<_i532.ComboRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i365.CatalogoPreviewCubit>(
      () => _i365.CatalogoPreviewCubit(
        getCatalogoPreviewUseCase: gh<_i75.GetCatalogoPreviewUseCase>(),
      ),
    );
    gh.lazySingleton<_i398.ProductoRepository>(
      () => _i469.ProductoRepositoryImpl(
        gh<_i1047.ProductoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i640.PrecioNivelRepository>(
      () => _i92.PrecioNivelRepositoryImpl(
        gh<_i872.PrecioNivelRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i135.EmpresaContextCubit>(
      () => _i135.EmpresaContextCubit(
        gh<_i1001.GetEmpresaContextUseCase>(),
        gh<_i744.LocalStorageService>(),
      ),
    );
    gh.factory<_i237.AgregarComponenteUseCase>(
      () => _i237.AgregarComponenteUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i40.EliminarComponenteUseCase>(
      () => _i40.EliminarComponenteUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i209.GetComboCompletoUseCase>(
      () => _i209.GetComboCompletoUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i235.GetCombosUseCase>(
      () => _i235.GetCombosUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i330.GetComponentesUseCase>(
      () => _i330.GetComponentesUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i59.UsuarioFormCubit>(
      () => _i59.UsuarioFormCubit(gh<_i715.RegistrarUsuarioUseCase>()),
    );
    gh.factory<_i147.AgregarFamiliar>(
      () => _i147.AgregarFamiliar(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i269.AsignarCategorias>(
      () => _i269.AsignarCategorias(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i1012.AsignarProductos>(
      () => _i1012.AsignarProductos(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i549.AsignarUsuarios>(
      () => _i549.AsignarUsuarios(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i199.CalcularDescuento>(
      () => _i199.CalcularDescuento(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i189.CreatePolitica>(
      () => _i189.CreatePolitica(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i26.DeletePolitica>(
      () => _i26.DeletePolitica(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i649.GetPoliticaById>(
      () => _i649.GetPoliticaById(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i849.GetPoliticasDescuento>(
      () => _i849.GetPoliticasDescuento(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i487.ObtenerFamiliares>(
      () => _i487.ObtenerFamiliares(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i145.ObtenerHistorialUso>(
      () => _i145.ObtenerHistorialUso(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i873.ObtenerUsuariosAsignados>(
      () => _i873.ObtenerUsuariosAsignados(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i756.RemoverFamiliar>(
      () => _i756.RemoverFamiliar(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i539.RemoverUsuario>(
      () => _i539.RemoverUsuario(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i120.UpdatePolitica>(
      () => _i120.UpdatePolitica(gh<_i605.DescuentoRepository>()),
    );
    gh.factory<_i123.AtributoPlantillaCubit>(
      () => _i123.AtributoPlantillaCubit(gh<_i1006.PlantillaRepository>()),
    );
    gh.factory<_i840.ConfiguracionPrecioCubit>(
      () => _i840.ConfiguracionPrecioCubit(
        gh<_i27.ConfiguracionPrecioRepository>(),
      ),
    );
    gh.factory<_i918.AsignarUsuariosCubit>(
      () => _i918.AsignarUsuariosCubit(
        gh<_i549.AsignarUsuarios>(),
        gh<_i873.ObtenerUsuariosAsignados>(),
      ),
    );
    gh.lazySingleton<_i787.AuthRepository>(
      () => _i153.AuthRepositoryImpl(
        remoteDataSource: gh<_i161.AuthRemoteDataSource>(),
        localDataSource: gh<_i992.AuthLocalDataSource>(),
        networkInfo: gh<_i932.NetworkInfo>(),
        errorHandler: gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i71.UsuarioListCubit>(
      () => _i71.UsuarioListCubit(gh<_i287.GetUsuariosUseCase>()),
    );
    gh.factory<_i658.MarcasEmpresaCubit>(
      () => _i658.MarcasEmpresaCubit(gh<_i1056.GetMarcasEmpresaUseCase>()),
    );
    gh.lazySingleton<_i809.CheckAuthMethodsUseCase>(
      () => _i809.CheckAuthMethodsUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i726.SetPasswordUseCase>(
      () => _i726.SetPasswordUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i471.PoliticaFormCubit>(
      () => _i471.PoliticaFormCubit(
        gh<_i189.CreatePolitica>(),
        gh<_i120.UpdatePolitica>(),
        gh<_i649.GetPoliticaById>(),
      ),
    );
    gh.factory<_i457.AsignarProductosCubit>(
      () => _i457.AsignarProductosCubit(
        gh<_i1012.AsignarProductos>(),
        gh<_i269.AsignarCategorias>(),
      ),
    );
    gh.factory<_i900.PoliticaListCubit>(
      () => _i900.PoliticaListCubit(
        gh<_i849.GetPoliticasDescuento>(),
        gh<_i26.DeletePolitica>(),
      ),
    );
    gh.factory<_i68.PrecioNivelCubit>(
      () => _i68.PrecioNivelCubit(gh<_i640.PrecioNivelRepository>()),
    );
    gh.factory<_i604.ActualizarProductoUseCase>(
      () => _i604.ActualizarProductoUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i619.AjusteMasivoPreciosUseCase>(
      () => _i619.AjusteMasivoPreciosUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i244.CrearProductoUseCase>(
      () => _i244.CrearProductoUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i419.EliminarProductoUseCase>(
      () => _i419.EliminarProductoUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i460.GetProductoUseCase>(
      () => _i460.GetProductoUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i787.GetProductosDisponiblesParaComboUseCase>(
      () => _i787.GetProductosDisponiblesParaComboUseCase(
        gh<_i398.ProductoRepository>(),
      ),
    );
    gh.factory<_i202.GetProductosUseCase>(
      () => _i202.GetProductosUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.lazySingleton<_i378.AgregarComponentesBatchUseCase>(
      () => _i378.AgregarComponentesBatchUseCase(gh<_i200.ComboRepository>()),
    );
    gh.lazySingleton<_i53.CreateComboUseCase>(
      () => _i53.CreateComboUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i227.ProductoListCubit>(
      () => _i227.ProductoListCubit(gh<_i202.GetProductosUseCase>()),
    );
    gh.factory<_i466.ProductoSelectorCubit>(
      () => _i466.ProductoSelectorCubit(
        gh<_i787.GetProductosDisponiblesParaComboUseCase>(),
      ),
    );
    gh.factory<_i788.ChangePasswordUseCase>(
      () => _i788.ChangePasswordUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i52.CheckAuthStatusUseCase>(
      () => _i52.CheckAuthStatusUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i612.CreateEmpresaUseCase>(
      () => _i612.CreateEmpresaUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i560.ForgotPasswordUseCase>(
      () => _i560.ForgotPasswordUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i568.GetProfileUseCase>(
      () => _i568.GetProfileUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i91.GoogleSignInUseCase>(
      () => _i91.GoogleSignInUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i188.LoginUseCase>(
      () => _i188.LoginUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i48.LogoutUseCase>(
      () => _i48.LogoutUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i157.RefreshTokenUseCase>(
      () => _i157.RefreshTokenUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i941.RegisterUseCase>(
      () => _i941.RegisterUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i698.ResendVerificationEmailUseCase>(
      () => _i698.ResendVerificationEmailUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i474.ResetPasswordUseCase>(
      () => _i474.ResetPasswordUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i30.VerifyEmailUseCase>(
      () => _i30.VerifyEmailUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i716.CreateEmpresaCubit>(
      () => _i716.CreateEmpresaCubit(
        createEmpresaUseCase: gh<_i612.CreateEmpresaUseCase>(),
      ),
    );
    gh.factory<_i1039.ComboCubit>(
      () => _i1039.ComboCubit(
        createComboUseCase: gh<_i53.CreateComboUseCase>(),
        getCombos: gh<_i235.GetCombosUseCase>(),
        getComboCompleto: gh<_i209.GetComboCompletoUseCase>(),
        agregarComponente: gh<_i237.AgregarComponenteUseCase>(),
        agregarComponentesBatch: gh<_i378.AgregarComponentesBatchUseCase>(),
        getComponentes: gh<_i330.GetComponentesUseCase>(),
        eliminarComponente: gh<_i40.EliminarComponenteUseCase>(),
      ),
    );
    gh.factory<_i743.ProductoDetailCubit>(
      () => _i743.ProductoDetailCubit(gh<_i460.GetProductoUseCase>()),
    );
    gh.factory<_i102.AjusteMasivoCubit>(
      () => _i102.AjusteMasivoCubit(gh<_i619.AjusteMasivoPreciosUseCase>()),
    );
    gh.factory<_i147.RegisterCubit>(
      () => _i147.RegisterCubit(registerUseCase: gh<_i941.RegisterUseCase>()),
    );
    gh.singleton<_i469.AuthBloc>(
      () => _i469.AuthBloc(
        checkAuthStatus: gh<_i52.CheckAuthStatusUseCase>(),
        getLocalUser: gh<_i386.GetLocalUserUseCase>(),
        logout: gh<_i48.LogoutUseCase>(),
      ),
    );
    gh.factory<_i547.AccountSecurityCubit>(
      () => _i547.AccountSecurityCubit(
        gh<_i809.CheckAuthMethodsUseCase>(),
        gh<_i726.SetPasswordUseCase>(),
        gh<_i469.AuthBloc>(),
      ),
    );
    gh.factory<_i65.LoginCubit>(
      () => _i65.LoginCubit(
        loginUseCase: gh<_i188.LoginUseCase>(),
        googleSignInUseCase: gh<_i91.GoogleSignInUseCase>(),
        checkAuthMethodsUseCase: gh<_i809.CheckAuthMethodsUseCase>(),
      ),
    );
    gh.factory<_i815.VerifyEmailCubit>(
      () => _i815.VerifyEmailCubit(
        verifyEmailUseCase: gh<_i30.VerifyEmailUseCase>(),
      ),
    );
    return this;
  }
}

class _$RegisterModule extends _i291.RegisterModule {}
