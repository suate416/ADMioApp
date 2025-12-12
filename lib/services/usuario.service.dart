
import 'package:http/http.dart' as http;
import '../models/usuario.model.dart';

class UsuarioService {
  final String _baseUrl = 'http://10.0.2.2:3011/api/usuarios';

  Future<List<Usuario>> fetchUsuarios() async {
    final uri = Uri.parse(_baseUrl);
    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final String responseBody = response.body;
      return usuarioListFromJson(responseBody);
    } else {
      throw Exception('Error al cargar los usuarios: ${response.statusCode}');
    }
  }
}