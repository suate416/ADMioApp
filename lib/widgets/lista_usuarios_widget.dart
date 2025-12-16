import 'package:flutter/material.dart';
import '../config/app_colors.dart';
import '../models/usuario.model.dart';

class ListaUsuariosWidget extends StatelessWidget {
  final List<Usuario> usuarios;
  final Usuario? usuarioSeleccionado;
  final Function(Usuario) onUsuarioSeleccionado;
  final VoidCallback onMostrarFormulario;

  const ListaUsuariosWidget({
    super.key,
    required this.usuarios,
    this.usuarioSeleccionado,
    required this.onUsuarioSeleccionado,
    required this.onMostrarFormulario,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Lista de usuarios guardados
        Container(
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
              ...usuarios.map(
                (usuario) => _buildUsuarioCard(usuario),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Botón para iniciar con otra cuenta
        TextButton(
          onPressed: onMostrarFormulario,
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
    final isSelected = usuarioSeleccionado?.id == usuario.id;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => onUsuarioSeleccionado(usuario),
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

