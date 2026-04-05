/// Constantes relacionadas con la API
class ApiConstants {
  ApiConstants._();

  // Endpoints de autenticación
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String googleSignIn = '/auth/google';
  static const String logout = '/auth/logout';
  static const String refreshToken = '/auth/refresh';
  static const String changePassword = '/auth/change-password';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String verifyEmail = '/auth/verify-email';
  static const String resendVerificationEmail = '/auth/resend-verification-email';
  static const String profile = '/auth/profile';
  static const String updateProfile = '/auth/profile';
  static const String sessions = '/auth/sessions';

  // Multi-method auth
  static const String checkAuthMethods = '/auth/methods';
  static const String setPassword = '/auth/set-password';

  // Endpoints de empresas
  static const String empresas = '/empresas';

  // Endpoints de productos
  static const String productos = '/productos';
  static const String productoBulkUploadTemplate = '/productos/bulk-upload/template';
  static const String productoBulkUpload = '/productos/bulk-upload';

  // Endpoints de plantillas de atributos
  static const String plantillasAtributos = '/producto-atributo-plantillas';

  // Endpoints de configuraciones de precios
  static const String configuracionesPrecios = '/configuraciones-precio';

  // Endpoints de combos
  static const String combos = '/combos';

  // Endpoints de catálogos
  static const String catalogos = '/catalogos';

  // Endpoints de clientes
  static const String clientes = '/clientes';
  static const String clientesEmpresa = '/clientes-empresa';

  // Endpoints de usuarios/empleados
  static const String usuarios = '/usuarios';

  // Endpoints de políticas de descuento
  static const String politicasDescuento = '/politicas-descuento';

  // Endpoints de cotizaciones
  static const String cotizaciones = '/cotizaciones';

  // Endpoints de configuración de códigos
  static const String configuracionCodigos = '/configuracion-codigos';

  // Endpoints de configuracion de documentos
  static const String configuracionDocumentos = '/configuracion-documentos';

  // Endpoints de servicios
  static const String servicios = '/servicios';
  static const String configuracionCamposServicio = '/configuracion-campos-servicio';
  static const String ordenesServicio = '/ordenes-servicio';
  static const String plantillasServicio = '/plantillas-servicio';

  // Endpoints de avisos de mantenimiento
  static const String avisosMantenimiento = '/avisos-mantenimiento';

  // Endpoints de componentes
  static const String componentes = '/componentes';
  static const String tiposComponente = '/tipos-componente';

  // Endpoints de tercerización B2B
  static const String tercerizacion = '/tercerizacion';

  // Endpoints de vinculación B2B
  static const String vinculacion = '/vinculacion';

  // Endpoints de citas
  static const String citas = '/citas';

  // Endpoints de notificaciones
  static const String notificaciones = '/notificaciones';

  // Endpoints de promociones
  static const String promociones = '/promociones';

  // Endpoints de direcciones
  static const String misDirecciones = '/mis-direcciones';

  // Endpoints de marketplace usuario
  static const String marketplaceUsuario = '/marketplace/usuario';

  // Endpoints de marketplace (público)
  static const String marketplaceProductos = '/marketplace/productos';
  static const String marketplaceCategorias = '/marketplace/categorias';
  static const String marketplaceEmpresas = '/marketplace/empresas';

  // Endpoints de consultas externas (SUNAT/RENIEC)
  static const String consultaRuc = '/consultas/ruc';
  static const String consultaDni = '/consultas/dni';

  // Endpoints de pagos de suscripcion
  static const String pagosSuscripcion = '/pagos-suscripcion';

  // Endpoints de configuracion del sistema
  static const String configuracionSistemaPublica = '/configuracion-sistema/publica';

  // Headers
  static const String authorization = 'Authorization';
  static const String contentType = 'Content-Type';
  static const String accept = 'Accept';
  static const String tenantId = 'x-tenant-id'; // Debe coincidir EXACTAMENTE con el backend (case-sensitive)


  // Timeout
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
