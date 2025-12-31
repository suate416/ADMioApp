// Servicio de almacenamiento local usando SharedPreferences: guarda/recupera token de autenticación, datos del usuario actual y lista de usuarios guardados para selección rápida
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/usuario.model.dart';

class StorageService {
  static const String _tokenKey = 'auth_token';
  static const String _usuarioKey = 'usuario_data';
  static const String _isLoggedInKey = 'is_logged_in';
  static const String _usuariosGuardadosKey = 'usuarios_guardados';

  /// Guarda el token de autenticación
  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  /// Obtiene el token de autenticación
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Guarda los datos del usuario
  Future<void> saveUsuario(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usuarioKey, json.encode(usuario.toJson()));
    // Guardar en la lista de usuarios guardados
    await _agregarUsuarioGuardado(usuario);
  }

  /// Agrega un usuario a la lista de usuarios guardados (sin duplicados)
  Future<void> _agregarUsuarioGuardado(Usuario usuario) async {
    final prefs = await SharedPreferences.getInstance();
    final usuariosGuardados = await getUsuariosGuardados();
    
    // Verificar si el usuario ya existe
    final existe = usuariosGuardados.any((u) => u.id == usuario.id);
    if (!existe) {
      usuariosGuardados.add(usuario);
      final usuariosJson = json.encode(usuariosGuardados.map((u) => u.toJson()).toList());
      await prefs.setString(_usuariosGuardadosKey, usuariosJson);
    }
  }

  /// Obtiene la lista de usuarios guardados
  Future<List<Usuario>> getUsuariosGuardados() async {
    final prefs = await SharedPreferences.getInstance();
    final usuariosJson = prefs.getString(_usuariosGuardadosKey);
    if (usuariosJson != null) {
      try {
        final List<dynamic> usuariosList = json.decode(usuariosJson);
        return usuariosList.map((u) => Usuario.fromJson(u as Map<String, dynamic>)).toList();
      } catch (e) {
        return [];
      }
    }
    return [];
  }

  /// Elimina un usuario de la lista de usuarios guardados
  Future<void> eliminarUsuarioGuardado(int usuarioId) async {
    final prefs = await SharedPreferences.getInstance();
    final usuariosGuardados = await getUsuariosGuardados();
    usuariosGuardados.removeWhere((u) => u.id == usuarioId);
    final usuariosJson = json.encode(usuariosGuardados.map((u) => u.toJson()).toList());
    await prefs.setString(_usuariosGuardadosKey, usuariosJson);
  }

  /// Obtiene los datos del usuario guardados
  Future<Usuario?> getUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuarioJson = prefs.getString(_usuarioKey);
    if (usuarioJson != null) {
      return Usuario.fromJson(json.decode(usuarioJson));
    }
    return null;
  }

  /// Verifica si el usuario está logueado (solo verifica si existe token)
  /// Nota: La validación real del token se hace en AuthService.isLoggedIn()
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_tokenKey);
    // Solo retornar true si existe token, pero la validación real se hace en AuthService
    return token != null && token.isNotEmpty;
  }

  /// Limpia todos los datos de autenticación
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_usuarioKey);
    await prefs.remove(_isLoggedInKey);
    // No eliminamos los usuarios guardados para permitir selección rápida
  }
}

