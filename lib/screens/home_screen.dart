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
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.titleText,
                      ),
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
                      CardRol(
                        usuario: _usuario!,
                        logoUrl: _negocio?.logo,
                      ),
                      SizedBox(height:50),
                      // Botón para agregar cliente a lista de espera
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: ElevatedButton.icon(
                          onPressed: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text(
                                  'Funcionalidad en desarrollo', style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: AppColors.secondary,
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person_add, size: 20),
                          label: const Text(
                            'Agregar Cliente a Lista',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.secondary,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                        ),
                      ),
                      // Lista de espera de clientes
                      ListaEsperaWidget(sucursalId: _usuario!.sucursalId),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
