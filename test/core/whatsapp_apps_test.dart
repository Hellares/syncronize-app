import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:syncronize/core/constants/storage_constants.dart';
import 'package:syncronize/core/di/injection_container.dart';
import 'package:syncronize/core/storage/local_storage_service.dart';
import 'package:syncronize/core/utils/whatsapp_apps.dart';

/// La preferencia de app existe para que quien siempre escribe desde Business
/// no tenga que corregir el selector en cada mensaje.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> conPreferencia(String? paquete) async {
    SharedPreferences.setMockInitialValues(
      paquete == null
          ? {}
          : {StorageConstants.appWhatsappPreferida: paquete},
    );
    final prefs = await SharedPreferences.getInstance();
    if (locator.isRegistered<LocalStorageService>()) {
      await locator.unregister<LocalStorageService>();
    }
    locator.registerSingleton<LocalStorageService>(LocalStorageService(prefs));
  }

  tearDown(() async {
    if (locator.isRegistered<LocalStorageService>()) {
      await locator.unregister<LocalStorageService>();
    }
  });

  group('appWhatsappPreferida', () {
    test('sin nada guardado manda la primera disponible', () async {
      await conPreferencia(null);

      expect(appWhatsappPreferida(AppWhatsapp.values), AppWhatsapp.normal);
    });

    test('🔴 con Business guardado, Business viene marcada', () async {
      await conPreferencia(AppWhatsapp.business.paquete);

      expect(appWhatsappPreferida(AppWhatsapp.values), AppWhatsapp.business);
    });

    test('la guardada que ya NO está instalada no gana', () async {
      // Desinstaló Business: preseleccionarla abriría una app que no está.
      await conPreferencia(AppWhatsapp.business.paquete);

      expect(
        appWhatsappPreferida(const [AppWhatsapp.normal]),
        AppWhatsapp.normal,
      );
    });

    test('sin apps disponibles no explota', () async {
      await conPreferencia(AppWhatsapp.business.paquete);

      expect(appWhatsappPreferida(const []), AppWhatsapp.normal);
    });

    test('🔴 sin storage registrado cae al default en vez de romper',
        () async {
      // Pasa en un test de widget, y pasaría en la app si el arranque fallara:
      // no poder leer la preferencia no puede impedir escribir un mensaje.
      if (locator.isRegistered<LocalStorageService>()) {
        await locator.unregister<LocalStorageService>();
      }

      expect(appWhatsappPreferida(AppWhatsapp.values), AppWhatsapp.normal);
    });
  });

  group('recordarAppWhatsapp', () {
    test('lo elegido se lee en la siguiente apertura', () async {
      await conPreferencia(null);
      expect(appWhatsappPreferida(AppWhatsapp.values), AppWhatsapp.normal);

      await recordarAppWhatsapp(AppWhatsapp.business);

      expect(appWhatsappPreferida(AppWhatsapp.values), AppWhatsapp.business);
    });
  });
}
