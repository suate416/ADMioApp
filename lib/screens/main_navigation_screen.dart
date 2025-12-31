import 'package:flutter/material.dart';
import '../widgets/bottom_nav_bar.dart';
import '../config/app_colors.dart';
import 'home_screen.dart';
import 'crear_orden_screen.dart';
import 'usuario_resumen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(key: const ValueKey('home')),
          CrearOrdenScreen(key: const ValueKey('crear_orden')),
          UsuarioResumenScreen(key: const ValueKey('usuario_resumen')),
        ],
      ),
      bottomNavigationBar: BuildBottomNavigationBar(
        currentIndex: _currentIndex,
        cambiarTab: _onTabChanged,
      ),
    );
  }
}

