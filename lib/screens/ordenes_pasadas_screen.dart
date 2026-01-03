import 'package:flutter/material.dart';
import '../services/orden.service.dart';
import '../services/orden_detalle.service.dart';
import '../models/orden.model.dart';
import '../models/orden_detalle.model.dart';
import '../models/usuario.model.dart';
import '../config/app_colors.dart';

class OrdenesPasadasScreen extends StatefulWidget {
  final Usuario usuario;
  final VoidCallback onRefresh;

  const OrdenesPasadasScreen({
    super.key,
    required this.usuario,
    required this.onRefresh,
  });

  @override
  State<OrdenesPasadasScreen> createState() => _OrdenesPasadasScreenState();
}

class _OrdenesPasadasScreenState extends State<OrdenesPasadasScreen> {
  final OrdenService _ordenService = OrdenService();
  final OrdenDetalleService _ordenDetalleService = OrdenDetalleService();
  
  List<Orden> _ordenes = [];
  List<Orden> _ordenesFiltradas = [];
  final Map<int, List<OrdenDetalle>> _detallesOrdenes = {};
  final Map<int, bool> _expandedOrdenes = {};
  final Map<int, bool> _cargandoDetalles = {};
  bool _isLoading = true;
  
  // Filtros
  String? _filtroEstado;
  String? _filtroServicio;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _tipoFiltroFecha = 'todos'; // 'todos', 'hoy', 'mes', 'dia', 'rango'

  @override
  void initState() {
    super.initState();
    _cargarOrdenes();
  }

