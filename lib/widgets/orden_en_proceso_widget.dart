import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../services/orden_detalle.service.dart';
import '../services/orden.service.dart';
import '../models/orden.model.dart';
import '../models/orden_detalle.model.dart';
import '../config/app_colors.dart';
import '../screens/agregar_detalle_screen.dart';

class OrdenEnProcesoWidget extends StatefulWidget {
  final Orden? ordenActiva;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onCambiarTabServicios;

  const OrdenEnProcesoWidget({
    super.key,
    this.ordenActiva,
    this.onRefresh,
    this.onCambiarTabServicios,
  });

  @override
  State<OrdenEnProcesoWidget> createState() => _OrdenEnProcesoWidgetState();
}

class _OrdenEnProcesoWidgetState extends State<OrdenEnProcesoWidget> {
  final OrdenDetalleService _ordenDetalleService = OrdenDetalleService();
  final OrdenService _ordenService = OrdenService();
  
  List<OrdenDetalle> _detalles = [];
  Map<int, bool> _expandedDetalles = {};
  String _searchQuery = '';
  bool _isLoading = true;
  Orden? _orden;

  @override
  void initState() {
    super.initState();
    _orden = widget.ordenActiva;
    if (_orden != null) {
      _cargarDetalles();
    } else {
      _isLoading = false;
    }
  }

  @override
  void didUpdateWidget(OrdenEnProcesoWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si cambió la orden activa
    if (widget.ordenActiva?.id != oldWidget.ordenActiva?.id) {
      _orden = widget.ordenActiva;
      if (_orden != null) {
        _cargarDetalles();
      } else {
        setState(() {
          _detalles = [];
          _isLoading = false;
        });
      }
    } else if (widget.ordenActiva != null && _orden != null && 
               widget.ordenActiva!.id == _orden!.id) {
      // Si es la misma orden pero puede haber cambiado (subtotal, etc.), actualizar la referencia
      _orden = widget.ordenActiva;
      // Recargar detalles por si se agregaron nuevos
      _cargarDetalles();
    }
  }

