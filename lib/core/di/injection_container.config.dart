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

import '../../features/agente_bancario/data/datasources/agente_bancario_remote_datasource.dart'
    as _i350;
import '../../features/agente_bancario/data/repositories/agente_bancario_repository_impl.dart'
    as _i1012;
import '../../features/agente_bancario/domain/repositories/agente_bancario_repository.dart'
    as _i487;
import '../../features/agente_bancario/domain/usecases/crear_agente_usecase.dart'
    as _i1049;
import '../../features/agente_bancario/domain/usecases/get_agentes_usecase.dart'
    as _i246;
import '../../features/agente_bancario/domain/usecases/get_resumen_agentes_usecase.dart'
    as _i803;
import '../../features/agente_bancario/domain/usecases/registrar_operacion_usecase.dart'
    as _i201;
import '../../features/agente_bancario/presentation/bloc/agente_bancario_cubit.dart'
    as _i247;
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
import '../../features/auth/domain/usecases/update_profile_usecase.dart'
    as _i798;
import '../../features/auth/domain/usecases/verify_email_usecase.dart' as _i30;
import '../../features/auth/presentation/bloc/account_security/account_security_cubit.dart'
    as _i547;
import '../../features/auth/presentation/bloc/auth/auth_bloc.dart' as _i469;
import '../../features/auth/presentation/bloc/complete_profile/complete_profile_cubit.dart'
    as _i87;
import '../../features/auth/presentation/bloc/create_empresa/create_empresa_cubit.dart'
    as _i716;
import '../../features/auth/presentation/bloc/login/login_cubit.dart' as _i65;
import '../../features/auth/presentation/bloc/register/register_cubit.dart'
    as _i147;
import '../../features/auth/presentation/bloc/verify_email/verify_email_cubit.dart'
    as _i815;
import '../../features/aviso_mantenimiento/data/datasources/aviso_mantenimiento_remote_datasource.dart'
    as _i129;
import '../../features/aviso_mantenimiento/data/repositories/aviso_mantenimiento_repository_impl.dart'
    as _i651;
import '../../features/aviso_mantenimiento/domain/repositories/aviso_mantenimiento_repository.dart'
    as _i1007;
import '../../features/aviso_mantenimiento/domain/usecases/get_aviso_resumen_usecase.dart'
    as _i727;
import '../../features/aviso_mantenimiento/domain/usecases/get_avisos_usecase.dart'
    as _i801;
import '../../features/aviso_mantenimiento/domain/usecases/get_configuracion_aviso_usecase.dart'
    as _i793;
import '../../features/aviso_mantenimiento/domain/usecases/update_configuracion_aviso_usecase.dart'
    as _i607;
import '../../features/aviso_mantenimiento/domain/usecases/update_estado_aviso_usecase.dart'
    as _i984;
import '../../features/aviso_mantenimiento/presentation/bloc/aviso_configuracion/aviso_configuracion_cubit.dart'
    as _i410;
import '../../features/aviso_mantenimiento/presentation/bloc/aviso_list/aviso_list_cubit.dart'
    as _i96;
import '../../features/caja/data/datasources/caja_remote_datasource.dart'
    as _i840;
import '../../features/caja/data/repositories/caja_repository_impl.dart'
    as _i276;
import '../../features/caja/domain/repositories/caja_repository.dart' as _i742;
import '../../features/caja/domain/usecases/abrir_caja_usecase.dart' as _i600;
import '../../features/caja/domain/usecases/anular_movimiento_usecase.dart'
    as _i750;
import '../../features/caja/domain/usecases/cerrar_caja_usecase.dart' as _i575;
import '../../features/caja/domain/usecases/crear_movimiento_usecase.dart'
    as _i290;
import '../../features/caja/domain/usecases/get_caja_activa_usecase.dart'
    as _i265;
import '../../features/caja/domain/usecases/get_historial_usecase.dart'
    as _i969;
import '../../features/caja/domain/usecases/get_monitor_usecase.dart' as _i519;
import '../../features/caja/domain/usecases/get_movimientos_usecase.dart'
    as _i259;
import '../../features/caja/domain/usecases/get_resumen_usecase.dart' as _i413;
import '../../features/caja/presentation/bloc/caja_activa_cubit.dart' as _i503;
import '../../features/caja/presentation/bloc/caja_historial_cubit.dart'
    as _i849;
import '../../features/caja/presentation/bloc/caja_monitor_cubit.dart' as _i282;
import '../../features/caja/presentation/bloc/caja_movimientos_cubit.dart'
    as _i38;
import '../../features/caja_chica/data/datasources/caja_chica_remote_datasource.dart'
    as _i383;
import '../../features/caja_chica/data/repositories/caja_chica_repository_impl.dart'
    as _i350;
import '../../features/caja_chica/domain/repositories/caja_chica_repository.dart'
    as _i806;
import '../../features/caja_chica/domain/usecases/aprobar_rendicion_usecase.dart'
    as _i505;
import '../../features/caja_chica/domain/usecases/crear_caja_chica_usecase.dart'
    as _i252;
import '../../features/caja_chica/domain/usecases/crear_rendicion_usecase.dart'
    as _i639;
import '../../features/caja_chica/domain/usecases/get_caja_chica_usecase.dart'
    as _i830;
import '../../features/caja_chica/domain/usecases/get_rendicion_usecase.dart'
    as _i1038;
import '../../features/caja_chica/domain/usecases/listar_cajas_chicas_usecase.dart'
    as _i322;
import '../../features/caja_chica/domain/usecases/listar_gastos_usecase.dart'
    as _i63;
import '../../features/caja_chica/domain/usecases/listar_rendiciones_usecase.dart'
    as _i1058;
import '../../features/caja_chica/domain/usecases/rechazar_rendicion_usecase.dart'
    as _i437;
import '../../features/caja_chica/domain/usecases/registrar_gasto_usecase.dart'
    as _i372;
import '../../features/caja_chica/presentation/bloc/caja_chica_detail_cubit.dart'
    as _i990;
import '../../features/caja_chica/presentation/bloc/caja_chica_list_cubit.dart'
    as _i911;
import '../../features/caja_chica/presentation/bloc/gasto_form_cubit.dart'
    as _i455;
import '../../features/caja_chica/presentation/bloc/rendicion_cubit.dart'
    as _i843;
import '../../features/caja_chica/presentation/bloc/rendiciones_list_cubit.dart'
    as _i38;
import '../../features/carrito/data/datasources/carrito_remote_datasource.dart'
    as _i503;
import '../../features/carrito/data/repositories/carrito_repository_impl.dart'
    as _i733;
import '../../features/carrito/domain/repositories/carrito_repository.dart'
    as _i982;
import '../../features/carrito/domain/usecases/actualizar_cantidad_usecase.dart'
    as _i224;
import '../../features/carrito/domain/usecases/agregar_item_usecase.dart'
    as _i81;
import '../../features/carrito/domain/usecases/eliminar_item_usecase.dart'
    as _i883;
import '../../features/carrito/domain/usecases/get_carrito_usecase.dart'
    as _i477;
import '../../features/carrito/domain/usecases/get_contador_usecase.dart'
    as _i689;
import '../../features/carrito/domain/usecases/vaciar_carrito_usecase.dart'
    as _i98;
import '../../features/carrito/presentation/bloc/carrito_cubit.dart' as _i447;
import '../../features/catalogo/data/datasources/catalogo_local_datasource.dart'
    as _i15;
import '../../features/catalogo/data/datasources/catalogo_remote_datasource.dart'
    as _i27;
import '../../features/catalogo/data/datasources/catalogos_remote_datasource.dart'
    as _i444;
import '../../features/catalogo/data/datasources/unidad_medida_remote_datasource.dart'
    as _i791;
import '../../features/catalogo/data/repositories/catalogo_repository_impl.dart'
    as _i780;
import '../../features/catalogo/data/repositories/catalogos_repository_impl.dart'
    as _i22;
import '../../features/catalogo/data/repositories/unidad_medida_repository_impl.dart'
    as _i537;
import '../../features/catalogo/domain/repositories/catalogo_repository.dart'
    as _i736;
import '../../features/catalogo/domain/repositories/catalogos_repository.dart'
    as _i858;
import '../../features/catalogo/domain/repositories/unidad_medida_repository.dart'
    as _i531;
import '../../features/catalogo/domain/usecases/activar_categoria_usecase.dart'
    as _i78;
import '../../features/catalogo/domain/usecases/activar_marca_usecase.dart'
    as _i895;
import '../../features/catalogo/domain/usecases/activar_unidad_usecase.dart'
    as _i446;
import '../../features/catalogo/domain/usecases/activar_unidades_populares_usecase.dart'
    as _i836;
import '../../features/catalogo/domain/usecases/desactivar_categoria_usecase.dart'
    as _i839;
import '../../features/catalogo/domain/usecases/desactivar_marca_usecase.dart'
    as _i405;
import '../../features/catalogo/domain/usecases/desactivar_unidad_usecase.dart'
    as _i229;
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
import '../../features/catalogo/domain/usecases/get_unidades_empresa_usecase.dart'
    as _i853;
import '../../features/catalogo/domain/usecases/get_unidades_maestras_usecase.dart'
    as _i696;
import '../../features/catalogo/presentation/bloc/catalogo_preview/catalogo_preview_cubit.dart'
    as _i365;
import '../../features/catalogo/presentation/bloc/categorias_empresa/categorias_empresa_cubit.dart'
    as _i314;
import '../../features/catalogo/presentation/bloc/categorias_maestras/categorias_maestras_cubit.dart'
    as _i863;
import '../../features/catalogo/presentation/bloc/marcas_empresa/marcas_empresa_cubit.dart'
    as _i658;
import '../../features/catalogo/presentation/bloc/marcas_maestras/marcas_maestras_cubit.dart'
    as _i291;
import '../../features/catalogo/presentation/bloc/unidades_medida/unidades_medida_cubit.dart'
    as _i121;
import '../../features/categoria_gasto/data/datasources/categoria_gasto_remote_datasource.dart'
    as _i1016;
import '../../features/categoria_gasto/data/repositories/categoria_gasto_repository_impl.dart'
    as _i251;
import '../../features/categoria_gasto/domain/repositories/categoria_gasto_repository.dart'
    as _i833;
import '../../features/categoria_gasto/domain/usecases/actualizar_categoria_gasto_usecase.dart'
    as _i295;
import '../../features/categoria_gasto/domain/usecases/crear_categoria_gasto_usecase.dart'
    as _i693;
import '../../features/categoria_gasto/domain/usecases/eliminar_categoria_gasto_usecase.dart'
    as _i750;
import '../../features/categoria_gasto/domain/usecases/get_categorias_gasto_usecase.dart'
    as _i687;
import '../../features/categoria_gasto/presentation/bloc/categoria_gasto_cubit.dart'
    as _i694;
import '../../features/checkout/data/datasources/checkout_remote_datasource.dart'
    as _i26;
import '../../features/checkout/data/repositories/checkout_repository_impl.dart'
    as _i949;
import '../../features/checkout/domain/repositories/checkout_repository.dart'
    as _i498;
import '../../features/checkout/domain/usecases/confirmar_pedido_usecase.dart'
    as _i532;
import '../../features/checkout/domain/usecases/get_opciones_envio_usecase.dart'
    as _i71;
import '../../features/checkout/presentation/bloc/checkout_cubit.dart' as _i848;
import '../../features/cita/data/datasources/cita_remote_datasource.dart'
    as _i224;
import '../../features/cita/data/repositories/cita_repository_impl.dart'
    as _i642;
import '../../features/cita/domain/repositories/cita_repository.dart' as _i20;
import '../../features/cita/presentation/bloc/cita_form/cita_form_cubit.dart'
    as _i1017;
import '../../features/cita/presentation/bloc/cita_list/cita_list_cubit.dart'
    as _i980;
import '../../features/cita/presentation/bloc/disponibilidad/disponibilidad_cubit.dart'
    as _i856;
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
import '../../features/cliente_empresa/data/datasources/cliente_empresa_remote_datasource.dart'
    as _i794;
import '../../features/cliente_empresa/data/repositories/cliente_empresa_repository_impl.dart'
    as _i606;
import '../../features/cliente_empresa/domain/repositories/cliente_empresa_repository.dart'
    as _i212;
import '../../features/combo/data/datasources/combo_remote_datasource.dart'
    as _i532;
import '../../features/combo/data/repositories/combo_repository_impl.dart'
    as _i206;
import '../../features/combo/domain/repositories/combo_repository.dart'
    as _i200;
import '../../features/combo/domain/usecases/actualizar_oferta_combo_usecase.dart'
    as _i370;
import '../../features/combo/domain/usecases/actualizar_precio_combo_usecase.dart'
    as _i1067;
import '../../features/combo/domain/usecases/agregar_componente_usecase.dart'
    as _i237;
import '../../features/combo/domain/usecases/agregar_componentes_batch_usecase.dart'
    as _i378;
import '../../features/combo/domain/usecases/create_combo_usecase.dart' as _i53;
import '../../features/combo/domain/usecases/desactivar_oferta_combo_usecase.dart'
    as _i840;
import '../../features/combo/domain/usecases/eliminar_componente_usecase.dart'
    as _i40;
import '../../features/combo/domain/usecases/eliminar_componentes_batch_usecase.dart'
    as _i619;
import '../../features/combo/domain/usecases/get_combo_completo_usecase.dart'
    as _i209;
import '../../features/combo/domain/usecases/get_combos_usecase.dart' as _i235;
import '../../features/combo/domain/usecases/get_componentes_usecase.dart'
    as _i330;
import '../../features/combo/domain/usecases/get_historial_precios_combo_usecase.dart'
    as _i824;
import '../../features/combo/domain/usecases/get_reservacion_usecase.dart'
    as _i1031;
import '../../features/combo/domain/usecases/liberar_reserva_usecase.dart'
    as _i813;
import '../../features/combo/domain/usecases/reservar_stock_usecase.dart'
    as _i409;
import '../../features/combo/presentation/bloc/combo_cubit.dart' as _i1039;
import '../../features/combo/presentation/bloc/producto_selector_cubit.dart'
    as _i466;
import '../../features/compra/data/datasources/compra_remote_datasource.dart'
    as _i463;
import '../../features/compra/data/repositories/compra_repository_impl.dart'
    as _i544;
import '../../features/compra/domain/repositories/compra_repository.dart'
    as _i19;
import '../../features/compra/domain/usecases/actualizar_orden_compra_usecase.dart'
    as _i895;
import '../../features/compra/domain/usecases/anular_compra_usecase.dart'
    as _i875;
import '../../features/compra/domain/usecases/cambiar_estado_oc_usecase.dart'
    as _i254;
import '../../features/compra/domain/usecases/confirmar_compra_usecase.dart'
    as _i72;
import '../../features/compra/domain/usecases/crear_compra_desde_oc_usecase.dart'
    as _i50;
import '../../features/compra/domain/usecases/crear_compra_usecase.dart'
    as _i526;
import '../../features/compra/domain/usecases/crear_orden_compra_usecase.dart'
    as _i812;
import '../../features/compra/domain/usecases/duplicar_orden_compra_usecase.dart'
    as _i176;
import '../../features/compra/domain/usecases/eliminar_compra_usecase.dart'
    as _i205;
import '../../features/compra/domain/usecases/eliminar_orden_compra_usecase.dart'
    as _i133;
import '../../features/compra/domain/usecases/export_compra_analytics_usecase.dart'
    as _i619;
import '../../features/compra/domain/usecases/get_compra_analytics_usecase.dart'
    as _i914;
import '../../features/compra/domain/usecases/get_compra_usecase.dart' as _i668;
import '../../features/compra/domain/usecases/get_compras_usecase.dart'
    as _i770;
import '../../features/compra/domain/usecases/get_lineas_pendientes_usecase.dart'
    as _i1006;
import '../../features/compra/domain/usecases/get_lotes_proximos_vencer_usecase.dart'
    as _i823;
import '../../features/compra/domain/usecases/get_lotes_usecase.dart' as _i805;
import '../../features/compra/domain/usecases/get_orden_compra_usecase.dart'
    as _i740;
import '../../features/compra/domain/usecases/get_ordenes_compra_usecase.dart'
    as _i217;
import '../../features/compra/domain/usecases/marcar_lotes_vencidos_usecase.dart'
    as _i396;
import '../../features/compra/presentation/bloc/compra_analytics/compra_analytics_cubit.dart'
    as _i427;
import '../../features/compra/presentation/bloc/compra_form/compra_form_cubit.dart'
    as _i999;
import '../../features/compra/presentation/bloc/compra_list/compra_list_cubit.dart'
    as _i654;
import '../../features/compra/presentation/bloc/lote_list/lote_list_cubit.dart'
    as _i906;
import '../../features/compra/presentation/bloc/orden_compra_form/orden_compra_form_cubit.dart'
    as _i1000;
import '../../features/compra/presentation/bloc/orden_compra_list/orden_compra_list_cubit.dart'
    as _i809;
import '../../features/configuracion_codigos/data/datasources/configuracion_codigos_remote_datasource.dart'
    as _i719;
import '../../features/configuracion_codigos/data/repositories/configuracion_codigos_repository_impl.dart'
    as _i960;
import '../../features/configuracion_codigos/domain/repositories/configuracion_codigos_repository.dart'
    as _i248;
import '../../features/configuracion_codigos/domain/usecases/get_configuracion_usecase.dart'
    as _i309;
import '../../features/configuracion_codigos/domain/usecases/preview_codigo_usecase.dart'
    as _i754;
import '../../features/configuracion_codigos/domain/usecases/sincronizar_contador_usecase.dart'
    as _i582;
import '../../features/configuracion_codigos/domain/usecases/update_config_productos_usecase.dart'
    as _i199;
import '../../features/configuracion_codigos/domain/usecases/update_config_servicios_usecase.dart'
    as _i925;
import '../../features/configuracion_codigos/domain/usecases/update_config_variantes_usecase.dart'
    as _i84;
import '../../features/configuracion_codigos/domain/usecases/update_config_ventas_usecase.dart'
    as _i951;
import '../../features/configuracion_codigos/presentation/bloc/configuracion_codigos_cubit.dart'
    as _i1046;
import '../../features/configuracion_documentos/data/datasources/configuracion_documentos_remote_datasource.dart'
    as _i1057;
import '../../features/configuracion_documentos/data/repositories/configuracion_documentos_repository_impl.dart'
    as _i772;
import '../../features/configuracion_documentos/domain/repositories/configuracion_documentos_repository.dart'
    as _i876;
import '../../features/configuracion_documentos/domain/usecases/get_configuracion_completa_usecase.dart'
    as _i930;
import '../../features/configuracion_documentos/domain/usecases/get_configuracion_documentos_usecase.dart'
    as _i448;
import '../../features/configuracion_documentos/domain/usecases/get_plantilla_by_tipo_usecase.dart'
    as _i294;
import '../../features/configuracion_documentos/domain/usecases/get_plantillas_usecase.dart'
    as _i638;
import '../../features/configuracion_documentos/domain/usecases/update_configuracion_documentos_usecase.dart'
    as _i466;
import '../../features/configuracion_documentos/domain/usecases/update_plantilla_usecase.dart'
    as _i715;
import '../../features/configuracion_documentos/presentation/bloc/configuracion_documentos_cubit.dart'
    as _i925;
import '../../features/consultas_externas/data/datasources/consultas_remote_datasource.dart'
    as _i906;
import '../../features/consultas_externas/data/repositories/consultas_repository_impl.dart'
    as _i36;
import '../../features/consultas_externas/domain/repositories/consultas_repository.dart'
    as _i112;
import '../../features/consultas_externas/domain/usecases/consultar_dni_usecase.dart'
    as _i53;
import '../../features/consultas_externas/domain/usecases/consultar_licencia_usecase.dart'
    as _i785;
import '../../features/consultas_externas/domain/usecases/consultar_placa_usecase.dart'
    as _i956;
import '../../features/consultas_externas/domain/usecases/consultar_ruc_usecase.dart'
    as _i633;
import '../../features/consultas_externas/presentation/bloc/consulta_ruc_cubit.dart'
    as _i193;
import '../../features/cotizacion/data/datasources/cotizacion_remote_datasource.dart'
    as _i369;
import '../../features/cotizacion/data/repositories/cotizacion_repository_impl.dart'
    as _i843;
import '../../features/cotizacion/domain/repositories/cotizacion_repository.dart'
    as _i823;
import '../../features/cotizacion/domain/usecases/actualizar_cotizacion_usecase.dart'
    as _i1016;
import '../../features/cotizacion/domain/usecases/cambiar_estado_cotizacion_usecase.dart'
    as _i716;
import '../../features/cotizacion/domain/usecases/crear_cotizacion_usecase.dart'
    as _i343;
import '../../features/cotizacion/domain/usecases/duplicar_cotizacion_usecase.dart'
    as _i499;
import '../../features/cotizacion/domain/usecases/eliminar_cotizacion_usecase.dart'
    as _i965;
import '../../features/cotizacion/domain/usecases/get_cotizacion_usecase.dart'
    as _i813;
import '../../features/cotizacion/domain/usecases/get_cotizaciones_usecase.dart'
    as _i232;
import '../../features/cotizacion/domain/usecases/validar_compatibilidad_cotizacion_usecase.dart'
    as _i76;
import '../../features/cotizacion/presentation/bloc/cotizacion_form/cotizacion_form_cubit.dart'
    as _i298;
