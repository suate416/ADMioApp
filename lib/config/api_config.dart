//Configuración centralizada de la API: define la URL base del servidor según dispositivo y endpoints de la aplicación
import 'dart:io';

class ApiConfig {
  static String get baseUrl {
    //IOS
    if (Platform.isIOS) {
      return 'http://localhost:3011';
    }
    if (Platform.isAndroid) {
      //10.0.2.2 para emulador

      return 'http://10.0.2.2:3011';
    } else {
      // Para dispositivo fisico ip local
      return 'http://192.168.191.93:3011';
    }
  }

  // Endpoints
  static const String loginEndpoint = '/api/usuarios/login';
  static const String usuariosEndpoint = '/api/usuarios';
  static const String ordenesEndpoint = '/api/ordenes';
  static const String ordenesDetallesEndpoint = '/api/ordenes-detalles';
  static const String serviciosEndpoint = '/api/servicios';
  static const String paquetesEndpoint = '/api/paquetes';
  static const String estacionesEndpoint = '/api/estaciones';
  static const String negociosEndpoint = '/api/negocios';
  static const String cajasEndpoint = '/api/cajas';
}
