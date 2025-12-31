// Modelo de datos para Servicio con información de precio (base y total), duración estimada y estado activo
import 'dart:convert';

Servicio servicioFromJson(String str) => Servicio.fromJson(json.decode(str));
List<Servicio> servicioListFromJson(String str) => List<Servicio>.from(json.decode(str).map((x) => Servicio.fromJson(x)));
String servicioToJson(Servicio data) => json.encode(data.toJson());

class Servicio {
  int id;
  int negocioId;
  String nombre;
  String? codigo;
  String? descripcion;
  int? duracionEstimada;
  double precioBase;
  double precioTotal;
  bool activo;

  Servicio({
    required this.id,
    required this.negocioId,
    required this.nombre,
    this.codigo,
    this.descripcion,
    this.duracionEstimada,
    required this.precioBase,
    required this.precioTotal,
    required this.activo,
  });

  factory Servicio.fromJson(Map<String, dynamic> json) => Servicio(
        id: _parseInt(json["id"]),
        negocioId: _parseInt(json["negocio_id"]),
        nombre: json["nombre"].toString(),
        codigo: json["codigo"]?.toString(),
        descripcion: json["descripcion"]?.toString(),
        duracionEstimada: json["duracion_estimada"] != null ? _parseInt(json["duracion_estimada"]) : null,
        precioBase: _parseDouble(json["precio_base"]),
        precioTotal: _parseDouble(json["precio_total"]),
        activo: json["activo"] as bool? ?? true,
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
        "negocio_id": negocioId,
        "nombre": nombre,
        "codigo": codigo,
        "descripcion": descripcion,
        "duracion_estimada": duracionEstimada,
        "precio_base": precioBase,
        "precio_total": precioTotal,
        "activo": activo,
      };
}

