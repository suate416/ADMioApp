import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../models/usuario.model.dart';
import 'home_screen.dart';
import '../config/app_colors.dart';
import '../widgets/login_form_widget.dart';

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
    // Enfocar el campo de contraseña después de un pequeño delay
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
            
            // Navegar a la pantalla principal
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeScreen()),
            );
          } else {
            throw Exception(loginResponse.message ?? 'Error en el login');
          }
        }
      } catch (e) {
        if (mounted) {
          // SnackBar de error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.error_outline, color: AppColors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      e.toString().replaceAll('Exception: ', ''),
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
                      // Logo o título con diseño mejorado
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.2),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.business_center,
                          size: 60,
                          color: AppColors.primary,
                        ),
                  ),
                      const SizedBox(height: 24),
                      Text(
                    'Admio App',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                          fontSize: 36,
                      fontWeight: FontWeight.bold,
                          color: AppColors.titleText,
                          letterSpacing: 1.2,
                    ),
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
                  ),
                  const SizedBox(height: 48),

                      // Mostrar lista de usuarios guardados o formulario
                      if (_isLoadingUsuarios)
                        const Center(child: CircularProgressIndicator())
                      else if (!_mostrarFormularioCompleto &&
                          _usuariosGuardados.isNotEmpty &&
                          _usuarioSeleccionado == null)
                        _buildListaUsuarios()
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
                        ),

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

  Widget _buildListaUsuarios() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lista de usuarios guardados
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gray300.withOpacity(0.5),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Selecciona una cuenta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              ..._usuariosGuardados.map(
                (usuario) => _buildUsuarioCard(usuario),
              ),
            ],
          ),
                  ),
                  const SizedBox(height: 16),
        // Botón para iniciar con otra cuenta
        TextButton(
          onPressed: _mostrarFormulario,
          child: Text(
            'Iniciar con otra cuenta',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUsuarioCard(Usuario usuario) {
    final isSelected = _usuarioSeleccionado?.id == usuario.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _seleccionarUsuario(usuario),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primaryLight.withOpacity(0.2)
                : AppColors.lightGray,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.primary : AppColors.gray300,
              width: isSelected ? 2 : 1,
                      ),
                    ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  '${usuario.nombre[0]}${usuario.apellido[0]}',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                  ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${usuario.nombre} ${usuario.apellido}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.usuarioUnico,
                      style: TextStyle(fontSize: 14, color: AppColors.bodyText),
                    ),
                    Text(
                      usuario.rol.nombre,
                      style: TextStyle(fontSize: 12, color: AppColors.gray600),
                    ),
                ],
              ),
            ),
              if (isSelected)
                Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
