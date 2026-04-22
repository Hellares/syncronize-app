import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/utils/resource.dart';
import '../../domain/entities/configuracion_facturacion.dart';
import '../../domain/usecases/get_configuracion_facturacion_usecase.dart';
import '../../domain/usecases/probar_conexion_usecase.dart';
import '../../domain/usecases/update_configuracion_facturacion_usecase.dart';
import 'configuracion_facturacion_state.dart';

@injectable
class ConfiguracionFacturacionCubit
    extends Cubit<ConfiguracionFacturacionState> {
  final GetConfiguracionFacturacionUseCase _getUseCase;
  final UpdateConfiguracionFacturacionUseCase _updateUseCase;
  final ProbarConexionUseCase _probarUseCase;

  ConfiguracionFacturacionCubit({
    required GetConfiguracionFacturacionUseCase getUseCase,
    required UpdateConfiguracionFacturacionUseCase updateUseCase,
    required ProbarConexionUseCase probarUseCase,
  })  : _getUseCase = getUseCase,
        _updateUseCase = updateUseCase,
        _probarUseCase = probarUseCase,
        super(const ConfiguracionFacturacionInitial());

  Future<void> cargar() async {
    emit(const ConfiguracionFacturacionLoading());
    final result = await _getUseCase();
    if (isClosed) return;

    if (result is Success<ConfiguracionFacturacion>) {
      emit(ConfiguracionFacturacionLoaded(
        original: result.data,
        editada: result.data,
      ));
    } else if (result is Error<ConfiguracionFacturacion>) {
      emit(ConfiguracionFacturacionError(result.message));
    }
  }

  // ── Edición en memoria ──

  void cambiarProveedor(ProveedorFacturacion proveedor) {
    final s = _loaded;
    if (s == null) return;
    final urlDefault = proveedor.defaultUrl(s.editada.entorno);
    // Al cambiar de proveedor: limpiar token y ajustar URL al default si hay.
    // También limpiar proveedorConfig porque es específico del proveedor.
    final nueva = s.editada.copyWith(
      proveedorActivo: proveedor,
      proveedorRuta: urlDefault.isNotEmpty ? urlDefault : s.editada.proveedorRuta,
      proveedorToken: '',
      proveedorConfig: proveedor.requiereCompanyBranch ? <String, dynamic>{} : null,
    );
    emit(s.copyWith(editada: nueva, limpiarResultadoPrueba: true));
  }

  void cambiarEntorno(EntornoFacturacion entorno) {
    final s = _loaded;
    if (s == null) return;
    final urlDefault = s.editada.proveedorActivo.defaultUrl(entorno);
    final nueva = s.editada.copyWith(
      entorno: entorno,
      proveedorRuta: urlDefault.isNotEmpty ? urlDefault : s.editada.proveedorRuta,
    );
    emit(s.copyWith(editada: nueva, limpiarResultadoPrueba: true));
  }

  void cambiarUrl(String url) {
    _editar((e) => e.copyWith(proveedorRuta: url));
  }

  void cambiarToken(String token) {
    _editar((e) => e.copyWith(proveedorToken: token));
  }

  void cambiarCompanyId(int? companyId) {
    _editarConfig((cfg) {
      if (companyId == null) {
        cfg.remove('companyId');
      } else {
        cfg['companyId'] = companyId;
      }
    });
  }

  void cambiarBranchId(int? branchId) {
    _editarConfig((cfg) {
      if (branchId == null) {
        cfg.remove('branchId');
      } else {
        cfg['branchId'] = branchId;
      }
    });
  }

  void cambiarFacturacionActiva(bool activa) {
    _editar((e) => e.copyWith(facturacionActiva: activa));
  }

  void cambiarEmailFacturacion(String? email) {
    _editar((e) => e.copyWith(emailFacturacion: email));
  }

  void cambiarResolucionSunat(String? resolucion) {
    _editar((e) => e.copyWith(resolucionSunat: resolucion));
  }

  void descartarCambios() {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(
      editada: s.original,
      limpiarResultadoPrueba: true,
      limpiarMensajeExito: true,
    ));
  }

  // ── Probar conexión ──

  Future<void> probarConexion() async {
    final s = _loaded;
    if (s == null) return;

    final url = (s.editada.proveedorRuta ?? '').trim();
    final token = (s.editada.proveedorToken ?? '').trim();
    if (url.isEmpty || token.isEmpty) {
      emit(s.copyWith(
        resultadoPrueba: ResultadoProbarConexion(
          ok: false,
          mensaje: 'Completa la URL y el token antes de probar.',
          proveedor: s.editada.proveedorActivo,
        ),
      ));
      return;
    }

    emit(s.copyWith(probando: true, limpiarResultadoPrueba: true));

    final result = await _probarUseCase(
      proveedorActivo: s.editada.proveedorActivo,
      proveedorRuta: url,
      proveedorToken: token,
      proveedorConfig: s.editada.proveedorConfig,
    );
    if (isClosed) return;

    final current = _loaded;
    if (current == null) return;

    if (result is Success<ResultadoProbarConexion>) {
      emit(current.copyWith(probando: false, resultadoPrueba: result.data));
    } else if (result is Error<ResultadoProbarConexion>) {
      emit(current.copyWith(
        probando: false,
        resultadoPrueba: ResultadoProbarConexion(
          ok: false,
          mensaje: 'Error al probar conexión',
          proveedor: current.editada.proveedorActivo,
          error: result.message,
        ),
      ));
    }
  }

  // ── Guardar ──

  Future<void> guardar() async {
    final s = _loaded;
    if (s == null || !s.tieneCambios) return;

    emit(s.copyWith(guardando: true, limpiarMensajeExito: true));

    final payload = _diffPayload(s.original, s.editada);
    final result = await _updateUseCase(payload);
    if (isClosed) return;

    final current = _loaded;
    if (current == null) return;

    if (result is Success<ConfiguracionFacturacion>) {
      emit(current.copyWith(
        original: result.data,
        editada: result.data,
        guardando: false,
        mensajeExito: current.cambioProveedor
            ? 'Proveedor actualizado. Recomendamos sincronizar series.'
            : 'Configuración guardada.',
      ));
    } else if (result is Error<ConfiguracionFacturacion>) {
      emit(current.copyWith(guardando: false));
      emit(ConfiguracionFacturacionError(result.message));
    }
  }

  // ── Helpers ──

  ConfiguracionFacturacionLoaded? get _loaded {
    final s = state;
    return s is ConfiguracionFacturacionLoaded ? s : null;
  }

  void _editar(
    ConfiguracionFacturacion Function(ConfiguracionFacturacion) mutator,
  ) {
    final s = _loaded;
    if (s == null) return;
    emit(s.copyWith(
      editada: mutator(s.editada),
      limpiarResultadoPrueba: true,
      limpiarMensajeExito: true,
    ));
  }

  void _editarConfig(void Function(Map<String, dynamic>) mutator) {
    final s = _loaded;
    if (s == null) return;
    final cfg = Map<String, dynamic>.from(s.editada.proveedorConfig ?? const {});
    mutator(cfg);
    emit(s.copyWith(
      editada: s.editada.copyWith(proveedorConfig: cfg),
      limpiarResultadoPrueba: true,
      limpiarMensajeExito: true,
    ));
  }

  /// Solo envía al backend los campos que realmente cambiaron.
  Map<String, dynamic> _diffPayload(
    ConfiguracionFacturacion antes,
    ConfiguracionFacturacion despues,
  ) {
    final payload = <String, dynamic>{};
    if (antes.proveedorActivo != despues.proveedorActivo) {
      payload['proveedorActivo'] = despues.proveedorActivo.value;
    }
    if (antes.proveedorRuta != despues.proveedorRuta) {
      payload['proveedorRuta'] = despues.proveedorRuta;
    }
    if (antes.proveedorToken != despues.proveedorToken) {
      payload['proveedorToken'] = despues.proveedorToken;
    }
    if (_configChanged(antes.proveedorConfig, despues.proveedorConfig)) {
      payload['proveedorConfig'] = despues.proveedorConfig ?? <String, dynamic>{};
    }
    if (antes.facturacionActiva != despues.facturacionActiva) {
      payload['facturacionActiva'] = despues.facturacionActiva;
    }
    if (antes.entorno != despues.entorno) {
      payload['entorno'] = despues.entorno.value;
    }
    if (antes.emailFacturacion != despues.emailFacturacion) {
      payload['emailFacturacion'] = despues.emailFacturacion;
    }
    if (antes.resolucionSunat != despues.resolucionSunat) {
      payload['resolucionSunat'] = despues.resolucionSunat;
    }
    return payload;
  }

  bool _configChanged(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return false;
    if (a == null || b == null) return true;
    if (a.length != b.length) return true;
    for (final entry in a.entries) {
      if (b[entry.key] != entry.value) return true;
    }
    return false;
  }
}
