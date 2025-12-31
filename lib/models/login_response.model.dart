// Modelo de respuesta del login que contiene: éxito de la operación, datos del usuario, token de autenticación, tiempo de expiración y mensaje opcional
import 'usuario.model.dart';

class LoginResponse {
  bool success;
  Usuario? data;
  String? token;
  int? expiresIn;
  String? message;

  LoginResponse({
    required this.success,
    this.data,
    this.token,
    this.expiresIn,
    this.message,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      success: json['success'] ?? false,
      data: json['data'] != null ? Usuario.fromJson(json['data']) : null,
      token: json['token']?.toString(),
      expiresIn: json['expiresIn'] is int 
          ? json['expiresIn'] as int
          : json['expiresIn'] != null 
              ? int.tryParse(json['expiresIn'].toString())
              : null,
      message: json['message']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'data': data?.toJson(),
      'token': token,
      'expiresIn': expiresIn,
      'message': message,
    };
  }
}

