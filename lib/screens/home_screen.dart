import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/negocio.service.dart';
import '../models/usuario.model.dart';
import '../models/negocio.model.dart';
import '../widgets/card_negocio_nombre.dart';
import '../widgets/lista_espera_widget.dart';
import '../config/app_colors.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final NegocioService _negocioService = NegocioService();
  Usuario? _usuario;
  Negocios? _negocio;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usuario = await _authService.getUsuario();
      if (usuario == null) {
        if (mounted) {
          _navigateToLogin();
        }
        return;
      }

      if (!mounted) return;
      
      // Cargar información completa del negocio
      try {
        final negocio = await _negocioService.getNegocioById(usuario.negocioId);
        if (mounted) {
          setState(() {
            _usuario = usuario;
            _negocio = negocio;
            _isLoading = false;
          });

        }
      } catch (e) {
        // Si falla cargar el negocio, continuar sin el logo
        print('Error al cargar negocio: $e');
        if (mounted) {
          setState(() {
            _usuario = usuario;
            _negocio = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      child: SafeArea(
        child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: AppColors.titleText),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                )
                : _usuario == null
                    ? const Center(
                        child: Text(
                          'No se pudo cargar la información del usuario.',
                          style: TextStyle(color: AppColors.titleText),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _loadData,
                        color: AppColors.secondary,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Column(
                            children: [
                              // Card Rol al comienzo
                              if (_usuario!.rol.nombre.isNotEmpty)
                                CardRol(rol: _usuario!.rol.nombre),
                              // Logo del negocio
                              if (_usuario!.negocio.nombreComercial.isNotEmpty ||
                                  _usuario!.negocio.nombre.isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      // Logo del negocio
                                      Builder(
                                        builder: (context) {
                                          // Verificar si hay logo válido
                                          final hasValidLogo = _negocio != null && 
                                              _negocio!.logo.isNotEmpty && 
                                              _negocio!.logo.trim().isNotEmpty;
                                          
                                          if (hasValidLogo) {
                                            final logoUri = Uri.tryParse(_negocio!.logo.trim());
                                            final isValidUrl = logoUri != null && 
                                                (logoUri.hasScheme && 
                                                (logoUri.scheme == 'http' || logoUri.scheme == 'https'));
                                            
                                            if (isValidUrl) {
                                              return Container(
                                                width: 150,
                                                height: 150,
                                                margin: const EdgeInsets.only(bottom: 16),
                                                decoration: BoxDecoration(
                                                  borderRadius: BorderRadius.circular(12),
                                                  border: Border.all(
                                                    color: AppColors.gray300,
                                                    width: 1,
                                                  ),
                                                ),
                                                child: ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.network(
                                                    _negocio!.logo.trim(),
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      print('Error al cargar imagen del logo: $error');
                                                      print('URL del logo: ${_negocio!.logo}');
                                                      return _buildPlaceholderLogo();
                                                    },
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return Center(
                                                        child: CircularProgressIndicator(
                                                          value: loadingProgress.expectedTotalBytes != null
                                                              ? loadingProgress.cumulativeBytesLoaded /
                                                                  loadingProgress.expectedTotalBytes!
                                                              : null,
                                                          color: AppColors.secondary,
                                                        ),
                                                      );
                                                    },
                                                  ),
                                                ),
                                              );
                                            }
                                          }
                                          
                                          // Si no hay logo válido, mostrar placeholder
                                          return _buildPlaceholderLogo();
                                        },
                                      ),
                                      const SizedBox(height: 8),
                                      // Nombre comercial
                                      Text(
                                        _usuario!.negocio.nombreComercial.isNotEmpty
                                            ? _usuario!.negocio.nombreComercial
                                            : _usuario!.negocio.nombre,
                                      style: const TextStyle(
                                          fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.titleText,
                                      ),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 4),
                                      // Nombre del negocio
                                      Text(
                                        _usuario!.negocio.nombre,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppColors.gray600,
                                        ),
                                        textAlign: TextAlign.center,
                                        ),
                                    ],
                                  ),
                                ),
                              // Lista de espera de clientes
                              if (_usuario != null)
                                ListaEsperaWidget(
                                  sucursalId: _usuario!.sucursalId,
                                ),
                            ],
                          ),
                        ),
                      ),
      ),
    );
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: AppColors.lightGray,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.gray300,
          width: 1,
        ),
      ),
      child: Icon(
        Icons.business,
        size: 64,
        color: AppColors.gray500,
      ),
    );
  }

}

