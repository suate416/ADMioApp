import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/orden.model.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class OrdenService {
  final StorageService _storageService = StorageService();
  
  Future<String?> _getToken() async {
    return await _storageService.getToken();
  }

  Future<Orden> createOrden({
    required int sucursalId,
    required int estacionId,
    String? observaciones,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesEndpoint}');
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode({
        'sucursal_id': sucursalId,
        'estacion_id': estacionId,
        'estado': 'en_proceso',
        'subtotal': 0.0,
        'observaciones': observaciones,
      }),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      
      if (responseData['success'] == true && responseData['data'] != null) {
        final ordenData = responseData['data'] as Map<String, dynamic>;
        return Orden.fromJson(ordenData);
      }
      throw Exception(responseData['message'] ?? 'Error al crear la orden');
    } else {
      final responseData = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(responseData?['message'] ?? 'Error al crear la orden');
    }
  }

  Future<List<Orden>> getOrdenesBySucursal(int sucursalId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesEndpoint}/sucursal/$sucursalId');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Orden.fromJson(json as Map<String, dynamic>)).toList();
    } else {
      throw Exception('Error al obtener las órdenes');
    }
  }

  Future<Orden> getOrdenById(int id) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesEndpoint}/$id');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return Orden.fromJson(json.decode(response.body) as Map<String, dynamic>);
    } else {
      throw Exception('Error al obtener la orden');
    }
  }

  Future<Orden> updateEstadoOrden({
    required int ordenId,
    required String estado,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    // Validar que el estado sea uno de los permitidos
    if (!['pendiente', 'en_proceso', 'completada', 'cancelada', 'facturada'].contains(estado)) {
      throw Exception('Estado inválido. Debe ser: pendiente, en_proceso, completada, cancelada o facturada');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesEndpoint}/$ordenId');
    
    final body = <String, dynamic>{
      'estado': estado,
    };
    
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return Orden.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw Exception(responseData['message'] ?? 'Error al actualizar el estado de la orden');
    } else {
      final responseData = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(responseData?['message'] ?? 'Error al actualizar el estado de la orden');
    }
  }

  Future<Orden> updateObservacionesOrden({
    required int ordenId,
    required String observaciones,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesEndpoint}/$ordenId');
    
    final body = <String, dynamic>{
      'observaciones': observaciones,
    };
    
    final response = await http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return Orden.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw Exception(responseData['message'] ?? 'Error al actualizar las observaciones');
    } else {
      final responseData = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(responseData?['message'] ?? 'Error al actualizar las observaciones');
    }
  }

  Future<void> deleteOrden(int ordenId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesEndpoint}/$ordenId');
    
    final response = await http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      if (responseData['success'] == true) {
        return;
      }
      throw Exception(responseData['message'] ?? 'Error al eliminar la orden');
    } else {
      final responseData = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(responseData?['message'] ?? 'Error al eliminar la orden');
    }
  }
}

