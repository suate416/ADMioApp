// Servicio para obtener estaciones filtradas por sucursal o por usuario
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/orden.model.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class EstacionService {
  final StorageService _storageService = StorageService();
  
  Future<String?> _getToken() async {
    return await _storageService.getToken();
  }

  Future<List<Estacion>> getEstacionesBySucursal(int sucursalId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estacionesEndpoint}/sucursal/$sucursalId');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .where((json) => (json as Map<String, dynamic>)['activo'] == true)
          .map((json) => Estacion.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al obtener las estaciones');
    }
  }

  Future<List<Estacion>> getEstacionesByUsuario(int usuarioId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.estacionesEndpoint}/usuario/$usuarioId');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data
          .where((json) => (json as Map<String, dynamic>)['activo'] == true)
          .map((json) => Estacion.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al obtener las estaciones del usuario');
    }
  }
}

