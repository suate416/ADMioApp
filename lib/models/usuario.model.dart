// To parse this JSON data, do
//
//     final usuario = usuarioFromJson(jsonString);

import 'dart:convert';

List<Usuario> usuarioListFromJson(String str) => List<Usuario>.from(json.decode(str).map((x) => Usuario.fromJson(x)));

Usuario usuarioFromJson(Map<String, dynamic> json) => Usuario.fromJson(json);

String usuarioListToJson(List<Usuario> data) => json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Usuario {
    int id;
    int negocioId;
    int sucursalId;
    int rolId;
    String nombre;
    String apellido;
    String usuarioUnico;
    bool activo;
    DateTime ultimoAcceso;
    DateTime fechaRegistro;
    DateTime fechaActualizacion;
    Rol rol;
    Negocio negocio;
    Sucursal sucursal;

    // Helper para parsear fechas de forma segura
    static DateTime _parseDateTime(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      try {
        return DateTime.parse(value.toString());
      } catch (e) {
        return DateTime.now();
      }
    }

    Usuario({
        required this.id,
        required this.negocioId,
        required this.sucursalId,
        required this.rolId,
        required this.nombre,
        required this.apellido,
        required this.usuarioUnico,
        required this.activo,
        required this.ultimoAcceso,
        required this.fechaRegistro,
        required this.fechaActualizacion,
        required this.rol,
        required this.negocio,
        required this.sucursal,
    });

    factory Usuario.fromJson(Map<String, dynamic> json) {
      try {
        return Usuario(
          id: json["id"] as int,
          negocioId: json["negocio_id"] as int,
          sucursalId: json["sucursal_id"] as int,
          rolId: json["rol_id"] as int,
          nombre: json["nombre"] as String,
          apellido: json["apellido"] as String,
          usuarioUnico: json["usuario_unico"] as String,
          activo: json["activo"] as bool,
          ultimoAcceso: _parseDateTime(json["ultimo_acceso"]),
          fechaRegistro: _parseDateTime(json["fecha_registro"]),
          fechaActualizacion: _parseDateTime(json["fecha_actualizacion"]),
          rol: json["rol"] != null 
              ? Rol.fromJson(json["rol"] as Map<String, dynamic>)
              : Rol(
                  id: json["rol_id"] as int,
                  nombre: "Sin rol",
                  descripcion: "",
                ),
          negocio: json["negocio"] != null
              ? Negocio.fromJson(json["negocio"] as Map<String, dynamic>)
              : Negocio(
                  id: json["negocio_id"] as int,
                  nombre: "Sin negocio",
                  nombreComercial: "",
                ),
          sucursal: json["sucursal"] != null
              ? Sucursal.fromJson(json["sucursal"] as Map<String, dynamic>)
              : Sucursal(
                  id: json["sucursal_id"] as int,
                  nombre: "Sin sucursal",
                  codigo: "",
                ),
        );
      } catch (e) {
 
        rethrow;
      }
    }

    Map<String, dynamic> toJson() => {
        "id": id,
        "negocio_id": negocioId,
        "sucursal_id": sucursalId,
        "rol_id": rolId,
        "nombre": nombre,
        "apellido": apellido,
        "usuario_unico": usuarioUnico,
        "activo": activo,
        "ultimo_acceso": ultimoAcceso.toIso8601String(),
        "fecha_registro": fechaRegistro.toIso8601String(),
        "fecha_actualizacion": fechaActualizacion.toIso8601String(),
        "rol": rol.toJson(),
        "negocio": negocio.toJson(),
        "sucursal": sucursal.toJson(),
    };
}

class Negocio {
    int id;
    String nombre;
    String nombreComercial;

    Negocio({
        required this.id,
        required this.nombre,
        required this.nombreComercial,
    });

    factory Negocio.fromJson(Map<String, dynamic> json) => Negocio(
        id: json["id"],
        nombre: json["nombre"],
        nombreComercial: json["nombre_comercial"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "nombre": nombre,
        "nombre_comercial": nombreComercial,
    };
}

class Rol {
    int id;
    String nombre;
    String descripcion;

    Rol({
        required this.id,
        required this.nombre,
        required this.descripcion,
    });

    factory Rol.fromJson(Map<String, dynamic> json) => Rol(
        id: json["id"],
        nombre: json["nombre"],
        descripcion: json["descripcion"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "nombre": nombre,
        "descripcion": descripcion,
    };
}

class Sucursal {
    int id;
    String nombre;
    String codigo;

    Sucursal({
        required this.id,
        required this.nombre,
        required this.codigo,
    });

    factory Sucursal.fromJson(Map<String, dynamic> json) => Sucursal(
        id: json["id"],
        nombre: json["nombre"],
        codigo: json["codigo"],
    );

    Map<String, dynamic> toJson() => {
        "id": id,
        "nombre": nombre,
        "codigo": codigo,
    };
}
