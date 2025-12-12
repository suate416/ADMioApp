import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/negocio.model.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class NegocioService {
  final StorageService _storageService = StorageService();
  
  Future<String?> _getToken() async {
    return await _storageService.getToken();
  }

  /// Obtiene todos los negocios
  Future<List<Negocios>> getNegocios() async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.negociosEndpoint}');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      
      // Caso 1: el backend devuelve directamente una lista de negocios
      if (decoded is List) {
        return decoded
            .map((json) => Negocios.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Caso 2: el backend devuelve un objeto con { success, data }
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          final List<dynamic> data = decoded['data'] as List<dynamic>;
          return data
              .map((json) => Negocios.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        // Si viene success=false con message, propagar ese mensaje
        if (decoded['success'] == false && decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      }

      // Si llega aquí, el formato no es el esperado
      throw Exception('Formato de respuesta inválido al obtener los negocios');
    } else {
      // Intentar extraer mensaje de error del backend
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      } catch (_) {
        // Ignorar error de parseo y lanzar mensaje genérico
      }
      throw Exception('Error al obtener los negocios (código ${response.statusCode})');
    }
  }

  /// Obtiene un negocio por su ID
  Future<Negocios> getNegocioById(int id) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.negociosEndpoint}/$id');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);
      
      // Caso 1: el backend devuelve directamente el negocio
      if (decoded is Map<String, dynamic> && decoded['id'] != null) {
        return Negocios.fromJson(decoded);
      }

      // Caso 2: el backend devuelve un objeto con { success, data }
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] != null) {
          return Negocios.fromJson(decoded['data'] as Map<String, dynamic>);
        }

        // Si viene success=false con message, propagar ese mensaje
        if (decoded['success'] == false && decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      }

      // Si llega aquí, el formato no es el esperado
      throw Exception('Formato de respuesta inválido al obtener el negocio');
    } else {
      // Intentar extraer mensaje de error del backend
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic> && decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      } catch (_) {
        // Ignorar error de parseo y lanzar mensaje genérico
      }
      throw Exception('Error al obtener el negocio (código ${response.statusCode})');
    }
  }
}

