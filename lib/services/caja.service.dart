// Servicio para verificar si hay cajas abiertas y obtener cajas abiertas por sucursal
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/storage_service.dart';
import '../services/auth_service.dart';

class CajaService {
  final StorageService _storageService = StorageService();
  final AuthService _authService = AuthService();
  
  Future<String?> _getToken() async {
    return await _storageService.getToken();
  }

  /// Verifica si hay una caja abierta para la sucursal especificada
  Future<bool> verificarCajaAbiertaPorSucursal(int sucursalId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    try {
      // Obtener todas las cajas abiertas
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cajasEndpoint}/abiertas');
      
      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      // Verificar si hay error de autenticación
      await _authService.checkAuthError(response);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        // Verificar si hay alguna caja abierta para esta sucursal
        for (var caja in data) {
          if (caja['surcusal_id'] == sucursalId && caja['abierta'] == true) {
            return true;
          }
        }
        return false;
      } else {
        // Si hay error, asumimos que no hay caja abierta
        return false;
      }
    } catch (e) {
      // Si hay error al verificar, retornamos false
      return false;
    }
  }

  /// Obtiene las cajas abiertas de una sucursal específica
  Future<List<Map<String, dynamic>>> getCajasAbiertasBySucursal(int sucursalId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.cajasEndpoint}/sucursal/$sucursalId');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    // Verificar si hay error de autenticación
    await _authService.checkAuthError(response);

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      
      // Filtrar solo las cajas abiertas
      return data
          .where((caja) => caja['abierta'] == true)
          .map((caja) => caja as Map<String, dynamic>)
          .toList();
    } else {
      throw Exception('Error al obtener las cajas de la sucursal');
    }
  }
}