import '../../features/cotizacion/presentation/bloc/cotizacion_list/cotizacion_list_cubit.dart'
    as _i9;
import '../../features/cuentas_por_cobrar/data/datasources/cuentas_cobrar_remote_datasource.dart'
    as _i401;
import '../../features/cuentas_por_cobrar/data/repositories/cuentas_cobrar_repository_impl.dart'
    as _i109;
import '../../features/cuentas_por_cobrar/domain/repositories/cuentas_cobrar_repository.dart'
    as _i588;
import '../../features/cuentas_por_cobrar/domain/usecases/get_cuentas_cobrar_usecase.dart'
    as _i853;
import '../../features/cuentas_por_cobrar/domain/usecases/get_resumen_cuentas_cobrar_usecase.dart'
    as _i1042;
import '../../features/cuentas_por_cobrar/presentation/bloc/cuentas_cobrar_cubit.dart'
    as _i232;
import '../../features/cuentas_por_pagar/data/datasources/cuentas_pagar_remote_datasource.dart'
    as _i102;
import '../../features/cuentas_por_pagar/data/repositories/cuentas_pagar_repository_impl.dart'
    as _i17;
import '../../features/cuentas_por_pagar/domain/repositories/cuentas_pagar_repository.dart'
    as _i855;
import '../../features/cuentas_por_pagar/domain/usecases/get_cuentas_pagar_usecase.dart'
    as _i455;
import '../../features/cuentas_por_pagar/domain/usecases/get_resumen_cuentas_pagar_usecase.dart'
    as _i211;
import '../../features/cuentas_por_pagar/presentation/bloc/cuentas_pagar_cubit.dart'
    as _i23;
import '../../features/dashboard_vendedor/data/datasources/dashboard_vendedor_remote_datasource.dart'
    as _i340;
import '../../features/dashboard_vendedor/data/repositories/dashboard_vendedor_repository_impl.dart'
    as _i230;
import '../../features/dashboard_vendedor/domain/repositories/dashboard_vendedor_repository.dart'
    as _i671;
import '../../features/dashboard_vendedor/domain/usecases/get_dashboard_vendedor_usecase.dart'
    as _i355;
import '../../features/dashboard_vendedor/presentation/bloc/dashboard_vendedor_cubit.dart'
    as _i551;
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
import '../../features/devolucion_venta/data/datasources/devolucion_venta_remote_datasource.dart'
    as _i381;
import '../../features/devolucion_venta/data/repositories/devolucion_venta_repository_impl.dart'
    as _i79;
import '../../features/devolucion_venta/domain/repositories/devolucion_venta_repository.dart'
    as _i552;
import '../../features/devolucion_venta/domain/usecases/aprobar_devolucion_usecase.dart'
    as _i234;
import '../../features/devolucion_venta/domain/usecases/crear_devolucion_usecase.dart'
    as _i60;
import '../../features/devolucion_venta/domain/usecases/get_devolucion_usecase.dart'
    as _i489;
import '../../features/devolucion_venta/domain/usecases/get_devoluciones_usecase.dart'
    as _i216;
import '../../features/devolucion_venta/domain/usecases/procesar_devolucion_usecase.dart'
    as _i1045;
import '../../features/devolucion_venta/presentation/bloc/devolucion_form/devolucion_form_cubit.dart'
    as _i867;
import '../../features/devolucion_venta/presentation/bloc/devolucion_list/devolucion_list_cubit.dart'
    as _i712;
import '../../features/direccion/data/datasources/direccion_remote_datasource.dart'
    as _i572;
import '../../features/direccion/data/repositories/direccion_repository_impl.dart'
    as _i866;
import '../../features/direccion/domain/repositories/direccion_repository.dart'
    as _i95;
import '../../features/direccion/presentation/bloc/direccion_list/direccion_list_cubit.dart'
    as _i593;
import '../../features/empresa/data/datasources/empresa_local_datasource.dart'
    as _i936;
import '../../features/empresa/data/datasources/empresa_remote_datasource.dart'
    as _i278;
import '../../features/empresa/data/datasources/plan_suscripcion_remote_datasource.dart'
    as _i1016;
import '../../features/empresa/data/repositories/empresa_repository_impl.dart'
    as _i538;
import '../../features/empresa/data/repositories/plan_suscripcion_repository_impl.dart'
    as _i624;
import '../../features/empresa/domain/repositories/empresa_repository.dart'
    as _i544;
import '../../features/empresa/domain/repositories/plan_suscripcion_repository.dart'
    as _i894;
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
import '../../features/empresa/presentation/bloc/configuracion_empresa/configuracion_empresa_cubit.dart'
    as _i740;
import '../../features/empresa/presentation/bloc/empresa_context/empresa_context_cubit.dart'
    as _i135;
import '../../features/empresa/presentation/bloc/plan_suscripcion/plan_suscripcion_cubit.dart'
    as _i480;
import '../../features/empresa_banco/data/datasources/empresa_banco_remote_datasource.dart'
    as _i634;
import '../../features/empresa_banco/data/repositories/empresa_banco_repository_impl.dart'
    as _i1066;
import '../../features/empresa_banco/domain/repositories/empresa_banco_repository.dart'
    as _i556;
import '../../features/empresa_banco/domain/usecases/actualizar_cuenta_bancaria_usecase.dart'
    as _i595;
import '../../features/empresa_banco/domain/usecases/actualizar_saldo_usecase.dart'
    as _i924;
import '../../features/empresa_banco/domain/usecases/crear_cuenta_bancaria_usecase.dart'
    as _i991;
import '../../features/empresa_banco/domain/usecases/eliminar_cuenta_bancaria_usecase.dart'
    as _i141;
import '../../features/empresa_banco/domain/usecases/get_conciliacion_usecase.dart'
    as _i742;
import '../../features/empresa_banco/domain/usecases/get_cuentas_bancarias_usecase.dart'
    as _i430;
import '../../features/empresa_banco/domain/usecases/marcar_principal_usecase.dart'
    as _i592;
import '../../features/empresa_banco/presentation/bloc/conciliacion_cubit.dart'
    as _i430;
import '../../features/empresa_banco/presentation/bloc/empresa_banco_cubit.dart'
    as _i131;
import '../../features/flujo_proyectado/data/datasources/flujo_proyectado_remote_datasource.dart'
    as _i629;
import '../../features/flujo_proyectado/data/repositories/flujo_proyectado_repository_impl.dart'
    as _i793;
import '../../features/flujo_proyectado/domain/repositories/flujo_proyectado_repository.dart'
    as _i366;
import '../../features/flujo_proyectado/domain/usecases/get_flujo_proyectado_usecase.dart'
    as _i889;
import '../../features/flujo_proyectado/presentation/bloc/flujo_proyectado_cubit.dart'
    as _i1073;
import '../../features/generador_barcode/data/datasources/barcode_remote_datasource.dart'
    as _i15;
import '../../features/generador_barcode/data/repositories/barcode_repository_impl.dart'
    as _i65;
import '../../features/generador_barcode/domain/repositories/barcode_repository.dart'
    as _i362;
import '../../features/generador_barcode/domain/usecases/generar_codigos_usecase.dart'
    as _i1070;
import '../../features/generador_barcode/domain/usecases/get_productos_sin_barcode_usecase.dart'
    as _i769;
import '../../features/generador_barcode/presentation/bloc/barcode_generator_cubit.dart'
    as _i460;
import '../../features/guia_remision/data/datasources/guia_remision_remote_datasource.dart'
    as _i593;
import '../../features/guia_remision/data/repositories/guia_remision_repository_impl.dart'
    as _i508;
import '../../features/guia_remision/domain/repositories/guia_remision_repository.dart'
    as _i108;
import '../../features/guia_remision/domain/usecases/crear_guia_remision_usecase.dart'
    as _i726;
import '../../features/guia_remision/domain/usecases/enviar_guia_remision_usecase.dart'
    as _i605;
import '../../features/guia_remision/domain/usecases/listar_guias_remision_usecase.dart'
    as _i934;
import '../../features/inventario/data/datasources/inventario_remote_datasource.dart'
    as _i319;
import '../../features/inventario/data/repositories/inventario_repository_impl.dart'
    as _i230;
import '../../features/inventario/domain/repositories/inventario_repository.dart'
    as _i173;
import '../../features/inventario/domain/usecases/aplicar_ajustes_usecase.dart'
    as _i791;
import '../../features/inventario/domain/usecases/aprobar_inventario_usecase.dart'
    as _i363;
import '../../features/inventario/domain/usecases/cancelar_inventario_usecase.dart'
    as _i516;
import '../../features/inventario/domain/usecases/crear_inventario_usecase.dart'
    as _i89;
import '../../features/inventario/domain/usecases/finalizar_conteo_usecase.dart'
    as _i809;
import '../../features/inventario/domain/usecases/get_detalle_inventario_usecase.dart'
    as _i433;
import '../../features/inventario/domain/usecases/iniciar_inventario_usecase.dart'
    as _i958;
import '../../features/inventario/domain/usecases/listar_inventarios_usecase.dart'
    as _i132;
import '../../features/inventario/domain/usecases/registrar_conteo_usecase.dart'
    as _i126;
import '../../features/inventario/presentation/bloc/inventario_detail_cubit.dart'
    as _i1070;
import '../../features/inventario/presentation/bloc/inventario_list_cubit.dart'
    as _i965;
import '../../features/libro_contable/data/datasources/libro_contable_remote_datasource.dart'
    as _i301;
import '../../features/libro_contable/data/repositories/libro_contable_repository_impl.dart'
    as _i640;
import '../../features/libro_contable/domain/repositories/libro_contable_repository.dart'
    as _i492;
import '../../features/libro_contable/domain/usecases/get_libro_contable_usecase.dart'
    as _i86;
import '../../features/libro_contable/presentation/bloc/libro_contable_cubit.dart'
    as _i763;
import '../../features/marketplace/data/datasources/marketplace_remote_datasource.dart'
    as _i221;
import '../../features/marketplace/presentation/bloc/marketplace_search_cubit.dart'
    as _i40;
import '../../features/meta_financiera/data/datasources/meta_financiera_remote_datasource.dart'
    as _i256;
import '../../features/meta_financiera/data/repositories/meta_financiera_repository_impl.dart'
    as _i271;
import '../../features/meta_financiera/domain/repositories/meta_financiera_repository.dart'
    as _i678;
import '../../features/meta_financiera/domain/usecases/crear_meta_financiera_usecase.dart'
    as _i615;
import '../../features/meta_financiera/domain/usecases/get_metas_financieras_usecase.dart'
    as _i930;
import '../../features/meta_financiera/presentation/bloc/meta_financiera_cubit.dart'
    as _i333;
import '../../features/mis_pedidos/data/datasources/mis_pedidos_remote_datasource.dart'
    as _i613;
import '../../features/mis_pedidos/data/repositories/mis_pedidos_repository_impl.dart'
    as _i559;
import '../../features/mis_pedidos/domain/repositories/mis_pedidos_repository.dart'
    as _i284;
import '../../features/mis_pedidos/domain/usecases/cancelar_pedido_usecase.dart'
    as _i653;
import '../../features/mis_pedidos/domain/usecases/confirmar_recepcion_usecase.dart'
    as _i591;
import '../../features/mis_pedidos/domain/usecases/get_mis_pedidos_usecase.dart'
    as _i511;
import '../../features/mis_pedidos/domain/usecases/get_pedido_detalle_usecase.dart'
    as _i1020;
import '../../features/mis_pedidos/domain/usecases/subir_comprobante_usecase.dart'
    as _i156;
import '../../features/mis_pedidos/presentation/bloc/mis_pedidos_cubit.dart'
    as _i588;
import '../../features/mis_pedidos/presentation/bloc/pedido_action_cubit.dart'
    as _i485;
import '../../features/monitor_facturacion/data/datasources/monitor_facturacion_remote_datasource.dart'
    as _i448;
import '../../features/monitor_facturacion/data/repositories/monitor_facturacion_repository_impl.dart'
    as _i37;
import '../../features/monitor_facturacion/domain/repositories/monitor_facturacion_repository.dart'
    as _i1026;
import '../../features/monitor_facturacion/domain/usecases/listar_comprobantes_usecase.dart'
    as _i782;
import '../../features/monitor_facturacion/domain/usecases/preview_sincronizacion_usecase.dart'
    as _monfactPrevSync;
import '../../features/monitor_facturacion/domain/usecases/aplicar_sincronizacion_usecase.dart'
    as _monfactApliSync;
import '../../features/configuracion_facturacion/data/datasources/configuracion_facturacion_remote_datasource.dart'
    as _cfgFactDs;
import '../../features/configuracion_facturacion/data/repositories/configuracion_facturacion_repository_impl.dart'
    as _cfgFactRepoImpl;
import '../../features/configuracion_facturacion/domain/repositories/configuracion_facturacion_repository.dart'
    as _cfgFactRepo;
import '../../features/configuracion_facturacion/domain/usecases/get_configuracion_facturacion_usecase.dart'
    as _cfgFactGet;
import '../../features/configuracion_facturacion/domain/usecases/update_configuracion_facturacion_usecase.dart'
    as _cfgFactUpd;
import '../../features/configuracion_facturacion/domain/usecases/probar_conexion_usecase.dart'
    as _cfgFactPrb;
import '../../features/configuracion_facturacion/presentation/bloc/configuracion_facturacion_cubit.dart'
    as _cfgFactCubit;
import '../../features/monitor_productos/data/datasources/monitor_productos_remote_datasource.dart'
    as _i746;
import '../../features/monitor_productos/data/repositories/monitor_productos_repository_impl.dart'
    as _i360;
import '../../features/monitor_productos/domain/repositories/monitor_productos_repository.dart'
    as _i608;
import '../../features/monitor_productos/domain/usecases/bulk_marketplace_usecase.dart'
    as _i513;
import '../../features/monitor_productos/domain/usecases/bulk_precio_igv_usecase.dart'
    as _i1058;
import '../../features/monitor_productos/domain/usecases/bulk_ubicacion_usecase.dart'
    as _i879;
import '../../features/monitor_productos/domain/usecases/get_monitor_productos_usecase.dart'
    as _i644;
import '../../features/monitor_productos/presentation/bloc/monitor_productos_cubit.dart'
    as _i344;
import '../../features/pago_suscripcion/data/datasources/pago_suscripcion_remote_datasource.dart'
    as _i995;
import '../../features/pago_suscripcion/data/repositories/pago_suscripcion_repository_impl.dart'
    as _i366;
import '../../features/pago_suscripcion/domain/repositories/pago_suscripcion_repository.dart'
    as _i656;
import '../../features/pago_suscripcion/domain/usecases/get_mis_pagos_usecase.dart'
    as _i899;
import '../../features/pago_suscripcion/domain/usecases/solicitar_pago_usecase.dart'
    as _i1052;
import '../../features/pago_suscripcion/domain/usecases/subir_comprobante_usecase.dart'
    as _i157;
import '../../features/pago_suscripcion/presentation/bloc/mis_pagos/mis_pagos_cubit.dart'
    as _i90;
import '../../features/pago_suscripcion/presentation/bloc/pago_suscripcion/pago_suscripcion_cubit.dart'
    as _i613;
import '../../features/pedido_marketplace_empresa/data/datasources/pedido_empresa_remote_datasource.dart'
    as _i469;
import '../../features/pedido_marketplace_empresa/data/repositories/pedido_empresa_repository_impl.dart'
    as _i407;
import '../../features/pedido_marketplace_empresa/domain/repositories/pedido_empresa_repository.dart'
    as _i37;
import '../../features/pedido_marketplace_empresa/domain/usecases/cambiar_estado_pedido_usecase.dart'
    as _i80;
import '../../features/pedido_marketplace_empresa/domain/usecases/get_detalle_pedido_empresa_usecase.dart'
    as _i399;
import '../../features/pedido_marketplace_empresa/domain/usecases/get_pedidos_empresa_usecase.dart'
    as _i599;
import '../../features/pedido_marketplace_empresa/domain/usecases/get_resumen_pedidos_usecase.dart'
    as _i986;
import '../../features/pedido_marketplace_empresa/domain/usecases/validar_pago_usecase.dart'
    as _i477;
import '../../features/pedido_marketplace_empresa/presentation/bloc/pedido_empresa_action_cubit.dart'
    as _i928;
import '../../features/pedido_marketplace_empresa/presentation/bloc/pedidos_empresa_cubit.dart'
    as _i520;
import '../../features/pos/data/datasources/pos_remote_datasource.dart'
    as _i449;
import '../../features/pos/data/repositories/pos_repository_impl.dart' as _i84;
import '../../features/pos/domain/repositories/pos_repository.dart' as _i511;
import '../../features/pos/domain/usecases/cargar_datos_cobro_usecase.dart'
    as _i384;
import '../../features/pos/domain/usecases/cobrar_cotizacion_usecase.dart'
    as _i24;
import '../../features/pos/presentation/bloc/cobrar_pos_cubit.dart' as _i60;
import '../../features/pos/presentation/bloc/cola_pos/cola_pos_cubit.dart'
    as _i5;
import '../../features/prestamo/data/datasources/prestamo_remote_datasource.dart'
    as _i283;
import '../../features/prestamo/data/repositories/prestamo_repository_impl.dart'
    as _i392;
import '../../features/prestamo/domain/repositories/prestamo_repository.dart'
    as _i341;
import '../../features/prestamo/domain/usecases/crear_prestamo_usecase.dart'
    as _i494;
import '../../features/prestamo/domain/usecases/get_prestamos_usecase.dart'
    as _i879;
import '../../features/prestamo/domain/usecases/get_resumen_prestamos_usecase.dart'
    as _i179;
import '../../features/prestamo/domain/usecases/registrar_pago_prestamo_usecase.dart'
    as _i1058;
import '../../features/prestamo/presentation/bloc/prestamo_cubit.dart' as _i377;
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
import '../../features/producto/data/datasources/producto_stock_remote_datasource.dart'
    as _i88;
import '../../features/producto/data/datasources/transferencia_stock_remote_datasource.dart'
    as _i815;
import '../../features/producto/data/repositories/configuracion_precio_repository_impl.dart'
    as _i185;
import '../../features/producto/data/repositories/plantilla_repository_impl.dart'
    as _i364;
import '../../features/producto/data/repositories/precio_nivel_repository_impl.dart'
    as _i92;
import '../../features/producto/data/repositories/producto_repository_impl.dart'
    as _i469;
import '../../features/producto/data/repositories/producto_stock_repository_impl.dart'
    as _i714;
import '../../features/producto/data/repositories/transferencia_stock_repository_impl.dart'
    as _i1027;
import '../../features/producto/domain/repositories/configuracion_precio_repository.dart'
    as _i27;
import '../../features/producto/domain/repositories/plantilla_repository.dart'
    as _i1006;
import '../../features/producto/domain/repositories/precio_nivel_repository.dart'
    as _i640;
import '../../features/producto/domain/repositories/producto_repository.dart'
    as _i398;
import '../../features/producto/domain/repositories/producto_stock_repository.dart'
    as _i262;
import '../../features/producto/domain/repositories/transferencia_stock_repository.dart'
    as _i812;
import '../../features/producto/domain/usecases/actualizar_precios_producto_stock_usecase.dart'
    as _i395;
import '../../features/producto/domain/usecases/actualizar_producto_usecase.dart'
    as _i604;
import '../../features/producto/domain/usecases/actualizar_regla_compatibilidad_usecase.dart'
    as _i397;
import '../../features/producto/domain/usecases/ajustar_stock_usecase.dart'
    as _i132;
import '../../features/producto/domain/usecases/ajuste_masivo_precios_usecase.dart'
    as _i619;
import '../../features/producto/domain/usecases/bulk_upload_productos_usecase.dart'
    as _i692;
import '../../features/producto/domain/usecases/crear_incidencia_posterior_usecase.dart'
    as _i374;
import '../../features/producto/domain/usecases/crear_producto_usecase.dart'
    as _i244;
import '../../features/producto/domain/usecases/crear_regla_compatibilidad_usecase.dart'
    as _i435;
import '../../features/producto/domain/usecases/crear_stock_inicial_usecase.dart'
    as _i494;
import '../../features/producto/domain/usecases/crear_transferencia_usecase.dart'
    as _i629;
import '../../features/producto/domain/usecases/crear_transferencias_multiples_usecase.dart'
    as _i831;
import '../../features/producto/domain/usecases/download_bulk_template_usecase.dart'
    as _i570;
import '../../features/producto/domain/usecases/eliminar_producto_usecase.dart'
    as _i419;
import '../../features/producto/domain/usecases/eliminar_regla_compatibilidad_usecase.dart'
    as _i432;
import '../../features/producto/domain/usecases/gestionar_transferencia_usecase.dart'
    as _i917;
import '../../features/producto/domain/usecases/get_alertas_stock_bajo_usecase.dart'
    as _i752;
import '../../features/producto/domain/usecases/get_historial_movimientos_usecase.dart'
    as _i861;
import '../../features/producto/domain/usecases/get_historial_precios_global_usecase.dart'
    as _i530;
import '../../features/producto/domain/usecases/get_producto_usecase.dart'
    as _i460;
import '../../features/producto/domain/usecases/get_productos_disponibles_para_combo_usecase.dart'
    as _i787;
import '../../features/producto/domain/usecases/get_productos_usecase.dart'
    as _i202;
import '../../features/producto/domain/usecases/get_reglas_compatibilidad_usecase.dart'
    as _i403;
