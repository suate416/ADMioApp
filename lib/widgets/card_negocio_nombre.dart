import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../models/usuario.model.dart';

class CardRol extends StatelessWidget {
  final Usuario usuario;
  final String? logoUrl;

  const CardRol({
    super.key,
    required this.usuario,
    this.logoUrl,
  });

  Widget _buildLogo() {
    // Verificar si hay logo válido
    final hasValidLogo = logoUrl != null &&
        logoUrl!.isNotEmpty &&
        logoUrl!.trim().isNotEmpty;

    if (hasValidLogo) {
      final logoUri = Uri.tryParse(logoUrl!.trim());
      final isValidUrl = logoUri != null &&
          logoUri.hasScheme &&
          (logoUri.scheme == 'http' || logoUri.scheme == 'https');

      if (isValidUrl) {
        return ClipOval(
          child: Image.network(
            logoUrl!.trim(),
            width: 70,
            height: 70,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return _buildPlaceholderLogo();
            },
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.lightGray,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: AppColors.secondary,
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            },
          ),
        );
      }
    }

    // Si no hay logo válido, mostrar placeholder
    return _buildPlaceholderLogo();
  }

  Widget _buildPlaceholderLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.business,
        color: AppColors.white,
        size: 28,
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final authService = AuthService();
    await authService.logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Cerrar Sesión'),
              onTap: () {
                Navigator.pop(context);
                _handleLogout(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreCompleto = '${usuario.nombre} ${usuario.apellido}'.trim();
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.secondary,
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sección superior: Información del usuario
          Row(
            children: [
              // Logo del negocio
              _buildLogo(),
              const SizedBox(width: 12),
              // Información del usuario
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreCompleto,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      usuario.usuarioUnico,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.bodyText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Badge del rol
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondaryLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        usuario.rol.nombre,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryDark,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Icono de menú
              GestureDetector(
                onTap: () => _showMenu(context),
                behavior: HitTestBehavior.opaque,
                child: const Icon(
                  Icons.menu,
                  color: AppColors.titleText,
                  size: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Divider
          Divider(
            color: AppColors.gray300,
            height: 1,
            thickness: 1,
          ),
          const SizedBox(height: 16),
          // Sección inferior: Información del negocio
          Row(
            children: [
              // Columna izquierda: Sucursal
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.store,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Sucursal',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.bodyText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            usuario.sucursal.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.titleText,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Columna derecha: Negocio
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      Icons.business,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Negocio',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.bodyText,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            usuario.negocio.nombreComercial.isNotEmpty
                                ? usuario.negocio.nombreComercial
                                : usuario.negocio.nombre,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.titleText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
