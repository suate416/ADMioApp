import 'dart:convert';
import 'servicio.model.dart';

Paquete paqueteFromJson(String str) => Paquete.fromJson(json.decode(str));
List<Paquete> paqueteListFromJson(String str) => List<Paquete>.from(json.decode(str).map((x) => Paquete.fromJson(x)));
String paqueteToJson(Paquete data) => json.encode(data.toJson());

class Paquete {
  int id;
  int negocioId;
  String nombre;
  String? codigo;
  String? descripcion;
  double precioTotal;
  int? duracionTotal;
  bool activo;
  List<Servicio>? servicios;

  Paquete({
    required this.id,
    required this.negocioId,
    required this.nombre,
    this.codigo,
    this.descripcion,
    required this.precioTotal,
    this.duracionTotal,
    required this.activo,
    this.servicios,
  });

  factory Paquete.fromJson(Map<String, dynamic> json) => Paquete(
        id: _parseInt(json["id"]),
        negocioId: _parseInt(json["negocio_id"]),
        nombre: json["nombre"].toString(),
        codigo: json["codigo"]?.toString(),
        descripcion: json["descripcion"]?.toString(),
        precioTotal: _parseDouble(json["precio_total"]),
        duracionTotal: json["duracion_total"] != null ? _parseInt(json["duracion_total"]) : null,
        activo: json["activo"] as bool? ?? true,
        servicios: json["servicios"] != null
            ? List<Servicio>.from(
                (json["servicios"] as List).map((x) => Servicio.fromJson(x as Map<String, dynamic>)))
            : null,
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
        "precio_total": precioTotal,
        "duracion_total": duracionTotal,
        "activo": activo,
      };
}