import '../../features/producto/domain/usecases/get_stock_por_sede_usecase.dart'
    as _i394;
import '../../features/producto/domain/usecases/get_stock_producto_en_sede_usecase.dart'
    as _i265;
import '../../features/producto/domain/usecases/get_stock_todas_sedes_usecase.dart'
    as _i858;
import '../../features/producto/domain/usecases/get_stock_variante_en_sede_usecase.dart'
    as _i84;
import '../../features/producto/domain/usecases/listar_incidencias_usecase.dart'
    as _i599;
import '../../features/producto/domain/usecases/listar_transferencias_usecase.dart'
    as _i875;
import '../../features/producto/domain/usecases/procesar_completo_transferencia_usecase.dart'
    as _i1062;
import '../../features/producto/domain/usecases/recibir_transferencia_con_incidencias_usecase.dart'
    as _i154;
import '../../features/producto/domain/usecases/resolver_incidencia_usecase.dart'
    as _i1007;
import '../../features/producto/domain/usecases/validar_compatibilidad_usecase.dart'
    as _i709;
import '../../features/producto/presentation/bloc/agregar_stock_inicial/agregar_stock_inicial_cubit.dart'
    as _i873;
import '../../features/producto/presentation/bloc/ajustar_stock/ajustar_stock_cubit.dart'
    as _i1021;
import '../../features/producto/presentation/bloc/ajuste_masivo/ajuste_masivo_cubit.dart'
    as _i102;
import '../../features/producto/presentation/bloc/alertas_stock/alertas_stock_cubit.dart'
    as _i914;
import '../../features/producto/presentation/bloc/atributo_plantilla/atributo_plantilla_cubit.dart'
    as _i123;
import '../../features/producto/presentation/bloc/bulk_upload/bulk_upload_cubit.dart'
    as _i286;
import '../../features/producto/presentation/bloc/compatibilidad/compatibilidad_cubit.dart'
    as _i243;
import '../../features/producto/presentation/bloc/configuracion_precio/configuracion_precio_cubit.dart'
    as _i840;
import '../../features/producto/presentation/bloc/configurar_precios/configurar_precios_cubit.dart'
    as _i303;
import '../../features/producto/presentation/bloc/crear_incidencia_posterior/crear_incidencia_posterior_cubit.dart'
    as _i724;
import '../../features/producto/presentation/bloc/crear_transferencia/crear_transferencia_cubit.dart'
    as _i238;
import '../../features/producto/presentation/bloc/gestionar_transferencia/gestionar_transferencia_cubit.dart'
    as _i773;
import '../../features/producto/presentation/bloc/historial_precios/historial_precios_cubit.dart'
    as _i737;
import '../../features/producto/presentation/bloc/listar_incidencias/listar_incidencias_cubit.dart'
    as _i961;
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
import '../../features/producto/presentation/bloc/producto_search/producto_search_cubit.dart'
    as _i1062;
import '../../features/producto/presentation/bloc/producto_variante/producto_variante_cubit.dart'
    as _i693;
import '../../features/producto/presentation/bloc/recibir_transferencia_incidencias/recibir_transferencia_incidencias_cubit.dart'
    as _i606;
import '../../features/producto/presentation/bloc/resolver_incidencia/resolver_incidencia_cubit.dart'
    as _i279;
import '../../features/producto/presentation/bloc/sede_selection/sede_selection_cubit.dart'
    as _i528;
import '../../features/producto/presentation/bloc/stock_por_sede/stock_por_sede_cubit.dart'
    as _i656;
import '../../features/producto/presentation/bloc/stock_todas_sedes/stock_todas_sedes_cubit.dart'
    as _i449;
import '../../features/producto/presentation/bloc/transferencia_detail/transferencia_detail_cubit.dart'
    as _i328;
import '../../features/producto/presentation/bloc/transferencias_list/transferencias_list_cubit.dart'
    as _i410;
import '../../features/producto/presentation/bloc/variante_atributo/variante_atributo_cubit.dart'
    as _i911;
import '../../features/promocion/data/datasources/promocion_remote_datasource.dart'
    as _i793;
import '../../features/promocion/data/repositories/promocion_repository_impl.dart'
    as _i160;
import '../../features/promocion/domain/repositories/promocion_repository.dart'
    as _i179;
import '../../features/promocion/presentation/bloc/campana_form/campana_form_cubit.dart'
    as _i295;
import '../../features/promocion/presentation/bloc/campana_list/campana_list_cubit.dart'
    as _i399;
import '../../features/proveedor/data/datasources/proveedor_remote_datasource.dart'
    as _i478;
import '../../features/proveedor/data/repositories/proveedor_repository_impl.dart'
    as _i919;
import '../../features/proveedor/domain/repositories/proveedor_repository.dart'
    as _i871;
import '../../features/proveedor/domain/usecases/actualizar_proveedor_usecase.dart'
    as _i57;
import '../../features/proveedor/domain/usecases/crear_proveedor_usecase.dart'
    as _i580;
import '../../features/proveedor/domain/usecases/evaluar_proveedor_usecase.dart'
    as _i40;
import '../../features/proveedor/domain/usecases/get_proveedor_usecase.dart'
    as _i676;
import '../../features/proveedor/domain/usecases/get_proveedores_usecase.dart'
    as _i825;
import '../../features/proveedor/presentation/bloc/proveedor_form/proveedor_form_cubit.dart'
    as _i878;
import '../../features/proveedor/presentation/bloc/proveedor_list/proveedor_list_cubit.dart'
    as _i94;
import '../../features/reporte_incidencia/data/datasources/productos_stock_remote_datasource.dart'
    as _i942;
import '../../features/reporte_incidencia/data/datasources/reporte_incidencia_remote_datasource.dart'
    as _i324;
import '../../features/reporte_incidencia/data/repositories/productos_stock_repository.dart'
    as _i690;
import '../../features/reporte_incidencia/data/repositories/productos_stock_repository_impl.dart'
    as _i733;
import '../../features/reporte_incidencia/data/repositories/reporte_incidencia_repository_impl.dart'
    as _i522;
import '../../features/reporte_incidencia/domain/repositories/reporte_incidencia_repository.dart'
    as _i266;
import '../../features/reporte_incidencia/domain/usecases/actualizar_reporte_usecase.dart'
    as _i1072;
import '../../features/reporte_incidencia/domain/usecases/agregar_item_usecase.dart'
    as _i87;
import '../../features/reporte_incidencia/domain/usecases/aprobar_reporte_usecase.dart'
    as _i153;
import '../../features/reporte_incidencia/domain/usecases/crear_reporte_usecase.dart'
    as _i338;
import '../../features/reporte_incidencia/domain/usecases/eliminar_item_usecase.dart'
    as _i192;
import '../../features/reporte_incidencia/domain/usecases/enviar_para_revision_usecase.dart'
    as _i218;
import '../../features/reporte_incidencia/domain/usecases/get_productos_stock_usecase.dart'
    as _i880;
import '../../features/reporte_incidencia/domain/usecases/listar_reportes_usecase.dart'
    as _i624;
import '../../features/reporte_incidencia/domain/usecases/obtener_reporte_usecase.dart'
    as _i146;
import '../../features/reporte_incidencia/domain/usecases/rechazar_reporte_usecase.dart'
    as _i1020;
import '../../features/reporte_incidencia/domain/usecases/resolver_item_usecase.dart'
    as _i605;
import '../../features/reporte_incidencia/presentation/bloc/agregar_item/agregar_item_cubit.dart'
    as _i835;
import '../../features/reporte_incidencia/presentation/bloc/crear_reporte_incidencia/crear_reporte_incidencia_cubit.dart'
    as _i346;
import '../../features/reporte_incidencia/presentation/bloc/eliminar_item/eliminar_item_cubit.dart'
    as _i413;
import '../../features/reporte_incidencia/presentation/bloc/gestionar_reporte/gestionar_reporte_cubit.dart'
    as _i620;
import '../../features/reporte_incidencia/presentation/bloc/productos_stock_selector/productos_stock_selector_cubit.dart'
    as _i101;
import '../../features/reporte_incidencia/presentation/bloc/reporte_incidencia_detail/reporte_incidencia_detail_cubit.dart'
    as _i829;
import '../../features/reporte_incidencia/presentation/bloc/reportes_incidencia_list/reportes_incidencia_list_cubit.dart'
    as _i648;
import '../../features/reporte_incidencia/presentation/bloc/resolver_item/resolver_item_cubit.dart'
    as _i692;
import '../../features/reporte_incidencia/presentation/bloc/sedes_selector/sedes_selector_cubit.dart'
    as _i169;
import '../../features/resumen_financiero/data/datasources/resumen_financiero_remote_datasource.dart'
    as _i565;
import '../../features/resumen_financiero/data/repositories/resumen_financiero_repository_impl.dart'
    as _i884;
import '../../features/resumen_financiero/domain/repositories/resumen_financiero_repository.dart'
    as _i320;
import '../../features/resumen_financiero/domain/usecases/export_reportes_usecase.dart'
    as _i43;
import '../../features/resumen_financiero/domain/usecases/get_grafico_diario_usecase.dart'
    as _i453;
import '../../features/resumen_financiero/domain/usecases/get_resumen_financiero_usecase.dart'
    as _i116;
import '../../features/resumen_financiero/presentation/bloc/resumen_financiero_cubit.dart'
    as _i570;
import '../../features/rrhh/data/datasources/adelanto_remote_datasource.dart'
    as _i753;
import '../../features/rrhh/data/datasources/asistencia_remote_datasource.dart'
    as _i251;
import '../../features/rrhh/data/datasources/dashboard_rrhh_remote_datasource.dart'
    as _i435;
import '../../features/rrhh/data/datasources/empleado_remote_datasource.dart'
    as _i340;
import '../../features/rrhh/data/datasources/horario_remote_datasource.dart'
    as _i1;
import '../../features/rrhh/data/datasources/incidencia_remote_datasource.dart'
    as _i569;
import '../../features/rrhh/data/datasources/planilla_remote_datasource.dart'
    as _i762;
import '../../features/rrhh/data/datasources/turno_remote_datasource.dart'
    as _i31;
import '../../features/rrhh/data/repositories/adelanto_repository_impl.dart'
    as _i210;
import '../../features/rrhh/data/repositories/asistencia_repository_impl.dart'
    as _i245;
import '../../features/rrhh/data/repositories/dashboard_rrhh_repository_impl.dart'
    as _i50;
import '../../features/rrhh/data/repositories/empleado_repository_impl.dart'
    as _i451;
import '../../features/rrhh/data/repositories/horario_repository_impl.dart'
    as _i472;
import '../../features/rrhh/data/repositories/incidencia_repository_impl.dart'
    as _i102;
import '../../features/rrhh/data/repositories/planilla_repository_impl.dart'
    as _i509;
import '../../features/rrhh/data/repositories/turno_repository_impl.dart'
    as _i1031;
import '../../features/rrhh/domain/repositories/adelanto_repository.dart'
    as _i345;
import '../../features/rrhh/domain/repositories/asistencia_repository.dart'
    as _i301;
import '../../features/rrhh/domain/repositories/dashboard_rrhh_repository.dart'
    as _i766;
import '../../features/rrhh/domain/repositories/empleado_repository.dart'
    as _i12;
import '../../features/rrhh/domain/repositories/horario_repository.dart'
    as _i795;
import '../../features/rrhh/domain/repositories/incidencia_repository.dart'
    as _i288;
import '../../features/rrhh/domain/repositories/planilla_repository.dart'
    as _i382;
import '../../features/rrhh/domain/repositories/turno_repository.dart' as _i303;
import '../../features/rrhh/presentation/bloc/adelanto/adelanto_cubit.dart'
    as _i1047;
import '../../features/rrhh/presentation/bloc/adelanto_list/adelanto_list_cubit.dart'
    as _i604;
import '../../features/rrhh/presentation/bloc/asistencia/asistencia_cubit.dart'
    as _i947;
import '../../features/rrhh/presentation/bloc/asistencia_list/asistencia_list_cubit.dart'
    as _i1015;
import '../../features/rrhh/presentation/bloc/asistencia_resumen/asistencia_resumen_cubit.dart'
    as _i599;
import '../../features/rrhh/presentation/bloc/boleta_detail/boleta_detail_cubit.dart'
    as _i43;
import '../../features/rrhh/presentation/bloc/dashboard_rrhh/dashboard_rrhh_cubit.dart'
    as _i913;
import '../../features/rrhh/presentation/bloc/empleado_detail/empleado_detail_cubit.dart'
    as _i1066;
import '../../features/rrhh/presentation/bloc/empleado_form/empleado_form_cubit.dart'
    as _i230;
import '../../features/rrhh/presentation/bloc/empleado_list/empleado_list_cubit.dart'
    as _i1018;
import '../../features/rrhh/presentation/bloc/horario_list/horario_list_cubit.dart'
    as _i426;
import '../../features/rrhh/presentation/bloc/horario_plantilla/horario_plantilla_cubit.dart'
    as _i305;
import '../../features/rrhh/presentation/bloc/incidencia/incidencia_cubit.dart'
    as _i980;
import '../../features/rrhh/presentation/bloc/incidencia_list/incidencia_list_cubit.dart'
    as _i536;
import '../../features/rrhh/presentation/bloc/planilla/planilla_cubit.dart'
    as _i252;
import '../../features/rrhh/presentation/bloc/planilla_detail/planilla_detail_cubit.dart'
    as _i307;
import '../../features/rrhh/presentation/bloc/planilla_list/planilla_list_cubit.dart'
    as _i800;
import '../../features/rrhh/presentation/bloc/turno_list/turno_list_cubit.dart'
    as _i252;
import '../../features/sede/data/datasources/sede_remote_datasource.dart'
    as _i785;
import '../../features/sede/data/repositories/sede_repository_impl.dart'
    as _i997;
import '../../features/sede/domain/repositories/sede_repository.dart' as _i419;
import '../../features/sede/domain/usecases/create_sede_usecase.dart' as _i1062;
import '../../features/sede/domain/usecases/delete_sede_usecase.dart' as _i746;
import '../../features/sede/domain/usecases/get_sede_by_id_usecase.dart'
    as _i1036;
import '../../features/sede/domain/usecases/get_sedes_usecase.dart' as _i873;
import '../../features/sede/domain/usecases/update_sede_usecase.dart' as _i195;
import '../../features/sede/presentation/bloc/sede_form/sede_form_cubit.dart'
    as _i126;
import '../../features/sede/presentation/bloc/sede_list/sede_list_cubit.dart'
    as _i639;
import '../../features/servicio/data/datasources/componente_remote_datasource.dart'
    as _i964;
import '../../features/servicio/data/datasources/configuracion_campos_remote_datasource.dart'
    as _i411;
import '../../features/servicio/data/datasources/estadisticas_servicio_remote_datasource.dart'
    as _i573;
import '../../features/servicio/data/datasources/orden_servicio_remote_datasource.dart'
    as _i286;
import '../../features/servicio/data/datasources/plantilla_servicio_remote_datasource.dart'
    as _i915;
import '../../features/servicio/data/datasources/servicio_remote_datasource.dart'
    as _i236;
import '../../features/servicio/data/repositories/componente_repository_impl.dart'
    as _i1052;
import '../../features/servicio/data/repositories/configuracion_campos_repository_impl.dart'
    as _i386;
import '../../features/servicio/data/repositories/estadisticas_servicio_repository_impl.dart'
    as _i1049;
import '../../features/servicio/data/repositories/orden_servicio_repository_impl.dart'
    as _i312;
import '../../features/servicio/data/repositories/plantilla_servicio_repository_impl.dart'
    as _i381;
import '../../features/servicio/data/repositories/servicio_repository_impl.dart'
    as _i978;
import '../../features/servicio/domain/repositories/componente_repository.dart'
    as _i150;
import '../../features/servicio/domain/repositories/configuracion_campos_repository.dart'
    as _i271;
import '../../features/servicio/domain/repositories/estadisticas_servicio_repository.dart'
    as _i742;
import '../../features/servicio/domain/repositories/orden_servicio_repository.dart'
    as _i1067;
import '../../features/servicio/domain/repositories/plantilla_servicio_repository.dart'
    as _i198;
import '../../features/servicio/domain/repositories/servicio_repository.dart'
    as _i603;
import '../../features/servicio/domain/usecases/create_configuracion_campo_usecase.dart'
    as _i29;
import '../../features/servicio/domain/usecases/delete_configuracion_campo_usecase.dart'
    as _i866;
import '../../features/servicio/domain/usecases/get_configuracion_campos_usecase.dart'
    as _i676;
import '../../features/servicio/domain/usecases/get_ordenes_servicio_usecase.dart'
    as _i850;
import '../../features/servicio/domain/usecases/get_servicios_usecase.dart'
    as _i123;
import '../../features/servicio/domain/usecases/reorder_configuracion_campos_usecase.dart'
    as _i176;
import '../../features/servicio/domain/usecases/update_configuracion_campo_usecase.dart'
    as _i997;
import '../../features/servicio/presentation/bloc/configuracion_campos/configuracion_campos_cubit.dart'
    as _i258;
import '../../features/servicio/presentation/bloc/dashboard/servicio_dashboard_cubit.dart'
    as _i175;
import '../../features/servicio/presentation/bloc/orden_servicio_list/orden_servicio_list_cubit.dart'
    as _i930;
import '../../features/servicio/presentation/bloc/servicio_list/servicio_list_cubit.dart'
    as _i239;
import '../../features/solicitud_cotizacion/data/datasources/solicitud_cotizacion_remote_datasource.dart'
    as _i126;
import '../../features/solicitud_cotizacion/data/repositories/solicitud_cotizacion_repository_impl.dart'
    as _i161;
import '../../features/solicitud_cotizacion/domain/repositories/solicitud_cotizacion_repository.dart'
    as _i800;
import '../../features/solicitud_cotizacion/domain/usecases/cancelar_solicitud_usecase.dart'
    as _i1010;
import '../../features/solicitud_cotizacion/domain/usecases/crear_solicitud_usecase.dart'
    as _i287;
import '../../features/solicitud_cotizacion/domain/usecases/get_mis_solicitudes_usecase.dart'
    as _i954;
import '../../features/solicitud_cotizacion/domain/usecases/get_solicitud_detalle_usecase.dart'
    as _i430;
import '../../features/solicitud_cotizacion/presentation/bloc/mis_solicitudes_cubit.dart'
    as _i1016;
import '../../features/solicitud_cotizacion/presentation/bloc/solicitud_form_cubit.dart'
    as _i483;
import '../../features/solicitud_cotizacion_empresa/data/datasources/solicitud_empresa_remote_datasource.dart'
    as _i129;
import '../../features/solicitud_cotizacion_empresa/data/repositories/solicitud_empresa_repository_impl.dart'
    as _i307;
import '../../features/solicitud_cotizacion_empresa/domain/repositories/solicitud_empresa_repository.dart'
    as _i462;
import '../../features/solicitud_cotizacion_empresa/domain/usecases/cotizar_solicitud_usecase.dart'
    as _i221;
import '../../features/solicitud_cotizacion_empresa/domain/usecases/get_detalle_solicitud_usecase.dart'
    as _i866;
import '../../features/solicitud_cotizacion_empresa/domain/usecases/get_solicitudes_recibidas_usecase.dart'
    as _i204;
import '../../features/solicitud_cotizacion_empresa/domain/usecases/rechazar_solicitud_usecase.dart'
    as _i420;
import '../../features/solicitud_cotizacion_empresa/presentation/bloc/solicitud_empresa_action_cubit.dart'
    as _i437;
import '../../features/solicitud_cotizacion_empresa/presentation/bloc/solicitudes_recibidas_cubit.dart'
    as _i60;
import '../../features/tercerizacion/data/datasources/tercerizacion_remote_datasource.dart'
    as _i176;
import '../../features/tercerizacion/data/repositories/tercerizacion_repository_impl.dart'
    as _i563;
import '../../features/tercerizacion/domain/repositories/tercerizacion_repository.dart'
    as _i289;
import '../../features/tercerizacion/domain/usecases/buscar_empresas_usecase.dart'
    as _i882;
import '../../features/tercerizacion/domain/usecases/cancelar_tercerizacion_usecase.dart'
    as _i967;
import '../../features/tercerizacion/domain/usecases/completar_tercerizacion_usecase.dart'
    as _i191;
import '../../features/tercerizacion/domain/usecases/crear_tercerizacion_usecase.dart'
    as _i466;
import '../../features/tercerizacion/domain/usecases/get_pendientes_usecase.dart'
    as _i363;
import '../../features/tercerizacion/domain/usecases/get_tercerizacion_usecase.dart'
    as _i453;
import '../../features/tercerizacion/domain/usecases/listar_tercerizaciones_usecase.dart'
    as _i335;
import '../../features/tercerizacion/domain/usecases/responder_tercerizacion_usecase.dart'
    as _i596;
import '../../features/tercerizacion/presentation/bloc/tercerizacion_list/tercerizacion_list_cubit.dart'
    as _i91;
import '../../features/tipo_cambio/data/datasources/tipo_cambio_remote_datasource.dart'
    as _i876;
import '../../features/tipo_cambio/data/repositories/tipo_cambio_repository_impl.dart'
    as _i1009;
import '../../features/tipo_cambio/domain/repositories/tipo_cambio_repository.dart'
    as _i925;
import '../../features/tipo_cambio/domain/usecases/get_configuracion_moneda_usecase.dart'
    as _i77;
import '../../features/tipo_cambio/domain/usecases/get_historial_tipo_cambio_usecase.dart'
    as _i142;
