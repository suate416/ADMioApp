// Modelo de datos para OrdenDetalle con relación a Servicio/Paquete y getters para identificar tipo (servicio/paquete)
import 'dart:convert';
import 'servicio.model.dart';
import 'paquete.model.dart';

OrdenDetalle ordenDetalleFromJson(String str) => OrdenDetalle.fromJson(json.decode(str));
List<OrdenDetalle> ordenDetalleListFromJson(String str) => List<OrdenDetalle>.from(json.decode(str).map((x) => OrdenDetalle.fromJson(x)));
String ordenDetalleToJson(OrdenDetalle data) => json.encode(data.toJson());

class OrdenDetalle {
  int id;
  int ordenId;
  int? servicioId;
  int? paqueteId;
  String estado;
  double subtotal;
  bool activo;
  Servicio? servicio;
  Paquete? paquete;
  List<OrdenDetalleExtra>? extras;

  OrdenDetalle({
    required this.id,
    required this.ordenId,
    this.servicioId,
    this.paqueteId,
    required this.estado,
    required this.subtotal,
    required this.activo,
    this.servicio,
    this.paquete,
    this.extras,
  });

  factory OrdenDetalle.fromJson(Map<String, dynamic> json) => OrdenDetalle(
        id: _parseInt(json["id"]),
        ordenId: _parseInt(json["orden_id"]),
        servicioId: json["servicio_id"] != null ? _parseInt(json["servicio_id"]) : null,
        paqueteId: json["paquete_id"] != null ? _parseInt(json["paquete_id"]) : null,
        estado: json["estado"].toString(),
        subtotal: _parseDouble(json["subtotal"]),
        activo: json["activo"] as bool? ?? true,
        servicio: json["servicio"] != null
            ? Servicio.fromJson(json["servicio"] as Map<String, dynamic>)
            : null,
        paquete: json["paquete"] != null
            ? Paquete.fromJson(json["paquete"] as Map<String, dynamic>)
            : null,
        extras: json["extras"] != null
            ? List<OrdenDetalleExtra>.from(
                (json["extras"] as List).map((x) => OrdenDetalleExtra.fromJson(x)))
            : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "orden_id": ordenId,
        "servicio_id": servicioId,
        "paquete_id": paqueteId,
        "estado": estado,
        "subtotal": subtotal,
        "activo": activo,
      };

  String get nombre => servicio?.nombre ?? paquete?.nombre ?? 'Sin nombre';
  bool get esPaquete => paqueteId != null;
  bool get esServicio => servicioId != null;

  // Helper para parsear double de forma segura
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    if (value is num) return value.toDouble();
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
}

class OrdenDetalleExtra {
  int id;
  int ordenDetalleId;
  int servicioExtraId;
  ServicioExtra? servicioExtra;

  OrdenDetalleExtra({
    required this.id,
    required this.ordenDetalleId,
    required this.servicioExtraId,
    this.servicioExtra,
  });

  factory OrdenDetalleExtra.fromJson(Map<String, dynamic> json) => OrdenDetalleExtra(
        id: OrdenDetalle._parseInt(json["id"]),
        ordenDetalleId: OrdenDetalle._parseInt(json["orden_detalle_id"]),
        servicioExtraId: OrdenDetalle._parseInt(json["servicio_extra_id"]),
        servicioExtra: json["servicio_extra"] != null
            ? ServicioExtra.fromJson(json["servicio_extra"] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "orden_detalle_id": ordenDetalleId,
        "servicio_extra_id": servicioExtraId,
      };
}

class ServicioExtra {
  int id;
  String nombre;
  double precioAdicional;
  int? tiempoAdicional;

  ServicioExtra({
    required this.id,
    required this.nombre,
    required this.precioAdicional,
    this.tiempoAdicional,
  });

  factory ServicioExtra.fromJson(Map<String, dynamic> json) => ServicioExtra(
        id: OrdenDetalle._parseInt(json["id"]),
        nombre: json["nombre"].toString(),
        precioAdicional: _parseDouble(json["precio_adicional"]),
        tiempoAdicional: json["tiempo_adicional"] != null ? _parseInt(json["tiempo_adicional"]) : null,
      );

  // Helper para parsear double de forma segura
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      try {
        return double.parse(value);
      } catch (e) {
        return 0.0;
      }
    }
    if (value is num) return value.toDouble();
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
        "nombre": nombre,
        "precio_adicional": precioAdicional,
        "tiempo_adicional": tiempoAdicional,
      };
}