  Future<void> _cargarOrdenes() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final ordenes = await _ordenService.getOrdenesBySucursal(widget.usuario.sucursalId);
      if (mounted) {
        final ordenesFiltradas = ordenes
            .where((orden) => orden.usuarioId == widget.usuario.id)
            .where((orden) {
              final estado = orden.estado.toLowerCase().trim();
              return estado == 'completada' || estado == 'cancelada' || estado == 'facturada';
            })
            .toList();
        
        // Cargar detalles de órdenes 
        for (var orden in ordenesFiltradas) {
          try {
            final detalles = await _ordenDetalleService.getOrdenesDetallesByOrden(orden.id);
            _detallesOrdenes[orden.id] = detalles;
          } catch (e) {
            // Ignorar errores al cargar detalles
          }
        }
        
        setState(() {
          _ordenes = ordenesFiltradas;
          _aplicarFiltros();
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
  
  void _aplicarFiltros() {
    var ordenesFiltradas = List<Orden>.from(_ordenes);
    
    // Filtro por estado
    if (_filtroEstado != null && _filtroEstado!.isNotEmpty) {
      ordenesFiltradas = ordenesFiltradas.where((orden) {
        return orden.estado.toLowerCase().trim() == _filtroEstado!.toLowerCase().trim();
      }).toList();
    }
    
    // Filtro por servicio
    if (_filtroServicio != null && _filtroServicio!.isNotEmpty) {
      ordenesFiltradas = ordenesFiltradas.where((orden) {
        final detalles = _detallesOrdenes[orden.id] ?? [];
        return detalles.any((detalle) => 
          detalle.activo && 
          detalle.nombre.toLowerCase().contains(_filtroServicio!.toLowerCase())
        );
      }).toList();
    }
    
    // Filtro por fecha
    if (_tipoFiltroFecha != 'todos' && _fechaInicio != null && _fechaFin != null) {
      ordenesFiltradas = ordenesFiltradas.where((orden) {
        final fechaOrden = orden.fechaRegistro;
        final fechaInicio = _fechaInicio ?? DateTime(1900);
        final fechaFin = _fechaFin ?? DateTime.now().add(const Duration(days: 365));
        
        // Comparar solo la fecha (sin hora)
        final fechaOrdenSolo = DateTime(
          fechaOrden.year,
          fechaOrden.month,
          fechaOrden.day,
        );
        final fechaInicioSolo = DateTime(
          fechaInicio.year,
          fechaInicio.month,
          fechaInicio.day,
        );
        final fechaFinSolo = DateTime(
          fechaFin.year,
          fechaFin.month,
          fechaFin.day,
        );
        
        return fechaOrdenSolo.isAfter(
              fechaInicioSolo.subtract(const Duration(days: 1)),
            ) &&
            fechaOrdenSolo.isBefore(fechaFinSolo.add(const Duration(days: 1)));
      }).toList();
    }
    
    if (mounted) {
      setState(() {
        _ordenesFiltradas = ordenesFiltradas;
      });
    }
  }

  Future<void> _cargarDetallesOrden(int ordenId) async {
    if (_detallesOrdenes.containsKey(ordenId)) {
      return;
    }

    setState(() {
      _cargandoDetalles[ordenId] = true;
    });

    try {
      final detalles = await _ordenDetalleService.getOrdenesDetallesByOrden(ordenId);
      if (mounted) {
        setState(() {
          _detallesOrdenes[ordenId] = detalles;
          _cargandoDetalles[ordenId] = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _cargandoDetalles[ordenId] = false;
        });
      }
    }
  }

  String _formatEstado(String estado) {
    switch (estado.toLowerCase().trim()) {
      case 'pendiente':
        return 'Pendiente';
      case 'en_proceso':
        return 'En Proceso';
      case 'completada':
        return 'Completada';
      case 'cancelada':
        return 'Cancelada';
      case 'facturada':
        return 'Facturada';
      default:
        return estado;
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase().trim()) {
      case 'pendiente':
        return AppColors.warning;
      case 'en_proceso':
        return AppColors.primary;
      case 'completada':
        return AppColors.success;
      case 'facturada':
        return AppColors.purple;
      case 'cancelada':
        return AppColors.danger;
      default:
        return AppColors.gray500;
    }
  }

  String _formatFechaHora(DateTime fecha) {
    final fechaLocal = fecha.toLocal();
    final dia = fechaLocal.day.toString().padLeft(2, '0');
    final mes = fechaLocal.month.toString().padLeft(2, '0');
    final anio = fechaLocal.year;
    
    int hora = fechaLocal.hour;
    final minutos = fechaLocal.minute.toString().padLeft(2, '0');
    String periodo = 'a.m.';
    
    if (hora == 0) {
      hora = 12;
      periodo = 'a.m.';
    } else if (hora == 12) {
      periodo = 'p.m.';
    } else if (hora > 12) {
      hora = hora - 12;
      periodo = 'p.m.';
    }
    
    return '$dia/$mes/$anio $hora:$minutos $periodo';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_ordenes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history,
              size: 64,
              color: AppColors.gray500,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay órdenes pasadas',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarOrdenes,
      child: Column(
        children: [
          // Botón de filtros
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Órdenes Pasadas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleText,
                  ),
                ),
                IconButton(
                  icon: Stack(
                    children: [
                      Icon(
                        Icons.filter_list,
                        color: _tieneFiltrosActivos() 
                            ? AppColors.primary 
                            : AppColors.gray600,
                      ),
                      if (_tieneFiltrosActivos())
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.danger,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  onPressed: _mostrarFiltros,
                  tooltip: 'Filtrar órdenes',
                ),
              ],
            ),
          ),
          // Lista de órdenes
          Expanded(
            child: _ordenesFiltradas.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.filter_alt_off,
                          size: 64,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No hay órdenes que coincidan con los filtros',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.gray500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _ordenesFiltradas.length,
                    itemBuilder: (context, index) {
                      final orden = _ordenesFiltradas[index];
                      final isExpanded = _expandedOrdenes[orden.id] ?? false;
                      return _buildOrdenExpandible(orden, isExpanded);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdenExpandible(Orden orden, bool isExpanded) {
    final estadoColor = _getEstadoColor(orden.estado);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: estadoColor,
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
          InkWell(
            onTap: () async {
              if (!isExpanded) {
                await _cargarDetallesOrden(orden.id);
                // una sola orden expandida a la vez
                setState(() {
                  _expandedOrdenes.clear();
                  _expandedOrdenes[orden.id] = true;
                });
              } else {
                // Si ya está expandida, cerrarla
                setState(() {
                  _expandedOrdenes[orden.id] = false;
                });
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              child: Row(
                children: [
                  Container(
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
                      Icons.receipt_long,
                      color: AppColors.secondary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Orden #${orden.id}',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.black,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Estado: ${_formatEstado(orden.estado)}',
                          style: TextStyle(
                            color: _getEstadoColor(orden.estado),
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                              ),
                            ),
                  
                        
                        if (orden.estado.toLowerCase() == 'completada' || 
                            orden.estado.toLowerCase() == 'facturada') ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle_outline,
                                size: 12,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Completada: ${_formatFechaHora(orden.fechaActualizacion)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.success,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 4),
                        Text(
                          'Subtotal: Lps. ${orden.subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.gray700,
                          ),
                        ),
                   
                      ],
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppColors.gray600,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.lightGray.withOpacity(0.3),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
                border: Border(
                  top: BorderSide(color: AppColors.gray300),
                ),
              ),
              child: _cargandoDetalles[orden.id] == true
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : _detallesOrdenes[orden.id] == null ||
                          _detallesOrdenes[orden.id]!.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text(
                            'No hay detalles disponibles',
                            style: TextStyle(color: AppColors.gray600),
                          ),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Información de fechas
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.lightGray.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.gray300,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.access_time,
                                        size: 16,
                                        color: AppColors.primary,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Fecha de Creación',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: AppColors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 24),
                                    child: Text(
                                      _formatFechaHora(orden.fechaRegistro),
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.gray700,
                                      ),
                                    ),
                                  ),
                                  if (orden.estado.toLowerCase() == 'completada' || 
                                      orden.estado.toLowerCase() == 'facturada') ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          size: 16,
                                          color: AppColors.success,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Fecha de Completado',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: AppColors.black,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 24),
                                      child: Text(
                                        _formatFechaHora(orden.fechaActualizacion),
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: AppColors.success,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (orden.observaciones != null &&
                                orden.observaciones!.isNotEmpty) ...[
                              const Text(
                                'Observaciones:',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                orden.observaciones!,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.gray600,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            const Text(
                              'Servicios:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...(_detallesOrdenes[orden.id] ?? [])
                                .where((detalle) => detalle.activo)
                                .map((detalle) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Icon(
                                      detalle.esPaquete
                                          ? Icons.inventory_2
                                          : Icons.content_cut,
                                      size: 20,
                                      color: AppColors.secondary,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            detalle.nombre,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          if (detalle.extras != null &&
                                              detalle.extras!.isNotEmpty) ...[
                                            ...detalle.extras!.map((extra) {
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 16, top: 4),
                                                child: Text(
                                                  '- ${extra.servicioExtra?.nombre ?? 'Extra'}',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.gray600,
                                                  ),
                                                ),
                                              );
                                            }),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Text(
                                      'Lps. ${detalle.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'Lps. ${orden.subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
            ),
        ],
      ),
    );
  }
  
  bool _tieneFiltrosActivos() {
    return (_filtroEstado != null && _filtroEstado!.isNotEmpty) ||
           (_filtroServicio != null && _filtroServicio!.isNotEmpty) ||
           (_tipoFiltroFecha != 'todos');
  }
  
  Future<void> _mostrarFiltros() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray400,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Filtrar Órdenes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleText,
                  ),
                ),
              ),
              // Filtro por estado
              ListTile(
                title: const Text('Estado'),
                trailing: DropdownButton<String>(
                  value: _filtroEstado,
                  hint: const Text('Todos'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('Todos'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'completada',
                      child: Text('Completada'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'cancelada',
                      child: Text('Cancelada'),
                    ),
                    const DropdownMenuItem<String>(
                      value: 'facturada',
                      child: Text('Facturada'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _filtroEstado = value;
                    });
                    _aplicarFiltros();
                  },
                ),
              ),
              // Filtro por servicio
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Buscar por servicio',
                    hintText: 'Nombre del servicio',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _filtroServicio != null && _filtroServicio!.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _filtroServicio = null;
                              });
                              _aplicarFiltros();
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _filtroServicio = value.isEmpty ? null : value;
                    });
                    _aplicarFiltros();
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Filtro por fecha
              ListTile(
                title: const Text('Filtrar por fecha'),
                trailing: TextButton(
                  onPressed: _mostrarSelectorFecha,
                  child: Text(
                    _formatearRangoFechas(),
                    style: TextStyle(
                      color: _tipoFiltroFecha != 'todos'
                          ? AppColors.primary
                          : AppColors.gray600,
                    ),
                  ),
                ),
              ),
              if (_tieneFiltrosActivos())
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _filtroEstado = null;
                          _filtroServicio = null;
                          _fechaInicio = null;
                          _fechaFin = null;
                          _tipoFiltroFecha = 'todos';
                        });
                        _aplicarFiltros();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.danger,
                        foregroundColor: AppColors.white,
                      ),
                      child: const Text('Limpiar filtros'),
                    ),
                  ),
                ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
  
  String _formatearRangoFechas() {
    switch (_tipoFiltroFecha) {
      case 'hoy':
        return 'Hoy';
      case 'mes':
        return 'Este mes';
      case 'dia':
        if (_fechaInicio != null) {
          return _formatearFecha(_fechaInicio!);
        }
        return 'Día específico';
      case 'rango':
        if (_fechaInicio != null && _fechaFin != null) {
          return '${_formatearFecha(_fechaInicio!)} - ${_formatearFecha(_fechaFin!)}';
        }
        return 'Rango de fechas';
      default:
        return 'Todos';
    }
  }
  
  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
  
  Future<void> _mostrarSelectorFecha() async {
    final opcion = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.gray400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Filtrar por fecha',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleText,
                ),
              ),
            ),
            _buildOpcionFiltroFecha('hoy', 'Hoy', Icons.today),
            _buildOpcionFiltroFecha('mes', 'Este mes', Icons.calendar_month),
            _buildOpcionFiltroFecha('dia', 'Día específico', Icons.event),
            _buildOpcionFiltroFecha('rango', 'Rango de fechas', Icons.date_range),
            _buildOpcionFiltroFecha('todos', 'Todos', Icons.clear_all),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (opcion == null) return;

    final ahora = DateTime.now();

    setState(() {
      switch (opcion) {
        case 'todos':
          _tipoFiltroFecha = 'todos';
          _fechaInicio = null;
          _fechaFin = null;
          break;
        case 'hoy':
          _tipoFiltroFecha = 'hoy';
          _fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
          _fechaFin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
          break;
        case 'mes':
          _tipoFiltroFecha = 'mes';
          _fechaInicio = DateTime(ahora.year, ahora.month, 1);
          _fechaFin = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);
          break;
        case 'dia':
          _tipoFiltroFecha = 'dia';
          _aplicarFiltroDiaEspecifico();
          return;
        case 'rango':
          _tipoFiltroFecha = 'rango';
          _aplicarFiltroRango();
          return;
      }
      _aplicarFiltros();
    });
  }
  
  Widget _buildOpcionFiltroFecha(String valor, String texto, IconData icono) {
    final estaSeleccionado = _tipoFiltroFecha == valor;
    return ListTile(
      leading: Icon(
        icono,
        color: estaSeleccionado ? AppColors.primary : AppColors.gray600,
      ),
      title: Text(
        texto,
        style: TextStyle(
          fontWeight: estaSeleccionado ? FontWeight.bold : FontWeight.normal,
          color: estaSeleccionado ? AppColors.primary : AppColors.titleText,
        ),
      ),
      trailing: estaSeleccionado
          ? Icon(Icons.check, color: AppColors.primary)
          : null,
      onTap: () => Navigator.pop(context, valor),
    );
  }
  
  Future<void> _aplicarFiltroDiaEspecifico() async {
    final DateTime ahora = DateTime.now();
    final DateTime primerDia = DateTime(ahora.year - 1, 1, 1);
    final DateTime ultimoDia = DateTime(ahora.year + 1, 12, 31);

    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? ahora,
      firstDate: primerDia,
      lastDate: ultimoDia,
      helpText: 'Selecciona día',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.titleText,
            ),
          ),
          child: Localizations.override(context: context, child: child!),
        );
      },
    );

    if (fechaSeleccionada != null) {
      setState(() {
        _fechaInicio = DateTime(
          fechaSeleccionada.year,
          fechaSeleccionada.month,
          fechaSeleccionada.day,
        );
        _fechaFin = DateTime(
          fechaSeleccionada.year,
          fechaSeleccionada.month,
          fechaSeleccionada.day,
          23,
          59,
          59,
        );
      });
      _aplicarFiltros();
    } else {
      setState(() {
        _tipoFiltroFecha = 'todos';
        _fechaInicio = null;
        _fechaFin = null;
      });
      _aplicarFiltros();
    }
  }

  Future<void> _aplicarFiltroRango() async {
    final DateTime ahora = DateTime.now();
    final DateTime primerDia = DateTime(ahora.year - 1, 1, 1);
    final DateTime ultimoDia = DateTime(ahora.year + 1, 12, 31);

    // Seleccionar fecha de inicio
    final DateTime? fechaInicioSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? ahora,
      firstDate: primerDia,
      lastDate: ultimoDia,
      helpText: 'Fecha inicio',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.titleText,
            ),
          ),
          child: Localizations.override(context: context, child: child!),
        );
      },
    );

    if (fechaInicioSeleccionada == null) {
      setState(() {
        _tipoFiltroFecha = 'todos';
        _fechaInicio = null;
        _fechaFin = null;
      });
      _aplicarFiltros();
      return;
    }

    // Seleccionar fecha de fin
    final DateTime? fechaFinSeleccionada = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? fechaInicioSeleccionada,
      firstDate: fechaInicioSeleccionada,
      lastDate: ultimoDia,
      helpText: 'Fecha fin',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.titleText,
            ),
          ),
          child: Localizations.override(context: context, child: child!),
        );
      },
    );

    if (fechaFinSeleccionada != null) {
      setState(() {
        _fechaInicio = DateTime(
          fechaInicioSeleccionada.year,
          fechaInicioSeleccionada.month,
          fechaInicioSeleccionada.day,
        );
        _fechaFin = DateTime(
          fechaFinSeleccionada.year,
          fechaFinSeleccionada.month,
          fechaFinSeleccionada.day,
          23,
          59,
          59,
        );
      });
      _aplicarFiltros();
    } else {
      setState(() {
        _tipoFiltroFecha = 'todos';
        _fechaInicio = null;
        _fechaFin = null;
      });
      _aplicarFiltros();
    }
  }
}