import '../../features/tipo_cambio/domain/usecases/get_tipo_cambio_hoy_usecase.dart'
    as _i15;
import '../../features/tipo_cambio/domain/usecases/registrar_tipo_cambio_manual_usecase.dart'
    as _i509;
import '../../features/tipo_cambio/presentation/bloc/tipo_cambio_cubit.dart'
    as _i629;
import '../../features/ubicacion_almacen/data/datasources/ubicacion_almacen_remote_datasource.dart'
    as _i792;
import '../../features/ubicacion_almacen/presentation/bloc/ubicacion_almacen_cubit.dart'
    as _i935;
import '../../features/usuario/data/datasources/usuario_remote_datasource.dart'
    as _i32;
import '../../features/usuario/data/repositories/usuario_repository_impl.dart'
    as _i941;
import '../../features/usuario/domain/repositories/usuario_repository.dart'
    as _i662;
import '../../features/usuario/domain/usecases/delete_usuario_usecase.dart'
    as _i353;
import '../../features/usuario/domain/usecases/get_usuario_usecase.dart'
    as _i1039;
import '../../features/usuario/domain/usecases/get_usuarios_usecase.dart'
    as _i287;
import '../../features/usuario/domain/usecases/registrar_usuario_usecase.dart'
    as _i715;
import '../../features/usuario/domain/usecases/update_usuario_usecase.dart'
    as _i1054;
import '../../features/usuario/presentation/bloc/usuario_form/usuario_form_cubit.dart'
    as _i59;
import '../../features/usuario/presentation/bloc/usuario_list/usuario_list_cubit.dart'
    as _i71;
import '../../features/venta/data/datasources/venta_remote_datasource.dart'
    as _i526;
import '../../features/venta/data/repositories/venta_repository_impl.dart'
    as _i953;
import '../../features/venta/domain/repositories/venta_repository.dart'
    as _i950;
import '../../features/venta/domain/usecases/actualizar_venta_usecase.dart'
    as _i790;
import '../../features/venta/domain/usecases/anular_venta_usecase.dart'
    as _i701;
import '../../features/venta/domain/usecases/buscar_venta_por_codigo_usecase.dart'
    as _i212;
import '../../features/venta/domain/usecases/confirmar_venta_usecase.dart'
    as _i376;
import '../../features/venta/domain/usecases/crear_venta_desde_cotizacion_usecase.dart'
    as _i624;
import '../../features/venta/domain/usecases/crear_venta_usecase.dart'
    as _i1031;
import '../../features/venta/domain/usecases/crear_y_cobrar_venta_usecase.dart'
    as _i825;
import '../../features/venta/domain/usecases/get_venta_usecase.dart' as _i436;
import '../../features/venta/domain/usecases/get_ventas_usecase.dart' as _i213;
import '../../features/venta/domain/usecases/procesar_pago_usecase.dart'
    as _i459;
import '../../features/venta/presentation/bloc/venta_analytics/venta_analytics_cubit.dart'
    as _i171;
import '../../features/venta/presentation/bloc/venta_form/venta_form_cubit.dart'
    as _i205;
import '../../features/venta/presentation/bloc/venta_list/venta_list_cubit.dart'
    as _i220;
import '../../features/vinculacion/data/datasources/vinculacion_remote_datasource.dart'
    as _i33;
import '../../features/vinculacion/data/repositories/vinculacion_repository_impl.dart'
    as _i953;
import '../../features/vinculacion/domain/repositories/vinculacion_repository.dart'
    as _i604;
import '../../features/vinculacion/domain/usecases/cancelar_vinculacion_usecase.dart'
    as _i1064;
import '../../features/vinculacion/domain/usecases/check_ruc_usecase.dart'
    as _i506;
import '../../features/vinculacion/domain/usecases/crear_vinculacion_usecase.dart'
    as _i649;
import '../../features/vinculacion/domain/usecases/desvincular_usecase.dart'
    as _i667;
import '../../features/vinculacion/domain/usecases/get_pendientes_vinculacion_usecase.dart'
    as _i215;
import '../../features/vinculacion/domain/usecases/listar_vinculaciones_usecase.dart'
    as _i639;
import '../../features/vinculacion/domain/usecases/responder_vinculacion_usecase.dart'
    as _i1053;
import '../../features/vinculacion/presentation/bloc/vinculacion_action/vinculacion_action_cubit.dart'
    as _i894;
import '../../features/vinculacion/presentation/bloc/vinculacion_list/vinculacion_list_cubit.dart'
    as _i1059;
