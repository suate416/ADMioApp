import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'services/auth_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'config/app_colors.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurar la barra de estado para que se adapte al color de la pantalla
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Hace la barra de estado transparente
      statusBarIconBrightness: Brightness.dark, // Iconos oscuros para fondo claro
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.white, // Color de la barra de navegación
      systemNavigationBarIconBrightness: Brightness.dark, // Iconos oscuros
    ),
  );
  
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      // isLoggedIn() ahora valida el token automáticamente
      final isLoggedIn = await _authService.isLoggedIn();
      
      if (mounted) {
        setState(() {
          _isLoggedIn = isLoggedIn;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Si hay error al validar, mostrar login
      if (mounted) {
        setState(() {
          _isLoggedIn = false;
          _isLoading = false;
        });
      }
    }
  }

  Widget _getInitialScreen() {
    if (_isLoading) {
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
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
    
    return _isLoggedIn ? const HomeScreen() : const LoginScreen();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Admio App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          secondary: AppColors.secondary,
        ),
        useMaterial3: true,
      ),
      home: _getInitialScreen(),
    );
  }
}