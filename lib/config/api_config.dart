import 'dart:io';

class ApiConfig {
  // CONFIGURACIÓN DE URL BASE DEL SERVIDOR
  // • Android Emulator: http://10.0.2.2:3011
  // • iOS Simulator: http://localhost:3011
  // • Dispositivo físico Android/iOS: http://TU_IP_LOCAL:3011
  
  // Cambia esta URL según tu entorno
  // Para desarrollo local, puedes usar:
  // - Android Emulator: 'http://10.0.2.2:3011'
  // - iOS Simulator: 'http://localhost:3011'
 
  // Detectar automáticamente el entorno
  static String get baseUrl {
    // Si estás en iOS, usa localhost
    if (Platform.isIOS) {
      return 'http://localhost:3011';
    } if (Platform.isAndroid) {
    // Si estás en Android, usa 10.0.2.2 para emulador
    
    return 'http://10.0.2.2:3011';
    } else {
      // Para dispositivo físico mi IP local
      return 'http://192.168.191.93:3011';
    }
    

  }
  
  // Endpoints
  static const String loginEndpoint = '/api/usuarios/login';
  static const String ordenesEndpoint = '/api/ordenes';
  static const String ordenesDetallesEndpoint = '/api/ordenes-detalles';
  static const String serviciosEndpoint = '/api/servicios';
  static const String paquetesEndpoint = '/api/paquetes';
  static const String estacionesEndpoint = '/api/estaciones';
  static const String negociosEndpoint = '/api/negocios';
}

