import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/environment/env_config.dart';
import '../constants/api_constants.dart';

/// Módulo para registrar dependencias externas (third-party)
@module
abstract class RegisterModule {
  @preResolve
  Future<SharedPreferences> get prefs => SharedPreferences.getInstance();

  @lazySingleton
  FlutterSecureStorage get secureStorage => const FlutterSecureStorage(
        aOptions: AndroidOptions(
          encryptedSharedPreferences: true,
        ),
      );

  @lazySingleton
  Connectivity get connectivity => Connectivity();

  @lazySingleton
  Dio get dio => Dio();

  /// Dio dedicado para refresh token (sin interceptores para evitar loops)
  @Named('authDio')
  @lazySingleton
  Dio get authDio => Dio(
        BaseOptions(
          baseUrl: EnvConfig.baseUrl,
          connectTimeout: ApiConstants.connectTimeout,
          receiveTimeout: ApiConstants.receiveTimeout,
          headers: {
            ApiConstants.contentType: 'application/json',
            ApiConstants.accept: 'application/json',
          },
        ),
      );
}
