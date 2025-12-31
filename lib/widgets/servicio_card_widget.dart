import 'package:flutter/material.dart';
import '../models/orden_detalle.model.dart';
import '../config/app_colors.dart';

class ServicioCardWidget extends StatelessWidget {
  final OrdenDetalle detalle;
  final bool isExpanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onRemoverDetalle;
  final Function(String) onCambiarEstado;

  const ServicioCardWidget({
    super.key,
    required this.detalle,
    required this.isExpanded,
    required this.onToggleExpanded,
    required this.onRemoverDetalle,
    required this.onCambiarEstado,
  });

  @override
  Widget build(BuildContext context) {
    final isCompletado = detalle.estado.toLowerCase() == 'completado';
    final isCancelado = detalle.estado.toLowerCase() == 'cancelado';
    
    // Obtener color del borde según el estado del detalle
    Color bordeColor;
    if (isCancelado) {
      bordeColor = AppColors.danger;
    } else if (isCompletado) {
      bordeColor = AppColors.success;
    } else {
      bordeColor = AppColors.primary;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bordeColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.25),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header del card
          GestureDetector(
           
            onTap: (){
              
            },
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.secondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.secondary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.content_cut,
                  color: AppColors.secondary,
                  size: 24,
                ),
              ),
              title: Text(
                detalle.nombre,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: AppColors.titleText,
                ),
              ),
              trailing: isCompletado || isCancelado
                  ? null
                  : IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColors.danger,
                      ),
                      onPressed: onRemoverDetalle,
                      tooltip: 'Remover servicio',
                    ),
            ),
          ),
          // Contenido expandible
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (detalle.servicio != null) ...[
                    if (detalle.servicio!.descripcion != null)
                      Text(
                        detalle.servicio!.descripcion!,
                        style: TextStyle(
                          color: AppColors.gray600,
                          fontSize: 14,
                        ),
                      ),
                    const SizedBox(height: 8),
                  ],
              
                ],
              ),
            ),
          // Footer del card
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.lightGray.withOpacity(0.3),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Servicio',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.gray600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lps. ${detalle.subtotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      isCancelado
                          ? 'Cancelado'
                          : isCompletado
                              ? 'Completado'
                              : 'En Proceso',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isCancelado
                            ? AppColors.warning
                            : isCompletado
                                ? AppColors.success
                                : AppColors.primary,
                      ),
                    ),
                    if (!isCancelado) ...[
                      const SizedBox(width: 8),
                      Switch(
                        value: isCompletado,
                        onChanged: (value) {
                          onCambiarEstado(value ? 'completado' : 'en_proceso');
                        },
                        activeColor: AppColors.success,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

