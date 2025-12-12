import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/login_response.model.dart';
import '../models/usuario.model.dart';
import '../config/api_config.dart';
import 'storage_service.dart';

class AuthService {
  final StorageService _storageService = StorageService();

  /// Realiza el login del usuario
  /// 
  /// [usuario] - Usuario único del usuario
  /// [contrasenia] - contrasenia del usuario
  /// 
  /// Retorna un [LoginResponse] con los datos del usuario y el token
  Future<LoginResponse> login(String usuario, String contrasenia) async {
    try {
      // Construir la URL completa
      final url = '${ApiConfig.baseUrl}${ApiConfig.loginEndpoint}';
      final uri = Uri.parse(url);
      
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'usuario_unico': usuario,
          'contraseña': contrasenia,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final responseData = json.decode(response.body) as Map<String, dynamic>;
          
          // Verificar que la respuesta tenga la estructura esperada
          if (!responseData.containsKey('success')) {
            throw Exception('Respuesta del servidor inválida: falta campo "success"');
          }

          final loginResponse = LoginResponse.fromJson(responseData);
          
          // Verificar que el login fue exitoso
          if (!loginResponse.success) {
            final message = loginResponse.message ?? 'Error en el login';
            throw Exception(message);
          }
          
          // Guardar token y datos del usuario
          if (loginResponse.token != null) {
            await _storageService.saveToken(loginResponse.token!);
          }
          if (loginResponse.data != null) {
            await _storageService.saveUsuario(loginResponse.data!);
          }
          
          return loginResponse;
        } catch (e) {
          // Error al parsear la respuesta
          if (e.toString().contains('Exception:')) {
            rethrow;
          }
          throw Exception('Error al procesar la respuesta del servidor: ${e.toString()}');
        }
      } else {
        // Manejar otros códigos de estado
        Map<String, dynamic>? responseData;
        try {
          responseData = json.decode(response.body) as Map<String, dynamic>?;
        } catch (_) {
          // Si no se puede parsear el JSON, usar el mensaje por defecto
        }

        if (response.statusCode == 401) {
          final message = responseData?['message'] ?? 'Usuario o contraseña incorrectos';
          throw Exception(message);
        } else if (response.statusCode == 400) {
          final message = responseData?['message'] ?? 'Datos inválidos';
          throw Exception(message);
        } else if (response.statusCode == 404) {
          throw Exception('Servidor no encontrado');
        } else {
          final message = responseData?['message'] ?? 'Error del servidor';
          throw Exception('$message (${response.statusCode})');
        }
      }
    } on http.ClientException catch (e) {
      final errorString = e.toString();
      String mensajeError = 'No se pudo conectar al servidor.\n\n';
      
      // Mensajes de ayuda según el tipo de error
      if (errorString.contains('Connection refused') || errorString.contains('errno = 111')) {
        mensajeError += 'El servidor parece no estar corriendo o la URL es incorrecta.\n\n';
        mensajeError += 'URL actual: ${ApiConfig.baseUrl}\n\n';
        mensajeError += 'Verifica que:\n';
        mensajeError += '• El servidor backend esté ejecutándose en el puerto 3011\n';
        mensajeError += '• La URL base sea correcta según tu entorno:\n';
        mensajeError += '  - Android Emulator: http://10.0.2.2:3011\n';
        mensajeError += '  - iOS Simulator: http://localhost:3011\n';
        mensajeError += '  - Dispositivo físico: http://TU_IP_LOCAL:3011\n\n';
        mensajeError += 'Para cambiar la URL, edita: lib/config/api_config.dart';
      } else if (errorString.contains('Network is unreachable')) {
        mensajeError += 'No hay conexión de red disponible.';
      } else {
        mensajeError += 'Verifica tu conexión a internet y que el servidor esté accesible.';
      }
      
      throw Exception(mensajeError);
    } on FormatException catch (e) {
      throw Exception('Error al procesar la respuesta del servidor: formato inválido');
    } catch (e) {
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Error de conexión: ${e.toString()}');
    }
  }

  /// Cierra la sesión del usuario
  Future<void> logout() async {
    await _storageService.clearAuth();
  }

  /// Valida si el token actual es válido haciendo una petición al servidor
  Future<bool> validateToken() async {
    try {
      final token = await _storageService.getToken();
      if (token == null || token.isEmpty) {
        return false;
      }

      // Hacer una petición a un endpoint protegido para validar el token
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.negociosEndpoint}');
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Timeout al validar token');
        },
      );

      // Si el token es válido, el servidor retornará 200
      // Si el token expiró o es inválido, retornará 401
      if (response.statusCode == 200) {
        return true;
      } else if (response.statusCode == 401) {
        // Token inválido o expirado, limpiar datos
        await _storageService.clearAuth();
        return false;
      }
      // Otros códigos de estado, asumir que el token es válido pero hay otro problema
      return true;
    } on http.ClientException catch (e) {
      // Error de conexión: si hay token, asumir que es válido temporalmente
      // El usuario podrá seguir usando la app offline
      final token = await _storageService.getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      // Otros errores: si hay token, asumir que es válido temporalmente
      final token = await _storageService.getToken();
      return token != null && token.isNotEmpty;
    }
  }

  /// Verifica si el usuario está logueado (valida el token)
  Future<bool> isLoggedIn() async {
    final token = await _storageService.getToken();
    if (token == null || token.isEmpty) {
      return false;
    }
    
    // Validar que el token sea válido
    return await validateToken();
  }

  /// Obtiene el token de autenticación guardado
  Future<String?> getToken() async {
    return await _storageService.getToken();
  }

  /// Obtiene los datos del usuario guardados
  Future<Usuario?> getUsuario() async {
    return await _storageService.getUsuario();
  }
}