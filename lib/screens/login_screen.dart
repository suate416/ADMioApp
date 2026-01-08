import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/usuario.model.dart';
import 'main_navigation_screen.dart';
import '../config/app_colors.dart';
import '../widgets/login_form_widget.dart';
import '../widgets/lista_usuarios_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usuarioController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  final _authService = AuthService();
  final _storageService = StorageService();

  bool _isLoading = false;
  bool _isLoadingUsuarios = true;
  bool _mostrarFormularioCompleto = false;
  List<Usuario> _usuariosGuardados = [];
  Usuario? _usuarioSeleccionado;

  @override
  void initState() {
    super.initState();
    _cargarUsuariosGuardados();
  }

  @override
  void dispose() {
    _usuarioController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _cargarUsuariosGuardados() async {
    try {
      final usuarios = await _storageService.getUsuariosGuardados();
      if (mounted) {
        setState(() {
          _usuariosGuardados = usuarios;
          _isLoadingUsuarios = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingUsuarios = false;
        });
      }
    }
  }

  void _seleccionarUsuario(Usuario usuario) {
    setState(() {
      _usuarioSeleccionado = usuario;
      _usuarioController.text = usuario.usuarioUnico;
      _mostrarFormularioCompleto =
          true; // Mostrar formulario cuando se selecciona
      _passwordController.clear();
    });
    // Enfocar el campo de contraseña
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _passwordFocusNode.requestFocus();
      }
    });
  }

  void _volverALista() {
    setState(() {
      _usuarioSeleccionado = null;
      _mostrarFormularioCompleto = false;
      _usuarioController.clear();
      _passwordController.clear();
    });
  }

  void _mostrarFormulario() {
    setState(() {
      _mostrarFormularioCompleto = true;
      _usuarioSeleccionado = null;
      _usuarioController.clear();
      _passwordController.clear();
    });
  }

  Future<void> _handleLogin() async {
      setState(() {
        _isLoading = true;
      });

      try {
        final loginResponse = await _authService.login(
          _usuarioController.text.trim(),
          _passwordController.text,
        );
        
        if (mounted) {
          // Verificar que el login fue exitoso
          if (loginResponse.success && loginResponse.data != null) {
            // SnackBar de éxito
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppColors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sesión iniciada correctamente',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.success,
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
              ),
            );
            
            // Navega después del SnackBar
            await Future.delayed(const Duration(seconds: 1));
            
            // Navegar a la pantalla principal con bottom navigation bar
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
            );
          } else {
            throw Exception(loginResponse.message ?? 'Error en el login');
          }
        }
      } catch (e) {
        if (mounted) {
          final errorMessage = e.toString().replaceAll('Exception: ', '');
          
          // Verificar si el error es por cuenta inactiva
          if (errorMessage.toLowerCase().contains('inactiva') || 
              errorMessage.toLowerCase().contains('inactivo')) {
            // Mostrar modal para cuenta inactiva
            _mostrarModalCuentaInactiva(context, errorMessage);
          } else {
            // SnackBar de error para otros errores
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        errorMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                backgroundColor: AppColors.danger,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                margin: const EdgeInsets.all(16),
                action: SnackBarAction(
                  label: 'Cerrar',
                  textColor: AppColors.white,
                  onPressed: () {},
                ),
              ),
            );
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primaryLight.withOpacity(0.1),
              AppColors.secondaryLight.withOpacity(0.1),
              AppColors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: GestureDetector(
            onTap: () {
              // Ocultar el teclado al tocar fuera de los inputs
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.opaque,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                      // Logo
                      Center(
                        child: Image.asset(
                          'assets/images/ADMIOlogocuadro2.png',
                          width: 180,
                          height: 180,
                          fit: BoxFit.contain,
                        )
                            .animate()
                            .fadeIn(duration: 700.ms)
                            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1), duration: 700.ms),
                      ),
                      Center(
                        child: Image.asset(
                          'assets/images/ADMIOlogotext.png',
                          height: 100,
                          fit: BoxFit.contain,
                        )
                            .animate()
                            .fadeIn(duration: 700.ms, delay: 100.ms)
                            .slideY(begin: 0.1, end: 0, duration: 700.ms, delay: 100.ms),
                      ),
                  const SizedBox(height: 8),
                      Text(
                    'Inicia sesión para continuar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                          color: AppColors.bodyText,
                          fontWeight: FontWeight.w400,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 700.ms, delay: 200.ms)
                      .slideY(begin: 0.1, end: 0, duration: 700.ms, delay: 200.ms),
                  const SizedBox(height: 20),

                      // Mostrar lista de usuarios guardados o formulario
                      if (_isLoadingUsuarios)
                        const Center(child: CircularProgressIndicator())
                            .animate()
                            .fadeIn(duration: 400.ms)
                      else if (!_mostrarFormularioCompleto &&
                          _usuariosGuardados.isNotEmpty &&
                          _usuarioSeleccionado == null)
                        ListaUsuariosWidget(
                          usuarios: _usuariosGuardados,
                          usuarioSeleccionado: _usuarioSeleccionado,
                          onUsuarioSeleccionado: _seleccionarUsuario,
                          onMostrarFormulario: _mostrarFormulario,
                        )
                            .animate()
                            .fadeIn(duration: 700.ms, delay: 300.ms)
                            .slideY(begin: 0.1, end: 0, duration: 700.ms, delay: 300.ms)
                      else
                        LoginFormWidget(
                          usuarioController: _usuarioController,
                          passwordController: _passwordController,
                          passwordFocusNode: _passwordFocusNode,
                          isLoading: _isLoading,
                          usuarioDeshabilitado: _usuarioSeleccionado != null,
                          autofocusPassword: _usuarioSeleccionado != null,
                          onLogin: _handleLogin,
                          onVolver: _usuarioSeleccionado != null &&
                                  _usuariosGuardados.isNotEmpty
                              ? _volverALista
                              : null,
                          nombreUsuario: _usuarioSeleccionado?.nombre,
                        )
                            .animate()
                            .fadeIn(duration: 700.ms, delay: 300.ms)
                            .slideY(begin: 0.1, end: 0, duration: 700.ms, delay: 300.ms),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }


  void _mostrarModalCuentaInactiva(BuildContext context, String mensaje) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: AppColors.warning,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cuenta Inactiva',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleText,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mensaje,
                style: TextStyle(
                  fontSize: 16,
                  color: AppColors.bodyText,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.warning.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppColors.warning,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Contacta a tu supervisor para reactivar tu cuenta.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.bodyText,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warning,
                foregroundColor: AppColors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Entendido',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
