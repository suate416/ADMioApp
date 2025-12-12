import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/orden_detalle.model.dart';
import '../config/api_config.dart';
import '../services/storage_service.dart';

class OrdenDetalleService {
  final StorageService _storageService = StorageService();
  
  Future<String?> _getToken() async {
    return await _storageService.getToken();
  }

  Future<OrdenDetalle> createOrdenDetalle({
    required int ordenId,
    int? servicioId,
    int? paqueteId,
    List<int>? extras,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    if (servicioId == null && paqueteId == null) {
      throw Exception('Debe proporcionar servicio_id o paquete_id');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesDetallesEndpoint}');
    
    final body = <String, dynamic>{
      'orden_id': ordenId,
    };

    if (servicioId != null) {
      body['servicio_id'] = servicioId;
    }
    if (paqueteId != null) {
      body['paquete_id'] = paqueteId;
    }
    if (extras != null && extras.isNotEmpty) {
      body['extras'] = extras;
    }
    
    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body) as Map<String, dynamic>;
      if (responseData['success'] == true && responseData['data'] != null) {
        return OrdenDetalle.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw Exception(responseData['message'] ?? 'Error al crear el detalle');
    } else {
      final responseData = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(responseData?['message'] ?? 'Error al crear el detalle');
    }
  }

  Future<List<OrdenDetalle>> getOrdenesDetallesByOrden(int ordenId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesDetallesEndpoint}/orden/$ordenId');
    
    final response = await http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final dynamic decoded = json.decode(response.body);

      // Caso 1: el backend devuelve directamente una lista de detalles
      if (decoded is List) {
        return decoded
            .map((json) => OrdenDetalle.fromJson(json as Map<String, dynamic>))
            .toList();
      }

      // Caso 2: el backend devuelve un objeto con { success, data }
      if (decoded is Map<String, dynamic>) {
        if (decoded['data'] is List) {
          final List<dynamic> data = decoded['data'] as List<dynamic>;
          return data
              .map((json) => OrdenDetalle.fromJson(json as Map<String, dynamic>))
              .toList();
        }

        // Si viene success=false con message, propagar ese mensaje
        if (decoded['success'] == false && decoded['message'] != null) {
          throw Exception(decoded['message']);
        }
      }

      // Si llega aquí, el formato no es el esperado
      throw Exception('Formato de respuesta inválido al obtener los detalles');
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
      throw Exception('Error al obtener los detalles (código ${response.statusCode})');
    }
  }

  Future<OrdenDetalle> updateEstadoOrdenDetalle({
    required int ordenDetalleId,
    required String estado,
  }) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    // Validar que el estado sea uno de los permitidos
    if (!['en_proceso', 'completado', 'cancelado'].contains(estado)) {
      throw Exception('Estado inválido. Debe ser: en_proceso, completado o cancelado');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ordenesDetallesEndpoint}/$ordenDetalleId');
    
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
        return OrdenDetalle.fromJson(responseData['data'] as Map<String, dynamic>);
      }
      throw Exception(responseData['message'] ?? 'Error al actualizar el estado del detalle');
    } else {
      final responseData = json.decode(response.body) as Map<String, dynamic>?;
      throw Exception(responseData?['message'] ?? 'Error al actualizar el estado del detalle');
    }
  }

  /// Cancela (soft delete) un detalle de orden.
  /// Marca el detalle como inactivo en el backend y recalcula subtotal/tiempo.
  Future<void> softDeleteOrdenDetalle(int ordenDetalleId) async {
    final token = await _getToken();
    if (token == null) {
      throw Exception('No hay token de autenticación');
    }

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.ordenesDetallesEndpoint}/$ordenDetalleId/soft-delete',
    );

    final response = await http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      Map<String, dynamic>? data;
      try {
        data = json.decode(response.body) as Map<String, dynamic>?;
      } catch (_) {}
      throw Exception(data?['message'] ?? 'Error al cancelar el detalle');
    }
  }
}

