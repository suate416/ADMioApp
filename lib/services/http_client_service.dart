// Cliente HTTP centralizado que intercepta todas las peticiones, agrega token de autenticación automáticamente y maneja errores 401 redirigiendo al login
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import 'storage_service.dart';
import '../screens/login_screen.dart';

/// Cliente HTTP que intercepta todas las peticiones y maneja errores de autenticación
class HttpClientService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();

  /// Obtiene el token de autenticación
  Future<String?> _getToken() async {
    return await _storageService.getToken();
  }

  /// Maneja errores de autenticación y redirige al login si es necesario
  Future<void> _handleAuthError() async {
    // Limpiar datos de autenticación
    await _authService.logout();
    
    // Redirigir al login si hay un contexto de navegación disponible
    final context = navigatorKey.currentContext;
    if (context != null) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  /// Realiza una petición GET
  Future<http.Response> get(
    Uri url, {
    Map<String, String>? headers,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Agregar token si se requiere autenticación
    if (requireAuth) {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        await _handleAuthError();
        throw Exception('No hay token de autenticación');
      }
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    final response = await http.get(url, headers: requestHeaders);

    // Si el token expiró o es inválido, redirigir al login
    if (response.statusCode == 401 && requireAuth) {
      await _handleAuthError();
      throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }

    return response;
  }

  /// Realiza una petición POST
  Future<http.Response> post(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Agregar token si se requiere autenticación
    if (requireAuth) {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        await _handleAuthError();
        throw Exception('No hay token de autenticación');
      }
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    final response = await http.post(
      url,
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );

    // Si el token expiró o es inválido, redirigir al login
    if (response.statusCode == 401 && requireAuth) {
      await _handleAuthError();
      throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }

    return response;
  }

  /// Realiza una petición PUT
  Future<http.Response> put(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Agregar token si se requiere autenticación
    if (requireAuth) {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        await _handleAuthError();
        throw Exception('No hay token de autenticación');
      }
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    final response = await http.put(
      url,
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );

    // Si el token expiró o es inválido, redirigir al login
    if (response.statusCode == 401 && requireAuth) {
      await _handleAuthError();
      throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }

    return response;
  }

  /// Realiza una petición PATCH
  Future<http.Response> patch(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Agregar token si se requiere autenticación
    if (requireAuth) {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        await _handleAuthError();
        throw Exception('No hay token de autenticación');
      }
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    final response = await http.patch(
      url,
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );

    // Si el token expiró o es inválido, redirigir al login
    if (response.statusCode == 401 && requireAuth) {
      await _handleAuthError();
      throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }

    return response;
  }

  /// Realiza una petición DELETE
  Future<http.Response> delete(
    Uri url, {
    Map<String, String>? headers,
    Object? body,
    Encoding? encoding,
    bool requireAuth = true,
  }) async {
    final Map<String, String> requestHeaders = {
      'Content-Type': 'application/json',
      ...?headers,
    };

    // Agregar token si se requiere autenticación
    if (requireAuth) {
      final token = await _getToken();
      if (token == null || token.isEmpty) {
        await _handleAuthError();
        throw Exception('No hay token de autenticación');
      }
      requestHeaders['Authorization'] = 'Bearer $token';
    }

    final response = await http.delete(
      url,
      headers: requestHeaders,
      body: body,
      encoding: encoding,
    );

    // Si el token expiró o es inválido, redirigir al login
    if (response.statusCode == 401 && requireAuth) {
      await _handleAuthError();
      throw Exception('Sesión expirada. Por favor, inicia sesión nuevamente.');
    }

    return response;
  }
}