import '../network/dio_client.dart' as _i667;
import '../network/interceptors/auth_interceptor.dart' as _i745;
import '../network/interceptors/error_interceptor.dart' as _i511;
import '../network/interceptors/refresh_token_interceptor.dart' as _i322;
import '../network/interceptors/sanitized_logging_interceptor.dart' as _i954;
import '../network/network_info.dart' as _i932;
import '../services/autorizacion_service.dart' as _i90;
import '../services/error_handler_service.dart' as _i490;
import '../services/export_service.dart' as _i26;
import '../services/logger_service.dart' as _i141;
import '../services/search_history_service.dart' as _i283;
import '../services/sistema_config_service.dart' as _i295;
import '../services/storage_service.dart' as _i306;
import '../storage/local_storage_service.dart' as _i744;
import '../storage/secure_storage_service.dart' as _i666;
import '../storage/storage.dart' as _i321;
import '../widgets/producto_sede_selector/producto_sede_search_cubit.dart'
    as _i13;
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
    gh.factory<_i528.SedeSelectionCubit>(
      () => _i528.SedeSelectionCubit(gh<_i460.SharedPreferences>()),
    );
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
    gh.lazySingleton<_i283.SearchHistoryService>(
      () => _i283.SearchHistoryService(gh<_i744.LocalStorageService>()),
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
    gh.lazySingleton<_i906.ConsultasRemoteDataSource>(
      () => _i906.ConsultasRemoteDataSourceImpl(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i858.CatalogosRepository>(
      () => _i22.CatalogosRepositoryImpl(
        remoteDataSource: gh<_i444.CatalogosRemoteDataSource>(),
        networkInfo: gh<_i932.NetworkInfo>(),
        errorHandler: gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i295.SistemaConfigService>(
      () => _i295.SistemaConfigService(gh<_i667.DioClient>()),
    );
    gh.factory<_i75.GetCatalogoPreviewUseCase>(
      () => _i75.GetCatalogoPreviewUseCase(gh<_i858.CatalogosRepository>()),
    );
    gh.lazySingleton<_i90.AutorizacionService>(
      () => _i90.AutorizacionService(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i26.ExportService>(
      () => _i26.ExportService(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i306.StorageService>(
      () => _i306.StorageService(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i350.AgenteBancarioRemoteDataSource>(
      () => _i350.AgenteBancarioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i129.AvisoMantenimientoRemoteDataSource>(
      () => _i129.AvisoMantenimientoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i840.CajaRemoteDataSource>(
      () => _i840.CajaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i383.CajaChicaRemoteDataSource>(
      () => _i383.CajaChicaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i503.CarritoRemoteDataSource>(
      () => _i503.CarritoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i27.CatalogoRemoteDataSource>(
      () => _i27.CatalogoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i791.UnidadMedidaRemoteDataSource>(
      () => _i791.UnidadMedidaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i1016.CategoriaGastoRemoteDataSource>(
      () => _i1016.CategoriaGastoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i26.CheckoutRemoteDataSource>(
      () => _i26.CheckoutRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i224.CitaRemoteDataSource>(
      () => _i224.CitaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i189.ClienteRemoteDataSource>(
      () => _i189.ClienteRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i794.ClienteEmpresaRemoteDataSource>(
      () => _i794.ClienteEmpresaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i532.ComboRemoteDataSource>(
      () => _i532.ComboRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i463.CompraRemoteDataSource>(
      () => _i463.CompraRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i719.ConfiguracionCodigosRemoteDataSource>(
      () => _i719.ConfiguracionCodigosRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i1057.ConfiguracionDocumentosRemoteDataSource>(
      () =>
          _i1057.ConfiguracionDocumentosRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i369.CotizacionRemoteDataSource>(
      () => _i369.CotizacionRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i401.CuentasCobrarRemoteDataSource>(
      () => _i401.CuentasCobrarRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i102.CuentasPagarRemoteDataSource>(
      () => _i102.CuentasPagarRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i340.DashboardVendedorRemoteDataSource>(
      () => _i340.DashboardVendedorRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i1036.DescuentoRemoteDataSource>(
      () => _i1036.DescuentoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i381.DevolucionVentaRemoteDataSource>(
      () => _i381.DevolucionVentaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i572.DireccionRemoteDataSource>(
      () => _i572.DireccionRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i278.EmpresaRemoteDataSource>(
      () => _i278.EmpresaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i1016.PlanSuscripcionRemoteDataSource>(
      () => _i1016.PlanSuscripcionRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i634.EmpresaBancoRemoteDataSource>(
      () => _i634.EmpresaBancoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i629.FlujoProyectadoRemoteDataSource>(
      () => _i629.FlujoProyectadoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i15.BarcodeRemoteDataSource>(
      () => _i15.BarcodeRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i593.GuiaRemisionRemoteDatasource>(
      () => _i593.GuiaRemisionRemoteDatasource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i319.InventarioRemoteDataSource>(
      () => _i319.InventarioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i301.LibroContableRemoteDataSource>(
      () => _i301.LibroContableRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i221.MarketplaceRemoteDataSource>(
      () => _i221.MarketplaceRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i256.MetaFinancieraRemoteDataSource>(
      () => _i256.MetaFinancieraRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i613.MisPedidosRemoteDataSource>(
      () => _i613.MisPedidosRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i448.MonitorFacturacionRemoteDatasource>(
      () => _i448.MonitorFacturacionRemoteDatasource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i746.MonitorProductosRemoteDataSource>(
      () => _i746.MonitorProductosRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i469.PedidoEmpresaRemoteDataSource>(
      () => _i469.PedidoEmpresaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i449.PosRemoteDataSource>(
      () => _i449.PosRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i283.PrestamoRemoteDataSource>(
      () => _i283.PrestamoRemoteDataSource(gh<_i667.DioClient>()),
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
    gh.lazySingleton<_i88.ProductoStockRemoteDataSource>(
      () => _i88.ProductoStockRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i815.TransferenciaStockRemoteDataSource>(
      () => _i815.TransferenciaStockRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i793.PromocionRemoteDataSource>(
      () => _i793.PromocionRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i478.ProveedorRemoteDataSource>(
      () => _i478.ProveedorRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i324.ReporteIncidenciaRemoteDataSource>(
      () => _i324.ReporteIncidenciaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i565.ResumenFinancieroRemoteDataSource>(
      () => _i565.ResumenFinancieroRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i753.AdelantoRemoteDataSource>(
      () => _i753.AdelantoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i251.AsistenciaRemoteDataSource>(
      () => _i251.AsistenciaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i435.DashboardRrhhRemoteDataSource>(
      () => _i435.DashboardRrhhRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i340.EmpleadoRemoteDataSource>(
      () => _i340.EmpleadoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i1.HorarioRemoteDataSource>(
      () => _i1.HorarioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i569.IncidenciaRemoteDataSource>(
      () => _i569.IncidenciaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i762.PlanillaRemoteDataSource>(
      () => _i762.PlanillaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i31.TurnoRemoteDataSource>(
      () => _i31.TurnoRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i785.SedeRemoteDataSource>(
      () => _i785.SedeRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i964.ComponenteRemoteDataSource>(
      () => _i964.ComponenteRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i411.ConfiguracionCamposRemoteDataSource>(
      () => _i411.ConfiguracionCamposRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i573.EstadisticasServicioRemoteDataSource>(
      () => _i573.EstadisticasServicioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i286.OrdenServicioRemoteDataSource>(
      () => _i286.OrdenServicioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i915.PlantillaServicioRemoteDataSource>(
      () => _i915.PlantillaServicioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i236.ServicioRemoteDataSource>(
      () => _i236.ServicioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i126.SolicitudCotizacionRemoteDataSource>(
      () => _i126.SolicitudCotizacionRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i129.SolicitudEmpresaRemoteDataSource>(
      () => _i129.SolicitudEmpresaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i176.TercerizacionRemoteDataSource>(
      () => _i176.TercerizacionRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i876.TipoCambioRemoteDataSource>(
      () => _i876.TipoCambioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i792.UbicacionAlmacenRemoteDataSource>(
      () => _i792.UbicacionAlmacenRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i32.UsuarioRemoteDataSource>(
      () => _i32.UsuarioRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i526.VentaRemoteDataSource>(
      () => _i526.VentaRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i33.VinculacionRemoteDataSource>(
      () => _i33.VinculacionRemoteDataSource(gh<_i667.DioClient>()),
    );
    gh.factory<_i942.ProductosStockRemoteDatasource>(
      () => _i942.ProductosStockRemoteDatasource(gh<_i667.DioClient>()),
    );
    gh.factory<_i171.VentaAnalyticsCubit>(
      () => _i171.VentaAnalyticsCubit(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i27.ConfiguracionPrecioRepository>(
      () => _i185.ConfiguracionPrecioRepositoryImpl(
        gh<_i134.ConfiguracionPrecioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i419.SedeRepository>(
      () => _i997.SedeRepositoryImpl(
        gh<_i785.SedeRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i833.CategoriaGastoRepository>(
      () => _i251.CategoriaGastoRepositoryImpl(
        gh<_i1016.CategoriaGastoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i840.ConfiguracionPrecioCubit>(
      () => _i840.ConfiguracionPrecioCubit(
        gh<_i27.ConfiguracionPrecioRepository>(),
      ),
    );
    gh.lazySingleton<_i382.PlanillaRepository>(
      () => _i509.PlanillaRepositoryImpl(
        gh<_i762.PlanillaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i95.DireccionRepository>(
      () => _i866.DireccionRepositoryImpl(
        gh<_i572.DireccionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i1062.CreateSedeUseCase>(
      () => _i1062.CreateSedeUseCase(gh<_i419.SedeRepository>()),
    );
    gh.factory<_i746.DeleteSedeUseCase>(
      () => _i746.DeleteSedeUseCase(gh<_i419.SedeRepository>()),
    );
    gh.factory<_i1036.GetSedeByIdUseCase>(
      () => _i1036.GetSedeByIdUseCase(gh<_i419.SedeRepository>()),
    );
    gh.factory<_i873.GetSedesUseCase>(
      () => _i873.GetSedesUseCase(gh<_i419.SedeRepository>()),
    );
    gh.factory<_i195.UpdateSedeUseCase>(
      () => _i195.UpdateSedeUseCase(gh<_i419.SedeRepository>()),
    );
    gh.lazySingleton<_i20.CitaRepository>(
      () => _i642.CitaRepositoryImpl(
        gh<_i224.CitaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i284.MisPedidosRepository>(
      () => _i559.MisPedidosRepositoryImpl(
        gh<_i613.MisPedidosRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i653.CancelarPedidoUseCase>(
      () => _i653.CancelarPedidoUseCase(gh<_i284.MisPedidosRepository>()),
    );
    gh.factory<_i591.ConfirmarRecepcionUseCase>(
      () => _i591.ConfirmarRecepcionUseCase(gh<_i284.MisPedidosRepository>()),
    );
    gh.factory<_i511.GetMisPedidosUseCase>(
      () => _i511.GetMisPedidosUseCase(gh<_i284.MisPedidosRepository>()),
    );
    gh.factory<_i1020.GetPedidoDetalleUseCase>(
      () => _i1020.GetPedidoDetalleUseCase(gh<_i284.MisPedidosRepository>()),
    );
    gh.factory<_i156.SubirComprobanteUseCase>(
      () => _i156.SubirComprobanteUseCase(gh<_i284.MisPedidosRepository>()),
    );
    gh.lazySingleton<_i795.HorarioRepository>(
      () => _i472.HorarioRepositoryImpl(
        gh<_i1.HorarioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
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
    gh.lazySingleton<_i108.GuiaRemisionRepository>(
      () => _i508.GuiaRemisionRepositoryImpl(
        gh<_i593.GuiaRemisionRemoteDatasource>(),
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
    gh.lazySingleton<_i982.CarritoRepository>(
      () => _i733.CarritoRepositoryImpl(
        gh<_i503.CarritoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i855.CuentasPagarRepository>(
      () => _i17.CuentasPagarRepositoryImpl(
        gh<_i102.CuentasPagarRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i248.ConfiguracionCodigosRepository>(
      () => _i960.ConfiguracionCodigosRepositoryImpl(
        gh<_i719.ConfiguracionCodigosRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i362.BarcodeRepository>(
      () => _i65.BarcodeRepositoryImpl(
        gh<_i15.BarcodeRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i639.SedeListCubit>(
      () => _i639.SedeListCubit(
        gh<_i873.GetSedesUseCase>(),
        gh<_i746.DeleteSedeUseCase>(),
      ),
    );
    gh.lazySingleton<_i1026.MonitorFacturacionRepository>(
      () => _i37.MonitorFacturacionRepositoryImpl(
        gh<_i448.MonitorFacturacionRemoteDatasource>(),
      ),
    );
    gh.factory<_i169.SedesSelectorCubit>(
      () => _i169.SedesSelectorCubit(gh<_i873.GetSedesUseCase>()),
    );
    gh.factory<_i588.MisPedidosCubit>(
      () => _i588.MisPedidosCubit(gh<_i511.GetMisPedidosUseCase>()),
    );
    gh.factory<_i210.ClienteListCubit>(
      () => _i210.ClienteListCubit(gh<_i646.GetClientesUseCase>()),
    );
    gh.lazySingleton<_i950.VentaRepository>(
      () => _i953.VentaRepositoryImpl(
        gh<_i526.VentaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i531.UnidadMedidaRepository>(
      () => _i537.UnidadMedidaRepositoryImpl(
        gh<_i791.UnidadMedidaRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i605.DescuentoRepository>(
      () =>
          _i571.DescuentoRepositoryImpl(gh<_i1036.DescuentoRemoteDataSource>()),
    );
    gh.lazySingleton<_i179.PromocionRepository>(
      () => _i160.PromocionRepositoryImpl(
        gh<_i793.PromocionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i511.PosRepository>(
      () => _i84.PosRepositoryImpl(
        gh<_i449.PosRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
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
    gh.lazySingleton<_i995.PagoSuscripcionRemoteDataSource>(
      () => _i995.PagoSuscripcionRemoteDataSourceImpl(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i301.AsistenciaRepository>(
      () => _i245.AsistenciaRepositoryImpl(
        gh<_i251.AsistenciaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i341.PrestamoRepository>(
      () => _i392.PrestamoRepositoryImpl(
        gh<_i283.PrestamoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i126.SedeFormCubit>(
      () => _i126.SedeFormCubit(
        gh<_i1036.GetSedeByIdUseCase>(),
        gh<_i1062.CreateSedeUseCase>(),
        gh<_i195.UpdateSedeUseCase>(),
      ),
    );
    gh.lazySingleton<_i736.CatalogoRepository>(
      () => _i780.CatalogoRepositoryImpl(
        gh<_i27.CatalogoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i876.ConfiguracionDocumentosRepository>(
      () => _i772.ConfiguracionDocumentosRepositoryImpl(
        gh<_i1057.ConfiguracionDocumentosRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i795.ClienteFormCubit>(
      () => _i795.ClienteFormCubit(gh<_i213.RegistrarClienteUseCase>()),
    );
    gh.factory<_i475.ProductoImagesCubit>(
      () => _i475.ProductoImagesCubit(gh<_i306.StorageService>()),
    );
    gh.factory<_i455.GetCuentasPagarUseCase>(
      () => _i455.GetCuentasPagarUseCase(gh<_i855.CuentasPagarRepository>()),
    );
    gh.factory<_i211.GetResumenCuentasPagarUseCase>(
      () => _i211.GetResumenCuentasPagarUseCase(
        gh<_i855.CuentasPagarRepository>(),
      ),
    );
    gh.lazySingleton<_i366.FlujoProyectadoRepository>(
      () => _i793.FlujoProyectadoRepositoryImpl(
        gh<_i629.FlujoProyectadoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i726.CrearGuiaRemisionUseCase>(
      () => _i726.CrearGuiaRemisionUseCase(gh<_i108.GuiaRemisionRepository>()),
    );
    gh.lazySingleton<_i605.EnviarGuiaRemisionUseCase>(
      () => _i605.EnviarGuiaRemisionUseCase(gh<_i108.GuiaRemisionRepository>()),
    );
    gh.lazySingleton<_i934.ListarGuiasRemisionUseCase>(
      () =>
          _i934.ListarGuiasRemisionUseCase(gh<_i108.GuiaRemisionRepository>()),
    );
    gh.lazySingleton<_i671.DashboardVendedorRepository>(
      () => _i230.DashboardVendedorRepositoryImpl(
        gh<_i340.DashboardVendedorRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i40.MarketplaceSearchCubit>(
      () =>
          _i40.MarketplaceSearchCubit(gh<_i221.MarketplaceRemoteDataSource>()),
    );
    gh.lazySingleton<_i800.SolicitudCotizacionRepository>(
      () => _i161.SolicitudCotizacionRepositoryImpl(
        gh<_i126.SolicitudCotizacionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
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
    gh.lazySingleton<_i588.CuentasCobrarRepository>(
      () => _i109.CuentasCobrarRepositoryImpl(
        gh<_i401.CuentasCobrarRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i487.AgenteBancarioRepository>(
      () => _i1012.AgenteBancarioRepositoryImpl(
        gh<_i350.AgenteBancarioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i355.GetDashboardVendedorUseCase>(
      () => _i355.GetDashboardVendedorUseCase(
        gh<_i671.DashboardVendedorRepository>(),
      ),
    );
    gh.factory<_i947.AsistenciaCubit>(
      () => _i947.AsistenciaCubit(gh<_i301.AsistenciaRepository>()),
    );
    gh.factory<_i1015.AsistenciaListCubit>(
      () => _i1015.AsistenciaListCubit(gh<_i301.AsistenciaRepository>()),
    );
    gh.factory<_i599.AsistenciaResumenCubit>(
      () => _i599.AsistenciaResumenCubit(gh<_i301.AsistenciaRepository>()),
    );
    gh.factory<_i690.ProductosStockRepository>(
      () => _i733.ProductosStockRepositoryImpl(
        gh<_i942.ProductosStockRemoteDatasource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i930.GetConfiguracionCompletaUseCase>(
      () => _i930.GetConfiguracionCompletaUseCase(
        gh<_i876.ConfiguracionDocumentosRepository>(),
      ),
    );
    gh.factory<_i448.GetConfiguracionDocumentosUseCase>(
      () => _i448.GetConfiguracionDocumentosUseCase(
        gh<_i876.ConfiguracionDocumentosRepository>(),
      ),
    );
    gh.factory<_i294.GetPlantillaByTipoUseCase>(
      () => _i294.GetPlantillaByTipoUseCase(
        gh<_i876.ConfiguracionDocumentosRepository>(),
      ),
    );
    gh.factory<_i638.GetPlantillasUseCase>(
      () => _i638.GetPlantillasUseCase(
        gh<_i876.ConfiguracionDocumentosRepository>(),
      ),
    );
    gh.factory<_i466.UpdateConfiguracionDocumentosUseCase>(
      () => _i466.UpdateConfiguracionDocumentosUseCase(
        gh<_i876.ConfiguracionDocumentosRepository>(),
      ),
    );
    gh.factory<_i715.UpdatePlantillaUseCase>(
      () => _i715.UpdatePlantillaUseCase(
        gh<_i876.ConfiguracionDocumentosRepository>(),
      ),
    );
    gh.lazySingleton<_i492.LibroContableRepository>(
      () => _i640.LibroContableRepositoryImpl(
        gh<_i301.LibroContableRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i320.ResumenFinancieroRepository>(
      () => _i884.ResumenFinancieroRepositoryImpl(
        gh<_i565.ResumenFinancieroRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i112.ConsultasRepository>(
      () => _i36.ConsultasRepositoryImpl(
        remoteDataSource: gh<_i906.ConsultasRemoteDataSource>(),
        networkInfo: gh<_i932.NetworkInfo>(),
        errorHandler: gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i608.MonitorProductosRepository>(
      () => _i360.MonitorProductosRepositoryImpl(
        gh<_i746.MonitorProductosRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i19.CompraRepository>(
      () => _i544.CompraRepositoryImpl(
        gh<_i463.CompraRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i262.ProductoStockRepository>(
      () => _i714.ProductoStockRepositoryImpl(
        gh<_i88.ProductoStockRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i935.UbicacionAlmacenCubit>(
      () => _i935.UbicacionAlmacenCubit(
        gh<_i792.UbicacionAlmacenRemoteDataSource>(),
      ),
    );
    gh.factory<_i1070.GenerarCodigosUseCase>(
      () => _i1070.GenerarCodigosUseCase(gh<_i362.BarcodeRepository>()),
    );
    gh.factory<_i769.GetProductosSinBarcodeUseCase>(
      () => _i769.GetProductosSinBarcodeUseCase(gh<_i362.BarcodeRepository>()),
    );
    gh.lazySingleton<_i678.MetaFinancieraRepository>(
      () => _i271.MetaFinancieraRepositoryImpl(
        gh<_i256.MetaFinancieraRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i23.CuentasPagarCubit>(
      () => _i23.CuentasPagarCubit(
        gh<_i455.GetCuentasPagarUseCase>(),
        gh<_i211.GetResumenCuentasPagarUseCase>(),
      ),
    );
    gh.lazySingleton<_i345.AdelantoRepository>(
      () => _i210.AdelantoRepositoryImpl(
        gh<_i753.AdelantoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i266.ReporteIncidenciaRepository>(
      () => _i522.ReporteIncidenciaRepositoryImpl(
        gh<_i324.ReporteIncidenciaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i53.ConsultarDniUseCase>(
      () => _i53.ConsultarDniUseCase(gh<_i112.ConsultasRepository>()),
    );
    gh.lazySingleton<_i785.ConsultarLicenciaUseCase>(
      () => _i785.ConsultarLicenciaUseCase(gh<_i112.ConsultasRepository>()),
    );
    gh.lazySingleton<_i956.ConsultarPlacaUseCase>(
      () => _i956.ConsultarPlacaUseCase(gh<_i112.ConsultasRepository>()),
    );
    gh.lazySingleton<_i633.ConsultarRucUseCase>(
      () => _i633.ConsultarRucUseCase(gh<_i112.ConsultasRepository>()),
    );
    gh.factory<_i446.ActivarUnidadUseCase>(
      () => _i446.ActivarUnidadUseCase(gh<_i531.UnidadMedidaRepository>()),
    );
    gh.factory<_i836.ActivarUnidadesPopularesUseCase>(
      () => _i836.ActivarUnidadesPopularesUseCase(
        gh<_i531.UnidadMedidaRepository>(),
      ),
    );
    gh.factory<_i229.DesactivarUnidadUseCase>(
      () => _i229.DesactivarUnidadUseCase(gh<_i531.UnidadMedidaRepository>()),
    );
    gh.factory<_i853.GetUnidadesEmpresaUseCase>(
      () => _i853.GetUnidadesEmpresaUseCase(gh<_i531.UnidadMedidaRepository>()),
    );
    gh.factory<_i696.GetUnidadesMaestrasUseCase>(
      () =>
          _i696.GetUnidadesMaestrasUseCase(gh<_i531.UnidadMedidaRepository>()),
    );
    gh.lazySingleton<_i662.UsuarioRepository>(
      () => _i941.UsuarioRepositoryImpl(
        gh<_i32.UsuarioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i353.DeleteUsuarioUseCase>(
      () => _i353.DeleteUsuarioUseCase(gh<_i662.UsuarioRepository>()),
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
    gh.factory<_i1054.UpdateUsuarioUseCase>(
      () => _i1054.UpdateUsuarioUseCase(gh<_i662.UsuarioRepository>()),
    );
    gh.lazySingleton<_i173.InventarioRepository>(
      () => _i230.InventarioRepositoryImpl(
        gh<_i319.InventarioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i1007.AvisoMantenimientoRepository>(
      () => _i651.AvisoMantenimientoRepositoryImpl(
        gh<_i129.AvisoMantenimientoRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i161.AuthRemoteDataSource>(
      () => _i161.AuthRemoteDataSourceImpl(gh<_i667.DioClient>()),
    );
    gh.lazySingleton<_i462.SolicitudEmpresaRepository>(
      () => _i307.SolicitudEmpresaRepositoryImpl(
        gh<_i129.SolicitudEmpresaRemoteDataSource>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i871.ProveedorRepository>(
      () => _i919.ProveedorRepositoryImpl(
        gh<_i478.ProveedorRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.lazySingleton<_i556.EmpresaBancoRepository>(
      () => _i1066.EmpresaBancoRepositoryImpl(
        gh<_i634.EmpresaBancoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i1006.PlantillaRepository>(
      () => _i364.PlantillaRepositoryImpl(
        gh<_i902.PlantillaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i78.ActivarCategoriaUseCase>(
      () => _i78.ActivarCategoriaUseCase(gh<_i736.CatalogoRepository>()),
    );
    gh.factory<_i895.ActivarMarcaUseCase>(
      () => _i895.ActivarMarcaUseCase(gh<_i736.CatalogoRepository>()),
    );
    gh.factory<_i839.DesactivarCategoriaUseCase>(
      () => _i839.DesactivarCategoriaUseCase(gh<_i736.CatalogoRepository>()),
    );
    gh.factory<_i405.DesactivarMarcaUseCase>(
      () => _i405.DesactivarMarcaUseCase(gh<_i736.CatalogoRepository>()),
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
    gh.lazySingleton<_i812.TransferenciaStockRepository>(
      () => _i1027.TransferenciaStockRepositoryImpl(
        gh<_i815.TransferenciaStockRemoteDataSource>(),
      ),
    );
    gh.lazySingleton<_i603.ServicioRepository>(
      () => _i978.ServicioRepositoryImpl(
        gh<_i236.ServicioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i925.TipoCambioRepository>(
      () => _i1009.TipoCambioRepositoryImpl(
        gh<_i876.TipoCambioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i593.DireccionListCubit>(
      () => _i593.DireccionListCubit(gh<_i95.DireccionRepository>()),
    );
    gh.lazySingleton<_i640.PrecioNivelRepository>(
      () => _i92.PrecioNivelRepositoryImpl(
        gh<_i872.PrecioNivelRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i604.VinculacionRepository>(
      () => _i953.VinculacionRepositoryImpl(
        gh<_i33.VinculacionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i1010.CancelarSolicitudUseCase>(
      () => _i1010.CancelarSolicitudUseCase(
        gh<_i800.SolicitudCotizacionRepository>(),
      ),
    );
    gh.lazySingleton<_i287.CrearSolicitudUseCase>(
      () => _i287.CrearSolicitudUseCase(
        gh<_i800.SolicitudCotizacionRepository>(),
      ),
    );
    gh.lazySingleton<_i954.GetMisSolicitudesUseCase>(
      () => _i954.GetMisSolicitudesUseCase(
        gh<_i800.SolicitudCotizacionRepository>(),
      ),
    );
    gh.lazySingleton<_i430.GetSolicitudDetalleUseCase>(
      () => _i430.GetSolicitudDetalleUseCase(
        gh<_i800.SolicitudCotizacionRepository>(),
      ),
    );
    gh.factory<_i221.CotizarSolicitudUseCase>(
      () =>
          _i221.CotizarSolicitudUseCase(gh<_i462.SolicitudEmpresaRepository>()),
    );
    gh.factory<_i866.GetDetalleSolicitudUseCase>(
      () => _i866.GetDetalleSolicitudUseCase(
        gh<_i462.SolicitudEmpresaRepository>(),
      ),
    );
    gh.factory<_i204.GetSolicitudesRecibidasUseCase>(
      () => _i204.GetSolicitudesRecibidasUseCase(
        gh<_i462.SolicitudEmpresaRepository>(),
      ),
    );
    gh.factory<_i420.RechazarSolicitudUseCase>(
      () => _i420.RechazarSolicitudUseCase(
        gh<_i462.SolicitudEmpresaRepository>(),
      ),
    );
    gh.factory<_i925.ConfiguracionDocumentosCubit>(
      () => _i925.ConfiguracionDocumentosCubit(
        getConfiguracionUseCase: gh<_i448.GetConfiguracionDocumentosUseCase>(),
        updateConfiguracionUseCase:
            gh<_i466.UpdateConfiguracionDocumentosUseCase>(),
        getPlantillasUseCase: gh<_i638.GetPlantillasUseCase>(),
        getPlantillaByTipoUseCase: gh<_i294.GetPlantillaByTipoUseCase>(),
        updatePlantillaUseCase: gh<_i715.UpdatePlantillaUseCase>(),
        getCompletaUseCase: gh<_i930.GetConfiguracionCompletaUseCase>(),
      ),
    );
    gh.lazySingleton<_i12.EmpleadoRepository>(
      () => _i451.EmpleadoRepositoryImpl(
        gh<_i340.EmpleadoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i365.CatalogoPreviewCubit>(
      () => _i365.CatalogoPreviewCubit(
        getCatalogoPreviewUseCase: gh<_i75.GetCatalogoPreviewUseCase>(),
      ),
    );
    gh.factory<_i43.BoletaDetailCubit>(
      () => _i43.BoletaDetailCubit(gh<_i382.PlanillaRepository>()),
    );
    gh.factory<_i252.PlanillaCubit>(
      () => _i252.PlanillaCubit(gh<_i382.PlanillaRepository>()),
    );
    gh.factory<_i307.PlanillaDetailCubit>(
      () => _i307.PlanillaDetailCubit(gh<_i382.PlanillaRepository>()),
    );
    gh.factory<_i800.PlanillaListCubit>(
      () => _i800.PlanillaListCubit(gh<_i382.PlanillaRepository>()),
    );
    gh.lazySingleton<_i498.CheckoutRepository>(
      () => _i949.CheckoutRepositoryImpl(
        gh<_i26.CheckoutRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i271.ConfiguracionCamposRepository>(
      () => _i386.ConfiguracionCamposRepositoryImpl(
        gh<_i411.ConfiguracionCamposRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i395.ActualizarPreciosProductoStockUseCase>(
      () => _i395.ActualizarPreciosProductoStockUseCase(
        gh<_i262.ProductoStockRepository>(),
      ),
    );
    gh.factory<_i132.AjustarStockUseCase>(
      () => _i132.AjustarStockUseCase(gh<_i262.ProductoStockRepository>()),
    );
    gh.factory<_i619.AjusteMasivoPreciosUseCase>(
      () =>
          _i619.AjusteMasivoPreciosUseCase(gh<_i262.ProductoStockRepository>()),
    );
    gh.factory<_i494.CrearStockInicialUseCase>(
      () => _i494.CrearStockInicialUseCase(gh<_i262.ProductoStockRepository>()),
    );
    gh.factory<_i752.GetAlertasStockBajoUseCase>(
      () =>
          _i752.GetAlertasStockBajoUseCase(gh<_i262.ProductoStockRepository>()),
    );
    gh.factory<_i861.GetHistorialMovimientosUseCase>(
      () => _i861.GetHistorialMovimientosUseCase(
        gh<_i262.ProductoStockRepository>(),
      ),
    );
    gh.factory<_i530.GetHistorialPreciosGlobalUseCase>(
      () => _i530.GetHistorialPreciosGlobalUseCase(
        gh<_i262.ProductoStockRepository>(),
      ),
    );
    gh.factory<_i530.ExportHistorialPreciosUseCase>(
      () => _i530.ExportHistorialPreciosUseCase(
        gh<_i262.ProductoStockRepository>(),
      ),
    );
    gh.factory<_i394.GetStockPorSedeUseCase>(
      () => _i394.GetStockPorSedeUseCase(gh<_i262.ProductoStockRepository>()),
    );
    gh.factory<_i265.GetStockProductoEnSedeUseCase>(
      () => _i265.GetStockProductoEnSedeUseCase(
        gh<_i262.ProductoStockRepository>(),
      ),
    );
    gh.factory<_i858.GetStockTodasSedesUseCase>(
      () =>
          _i858.GetStockTodasSedesUseCase(gh<_i262.ProductoStockRepository>()),
    );
    gh.factory<_i84.GetStockVarianteEnSedeUseCase>(
      () => _i84.GetStockVarianteEnSedeUseCase(
        gh<_i262.ProductoStockRepository>(),
      ),
    );
    gh.lazySingleton<_i742.CajaRepository>(
      () => _i276.CajaRepositoryImpl(
        gh<_i840.CajaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i460.BarcodeGeneratorCubit>(
      () => _i460.BarcodeGeneratorCubit(
        gh<_i769.GetProductosSinBarcodeUseCase>(),
        gh<_i1070.GenerarCodigosUseCase>(),
      ),
    );
    gh.factory<_i314.CategoriasEmpresaCubit>(
      () => _i314.CategoriasEmpresaCubit(
        gh<_i835.GetCategoriasEmpresaUseCase>(),
        gh<_i78.ActivarCategoriaUseCase>(),
        gh<_i839.DesactivarCategoriaUseCase>(),
      ),
    );
    gh.lazySingleton<_i552.DevolucionVentaRepository>(
      () => _i79.DevolucionVentaRepositoryImpl(
        gh<_i381.DevolucionVentaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i1049.CrearAgenteUseCase>(
      () => _i1049.CrearAgenteUseCase(gh<_i487.AgenteBancarioRepository>()),
    );
    gh.factory<_i246.GetAgentesUseCase>(
      () => _i246.GetAgentesUseCase(gh<_i487.AgenteBancarioRepository>()),
    );
    gh.factory<_i803.GetResumenAgentesUseCase>(
      () =>
          _i803.GetResumenAgentesUseCase(gh<_i487.AgenteBancarioRepository>()),
    );
    gh.factory<_i201.RegistrarOperacionUseCase>(
      () =>
          _i201.RegistrarOperacionUseCase(gh<_i487.AgenteBancarioRepository>()),
    );
    gh.factory<_i449.StockTodasSedesCubit>(
      () => _i449.StockTodasSedesCubit(gh<_i858.GetStockTodasSedesUseCase>()),
    );
    gh.lazySingleton<_i303.TurnoRepository>(
      () => _i1031.TurnoRepositoryImpl(
        gh<_i31.TurnoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i212.ClienteEmpresaRepository>(
      () => _i606.ClienteEmpresaRepositoryImpl(
        gh<_i794.ClienteEmpresaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i37.PedidoEmpresaRepository>(
      () => _i407.PedidoEmpresaRepositoryImpl(
        gh<_i469.PedidoEmpresaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i656.StockPorSedeCubit>(
      () => _i656.StockPorSedeCubit(gh<_i394.GetStockPorSedeUseCase>()),
    );
    gh.factory<_i295.ActualizarCategoriaGastoUseCase>(
      () => _i295.ActualizarCategoriaGastoUseCase(
        gh<_i833.CategoriaGastoRepository>(),
      ),
    );
    gh.factory<_i693.CrearCategoriaGastoUseCase>(
      () => _i693.CrearCategoriaGastoUseCase(
        gh<_i833.CategoriaGastoRepository>(),
      ),
    );
    gh.factory<_i750.EliminarCategoriaGastoUseCase>(
      () => _i750.EliminarCategoriaGastoUseCase(
        gh<_i833.CategoriaGastoRepository>(),
      ),
    );
    gh.factory<_i687.GetCategoriasGastoUseCase>(
      () =>
          _i687.GetCategoriasGastoUseCase(gh<_i833.CategoriaGastoRepository>()),
    );
    gh.lazySingleton<_i289.TercerizacionRepository>(
      () => _i563.TercerizacionRepositoryImpl(
        gh<_i176.TercerizacionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i398.ProductoRepository>(
      () => _i469.ProductoRepositoryImpl(
        gh<_i1047.ProductoRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i77.GetConfiguracionMonedaUseCase>(
      () =>
          _i77.GetConfiguracionMonedaUseCase(gh<_i925.TipoCambioRepository>()),
    );
    gh.factory<_i142.GetHistorialTipoCambioUseCase>(
      () =>
          _i142.GetHistorialTipoCambioUseCase(gh<_i925.TipoCambioRepository>()),
    );
    gh.factory<_i15.GetTipoCambioHoyUseCase>(
      () => _i15.GetTipoCambioHoyUseCase(gh<_i925.TipoCambioRepository>()),
    );
    gh.factory<_i509.RegistrarTipoCambioManualUseCase>(
      () => _i509.RegistrarTipoCambioManualUseCase(
        gh<_i925.TipoCambioRepository>(),
      ),
    );
    gh.lazySingleton<_i742.EstadisticasServicioRepository>(
      () => _i1049.EstadisticasServicioRepositoryImpl(
        gh<_i573.EstadisticasServicioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i198.PlantillaServicioRepository>(
      () => _i381.PlantillaServicioRepositoryImpl(
        gh<_i915.PlantillaServicioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i57.ActualizarProveedorUseCase>(
      () => _i57.ActualizarProveedorUseCase(gh<_i871.ProveedorRepository>()),
    );
    gh.factory<_i580.CrearProveedorUseCase>(
      () => _i580.CrearProveedorUseCase(gh<_i871.ProveedorRepository>()),
    );
    gh.factory<_i40.EvaluarProveedorUseCase>(
      () => _i40.EvaluarProveedorUseCase(gh<_i871.ProveedorRepository>()),
    );
    gh.factory<_i676.GetProveedorUseCase>(
      () => _i676.GetProveedorUseCase(gh<_i871.ProveedorRepository>()),
    );
    gh.factory<_i825.GetProveedoresUseCase>(
      () => _i825.GetProveedoresUseCase(gh<_i871.ProveedorRepository>()),
    );
    gh.factory<_i658.MarcasEmpresaCubit>(
      () => _i658.MarcasEmpresaCubit(
        gh<_i1056.GetMarcasEmpresaUseCase>(),
        gh<_i895.ActivarMarcaUseCase>(),
        gh<_i405.DesactivarMarcaUseCase>(),
      ),
    );
    gh.lazySingleton<_i823.CotizacionRepository>(
      () => _i843.CotizacionRepositoryImpl(
        gh<_i369.CotizacionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i224.ActualizarCantidadUseCase>(
      () => _i224.ActualizarCantidadUseCase(gh<_i982.CarritoRepository>()),
    );
    gh.factory<_i81.AgregarItemUseCase>(
      () => _i81.AgregarItemUseCase(gh<_i982.CarritoRepository>()),
    );
    gh.factory<_i883.EliminarItemUseCase>(
      () => _i883.EliminarItemUseCase(gh<_i982.CarritoRepository>()),
    );
    gh.factory<_i477.GetCarritoUseCase>(
      () => _i477.GetCarritoUseCase(gh<_i982.CarritoRepository>()),
    );
    gh.factory<_i689.GetContadorUseCase>(
      () => _i689.GetContadorUseCase(gh<_i982.CarritoRepository>()),
    );
    gh.factory<_i98.VaciarCarritoUseCase>(
      () => _i98.VaciarCarritoUseCase(gh<_i982.CarritoRepository>()),
    );
    gh.lazySingleton<_i656.PagoSuscripcionRepository>(
      () => _i366.PagoSuscripcionRepositoryImpl(
        gh<_i995.PagoSuscripcionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i766.DashboardRrhhRepository>(
      () => _i50.DashboardRrhhRepositoryImpl(
        gh<_i435.DashboardRrhhRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i135.EmpresaContextCubit>(
      () => _i135.EmpresaContextCubit(
        gh<_i1001.GetEmpresaContextUseCase>(),
        gh<_i744.LocalStorageService>(),
      ),
    );
    gh.lazySingleton<_i288.IncidenciaRepository>(
      () => _i102.IncidenciaRepositoryImpl(
        gh<_i569.IncidenciaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i150.ComponenteRepository>(
      () => _i1052.ComponenteRepositoryImpl(
        gh<_i964.ComponenteRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i43.ExportLibroContableUseCase>(
      () => _i43.ExportLibroContableUseCase(
        gh<_i320.ResumenFinancieroRepository>(),
      ),
    );
    gh.factory<_i43.ExportCuentasCobrarUseCase>(
      () => _i43.ExportCuentasCobrarUseCase(
        gh<_i320.ResumenFinancieroRepository>(),
      ),
    );
    gh.factory<_i43.ExportCuentasPagarUseCase>(
      () => _i43.ExportCuentasPagarUseCase(
        gh<_i320.ResumenFinancieroRepository>(),
      ),
    );
    gh.factory<_i453.GetGraficoDiarioUseCase>(
      () => _i453.GetGraficoDiarioUseCase(
        gh<_i320.ResumenFinancieroRepository>(),
      ),
    );
    gh.factory<_i116.GetResumenFinancieroUseCase>(
      () => _i116.GetResumenFinancieroUseCase(
        gh<_i320.ResumenFinancieroRepository>(),
      ),
    );
    gh.lazySingleton<_i894.PlanSuscripcionRepository>(
      () => _i624.PlanSuscripcionRepositoryImpl(
        gh<_i1016.PlanSuscripcionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
      ),
    );
    gh.factory<_i1072.ActualizarReporteUsecase>(
      () => _i1072.ActualizarReporteUsecase(
        gh<_i266.ReporteIncidenciaRepository>(),
      ),
    );
    gh.factory<_i87.AgregarItemUsecase>(
      () => _i87.AgregarItemUsecase(gh<_i266.ReporteIncidenciaRepository>()),
    );
    gh.factory<_i153.AprobarReporteUsecase>(
      () =>
          _i153.AprobarReporteUsecase(gh<_i266.ReporteIncidenciaRepository>()),
    );
    gh.factory<_i338.CrearReporteUsecase>(
      () => _i338.CrearReporteUsecase(gh<_i266.ReporteIncidenciaRepository>()),
    );
    gh.factory<_i192.EliminarItemUsecase>(
      () => _i192.EliminarItemUsecase(gh<_i266.ReporteIncidenciaRepository>()),
    );
    gh.factory<_i218.EnviarParaRevisionUsecase>(
      () => _i218.EnviarParaRevisionUsecase(
        gh<_i266.ReporteIncidenciaRepository>(),
      ),
    );
    gh.factory<_i624.ListarReportesUsecase>(
      () =>
          _i624.ListarReportesUsecase(gh<_i266.ReporteIncidenciaRepository>()),
    );
    gh.factory<_i146.ObtenerReporteUsecase>(
      () =>
          _i146.ObtenerReporteUsecase(gh<_i266.ReporteIncidenciaRepository>()),
    );
    gh.factory<_i1020.RechazarReporteUsecase>(
      () => _i1020.RechazarReporteUsecase(
        gh<_i266.ReporteIncidenciaRepository>(),
      ),
    );
    gh.factory<_i605.ResolverItemUsecase>(
      () => _i605.ResolverItemUsecase(gh<_i266.ReporteIncidenciaRepository>()),
    );
    gh.factory<_i1017.CitaFormCubit>(
      () => _i1017.CitaFormCubit(gh<_i20.CitaRepository>()),
    );
    gh.factory<_i980.CitaListCubit>(
      () => _i980.CitaListCubit(gh<_i20.CitaRepository>()),
    );
    gh.factory<_i856.DisponibilidadCubit>(
      () => _i856.DisponibilidadCubit(gh<_i20.CitaRepository>()),
    );
    gh.lazySingleton<_i806.CajaChicaRepository>(
      () => _i350.CajaChicaRepositoryImpl(
        gh<_i383.CajaChicaRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_i1031.CrearVentaUseCase>(
      () => _i1031.CrearVentaUseCase(gh<_i950.VentaRepository>()),
    );
    gh.lazySingleton<_i825.CrearYCobrarVentaUseCase>(
      () => _i825.CrearYCobrarVentaUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i790.ActualizarVentaUseCase>(
      () => _i790.ActualizarVentaUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i701.AnularVentaUseCase>(
      () => _i701.AnularVentaUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i212.BuscarVentaPorCodigoUseCase>(
      () => _i212.BuscarVentaPorCodigoUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i376.ConfirmarVentaUseCase>(
      () => _i376.ConfirmarVentaUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i624.CrearVentaDesdeCotizacionUseCase>(
      () => _i624.CrearVentaDesdeCotizacionUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i436.GetVentaUseCase>(
      () => _i436.GetVentaUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i213.GetVentasUseCase>(
      () => _i213.GetVentasUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i459.ProcesarPagoUseCase>(
      () => _i459.ProcesarPagoUseCase(gh<_i950.VentaRepository>()),
    );
    gh.factory<_i426.HorarioListCubit>(
      () => _i426.HorarioListCubit(gh<_i795.HorarioRepository>()),
    );
    gh.factory<_i305.HorarioPlantillaCubit>(
      () => _i305.HorarioPlantillaCubit(gh<_i795.HorarioRepository>()),
    );
    gh.factory<_i59.UsuarioFormCubit>(
      () => _i59.UsuarioFormCubit(gh<_i715.RegistrarUsuarioUseCase>()),
    );
    gh.lazySingleton<_i200.ComboRepository>(
      () => _i206.ComboRepositoryImpl(
        gh<_i532.ComboRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i889.GetFlujoProyectadoUseCase>(
      () => _i889.GetFlujoProyectadoUseCase(
        gh<_i366.FlujoProyectadoRepository>(),
      ),
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
    gh.factory<_i485.PedidoActionCubit>(
      () => _i485.PedidoActionCubit(
        gh<_i156.SubirComprobanteUseCase>(),
        gh<_i653.CancelarPedidoUseCase>(),
        gh<_i591.ConfirmarRecepcionUseCase>(),
      ),
    );
    gh.lazySingleton<_i1067.OrdenServicioRepository>(
      () => _i312.OrdenServicioRepositoryImpl(
        gh<_i286.OrdenServicioRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.factory<_i86.GetLibroContableUseCase>(
      () => _i86.GetLibroContableUseCase(gh<_i492.LibroContableRepository>()),
    );
    gh.factory<_i71.UsuarioListCubit>(
      () => _i71.UsuarioListCubit(
        gh<_i287.GetUsuariosUseCase>(),
        gh<_i1054.UpdateUsuarioUseCase>(),
        gh<_i353.DeleteUsuarioUseCase>(),
      ),
    );
    gh.factory<_i494.CrearPrestamoUseCase>(
      () => _i494.CrearPrestamoUseCase(gh<_i341.PrestamoRepository>()),
    );
    gh.factory<_i879.GetPrestamosUseCase>(
      () => _i879.GetPrestamosUseCase(gh<_i341.PrestamoRepository>()),
    );
    gh.factory<_i179.GetResumenPrestamosUseCase>(
      () => _i179.GetResumenPrestamosUseCase(gh<_i341.PrestamoRepository>()),
    );
    gh.factory<_i1058.RegistrarPagoPrestamoUseCase>(
      () => _i1058.RegistrarPagoPrestamoUseCase(gh<_i341.PrestamoRepository>()),
    );
    gh.factory<_i123.AtributoPlantillaCubit>(
      () => _i123.AtributoPlantillaCubit(gh<_i1006.PlantillaRepository>()),
    );
    gh.factory<_i551.DashboardVendedorCubit>(
      () =>
          _i551.DashboardVendedorCubit(gh<_i355.GetDashboardVendedorUseCase>()),
    );
    gh.factory<_i882.BuscarEmpresasUseCase>(
      () => _i882.BuscarEmpresasUseCase(gh<_i289.TercerizacionRepository>()),
    );
    gh.factory<_i967.CancelarTercerizacionUseCase>(
      () => _i967.CancelarTercerizacionUseCase(
        gh<_i289.TercerizacionRepository>(),
      ),
    );
    gh.factory<_i191.CompletarTercerizacionUseCase>(
      () => _i191.CompletarTercerizacionUseCase(
        gh<_i289.TercerizacionRepository>(),
      ),
    );
    gh.factory<_i466.CrearTercerizacionUseCase>(
      () =>
          _i466.CrearTercerizacionUseCase(gh<_i289.TercerizacionRepository>()),
    );
    gh.factory<_i363.GetPendientesUseCase>(
      () => _i363.GetPendientesUseCase(gh<_i289.TercerizacionRepository>()),
    );
    gh.factory<_i453.GetTercerizacionUseCase>(
      () => _i453.GetTercerizacionUseCase(gh<_i289.TercerizacionRepository>()),
    );
    gh.factory<_i335.ListarTercerizacionesUseCase>(
      () => _i335.ListarTercerizacionesUseCase(
        gh<_i289.TercerizacionRepository>(),
      ),
    );
    gh.factory<_i596.ResponderTercerizacionUseCase>(
      () => _i596.ResponderTercerizacionUseCase(
        gh<_i289.TercerizacionRepository>(),
      ),
    );
    gh.factory<_i895.ActualizarOrdenCompraUseCase>(
      () => _i895.ActualizarOrdenCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i875.AnularCompraUseCase>(
      () => _i875.AnularCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i254.CambiarEstadoOcUseCase>(
      () => _i254.CambiarEstadoOcUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i72.ConfirmarCompraUseCase>(
      () => _i72.ConfirmarCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i50.CrearCompraDesdeOcUseCase>(
      () => _i50.CrearCompraDesdeOcUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i526.CrearCompraUseCase>(
      () => _i526.CrearCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i812.CrearOrdenCompraUseCase>(
      () => _i812.CrearOrdenCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i176.DuplicarOrdenCompraUseCase>(
      () => _i176.DuplicarOrdenCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i205.EliminarCompraUseCase>(
      () => _i205.EliminarCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i133.EliminarOrdenCompraUseCase>(
      () => _i133.EliminarOrdenCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i619.ExportComprasPorProductoUseCase>(
      () => _i619.ExportComprasPorProductoUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i619.ExportComprasPorProveedorUseCase>(
      () => _i619.ExportComprasPorProveedorUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i914.GetCompraAnalyticsUseCase>(
      () => _i914.GetCompraAnalyticsUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i668.GetCompraUseCase>(
      () => _i668.GetCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i770.GetComprasUseCase>(
      () => _i770.GetComprasUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i1006.GetLineasPendientesUseCase>(
      () => _i1006.GetLineasPendientesUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i823.GetLotesProximosVencerUseCase>(
      () => _i823.GetLotesProximosVencerUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i805.GetLotesUseCase>(
      () => _i805.GetLotesUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i740.GetOrdenCompraUseCase>(
      () => _i740.GetOrdenCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i217.GetOrdenesCompraUseCase>(
      () => _i217.GetOrdenesCompraUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i396.MarcarLotesVencidosUseCase>(
      () => _i396.MarcarLotesVencidosUseCase(gh<_i19.CompraRepository>()),
    );
    gh.factory<_i102.AjusteMasivoCubit>(
      () => _i102.AjusteMasivoCubit(gh<_i619.AjusteMasivoPreciosUseCase>()),
    );
    gh.factory<_i1073.FlujoProyectadoCubit>(
      () => _i1073.FlujoProyectadoCubit(gh<_i889.GetFlujoProyectadoUseCase>()),
    );
    gh.factory<_i29.CreateConfiguracionCampoUseCase>(
      () => _i29.CreateConfiguracionCampoUseCase(
        gh<_i271.ConfiguracionCamposRepository>(),
      ),
    );
    gh.factory<_i866.DeleteConfiguracionCampoUseCase>(
      () => _i866.DeleteConfiguracionCampoUseCase(
        gh<_i271.ConfiguracionCamposRepository>(),
      ),
    );
    gh.factory<_i676.GetConfiguracionCamposUseCase>(
      () => _i676.GetConfiguracionCamposUseCase(
        gh<_i271.ConfiguracionCamposRepository>(),
      ),
    );
    gh.factory<_i176.ReorderConfiguracionCamposUseCase>(
      () => _i176.ReorderConfiguracionCamposUseCase(
        gh<_i271.ConfiguracionCamposRepository>(),
      ),
    );
    gh.factory<_i997.UpdateConfiguracionCampoUseCase>(
      () => _i997.UpdateConfiguracionCampoUseCase(
        gh<_i271.ConfiguracionCamposRepository>(),
      ),
    );
    gh.factory<_i513.BulkMarketplaceUseCase>(
      () =>
          _i513.BulkMarketplaceUseCase(gh<_i608.MonitorProductosRepository>()),
    );
    gh.factory<_i1058.BulkPrecioIgvUseCase>(
      () => _i1058.BulkPrecioIgvUseCase(gh<_i608.MonitorProductosRepository>()),
    );
    gh.factory<_i879.BulkUbicacionUseCase>(
      () => _i879.BulkUbicacionUseCase(gh<_i608.MonitorProductosRepository>()),
    );
    gh.factory<_i644.GetMonitorProductosUseCase>(
      () => _i644.GetMonitorProductosUseCase(
        gh<_i608.MonitorProductosRepository>(),
      ),
    );
    gh.factory<_i570.ResumenFinancieroCubit>(
      () => _i570.ResumenFinancieroCubit(
        gh<_i116.GetResumenFinancieroUseCase>(),
        gh<_i453.GetGraficoDiarioUseCase>(),
      ),
    );
    gh.factory<_i740.ConfiguracionEmpresaCubit>(
      () => _i740.ConfiguracionEmpresaCubit(gh<_i544.EmpresaRepository>()),
    );
    gh.factory<_i853.GetCuentasCobrarUseCase>(
      () => _i853.GetCuentasCobrarUseCase(gh<_i588.CuentasCobrarRepository>()),
    );
    gh.factory<_i1042.GetResumenCuentasCobrarUseCase>(
      () => _i1042.GetResumenCuentasCobrarUseCase(
        gh<_i588.CuentasCobrarRepository>(),
      ),
    );
    gh.factory<_i648.ReportesIncidenciaListCubit>(
      () =>
          _i648.ReportesIncidenciaListCubit(gh<_i624.ListarReportesUsecase>()),
    );
    gh.factory<_i384.CargarDatosCobroUseCase>(
      () => _i384.CargarDatosCobroUseCase(gh<_i511.PosRepository>()),
    );
    gh.factory<_i24.CobrarCotizacionUseCase>(
      () => _i24.CobrarCotizacionUseCase(gh<_i511.PosRepository>()),
    );
    gh.factory<_i5.ColaPosCubit>(
      () => _i5.ColaPosCubit(gh<_i511.PosRepository>()),
    );
    gh.factory<_i505.AprobarRendicionUseCase>(
      () => _i505.AprobarRendicionUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i252.CrearCajaChicaUseCase>(
      () => _i252.CrearCajaChicaUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i639.CrearRendicionUseCase>(
      () => _i639.CrearRendicionUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i830.GetCajaChicaUseCase>(
      () => _i830.GetCajaChicaUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i1038.GetRendicionUseCase>(
      () => _i1038.GetRendicionUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i322.ListarCajasChicasUseCase>(
      () => _i322.ListarCajasChicasUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i63.ListarGastosUseCase>(
      () => _i63.ListarGastosUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i1058.ListarRendicionesUseCase>(
      () => _i1058.ListarRendicionesUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i437.RechazarRendicionUseCase>(
      () => _i437.RechazarRendicionUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i372.RegistrarGastoUseCase>(
      () => _i372.RegistrarGastoUseCase(gh<_i806.CajaChicaRepository>()),
    );
    gh.factory<_i295.CampanaFormCubit>(
      () => _i295.CampanaFormCubit(gh<_i179.PromocionRepository>()),
    );
    gh.factory<_i399.CampanaListCubit>(
      () => _i399.CampanaListCubit(gh<_i179.PromocionRepository>()),
    );
    gh.factory<_i654.CompraListCubit>(
      () => _i654.CompraListCubit(
        gh<_i770.GetComprasUseCase>(),
        gh<_i72.ConfirmarCompraUseCase>(),
        gh<_i875.AnularCompraUseCase>(),
        gh<_i205.EliminarCompraUseCase>(),
      ),
    );
    gh.factory<_i480.PlanSuscripcionCubit>(
      () => _i480.PlanSuscripcionCubit(gh<_i894.PlanSuscripcionRepository>()),
    );
    gh.factory<_i763.LibroContableCubit>(
      () => _i763.LibroContableCubit(gh<_i86.GetLibroContableUseCase>()),
    );
    gh.factory<_i911.CajaChicaListCubit>(
      () => _i911.CajaChicaListCubit(gh<_i322.ListarCajasChicasUseCase>()),
    );
    gh.lazySingleton<_i782.ListarComprobantesUseCase>(
      () => _i782.ListarComprobantesUseCase(
        gh<_i1026.MonitorFacturacionRepository>(),
      ),
    );
    gh.lazySingleton<_monfactPrevSync.PreviewSincronizacionUseCase>(
      () => _monfactPrevSync.PreviewSincronizacionUseCase(
        gh<_i1026.MonitorFacturacionRepository>(),
      ),
    );
    gh.lazySingleton<_monfactApliSync.AplicarSincronizacionUseCase>(
      () => _monfactApliSync.AplicarSincronizacionUseCase(
        gh<_i1026.MonitorFacturacionRepository>(),
      ),
    );
    gh.lazySingleton<_cfgFactDs.ConfiguracionFacturacionRemoteDataSource>(
      () => _cfgFactDs.ConfiguracionFacturacionRemoteDataSource(
        gh<_i667.DioClient>(),
      ),
    );
    gh.lazySingleton<_cfgFactRepo.ConfiguracionFacturacionRepository>(
      () => _cfgFactRepoImpl.ConfiguracionFacturacionRepositoryImpl(
        gh<_cfgFactDs.ConfiguracionFacturacionRemoteDataSource>(),
        gh<_i932.NetworkInfo>(),
        gh<_i490.ErrorHandlerService>(),
      ),
    );
    gh.lazySingleton<_cfgFactGet.GetConfiguracionFacturacionUseCase>(
      () => _cfgFactGet.GetConfiguracionFacturacionUseCase(
        gh<_cfgFactRepo.ConfiguracionFacturacionRepository>(),
      ),
    );
    gh.lazySingleton<_cfgFactUpd.UpdateConfiguracionFacturacionUseCase>(
      () => _cfgFactUpd.UpdateConfiguracionFacturacionUseCase(
        gh<_cfgFactRepo.ConfiguracionFacturacionRepository>(),
      ),
    );
    gh.lazySingleton<_cfgFactPrb.ProbarConexionUseCase>(
      () => _cfgFactPrb.ProbarConexionUseCase(
        gh<_cfgFactRepo.ConfiguracionFacturacionRepository>(),
      ),
    );
    gh.factory<_cfgFactCubit.ConfiguracionFacturacionCubit>(
      () => _cfgFactCubit.ConfiguracionFacturacionCubit(
        getUseCase: gh<_cfgFactGet.GetConfiguracionFacturacionUseCase>(),
        updateUseCase: gh<_cfgFactUpd.UpdateConfiguracionFacturacionUseCase>(),
        probarUseCase: gh<_cfgFactPrb.ProbarConexionUseCase>(),
      ),
    );
    gh.factory<_i309.GetConfiguracionUseCase>(
      () => _i309.GetConfiguracionUseCase(
        gh<_i248.ConfiguracionCodigosRepository>(),
      ),
    );
    gh.factory<_i754.PreviewCodigoUseCase>(
      () => _i754.PreviewCodigoUseCase(
        gh<_i248.ConfiguracionCodigosRepository>(),
      ),
    );
    gh.factory<_i582.SincronizarContadorUseCase>(
      () => _i582.SincronizarContadorUseCase(
        gh<_i248.ConfiguracionCodigosRepository>(),
      ),
    );
    gh.factory<_i199.UpdateConfigProductosUseCase>(
      () => _i199.UpdateConfigProductosUseCase(
        gh<_i248.ConfiguracionCodigosRepository>(),
      ),
    );
    gh.factory<_i925.UpdateConfigServiciosUseCase>(
      () => _i925.UpdateConfigServiciosUseCase(
        gh<_i248.ConfiguracionCodigosRepository>(),
      ),
    );
    gh.factory<_i84.UpdateConfigVariantesUseCase>(
      () => _i84.UpdateConfigVariantesUseCase(
        gh<_i248.ConfiguracionCodigosRepository>(),
      ),
    );
    gh.factory<_i951.UpdateConfigVentasUseCase>(
      () => _i951.UpdateConfigVentasUseCase(
        gh<_i248.ConfiguracionCodigosRepository>(),
      ),
    );
    gh.factory<_i374.CrearIncidenciaPosteriorUseCase>(
      () => _i374.CrearIncidenciaPosteriorUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i629.CrearTransferenciaUseCase>(
      () => _i629.CrearTransferenciaUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i831.CrearTransferenciasMultiplesUseCase>(
      () => _i831.CrearTransferenciasMultiplesUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i917.ObtenerTransferenciaUseCase>(
      () => _i917.ObtenerTransferenciaUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i917.AprobarTransferenciaUseCase>(
      () => _i917.AprobarTransferenciaUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i917.EnviarTransferenciaUseCase>(
      () => _i917.EnviarTransferenciaUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i917.RecibirTransferenciaUseCase>(
      () => _i917.RecibirTransferenciaUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i917.RechazarTransferenciaUseCase>(
      () => _i917.RechazarTransferenciaUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i917.CancelarTransferenciaUseCase>(
      () => _i917.CancelarTransferenciaUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i875.ListarTransferenciasUseCase>(
      () => _i875.ListarTransferenciasUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i1062.ProcesarCompletoTransferenciaUseCase>(
      () => _i1062.ProcesarCompletoTransferenciaUseCase(
        gh<_i812.TransferenciaStockRepository>(),
      ),
    );
    gh.factory<_i595.ActualizarCuentaBancariaUseCase>(
      () => _i595.ActualizarCuentaBancariaUseCase(
        gh<_i556.EmpresaBancoRepository>(),
      ),
    );
    gh.factory<_i924.ActualizarSaldoUseCase>(
      () => _i924.ActualizarSaldoUseCase(gh<_i556.EmpresaBancoRepository>()),
    );
    gh.factory<_i991.CrearCuentaBancariaUseCase>(
      () =>
          _i991.CrearCuentaBancariaUseCase(gh<_i556.EmpresaBancoRepository>()),
    );
    gh.factory<_i141.EliminarCuentaBancariaUseCase>(
      () => _i141.EliminarCuentaBancariaUseCase(
        gh<_i556.EmpresaBancoRepository>(),
      ),
    );
    gh.factory<_i742.GetConciliacionUseCase>(
      () => _i742.GetConciliacionUseCase(gh<_i556.EmpresaBancoRepository>()),
    );
    gh.factory<_i430.GetCuentasBancariasUseCase>(
      () =>
          _i430.GetCuentasBancariasUseCase(gh<_i556.EmpresaBancoRepository>()),
    );
    gh.factory<_i592.MarcarPrincipalUseCase>(
      () => _i592.MarcarPrincipalUseCase(gh<_i556.EmpresaBancoRepository>()),
    );
    gh.factory<_i863.CategoriasMaestrasCubit>(
      () => _i863.CategoriasMaestrasCubit(
        gh<_i736.GetCategoriasMaestrasUseCase>(),
      ),
    );
    gh.factory<_i193.ConsultaRucCubit>(
      () => _i193.ConsultaRucCubit(gh<_i633.ConsultarRucUseCase>()),
    );
    gh.factory<_i615.CrearMetaFinancieraUseCase>(
      () => _i615.CrearMetaFinancieraUseCase(
        gh<_i678.MetaFinancieraRepository>(),
      ),
    );
    gh.factory<_i930.GetMetasFinancierasUseCase>(
      () => _i930.GetMetasFinancierasUseCase(
        gh<_i678.MetaFinancieraRepository>(),
      ),
    );
    gh.factory<_i532.ConfirmarPedidoUseCase>(
      () => _i532.ConfirmarPedidoUseCase(gh<_i498.CheckoutRepository>()),
    );
    gh.factory<_i71.GetOpcionesEnvioUseCase>(
      () => _i71.GetOpcionesEnvioUseCase(gh<_i498.CheckoutRepository>()),
    );
    gh.factory<_i1066.EmpleadoDetailCubit>(
      () => _i1066.EmpleadoDetailCubit(gh<_i12.EmpleadoRepository>()),
    );
    gh.factory<_i230.EmpleadoFormCubit>(
      () => _i230.EmpleadoFormCubit(gh<_i12.EmpleadoRepository>()),
    );
    gh.factory<_i1018.EmpleadoListCubit>(
      () => _i1018.EmpleadoListCubit(gh<_i12.EmpleadoRepository>()),
    );
    gh.factory<_i791.AplicarAjustesUseCase>(
      () => _i791.AplicarAjustesUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i363.AprobarInventarioUseCase>(
      () => _i363.AprobarInventarioUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i516.CancelarInventarioUseCase>(
      () => _i516.CancelarInventarioUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i89.CrearInventarioUseCase>(
      () => _i89.CrearInventarioUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i809.FinalizarConteoUseCase>(
      () => _i809.FinalizarConteoUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i433.GetDetalleInventarioUseCase>(
      () => _i433.GetDetalleInventarioUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i958.IniciarInventarioUseCase>(
      () => _i958.IniciarInventarioUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i132.ListarInventariosUseCase>(
      () => _i132.ListarInventariosUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i126.RegistrarConteoUseCase>(
      () => _i126.RegistrarConteoUseCase(gh<_i173.InventarioRepository>()),
    );
    gh.factory<_i913.DashboardRrhhCubit>(
      () => _i913.DashboardRrhhCubit(gh<_i766.DashboardRrhhRepository>()),
    );
    gh.factory<_i80.CambiarEstadoPedidoUseCase>(
      () => _i80.CambiarEstadoPedidoUseCase(gh<_i37.PedidoEmpresaRepository>()),
    );
    gh.factory<_i399.GetDetallePedidoEmpresaUseCase>(
      () => _i399.GetDetallePedidoEmpresaUseCase(
        gh<_i37.PedidoEmpresaRepository>(),
      ),
    );
    gh.factory<_i599.GetPedidosEmpresaUseCase>(
      () => _i599.GetPedidosEmpresaUseCase(gh<_i37.PedidoEmpresaRepository>()),
    );
    gh.factory<_i986.GetResumenPedidosUseCase>(
      () => _i986.GetResumenPedidosUseCase(gh<_i37.PedidoEmpresaRepository>()),
    );
    gh.factory<_i477.ValidarPagoUseCase>(
      () => _i477.ValidarPagoUseCase(gh<_i37.PedidoEmpresaRepository>()),
    );
    gh.factory<_i247.AgenteBancarioCubit>(
      () => _i247.AgenteBancarioCubit(
        gh<_i803.GetResumenAgentesUseCase>(),
        gh<_i246.GetAgentesUseCase>(),
        gh<_i201.RegistrarOperacionUseCase>(),
        gh<_i1049.CrearAgenteUseCase>(),
        gh<_i487.AgenteBancarioRepository>(),
      ),
    );
    gh.factory<_i1000.OrdenCompraFormCubit>(
      () => _i1000.OrdenCompraFormCubit(
        gh<_i812.CrearOrdenCompraUseCase>(),
        gh<_i895.ActualizarOrdenCompraUseCase>(),
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
    gh.factory<_i629.TipoCambioCubit>(
      () => _i629.TipoCambioCubit(
        gh<_i15.GetTipoCambioHoyUseCase>(),
        gh<_i142.GetHistorialTipoCambioUseCase>(),
        gh<_i509.RegistrarTipoCambioManualUseCase>(),
        gh<_i77.GetConfiguracionMonedaUseCase>(),
      ),
    );
    gh.factory<_i724.CrearIncidenciaPosteriorCubit>(
      () => _i724.CrearIncidenciaPosteriorCubit(
        gh<_i374.CrearIncidenciaPosteriorUseCase>(),
        gh<_i306.StorageService>(),
      ),
    );
    gh.factory<_i1070.InventarioDetailCubit>(
      () => _i1070.InventarioDetailCubit(
        gh<_i433.GetDetalleInventarioUseCase>(),
        gh<_i958.IniciarInventarioUseCase>(),
        gh<_i126.RegistrarConteoUseCase>(),
        gh<_i809.FinalizarConteoUseCase>(),
        gh<_i363.AprobarInventarioUseCase>(),
        gh<_i791.AplicarAjustesUseCase>(),
        gh<_i516.CancelarInventarioUseCase>(),
      ),
    );
    gh.factory<_i303.ConfigurarPreciosCubit>(
      () => _i303.ConfigurarPreciosCubit(
        gh<_i395.ActualizarPreciosProductoStockUseCase>(),
      ),
    );
    gh.factory<_i878.ProveedorFormCubit>(
      () => _i878.ProveedorFormCubit(
        gh<_i580.CrearProveedorUseCase>(),
        gh<_i57.ActualizarProveedorUseCase>(),
      ),
    );
    gh.factory<_i880.GetProductosStockUseCase>(
      () =>
          _i880.GetProductosStockUseCase(gh<_i690.ProductosStockRepository>()),
    );
    gh.factory<_i809.OrdenCompraListCubit>(
      () => _i809.OrdenCompraListCubit(
        gh<_i217.GetOrdenesCompraUseCase>(),
        gh<_i133.EliminarOrdenCompraUseCase>(),
        gh<_i254.CambiarEstadoOcUseCase>(),
        gh<_i176.DuplicarOrdenCompraUseCase>(),
      ),
    );
    gh.factory<_i344.MonitorProductosCubit>(
      () => _i344.MonitorProductosCubit(
        gh<_i644.GetMonitorProductosUseCase>(),
        gh<_i513.BulkMarketplaceUseCase>(),
        gh<_i879.BulkUbicacionUseCase>(),
        gh<_i1058.BulkPrecioIgvUseCase>(),
      ),
    );
    gh.factory<_i252.TurnoListCubit>(
      () => _i252.TurnoListCubit(gh<_i303.TurnoRepository>()),
    );
    gh.factory<_i620.GestionarReporteCubit>(
      () => _i620.GestionarReporteCubit(
        gh<_i218.EnviarParaRevisionUsecase>(),
        gh<_i153.AprobarReporteUsecase>(),
        gh<_i1020.RechazarReporteUsecase>(),
      ),
    );
    gh.factory<_i238.CrearTransferenciaCubit>(
      () => _i238.CrearTransferenciaCubit(
        gh<_i629.CrearTransferenciaUseCase>(),
        gh<_i831.CrearTransferenciasMultiplesUseCase>(),
      ),
    );
    gh.factory<_i447.CarritoCubit>(
      () => _i447.CarritoCubit(
        gh<_i477.GetCarritoUseCase>(),
        gh<_i81.AgregarItemUseCase>(),
        gh<_i224.ActualizarCantidadUseCase>(),
        gh<_i883.EliminarItemUseCase>(),
        gh<_i98.VaciarCarritoUseCase>(),
        gh<_i689.GetContadorUseCase>(),
      ),
    );
    gh.factory<_i850.GetOrdenesServicioUseCase>(
      () =>
          _i850.GetOrdenesServicioUseCase(gh<_i1067.OrdenServicioRepository>()),
    );
    gh.factory<_i835.AgregarItemCubit>(
      () => _i835.AgregarItemCubit(gh<_i87.AgregarItemUsecase>()),
    );
    gh.lazySingleton<_i343.CrearCotizacionUseCase>(
      () => _i343.CrearCotizacionUseCase(gh<_i823.CotizacionRepository>()),
    );
    gh.factory<_i1016.ActualizarCotizacionUseCase>(
      () =>
          _i1016.ActualizarCotizacionUseCase(gh<_i823.CotizacionRepository>()),
    );
    gh.factory<_i716.CambiarEstadoCotizacionUseCase>(
      () => _i716.CambiarEstadoCotizacionUseCase(
        gh<_i823.CotizacionRepository>(),
      ),
    );
    gh.factory<_i499.DuplicarCotizacionUseCase>(
      () => _i499.DuplicarCotizacionUseCase(gh<_i823.CotizacionRepository>()),
    );
    gh.factory<_i965.EliminarCotizacionUseCase>(
      () => _i965.EliminarCotizacionUseCase(gh<_i823.CotizacionRepository>()),
    );
    gh.factory<_i813.GetCotizacionUseCase>(
      () => _i813.GetCotizacionUseCase(gh<_i823.CotizacionRepository>()),
    );
    gh.factory<_i232.GetCotizacionesUseCase>(
      () => _i232.GetCotizacionesUseCase(gh<_i823.CotizacionRepository>()),
    );
    gh.factory<_i76.ValidarCompatibilidadCotizacionUseCase>(
      () => _i76.ValidarCompatibilidadCotizacionUseCase(
        gh<_i823.CotizacionRepository>(),
      ),
    );
    gh.factory<_i1047.AdelantoCubit>(
      () => _i1047.AdelantoCubit(gh<_i345.AdelantoRepository>()),
    );
    gh.factory<_i604.AdelantoListCubit>(
      () => _i604.AdelantoListCubit(gh<_i345.AdelantoRepository>()),
    );
    gh.factory<_i437.SolicitudEmpresaActionCubit>(
      () => _i437.SolicitudEmpresaActionCubit(
        gh<_i866.GetDetalleSolicitudUseCase>(),
        gh<_i420.RechazarSolicitudUseCase>(),
        gh<_i221.CotizarSolicitudUseCase>(),
      ),
    );
    gh.factory<_i121.UnidadMedidaCubit>(
      () => _i121.UnidadMedidaCubit(
        gh<_i696.GetUnidadesMaestrasUseCase>(),
        gh<_i853.GetUnidadesEmpresaUseCase>(),
        gh<_i446.ActivarUnidadUseCase>(),
        gh<_i229.DesactivarUnidadUseCase>(),
        gh<_i836.ActivarUnidadesPopularesUseCase>(),
      ),
    );
    gh.factory<_i91.TercerizacionListCubit>(
      () =>
          _i91.TercerizacionListCubit(gh<_i335.ListarTercerizacionesUseCase>()),
    );
    gh.lazySingleton<_i809.CheckAuthMethodsUseCase>(
      () => _i809.CheckAuthMethodsUseCase(gh<_i787.AuthRepository>()),
    );
    gh.lazySingleton<_i726.SetPasswordUseCase>(
      () => _i726.SetPasswordUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i60.CobrarPosCubit>(
      () => _i60.CobrarPosCubit(
        gh<_i384.CargarDatosCobroUseCase>(),
        gh<_i24.CobrarCotizacionUseCase>(),
      ),
    );
    gh.factory<_i471.PoliticaFormCubit>(
      () => _i471.PoliticaFormCubit(
        gh<_i189.CreatePolitica>(),
        gh<_i120.UpdatePolitica>(),
        gh<_i649.GetPoliticaById>(),
      ),
    );
    gh.factory<_i483.SolicitudFormCubit>(
      () => _i483.SolicitudFormCubit(
        gh<_i287.CrearSolicitudUseCase>(),
        gh<_i126.SolicitudCotizacionRemoteDataSource>(),
      ),
    );
    gh.factory<_i457.AsignarProductosCubit>(
      () => _i457.AsignarProductosCubit(
        gh<_i1012.AsignarProductos>(),
        gh<_i269.AsignarCategorias>(),
      ),
    );
    gh.factory<_i430.ConciliacionCubit>(
      () => _i430.ConciliacionCubit(gh<_i742.GetConciliacionUseCase>()),
    );
    gh.factory<_i234.AprobarDevolucionUseCase>(
      () =>
          _i234.AprobarDevolucionUseCase(gh<_i552.DevolucionVentaRepository>()),
    );
    gh.factory<_i60.CrearDevolucionUseCase>(
      () => _i60.CrearDevolucionUseCase(gh<_i552.DevolucionVentaRepository>()),
    );
    gh.factory<_i489.GetDevolucionUseCase>(
      () => _i489.GetDevolucionUseCase(gh<_i552.DevolucionVentaRepository>()),
    );
    gh.factory<_i216.GetDevolucionesUseCase>(
      () => _i216.GetDevolucionesUseCase(gh<_i552.DevolucionVentaRepository>()),
    );
    gh.factory<_i1045.ProcesarDevolucionUseCase>(
      () => _i1045.ProcesarDevolucionUseCase(
        gh<_i552.DevolucionVentaRepository>(),
      ),
    );
    gh.factory<_i38.RendicionesListCubit>(
      () => _i38.RendicionesListCubit(gh<_i1058.ListarRendicionesUseCase>()),
    );
    gh.factory<_i999.CompraFormCubit>(
      () => _i999.CompraFormCubit(
        gh<_i526.CrearCompraUseCase>(),
        gh<_i50.CrearCompraDesdeOcUseCase>(),
      ),
    );
    gh.factory<_i123.GetServiciosUseCase>(
      () => _i123.GetServiciosUseCase(gh<_i603.ServicioRepository>()),
    );
    gh.factory<_i1046.ConfiguracionCodigosCubit>(
      () => _i1046.ConfiguracionCodigosCubit(
        gh<_i309.GetConfiguracionUseCase>(),
        gh<_i199.UpdateConfigProductosUseCase>(),
        gh<_i84.UpdateConfigVariantesUseCase>(),
        gh<_i925.UpdateConfigServiciosUseCase>(),
        gh<_i951.UpdateConfigVentasUseCase>(),
        gh<_i754.PreviewCodigoUseCase>(),
        gh<_i582.SincronizarContadorUseCase>(),
      ),
    );
    gh.factory<_i1016.MisSolicitudesCubit>(
      () => _i1016.MisSolicitudesCubit(
        gh<_i954.GetMisSolicitudesUseCase>(),
        gh<_i1010.CancelarSolicitudUseCase>(),
      ),
    );
    gh.factory<_i694.CategoriaGastoCubit>(
      () => _i694.CategoriaGastoCubit(
        gh<_i687.GetCategoriasGastoUseCase>(),
        gh<_i693.CrearCategoriaGastoUseCase>(),
        gh<_i295.ActualizarCategoriaGastoUseCase>(),
        gh<_i750.EliminarCategoriaGastoUseCase>(),
      ),
    );
    gh.factory<_i829.ReporteIncidenciaDetailCubit>(
      () =>
          _i829.ReporteIncidenciaDetailCubit(gh<_i146.ObtenerReporteUsecase>()),
    );
    gh.factory<_i328.TransferenciaDetailCubit>(
      () => _i328.TransferenciaDetailCubit(
        gh<_i917.ObtenerTransferenciaUseCase>(),
      ),
    );
    gh.factory<_i60.SolicitudesRecibidasCubit>(
      () => _i60.SolicitudesRecibidasCubit(
        gh<_i204.GetSolicitudesRecibidasUseCase>(),
      ),
    );
    gh.factory<_i727.GetAvisoResumenUseCase>(
      () => _i727.GetAvisoResumenUseCase(
        gh<_i1007.AvisoMantenimientoRepository>(),
      ),
    );
    gh.factory<_i801.GetAvisosUseCase>(
      () => _i801.GetAvisosUseCase(gh<_i1007.AvisoMantenimientoRepository>()),
    );
    gh.factory<_i793.GetConfiguracionAvisoUseCase>(
      () => _i793.GetConfiguracionAvisoUseCase(
        gh<_i1007.AvisoMantenimientoRepository>(),
      ),
    );
    gh.factory<_i607.UpdateConfiguracionAvisoUseCase>(
      () => _i607.UpdateConfiguracionAvisoUseCase(
        gh<_i1007.AvisoMantenimientoRepository>(),
      ),
    );
    gh.factory<_i984.UpdateEstadoAvisoUseCase>(
      () => _i984.UpdateEstadoAvisoUseCase(
        gh<_i1007.AvisoMantenimientoRepository>(),
      ),
    );
    gh.factory<_i600.AbrirCajaUseCase>(
      () => _i600.AbrirCajaUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i750.AnularMovimientoUseCase>(
      () => _i750.AnularMovimientoUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i575.CerrarCajaUseCase>(
      () => _i575.CerrarCajaUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i290.CrearMovimientoUseCase>(
      () => _i290.CrearMovimientoUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i265.GetCajaActivaUseCase>(
      () => _i265.GetCajaActivaUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i969.GetHistorialUseCase>(
      () => _i969.GetHistorialUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i519.GetMonitorUseCase>(
      () => _i519.GetMonitorUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i259.GetMovimientosUseCase>(
      () => _i259.GetMovimientosUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i413.GetResumenUseCase>(
      () => _i413.GetResumenUseCase(gh<_i742.CajaRepository>()),
    );
    gh.factory<_i291.MarcasMaestrasCubit>(
      () => _i291.MarcasMaestrasCubit(gh<_i608.GetMarcasMaestrasUseCase>()),
    );
    gh.factory<_i692.ResolverItemCubit>(
      () => _i692.ResolverItemCubit(gh<_i605.ResolverItemUsecase>()),
    );
    gh.factory<_i873.AgregarStockInicialCubit>(
      () => _i873.AgregarStockInicialCubit(
        gh<_i494.CrearStockInicialUseCase>(),
        gh<_i265.GetStockProductoEnSedeUseCase>(),
        gh<_i395.ActualizarPreciosProductoStockUseCase>(),
        gh<_i132.AjustarStockUseCase>(),
      ),
    );
    gh.factory<_i900.PoliticaListCubit>(
      () => _i900.PoliticaListCubit(
        gh<_i849.GetPoliticasDescuento>(),
        gh<_i26.DeletePolitica>(),
      ),
    );
    gh.factory<_i455.GastoFormCubit>(
      () => _i455.GastoFormCubit(gh<_i372.RegistrarGastoUseCase>()),
    );
    gh.factory<_i990.CajaChicaDetailCubit>(
      () => _i990.CajaChicaDetailCubit(
        gh<_i830.GetCajaChicaUseCase>(),
        gh<_i63.ListarGastosUseCase>(),
      ),
    );
    gh.factory<_i737.HistorialPreciosCubit>(
      () => _i737.HistorialPreciosCubit(
        gh<_i530.GetHistorialPreciosGlobalUseCase>(),
        gh<_i530.ExportHistorialPreciosUseCase>(),
        gh<_i873.GetSedesUseCase>(),
      ),
    );
    gh.factory<_i410.AvisoConfiguracionCubit>(
      () => _i410.AvisoConfiguracionCubit(
        gh<_i793.GetConfiguracionAvisoUseCase>(),
        gh<_i607.UpdateConfiguracionAvisoUseCase>(),
      ),
    );
    gh.factory<_i1064.CancelarVinculacionUseCase>(
      () =>
          _i1064.CancelarVinculacionUseCase(gh<_i604.VinculacionRepository>()),
    );
    gh.factory<_i506.CheckRucUseCase>(
      () => _i506.CheckRucUseCase(gh<_i604.VinculacionRepository>()),
    );
    gh.factory<_i649.CrearVinculacionUseCase>(
      () => _i649.CrearVinculacionUseCase(gh<_i604.VinculacionRepository>()),
    );
    gh.factory<_i667.DesvincularUseCase>(
      () => _i667.DesvincularUseCase(gh<_i604.VinculacionRepository>()),
    );
    gh.factory<_i215.GetPendientesVinculacionUseCase>(
      () => _i215.GetPendientesVinculacionUseCase(
        gh<_i604.VinculacionRepository>(),
      ),
    );
    gh.factory<_i639.ListarVinculacionesUseCase>(
      () => _i639.ListarVinculacionesUseCase(gh<_i604.VinculacionRepository>()),
    );
    gh.factory<_i1053.ResponderVinculacionUseCase>(
      () =>
          _i1053.ResponderVinculacionUseCase(gh<_i604.VinculacionRepository>()),
    );
    gh.factory<_i899.GetMisPagosUseCase>(
      () => _i899.GetMisPagosUseCase(gh<_i656.PagoSuscripcionRepository>()),
    );
    gh.factory<_i1052.SolicitarPagoUseCase>(
      () => _i1052.SolicitarPagoUseCase(gh<_i656.PagoSuscripcionRepository>()),
    );
    gh.factory<_i157.SubirComprobantePagoUseCase>(
      () => _i157.SubirComprobantePagoUseCase(
        gh<_i656.PagoSuscripcionRepository>(),
      ),
    );
    gh.factory<_i38.CajaMovimientosCubit>(
      () => _i38.CajaMovimientosCubit(
        gh<_i259.GetMovimientosUseCase>(),
        gh<_i290.CrearMovimientoUseCase>(),
        gh<_i413.GetResumenUseCase>(),
        gh<_i750.AnularMovimientoUseCase>(),
      ),
    );
    gh.factory<_i68.PrecioNivelCubit>(
      () => _i68.PrecioNivelCubit(gh<_i640.PrecioNivelRepository>()),
    );
    gh.factory<_i604.ActualizarProductoUseCase>(
      () => _i604.ActualizarProductoUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i397.ActualizarReglaCompatibilidadUseCase>(
      () => _i397.ActualizarReglaCompatibilidadUseCase(
        gh<_i398.ProductoRepository>(),
      ),
    );
    gh.factory<_i692.BulkUploadProductosUseCase>(
      () => _i692.BulkUploadProductosUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i244.CrearProductoUseCase>(
      () => _i244.CrearProductoUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i435.CrearReglaCompatibilidadUseCase>(
      () =>
          _i435.CrearReglaCompatibilidadUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i570.DownloadBulkTemplateUseCase>(
      () => _i570.DownloadBulkTemplateUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i419.EliminarProductoUseCase>(
      () => _i419.EliminarProductoUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i432.EliminarReglaCompatibilidadUseCase>(
      () => _i432.EliminarReglaCompatibilidadUseCase(
        gh<_i398.ProductoRepository>(),
      ),
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
    gh.factory<_i403.GetReglasCompatibilidadUseCase>(
      () =>
          _i403.GetReglasCompatibilidadUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i599.ListarIncidenciasUseCase>(
      () => _i599.ListarIncidenciasUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i154.RecibirTransferenciaConIncidenciasUseCase>(
      () => _i154.RecibirTransferenciaConIncidenciasUseCase(
        gh<_i398.ProductoRepository>(),
      ),
    );
    gh.factory<_i1007.ResolverIncidenciaUseCase>(
      () => _i1007.ResolverIncidenciaUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i709.ValidarCompatibilidadUseCase>(
      () => _i709.ValidarCompatibilidadUseCase(gh<_i398.ProductoRepository>()),
    );
    gh.factory<_i205.VentaFormCubit>(
      () => _i205.VentaFormCubit(
        crearVentaUseCase: gh<_i1031.CrearVentaUseCase>(),
        crearDesdeCotizacionUseCase:
            gh<_i624.CrearVentaDesdeCotizacionUseCase>(),
        crearYCobrarVentaUseCase: gh<_i825.CrearYCobrarVentaUseCase>(),
        actualizarVentaUseCase: gh<_i790.ActualizarVentaUseCase>(),
        confirmarVentaUseCase: gh<_i376.ConfirmarVentaUseCase>(),
        procesarPagoUseCase: gh<_i459.ProcesarPagoUseCase>(),
        anularVentaUseCase: gh<_i701.AnularVentaUseCase>(),
      ),
    );
    gh.lazySingleton<_i378.AgregarComponentesBatchUseCase>(
      () => _i378.AgregarComponentesBatchUseCase(gh<_i200.ComboRepository>()),
    );
    gh.lazySingleton<_i53.CreateComboUseCase>(
      () => _i53.CreateComboUseCase(gh<_i200.ComboRepository>()),
    );
    gh.lazySingleton<_i619.EliminarComponentesBatchUseCase>(
      () => _i619.EliminarComponentesBatchUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i413.EliminarItemCubit>(
      () => _i413.EliminarItemCubit(gh<_i192.EliminarItemUsecase>()),
    );
    gh.factory<_i96.AvisoListCubit>(
      () => _i96.AvisoListCubit(
        gh<_i801.GetAvisosUseCase>(),
        gh<_i727.GetAvisoResumenUseCase>(),
        gh<_i984.UpdateEstadoAvisoUseCase>(),
      ),
    );
    gh.factory<_i90.MisPagosSuscripcionCubit>(
      () => _i90.MisPagosSuscripcionCubit(gh<_i899.GetMisPagosUseCase>()),
    );
    gh.factory<_i131.EmpresaBancoCubit>(
      () => _i131.EmpresaBancoCubit(
        gh<_i430.GetCuentasBancariasUseCase>(),
        gh<_i991.CrearCuentaBancariaUseCase>(),
        gh<_i595.ActualizarCuentaBancariaUseCase>(),
        gh<_i141.EliminarCuentaBancariaUseCase>(),
        gh<_i592.MarcarPrincipalUseCase>(),
        gh<_i924.ActualizarSaldoUseCase>(),
      ),
    );
    gh.factory<_i843.RendicionCubit>(
      () => _i843.RendicionCubit(
        gh<_i639.CrearRendicionUseCase>(),
        gh<_i1038.GetRendicionUseCase>(),
        gh<_i505.AprobarRendicionUseCase>(),
        gh<_i437.RechazarRendicionUseCase>(),
      ),
    );
    gh.factory<_i298.CotizacionFormCubit>(
      () => _i298.CotizacionFormCubit(
        crearCotizacionUseCase: gh<_i343.CrearCotizacionUseCase>(),
        actualizarCotizacionUseCase: gh<_i1016.ActualizarCotizacionUseCase>(),
        cambiarEstadoUseCase: gh<_i716.CambiarEstadoCotizacionUseCase>(),
        duplicarCotizacionUseCase: gh<_i499.DuplicarCotizacionUseCase>(),
        eliminarCotizacionUseCase: gh<_i965.EliminarCotizacionUseCase>(),
        validarCompatibilidadUseCase:
            gh<_i76.ValidarCompatibilidadCotizacionUseCase>(),
      ),
    );
    gh.factory<_i227.ProductoListCubit>(
      () => _i227.ProductoListCubit(gh<_i202.GetProductosUseCase>()),
    );
    gh.factory<_i1062.ProductoSearchCubit>(
      () => _i1062.ProductoSearchCubit(gh<_i202.GetProductosUseCase>()),
    );
    gh.factory<_i175.ServicioDashboardCubit>(
      () => _i175.ServicioDashboardCubit(
        gh<_i742.EstadisticasServicioRepository>(),
      ),
    );
    gh.factory<_i849.CajaHistorialCubit>(
      () => _i849.CajaHistorialCubit(gh<_i969.GetHistorialUseCase>()),
    );
    gh.factory<_i894.VinculacionActionCubit>(
      () => _i894.VinculacionActionCubit(
        gh<_i506.CheckRucUseCase>(),
        gh<_i649.CrearVinculacionUseCase>(),
        gh<_i1053.ResponderVinculacionUseCase>(),
        gh<_i1064.CancelarVinculacionUseCase>(),
        gh<_i667.DesvincularUseCase>(),
      ),
    );
    gh.factory<_i1021.AjustarStockCubit>(
      () => _i1021.AjustarStockCubit(gh<_i132.AjustarStockUseCase>()),
    );
    gh.factory<_i466.ProductoSelectorCubit>(
      () => _i466.ProductoSelectorCubit(
        gh<_i787.GetProductosDisponiblesParaComboUseCase>(),
      ),
    );
    gh.factory<_i914.AlertasStockCubit>(
      () => _i914.AlertasStockCubit(gh<_i752.GetAlertasStockBajoUseCase>()),
    );
    gh.factory<_i346.CrearReporteIncidenciaCubit>(
      () => _i346.CrearReporteIncidenciaCubit(gh<_i338.CrearReporteUsecase>()),
    );
    gh.factory<_i258.ConfiguracionCamposCubit>(
      () => _i258.ConfiguracionCamposCubit(
        gh<_i676.GetConfiguracionCamposUseCase>(),
        gh<_i29.CreateConfiguracionCampoUseCase>(),
        gh<_i997.UpdateConfiguracionCampoUseCase>(),
        gh<_i866.DeleteConfiguracionCampoUseCase>(),
        gh<_i176.ReorderConfiguracionCamposUseCase>(),
      ),
    );
    gh.factory<_i613.PagoSuscripcionCubit>(
      () => _i613.PagoSuscripcionCubit(
        gh<_i1052.SolicitarPagoUseCase>(),
        gh<_i157.SubirComprobantePagoUseCase>(),
      ),
    );
    gh.factory<_i918.AsignarUsuariosCubit>(
      () => _i918.AsignarUsuariosCubit(
        gh<_i549.AsignarUsuarios>(),
        gh<_i873.ObtenerUsuariosAsignados>(),
        gh<_i141.LoggerService>(),
      ),
    );
    gh.factory<_i427.CompraAnalyticsCubit>(
      () => _i427.CompraAnalyticsCubit(gh<_i914.GetCompraAnalyticsUseCase>()),
    );
    gh.factory<_i503.CajaActivaCubit>(
      () => _i503.CajaActivaCubit(
        gh<_i265.GetCajaActivaUseCase>(),
        gh<_i600.AbrirCajaUseCase>(),
        gh<_i575.CerrarCajaUseCase>(),
      ),
    );
    gh.factory<_i94.ProveedorListCubit>(
      () => _i94.ProveedorListCubit(gh<_i825.GetProveedoresUseCase>()),
    );
    gh.factory<_i286.BulkUploadCubit>(
      () => _i286.BulkUploadCubit(
        gh<_i570.DownloadBulkTemplateUseCase>(),
        gh<_i692.BulkUploadProductosUseCase>(),
      ),
    );
    gh.factory<_i980.IncidenciaCubit>(
      () => _i980.IncidenciaCubit(gh<_i288.IncidenciaRepository>()),
    );
    gh.factory<_i536.IncidenciaListCubit>(
      () => _i536.IncidenciaListCubit(gh<_i288.IncidenciaRepository>()),
    );
    gh.factory<_i220.VentaListCubit>(
      () => _i220.VentaListCubit(gh<_i213.GetVentasUseCase>()),
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
    gh.factory<_i798.UpdateProfileUseCase>(
      () => _i798.UpdateProfileUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i30.VerifyEmailUseCase>(
      () => _i30.VerifyEmailUseCase(gh<_i787.AuthRepository>()),
    );
    gh.factory<_i377.PrestamoCubit>(
      () => _i377.PrestamoCubit(
        gh<_i879.GetPrestamosUseCase>(),
        gh<_i179.GetResumenPrestamosUseCase>(),
        gh<_i494.CrearPrestamoUseCase>(),
        gh<_i1058.RegistrarPagoPrestamoUseCase>(),
      ),
    );
    gh.factory<_i716.CreateEmpresaCubit>(
      () => _i716.CreateEmpresaCubit(
        createEmpresaUseCase: gh<_i612.CreateEmpresaUseCase>(),
      ),
    );
    gh.factory<_i961.ListarIncidenciasCubit>(
      () => _i961.ListarIncidenciasCubit(gh<_i599.ListarIncidenciasUseCase>()),
    );
    gh.factory<_i906.LoteListCubit>(
      () => _i906.LoteListCubit(
        gh<_i805.GetLotesUseCase>(),
        gh<_i823.GetLotesProximosVencerUseCase>(),
        gh<_i396.MarcarLotesVencidosUseCase>(),
      ),
    );
    gh.factory<_i370.ActualizarOfertaComboUseCase>(
      () => _i370.ActualizarOfertaComboUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i1067.ActualizarPrecioComboUseCase>(
      () => _i1067.ActualizarPrecioComboUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i237.AgregarComponenteUseCase>(
      () => _i237.AgregarComponenteUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i840.DesactivarOfertaComboUseCase>(
      () => _i840.DesactivarOfertaComboUseCase(gh<_i200.ComboRepository>()),
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
    gh.factory<_i824.GetHistorialPreciosComboUseCase>(
      () => _i824.GetHistorialPreciosComboUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i1031.GetReservacionUseCase>(
      () => _i1031.GetReservacionUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i813.LiberarReservaUseCase>(
      () => _i813.LiberarReservaUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i409.ReservarStockUseCase>(
      () => _i409.ReservarStockUseCase(gh<_i200.ComboRepository>()),
    );
    gh.factory<_i743.ProductoDetailCubit>(
      () => _i743.ProductoDetailCubit(gh<_i460.GetProductoUseCase>()),
    );
    gh.factory<_i1059.VinculacionListCubit>(
      () => _i1059.VinculacionListCubit(gh<_i639.ListarVinculacionesUseCase>()),
    );
    gh.factory<_i520.PedidosEmpresaCubit>(
      () => _i520.PedidosEmpresaCubit(gh<_i599.GetPedidosEmpresaUseCase>()),
    );
    gh.factory<_i965.InventarioListCubit>(
      () => _i965.InventarioListCubit(gh<_i132.ListarInventariosUseCase>()),
    );
    gh.factory<_i232.CuentasCobrarCubit>(
      () => _i232.CuentasCobrarCubit(
        gh<_i853.GetCuentasCobrarUseCase>(),
        gh<_i1042.GetResumenCuentasCobrarUseCase>(),
      ),
    );
    gh.factory<_i410.TransferenciasListCubit>(
      () => _i410.TransferenciasListCubit(
        gh<_i875.ListarTransferenciasUseCase>(),
      ),
    );
    gh.factory<_i928.PedidoEmpresaActionCubit>(
      () => _i928.PedidoEmpresaActionCubit(
        gh<_i399.GetDetallePedidoEmpresaUseCase>(),
        gh<_i477.ValidarPagoUseCase>(),
        gh<_i80.CambiarEstadoPedidoUseCase>(),
      ),
    );
    gh.factory<_i87.CompleteProfileCubit>(
      () => _i87.CompleteProfileCubit(
        updateProfileUseCase: gh<_i798.UpdateProfileUseCase>(),
        consultarDniUseCase: gh<_i53.ConsultarDniUseCase>(),
        authRepository: gh<_i787.AuthRepository>(),
      ),
    );
    gh.factory<_i333.MetaFinancieraCubit>(
      () => _i333.MetaFinancieraCubit(
        gh<_i930.GetMetasFinancierasUseCase>(),
        gh<_i615.CrearMetaFinancieraUseCase>(),
      ),
    );
    gh.factory<_i773.GestionarTransferenciaCubit>(
      () => _i773.GestionarTransferenciaCubit(
        gh<_i917.AprobarTransferenciaUseCase>(),
        gh<_i917.EnviarTransferenciaUseCase>(),
        gh<_i917.RecibirTransferenciaUseCase>(),
        gh<_i917.RechazarTransferenciaUseCase>(),
        gh<_i917.CancelarTransferenciaUseCase>(),
        gh<_i1062.ProcesarCompletoTransferenciaUseCase>(),
      ),
    );
    gh.factory<_i101.ProductosStockSelectorCubit>(
      () => _i101.ProductosStockSelectorCubit(
        gh<_i880.GetProductosStockUseCase>(),
      ),
    );
    gh.factory<_i848.CheckoutCubit>(
      () => _i848.CheckoutCubit(
        gh<_i71.GetOpcionesEnvioUseCase>(),
        gh<_i532.ConfirmarPedidoUseCase>(),
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
        eliminarComponentesBatch: gh<_i619.EliminarComponentesBatchUseCase>(),
        getReservacionUseCase: gh<_i1031.GetReservacionUseCase>(),
        reservarStockUseCase: gh<_i409.ReservarStockUseCase>(),
        liberarReservaUseCase: gh<_i813.LiberarReservaUseCase>(),
        actualizarPrecioComboUseCase: gh<_i1067.ActualizarPrecioComboUseCase>(),
        actualizarOfertaComboUseCase: gh<_i370.ActualizarOfertaComboUseCase>(),
        desactivarOfertaComboUseCase: gh<_i840.DesactivarOfertaComboUseCase>(),
        getHistorialPreciosComboUseCase:
            gh<_i824.GetHistorialPreciosComboUseCase>(),
      ),
    );
    gh.factory<_i282.CajaMonitorCubit>(
      () => _i282.CajaMonitorCubit(gh<_i519.GetMonitorUseCase>()),
    );
    gh.factory<_i147.RegisterCubit>(
      () => _i147.RegisterCubit(registerUseCase: gh<_i941.RegisterUseCase>()),
    );
    gh.factory<_i9.CotizacionListCubit>(
      () => _i9.CotizacionListCubit(gh<_i232.GetCotizacionesUseCase>()),
    );
    gh.factory<_i279.ResolverIncidenciaCubit>(
      () =>
          _i279.ResolverIncidenciaCubit(gh<_i1007.ResolverIncidenciaUseCase>()),
    );
    gh.factory<_i712.DevolucionListCubit>(
      () => _i712.DevolucionListCubit(gh<_i216.GetDevolucionesUseCase>()),
    );
    gh.factory<_i606.RecibirTransferenciaIncidenciasCubit>(
      () => _i606.RecibirTransferenciaIncidenciasCubit(
        gh<_i154.RecibirTransferenciaConIncidenciasUseCase>(),
      ),
    );
    gh.factory<_i867.DevolucionFormCubit>(
      () => _i867.DevolucionFormCubit(
        crearUseCase: gh<_i60.CrearDevolucionUseCase>(),
        aprobarUseCase: gh<_i234.AprobarDevolucionUseCase>(),
        procesarUseCase: gh<_i1045.ProcesarDevolucionUseCase>(),
      ),
    );
    gh.singleton<_i469.AuthBloc>(
      () => _i469.AuthBloc(
        checkAuthStatus: gh<_i52.CheckAuthStatusUseCase>(),
        getLocalUser: gh<_i386.GetLocalUserUseCase>(),
        logout: gh<_i48.LogoutUseCase>(),
      ),
    );
    gh.factory<_i243.CompatibilidadCubit>(
      () => _i243.CompatibilidadCubit(
        gh<_i403.GetReglasCompatibilidadUseCase>(),
        gh<_i435.CrearReglaCompatibilidadUseCase>(),
        gh<_i397.ActualizarReglaCompatibilidadUseCase>(),
        gh<_i432.EliminarReglaCompatibilidadUseCase>(),
        gh<_i709.ValidarCompatibilidadUseCase>(),
      ),
    );
    gh.factory<_i547.AccountSecurityCubit>(
      () => _i547.AccountSecurityCubit(
        gh<_i809.CheckAuthMethodsUseCase>(),
        gh<_i726.SetPasswordUseCase>(),
        gh<_i469.AuthBloc>(),
      ),
    );
    gh.factory<_i930.OrdenServicioListCubit>(
      () => _i930.OrdenServicioListCubit(gh<_i850.GetOrdenesServicioUseCase>()),
    );
    gh.factory<_i13.ProductoSedeSearchCubit>(
      () => _i13.ProductoSedeSearchCubit(gh<_i202.GetProductosUseCase>()),
    );
    gh.factory<_i239.ServicioListCubit>(
      () => _i239.ServicioListCubit(gh<_i123.GetServiciosUseCase>()),
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
