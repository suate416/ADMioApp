import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/paquete.model.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class PaqueteService {
  final StorageService _storageService = StorageService();
  
  Future<String?> _getToken() async {
    return await _storageService.getToken();
  }

  Future<List<Paquete>> getPaquetesByNegocio(int negocioId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.paquetesEndpoint}/negocio/$negocioId');
    
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
          .map((json) => Paquete.fromJson(json as Map<String, dynamic>))
          .toList();
    } else {
      throw Exception('Error al obtener los paquetes');
    }
  }
}

