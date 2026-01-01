import 'package:flutter_test/flutter_test.dart';
import 'package:syncronize/core/utils/log_sanitizer.dart';

void main() {
  group('LogSanitizer', () {
    group('sanitizeHeaders', () {
      test('debe sanitizar header Authorization', () {
        final headers = {
          'Authorization': 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.signature',
          'Content-Type': 'application/json',
        };

        final sanitized = LogSanitizer.sanitizeHeaders(headers);

        expect(sanitized!['Authorization'], equals('***REDACTED***'));
        expect(sanitized['Content-Type'], equals('application/json'));
      });

      test('debe sanitizar múltiples headers sensibles', () {
        final headers = {
          'Authorization': 'Bearer token123',
          'X-API-Key': 'secret-api-key',
          'Cookie': 'session=abc123',
          'User-Agent': 'MyApp/1.0',
        };

        final sanitized = LogSanitizer.sanitizeHeaders(headers);

        expect(sanitized!['Authorization'], equals('***REDACTED***'));
        expect(sanitized['X-API-Key'], equals('***REDACTED***'));
        expect(sanitized['Cookie'], equals('***REDACTED***'));
        expect(sanitized['User-Agent'], equals('MyApp/1.0'));
      });

      test('debe retornar null si headers es null', () {
        final sanitized = LogSanitizer.sanitizeHeaders(null);
        expect(sanitized, isNull);
      });
    });

    group('sanitizeBody', () {
      test('debe sanitizar campos de contraseña en Map', () {
        final body = {
          'email': 'user@example.com',
          'password': 'MySecretPassword123!',
          'nombre': 'Juan',
        };

        final sanitized = LogSanitizer.sanitizeBody(body) as Map<String, dynamic>;

        expect(sanitized['email'], equals('user@example.com'));
        expect(sanitized['password'], equals('***REDACTED***'));
        expect(sanitized['nombre'], equals('Juan'));
      });

      test('debe sanitizar tokens en Map', () {
        final body = {
          'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.sig',
          'refreshToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh.sig',
          'userId': '123',
        };

        final sanitized = LogSanitizer.sanitizeBody(body) as Map<String, dynamic>;

        expect(sanitized['accessToken'], equals('***REDACTED***'));
        expect(sanitized['refreshToken'], equals('***REDACTED***'));
        expect(sanitized['userId'], equals('123'));
      });

      test('debe sanitizar recursivamente Maps anidados', () {
        final body = {
          'user': {
            'email': 'user@example.com',
            'credentials': {
              'password': 'secret123',
              'apiKey': 'my-secret-api-key',
            },
          },
          'timestamp': '2023-01-01',
        };

        final sanitized = LogSanitizer.sanitizeBody(body) as Map<String, dynamic>;
        final user = sanitized['user'] as Map<String, dynamic>;
        final credentials = user['credentials'] as Map<String, dynamic>;

        expect(user['email'], equals('user@example.com'));
        expect(credentials['password'], equals('***REDACTED***'));
        expect(credentials['apiKey'], equals('***REDACTED***'));
        expect(sanitized['timestamp'], equals('2023-01-01'));
      });

      test('debe sanitizar Lists con Maps', () {
        final body = [
          {'password': 'secret1', 'name': 'User1'},
          {'password': 'secret2', 'name': 'User2'},
        ];

        final sanitized = LogSanitizer.sanitizeBody(body) as List;
        final first = sanitized[0] as Map<String, dynamic>;
        final second = sanitized[1] as Map<String, dynamic>;

        expect(first['password'], equals('***REDACTED***'));
        expect(first['name'], equals('User1'));
        expect(second['password'], equals('***REDACTED***'));
        expect(second['name'], equals('User2'));
      });

      test('debe retornar null si body es null', () {
        final sanitized = LogSanitizer.sanitizeBody(null);
        expect(sanitized, isNull);
      });
    });

    group('sanitizeErrorMessage', () {
      test('debe sanitizar JWT tokens en mensajes', () {
        final message =
            'Invalid token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature';

        final sanitized = LogSanitizer.sanitizeErrorMessage(message);

        expect(sanitized, equals('Invalid token: ***REDACTED***'));
      });

      test('debe sanitizar Bearer tokens en mensajes', () {
        final message = 'Authorization failed for Bearer eyJhbGc.test.sig';

        final sanitized = LogSanitizer.sanitizeErrorMessage(message);

        expect(sanitized, contains('Bearer ***REDACTED***'));
      });

      test('debe mantener mensajes sin tokens intactos', () {
        final message = 'Error de conexión al servidor';

        final sanitized = LogSanitizer.sanitizeErrorMessage(message);

        expect(sanitized, equals(message));
      });
    });

    group('sanitizeUrl', () {
      test('debe sanitizar tokens en query parameters', () {
        final url =
            'https://api.example.com/verify?token=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.test.sig&email=user@test.com';

        final sanitized = LogSanitizer.sanitizeUrl(url);

        expect(sanitized, contains('token=***REDACTED***'));
        expect(sanitized, contains('email=user@test.com'));
      });

      test('debe sanitizar claves API en query parameters', () {
        final url = 'https://api.example.com/data?apiKey=secret123&limit=10';

        final sanitized = LogSanitizer.sanitizeUrl(url);

        expect(sanitized, contains('apiKey=***REDACTED***'));
        expect(sanitized, contains('limit=10'));
      });

      test('debe retornar URL intacta si no tiene params sensibles', () {
        final url = 'https://api.example.com/users?page=1&limit=10';

        final sanitized = LogSanitizer.sanitizeUrl(url);

        expect(sanitized, equals(url));
      });
    });

    group('sanitizeQueryParams', () {
      test('debe sanitizar parámetros sensibles', () {
        final params = {
          'token': 'secret-token-123',
          'page': '1',
          'password': 'mypassword',
        };

        final sanitized = LogSanitizer.sanitizeQueryParams(params);

        expect(sanitized!['token'], equals('***REDACTED***'));
        expect(sanitized['page'], equals('1'));
        expect(sanitized['password'], equals('***REDACTED***'));
      });

      test('debe retornar null si params es null', () {
        final sanitized = LogSanitizer.sanitizeQueryParams(null);
        expect(sanitized, isNull);
      });
    });

    group('isSensitiveValue', () {
      test('debe detectar JWT tokens', () {
        final jwtToken =
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.signature';

        expect(LogSanitizer.isSensitiveValue(jwtToken), isTrue);
      });

      test('debe detectar Bearer tokens', () {
        final bearerToken = 'Bearer eyJhbGc.test.sig';

        expect(LogSanitizer.isSensitiveValue(bearerToken), isTrue);
      });

      test('debe detectar API keys largas', () {
        final apiKey = 'a' * 40; // String largo alfanumérico

        expect(LogSanitizer.isSensitiveValue(apiKey), isTrue);
      });

      test('no debe detectar strings normales como sensibles', () {
        expect(LogSanitizer.isSensitiveValue('user@example.com'), isFalse);
        expect(LogSanitizer.isSensitiveValue('Juan Pérez'), isFalse);
        expect(LogSanitizer.isSensitiveValue('123456'), isFalse);
      });
    });

    group('Casos de uso reales', () {
      test('debe sanitizar respuesta de login completa', () {
        final loginResponse = {
          'user': {
            'id': '123',
            'email': 'user@example.com',
            'nombre': 'Juan',
          },
          'accessToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.access.sig',
          'refreshToken': 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.refresh.sig',
          'tenant': {
            'id': '456',
            'name': 'My Company',
          },
        };

        final sanitized =
            LogSanitizer.sanitizeBody(loginResponse) as Map<String, dynamic>;

        expect(sanitized['accessToken'], equals('***REDACTED***'));
        expect(sanitized['refreshToken'], equals('***REDACTED***'));
        final user = sanitized['user'] as Map<String, dynamic>;
        expect(user['email'], equals('user@example.com'));
        final tenant = sanitized['tenant'] as Map<String, dynamic>;
        expect(tenant['name'], equals('My Company'));
      });

      test('debe sanitizar request de registro completo', () {
        final registerRequest = {
          'email': 'newuser@example.com',
          'password': 'MySecretPassword123!',
          'confirmPassword': 'MySecretPassword123!',
          'nombres': 'Juan',
          'apellidos': 'Pérez',
          'telefono': '+1234567890',
        };

        final sanitized =
            LogSanitizer.sanitizeBody(registerRequest) as Map<String, dynamic>;

        expect(sanitized['password'], equals('***REDACTED***'));
        expect(sanitized['confirmPassword'], equals('***REDACTED***'));
        expect(sanitized['email'], equals('newuser@example.com'));
        expect(sanitized['nombres'], equals('Juan'));
        expect(sanitized['telefono'], equals('+1234567890'));
      });

      test('debe sanitizar error con token expirado', () {
        final errorMessage =
            'Token expired: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.expired.sig. Please login again.';

        final sanitized = LogSanitizer.sanitizeErrorMessage(errorMessage);

        expect(sanitized, contains('Token expired: ***REDACTED***'));
        expect(sanitized, contains('Please login again'));
      });
    });
  });
}