  Future<void> _cargarDetalles() async {
    if (_orden == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final detalles = await _ordenDetalleService.getOrdenesDetallesByOrden(_orden!.id);
      final ordenActualizada = await _ordenService.getOrdenById(_orden!.id);
      
      if (mounted) {
        setState(() {
          _detalles = detalles;
          _orden = ordenActualizada;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  String _formatFecha(DateTime fecha) {
    final meses = [
      'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
      'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre'
    ];
    
    int hora;
    String periodo;
    
    if (fecha.hour == 0) {
      hora = 12;
      periodo = 'a.m.';
    } else if (fecha.hour == 12) {
      hora = 12;
      periodo = 'p.m.';
    } else if (fecha.hour > 12) {
      hora = fecha.hour - 12;
      periodo = 'p.m.';
    } else {
      hora = fecha.hour;
      periodo = 'a.m.';
    }
    
    final minutos = fecha.minute.toString().padLeft(2, '0');
    return '${meses[fecha.month - 1]} ${fecha.day}-${fecha.year} $hora:$minutos $periodo';
  }

  Future<void> _navigateToAgregarDetalle() async {
    if (_orden == null) return;

    // Si hay un callback para cambiar al tab de Servicios, usarlo
    if (widget.onCambiarTabServicios != null) {
      widget.onCambiarTabServicios!();
      return;
    }

    // Si no hay callback, usar la navegación antigua (para compatibilidad)
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AgregarDetalleScreen(orden: _orden!),
      ),
    );

    if (result == true && mounted) {
      // Recargar detalles y actualizar la orden
      await _cargarDetalles();
      // Notificar al padre para que recargue las órdenes activas
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    }
  }

  Future<void> _cambiarEstadoDetalle(OrdenDetalle detalle, String nuevoEstado) async {
    try {
      await _ordenDetalleService.updateEstadoOrdenDetalle(
        ordenDetalleId: detalle.id,
        estado: nuevoEstado,
      );
      await _cargarDetalles();
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removerDetalle(OrdenDetalle detalle) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Servicio'),
        content: Text('¿Estás seguro de que deseas remover "${detalle.nombre}" de la orden?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _ordenDetalleService.softDeleteOrdenDetalle(detalle.id);
      await _cargarDetalles();
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio removido exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelarDetalle(OrdenDetalle detalle) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Servicio'),
        content: Text('¿Estás seguro de que deseas cancelar "${detalle.nombre}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.warning,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    // Actualizar el estado local inmediatamente para feedback visual
    setState(() {
      final index = _detalles.indexWhere((d) => d.id == detalle.id);
      if (index != -1) {
        final detalleActual = _detalles[index];
        _detalles[index] = OrdenDetalle(
          id: detalleActual.id,
          ordenId: detalleActual.ordenId,
          servicioId: detalleActual.servicioId,
          paqueteId: detalleActual.paqueteId,
          estado: 'cancelado',
          subtotal: detalleActual.subtotal,
          activo: detalleActual.activo,
          servicio: detalleActual.servicio,
          paquete: detalleActual.paquete,
          extras: detalleActual.extras,
        );
      }
    });

    try {
      await _ordenDetalleService.updateEstadoOrdenDetalle(
        ordenDetalleId: detalle.id,
        estado: 'cancelado',
      );
      // Recargar detalles para asegurar sincronización con el backend
      await _cargarDetalles();
      if (widget.onRefresh != null) {
        widget.onRefresh!();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Servicio cancelado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      // Si hay error, revertir el cambio local recargando desde el backend
      if (mounted) {
        await _cargarDetalles();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _completarOrden() async {
    if (_orden == null) return;

    final detalles = _detalles;
    final detallesActivos = detalles.where((d) => d.activo).toList();

    // Verificar si hay detalles activos
    if (detallesActivos.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se puede completar órdenes sin detalle'),
            backgroundColor: AppColors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final allDetailsCompleted = detallesActivos.every((d) => d.estado.toLowerCase() == 'completado');

    if (!allDetailsCompleted) {
      // Obtener detalles que están en proceso
      final detallesEnProceso = detallesActivos.where((d) => 
        d.estado.toLowerCase() != 'completado' && 
        d.estado.toLowerCase() != 'cancelado'
      ).toList();

      if (mounted) {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 28),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'No se puede completar la orden',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Todos los servicios deben estar completados para finalizar la orden.',
                  style: TextStyle(fontSize: 14),
                ),
                if (detallesEnProceso.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Servicios en proceso:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: detallesEnProceso.map((detalle) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Icon(Icons.circle, size: 8, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    detalle.nombre,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.white,
                ),
                child: const Text('Entendido'),
              ),
            ],
          ),
        );
      }
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Orden'),
        content: Text('¿Estás seguro de que deseas completar la orden #${_orden!.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Completar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await _ordenService.updateEstadoOrden(
        ordenId: _orden!.id,
        estado: 'completada',
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Orden completada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.onRefresh != null) {
          widget.onRefresh!();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelarOrden(Orden orden) async {
    // Mostrar diálogo de confirmación
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar Orden'),
        content: Text('¿Estás seguro de que deseas cancelar la Orden #${orden.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirmar != true) {
      return;
    }

    try {
      await _ordenService.updateEstadoOrden(
        ordenId: orden.id,
        estado: 'cancelada',
      );
      
      if (mounted) {
        // Limpiar el estado local ya que la orden fue cancelada
        setState(() {
          _orden = null;
          _detalles = [];
          _isLoading = false;
        });
        
        // Notificar al widget padre para que recargue las órdenes y actualice la pantalla
        if (widget.onRefresh != null) {
          await widget.onRefresh!();
        }
        
        // Forzar actualización del widget después de recargar
        if (mounted) {
          setState(() {});
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Orden #${orden.id} cancelada exitosamente'),
              backgroundColor: AppColors.success,
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }

  Future<void> _agregarComentario() async {
    if (_orden == null) return;

    final TextEditingController comentarioController = TextEditingController(
      text: _orden!.observaciones ?? '',
    );

    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Comentario'),
        content: TextField(
          controller: comentarioController,
          maxLines: 5,
          decoration: const InputDecoration(
            hintText: 'Escribe un comentario sobre la orden...',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, comentarioController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondary,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    if (result != null) {
      try {
        final ordenActualizada = await _ordenService.updateObservacionesOrden(
          ordenId: _orden!.id,
          observaciones: result,
        );
        
        if (mounted) {
          setState(() {
            _orden = ordenActualizada;
          });
          if (widget.onRefresh != null) {
            widget.onRefresh!();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Comentario guardado exitosamente'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  List<OrdenDetalle> _getDetallesFiltrados() {
    var detalles = _detalles.where((detalle) => detalle.activo).toList();

    if (_searchQuery.isNotEmpty) {
      detalles = detalles.where((detalle) {
        final nombre = detalle.nombre.toLowerCase();
        return nombre.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    return detalles;
  }

  double _getTotalOrden() {
    return _detalles
        .where((detalle) => detalle.activo)
        .fold(0.0, (sum, detalle) => sum + detalle.subtotal);
  }

  @override
  Widget build(BuildContext context) {
    if (_orden == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 64, color: AppColors.gray500),
            const SizedBox(height: 16),
            Text(
              'No hay órdenes en proceso',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final detallesFiltrados = _getDetallesFiltrados();
    final totalOrden = _getTotalOrden();

    return RefreshIndicator(
      onRefresh: _cargarDetalles,
      child: Column(
        children: [
          // Información de la orden
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Orden #${_orden!.id}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatFecha(_orden!.fecha.toLocal()),
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.gray600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _orden!.observaciones != null && _orden!.observaciones!.isNotEmpty
                                ? Icons.comment
                                : Icons.comment_outlined,
                            color: _orden!.observaciones != null && _orden!.observaciones!.isNotEmpty
                                ? AppColors.secondary
                                : AppColors.gray500,
                          ),
                          onPressed: _agregarComentario,
                          tooltip: 'Agregar comentario',
                        ),
                        // Botón X para cancelar orden (solo si no está cancelada o completada)
                        if (_orden!.estado.toLowerCase() != 'cancelada' && 
                            _orden!.estado.toLowerCase() != 'completada' &&
                            _orden!.estado.toLowerCase() != 'facturada')
                          IconButton(
                            icon: const Icon(Icons.close, color: AppColors.red, size: 40),
                            onPressed: () => _cancelarOrden(_orden!),
                            tooltip: 'Cancelar orden',
                          ),
                      ],
                    ),
                  ],
                ),
                // Mostrar comentario existente si hay
                if (_orden!.observaciones != null && _orden!.observaciones!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.gray300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.comment,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _orden!.observaciones!,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Buscar servicio',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                filled: true,
                fillColor: AppColors.lightGray,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Lista de servicios
          Expanded(
            child: detallesFiltrados.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.content_cut_sharp, size: 64, color: AppColors.gray500),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'No se encontraron servicios'
                              : 'No hay servicios',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.gray500,
                          ),
                        ),
                        if (_searchQuery.isEmpty) ...[
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            onPressed: _navigateToAgregarDetalle,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar Servicio'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.secondary,
                              foregroundColor: AppColors.white,
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: detallesFiltrados.length,
                    itemBuilder: (context, index) {
                      final detalle = detallesFiltrados[index];
                      final isExpanded = _expandedDetalles[detalle.id] ?? false;
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

                      final cardWidget = Container(
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
                              onTap: () {
                                setState(() {
                                  _expandedDetalles[detalle.id] = !isExpanded;
                                });
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
                                        onPressed: () {
                                          _removerDetalle(detalle);
                                        },
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
                                    if (detalle.extras != null &&
                                        detalle.extras!.isNotEmpty) ...[
                                      const Text(
                                        'Extras:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      ...detalle.extras!.map((extra) => Padding(
                                            padding: const EdgeInsets.only(left: 16, top: 4),
                                            child: Text(
                                              '- ${extra.servicioExtra?.nombre ?? 'Extra'}',
                                              style: TextStyle(
                                                color: AppColors.gray600,
                                                fontSize: 14,
                                              ),
                                            ),
                                          )),
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
                                            _cambiarEstadoDetalle(
                                              detalle,
                                              value ? 'completado' : 'en_proceso',
                                            );
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

                      // Si está completado o cancelado, no mostrar Slidable
                      if (isCompletado || isCancelado) {
                        return cardWidget;
                      }

                      // Si no está completado, mostrar con Slidable
                      return Slidable(
                        key: ValueKey(detalle.id),
                        endActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                _cancelarDetalle(detalle);
                              },
                              backgroundColor: AppColors.warning,
                              foregroundColor: AppColors.white,
                              icon: Icons.cancel,
                              label: 'Cancelar',
                              borderRadius: const BorderRadius.only(
                                topRight: Radius.circular(10),
                                bottomRight: Radius.circular(10),
                              ),
                            ),
                          ],
                        ),
                        startActionPane: ActionPane(
                          motion: const StretchMotion(),
                          children: [
                            SlidableAction(
                              onPressed: (context) {
                                _cambiarEstadoDetalle(
                                  detalle,
                                  'completado',
                                );
                              },
                              backgroundColor: AppColors.success,
                              foregroundColor: AppColors.white,
                              icon: Icons.check,
                              label: 'Completar',
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(10),
                                bottomLeft: Radius.circular(10),
                              ),
                            ),
                          ],
                        ),
                        child: cardWidget,
                      );
                    },
                  ),
          ),
          // Total de la orden y botón Completar
          Padding(
            padding: const EdgeInsets.only(
              left: 16,
              right: 16,
              top: 24,
              bottom: 32,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    border: Border(
                      top: BorderSide(color: AppColors.gray300),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total Orden',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Lps. ${totalOrden.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _completarOrden,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Completar Orden',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


