import 'dart:convert';
import 'usuario.model.dart';

Orden ordenFromJson(String str) => Orden.fromJson(json.decode(str));
List<Orden> ordenListFromJson(String str) => List<Orden>.from(json.decode(str).map((x) => Orden.fromJson(x)));
String ordenToJson(Orden data) => json.encode(data.toJson());

class Orden {
  int id;
  int sucursalId;
  int estacionId;
  int usuarioId;
  DateTime fecha;
  String estado;
  double subtotal;
  int tiempoTotal;
  String? observaciones;
  bool activo;
  Estacion? estacion;
  Usuario? usuario;

  Orden({
    required this.id,
    required this.sucursalId,
    required this.estacionId,
    required this.usuarioId,
    required this.fecha,
    required this.estado,
    required this.subtotal,
    required this.tiempoTotal,
    this.observaciones,
    required this.activo,
    this.estacion,
    this.usuario,
  });

  factory Orden.fromJson(Map<String, dynamic> json) {
    return Orden(
      id: _parseInt(json["id"]),
      sucursalId: _parseInt(json["sucursal_id"]),
      estacionId: _parseInt(json["estacion_id"]),
      usuarioId: _parseInt(json["usuario_id"]),
      fecha: DateTime.parse(json["fecha"].toString()),
      estado: json["estado"].toString(),
      subtotal: _parseDouble(json["subtotal"] ?? json["sub_total"] ?? 0.0),
      tiempoTotal: _parseInt(json["tiempo_total"] ?? json["tiempoTotal"] ?? 0),
      observaciones: json["observaciones"]?.toString(),
      activo: json["activo"] as bool? ?? true,
      estacion: json["estacion"] != null
          ? Estacion.fromJson(json["estacion"] as Map<String, dynamic>)
          : null,
      usuario: json["usuario"] != null
          ? _parseUsuarioFromJson(json["usuario"] as Map<String, dynamic>)
          : null,
    );
  }

  // Helper para parsear double de forma segura (puede venir como num o string)
  static double _parseDouble(dynamic value) {
    if (value == null) {
      return 0.0;
    }
    
    // Si es double, retornar directamente
    if (value is double) {
      return value;
    }
    
    // Si es int, convertir a double
    if (value is int) {
      return value.toDouble();
    }
    
    // Si es String, intentar parsear
    if (value is String) {
      // Limpiar el string (quitar espacios, comas, etc.)
      final cleaned = value.trim().replaceAll(',', '');
      if (cleaned.isEmpty) {
        return 0.0;
      }
      try {
        return double.parse(cleaned);
      } catch (e) {
        return 0.0;
      }
    }
    
    // Si es num (cualquier número), convertir a double
    if (value is num) {
      return value.toDouble();
    }
    
    // Intentar convertir a string y luego parsear
    try {
      final stringValue = value.toString();
      final cleaned = stringValue.trim().replaceAll(',', '');
      if (cleaned.isNotEmpty) {
        return double.parse(cleaned);
      }
    } catch (e) {
      // Error al parsear, retornar 0.0
    }
    
    return 0.0;
  }

  // Helper para parsear int de forma segura
  static int _parseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      try {
        return int.parse(value);
      } catch (e) {
        return 0;
      }
    }
    if (value is num) return value.toInt();
    return 0;
  }

  Map<String, dynamic> toJson() => {
        "id": id,
        "sucursal_id": sucursalId,
        "estacion_id": estacionId,
        "usuario_id": usuarioId,
        "fecha": fecha.toIso8601String(),
        "estado": estado,
        "subtotal": subtotal,
        "tiempo_total": tiempoTotal,
        "observaciones": observaciones,
        "activo": activo,
      };
}

class Estacion {
  int id;
  String codigo;
  String? descripcion;

  Estacion({
    required this.id,
    required this.codigo,
    this.descripcion,
  });

  factory Estacion.fromJson(Map<String, dynamic> json) => Estacion(
        id: Orden._parseInt(json["id"]),
        codigo: json["codigo"].toString(),
        descripcion: json["descripcion"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "codigo": codigo,
        "descripcion": descripcion,
      };
}

// Helper para parsear Usuario desde JSON de orden (versión simplificada o completa)
Usuario _parseUsuarioFromJson(Map<String, dynamic> json) {
  try {
    // Intentar parsear como Usuario completo primero
    return Usuario.fromJson(json);
  } catch (e) {
    // Si falla, crear un Usuario con datos mínimos desde la versión simplificada
    // Esto maneja el caso donde el backend solo envía id, nombre, apellido, usuario_unico
    final usuarioJson = json;
    final now = DateTime.now();
    
    return Usuario(
      id: usuarioJson["id"] as int,
      negocioId: usuarioJson["negocio_id"] as int? ?? 0,
      sucursalId: usuarioJson["sucursal_id"] as int? ?? 0,
      rolId: usuarioJson["rol_id"] as int? ?? 0,
      nombre: usuarioJson["nombre"] as String? ?? "",
      apellido: usuarioJson["apellido"] as String? ?? "",
      usuarioUnico: usuarioJson["usuario_unico"] as String? ?? "",
      activo: usuarioJson["activo"] as bool? ?? true,
      ultimoAcceso: now,
      fechaRegistro: now,
      fechaActualizacion: now,
      rol: usuarioJson["rol"] != null
          ? Rol.fromJson(usuarioJson["rol"] as Map<String, dynamic>)
          : Rol(id: 0, nombre: "Sin rol", descripcion: ""),
      negocio: usuarioJson["negocio"] != null
          ? Negocio.fromJson(usuarioJson["negocio"] as Map<String, dynamic>)
          : Negocio(id: 0, nombre: "Sin negocio", nombreComercial: ""),
      sucursal: usuarioJson["sucursal"] != null
          ? Sucursal.fromJson(usuarioJson["sucursal"] as Map<String, dynamic>)
          : Sucursal(id: 0, nombre: "Sin sucursal", codigo: ""),
    );
  }
}

