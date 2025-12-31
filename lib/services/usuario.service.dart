// Servicio para obtener la lista de usuarios desde la API del backend
import 'package:http/http.dart' as http;
import '../models/usuario.model.dart';
import '../config/api_config.dart';

class UsuarioService {
  Future<List<Usuario>> fetchUsuarios() async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.usuariosEndpoint}');
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final String responseBody = response.body;
      return usuarioListFromJson(responseBody);
    } else {
      throw Exception('Error al cargar los usuarios: ${response.statusCode}');
    }
  }
}