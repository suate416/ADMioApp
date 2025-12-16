import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/orden.service.dart';
import '../services/estacion.service.dart';
import '../services/orden_detalle.service.dart';
import '../models/usuario.model.dart';
import '../models/orden.model.dart';
import '../models/orden_detalle.model.dart';
import '../widgets/bottom_nav_bar.dart';
import '../widgets/tab_navigation_bar.dart';
import '../widgets/orden_en_proceso_widget.dart';
import '../widgets/servicios_y_paquetes_widget.dart';
import '../config/app_colors.dart';
import 'usuario_resumen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class CrearOrdenScreen extends StatefulWidget {
  const CrearOrdenScreen({super.key});

  @override
  State<CrearOrdenScreen> createState() => _CrearOrdenScreenState();
}

class _CrearOrdenScreenState extends State<CrearOrdenScreen> {
  final AuthService _authService = AuthService();
  final OrdenService _ordenService = OrdenService();
  final EstacionService _estacionService = EstacionService();
  final OrdenDetalleService _ordenDetalleService = OrdenDetalleService();
  final _observacionesController = TextEditingController();

  Usuario? _usuario;
  List<Estacion> _estaciones = [];
  Estacion? _estacionSeleccionada;
  List<Orden> _ordenesActivas = [];
  List<Orden> _todasLasOrdenes = [];
  bool _isLoading = false;
  bool _isLoadingEstaciones = true;
  bool _isLoadingOrdenes = false;
  bool _tieneEstacionAsignada = false; 
  String? _error;
  int _selectedTab = 2; // 0: Pasadas, 1: Servicios, 2: En Proceso
  int _currentBottomNavIndex = 1; // Botón central (tijeras) está activo
  Map<int, bool> _expandedOrdenes = {}; // Para controlar qué órdenes están expandidas
  Map<int, List<OrdenDetalle>> _detallesOrdenes = {}; // Cache de detalles por orden
  Map<int, bool> _cargandoDetalles = {}; // Para controlar qué órdenes están cargando detalles
  
  // Filtros para órdenes pasadas
  String? _filtroEstado;
  String? _filtroServicio;
  String? _filtroServicioSeleccionado; // Servicio seleccionado del dropdown
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _tipoFiltroFecha = 'todos'; // 'todos', 'hoy', 'mes', 'dia', 'rango'
  List<Orden> _ordenesPasadasFiltradas = [];
  List<String> _serviciosRealizados = []; // Lista de servicios únicos realizados

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final usuario = await _authService.getUsuario();
      if (usuario == null) {
        if (mounted) {
          Navigator.pop(context);
        }
        return;
      }

      if (!mounted) return;
      setState(() {
        _usuario = usuario;
      });

      // Primero intentar obtener la estación asignada al usuario
      try {
        final estacionesUsuario = await _estacionService.getEstacionesByUsuario(usuario.id);
        if (estacionesUsuario.isNotEmpty && mounted) {
          setState(() {
            _estacionSeleccionada = estacionesUsuario.first;
            _estaciones = estacionesUsuario;
            _tieneEstacionAsignada = true;
            _isLoadingEstaciones = false;
          });
          // Cargar órdenes activas antes de retornar
          await _cargarOrdenesActivas();
          return;
        }
      } catch (e) {
        // Si no tiene estación asignada, cargar todas las estaciones de la sucursal
      }

      // Si no tiene estación asignada, cargar todas las estaciones de la sucursal
      final estaciones = await _estacionService.getEstacionesBySucursal(usuario.sucursalId);
      if (mounted) {
        setState(() {
          _estaciones = estaciones;
          _tieneEstacionAsignada = false; // No tiene estación asignada específicamente
          _isLoadingEstaciones = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoadingEstaciones = false;
        });
      }
    }

    // Cargar órdenes activas
    await _cargarOrdenesActivas();
  }

  Future<void> _cargarOrdenesActivas() async {
    if (_usuario == null) return;

    try {
      final ordenes = await _ordenService.getOrdenesBySucursal(_usuario!.sucursalId);
      if (mounted) {
        final todasLasOrdenes = ordenes.where((orden) => 
          orden.usuarioId == _usuario!.id
        ).toList();
        
        // Cargar detalles de órdenes pasadas para poder filtrar por servicio
        final ordenesPasadas = todasLasOrdenes.where((orden) {
          final estado = orden.estado.toLowerCase().trim();
          return estado == 'completada' || estado == 'cancelada' || estado == 'facturada';
        }).toList();
        
        for (var orden in ordenesPasadas) {
          try {
            final detalles = await _ordenDetalleService.getOrdenesDetallesByOrden(orden.id);
            _detallesOrdenes[orden.id] = detalles;
          } catch (e) {
            // Ignorar errores al cargar detalles
          }
        }
        
        setState(() {
          // Filtrar todas las órdenes del usuario actual
          _todasLasOrdenes = todasLasOrdenes;
          
          // Filtrar órdenes activas (en_proceso o pendiente) del usuario actual
          _ordenesActivas = _todasLasOrdenes.where((orden) {
            final estado = orden.estado.toLowerCase().trim();
            return estado == 'en_proceso' || estado == 'pendiente';
          }).toList();
        });
        
        // Obtener lista de servicios realizados
        _obtenerServiciosRealizados();
        
        // Aplicar filtros a órdenes pasadas
        _aplicarFiltrosOrdenesPasadas();
      }
    } catch (e) {
      // Si hay error al cargar órdenes, no mostramos el botón
      if (mounted) {
        setState(() {
          _ordenesActivas = [];
          _todasLasOrdenes = [];
          _ordenesPasadasFiltradas = [];
        });
      }
    }
  }
  
  void _obtenerServiciosRealizados() {
    final Set<String> serviciosUnicos = {};
    
    for (var orden in _todasLasOrdenes) {
      final estado = orden.estado.toLowerCase().trim();
      if (estado == 'completada' || estado == 'cancelada' || estado == 'facturada') {
        final detalles = _detallesOrdenes[orden.id] ?? [];
        for (var detalle in detalles) {
          if (detalle.activo && detalle.nombre.isNotEmpty) {
            serviciosUnicos.add(detalle.nombre);
          }
        }
      }
    }
    
    setState(() {
      _serviciosRealizados = serviciosUnicos.toList()..sort();
    });
  }
  
  void _aplicarFiltrosOrdenesPasadas() {
    var ordenesPasadas = _todasLasOrdenes.where((orden) {
      final estado = orden.estado.toLowerCase().trim();
      return estado == 'completada' || estado == 'cancelada' || estado == 'facturada';
    }).toList();
    
    // Filtro por estado
    if (_filtroEstado != null && _filtroEstado!.isNotEmpty) {
      ordenesPasadas = ordenesPasadas.where((orden) {
        return orden.estado.toLowerCase().trim() == _filtroEstado!.toLowerCase().trim();
      }).toList();
    }
    
    // Filtro por servicio (prioridad al dropdown, luego al campo de texto)
    String? servicioFiltro = _filtroServicioSeleccionado ?? _filtroServicio;
    if (servicioFiltro != null && servicioFiltro.isNotEmpty) {
      ordenesPasadas = ordenesPasadas.where((orden) {
        final detalles = _detallesOrdenes[orden.id] ?? [];
        return detalles.any((detalle) => 
          detalle.activo && 
          detalle.nombre.toLowerCase().contains(servicioFiltro.toLowerCase())
        );
      }).toList();
    }
    
    // Filtro por fecha
    if (_tipoFiltroFecha != 'todos' && _fechaInicio != null && _fechaFin != null) {
      ordenesPasadas = ordenesPasadas.where((orden) {
        final fechaOrden = orden.fecha;
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
        _ordenesPasadasFiltradas = ordenesPasadas;
      });
    }
  }

  List<Orden> _getOrdenesPorTab() {
    switch (_selectedTab) {
      case 0: // Pasadas
        return _ordenesPasadasFiltradas;
      case 1: // Servicios
        return []; // Por ahora vacío, se puede implementar después
      case 2: // En Proceso
        return _ordenesActivas;
      default:
        return [];
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

  Future<void> _abrirModalCrearOrden() async {
    if (_estacionSeleccionada == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona una estación'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CrearOrdenModal(
        usuario: _usuario!,
        estacionSeleccionada: _estacionSeleccionada!,
        estaciones: _estaciones,
        onEstacionChanged: (estacion) {
          setState(() {
            _estacionSeleccionada = estacion;
          });
        },
        onCreateOrden: _crearOrden,
        isLoading: _isLoading,
      ),
    );
  }

  Future<void> _crearOrden() async {
    if (_estacionSeleccionada == null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orden = await _ordenService.createOrden(
        sucursalId: _usuario!.sucursalId,
        estacionId: _estacionSeleccionada!.id,
        observaciones: _observacionesController.text.trim().isEmpty
            ? null
            : _observacionesController.text.trim(),
      );

      setState(() {
        _isLoading = false;
      });

      // Recargar órdenes activas después de crear una orden
      await _cargarOrdenesActivas();

      if (mounted) {
        // Cambiar a la pestaña de Servicios ANTES de cerrar el modal
        setState(() {
          _selectedTab = 1; // Tab de Servicios
        });
        
        // Cerrar modal
        Navigator.pop(context);
        
        // Mostrar mensaje de éxito después de un pequeño delay para asegurar que el modal se cerró
        await Future.delayed(const Duration(milliseconds: 100));
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Orden #${orden.id} creada exitosamente.'),
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
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _selectedTab = index;
    });
    // Recargar órdenes cuando cambia el tab
    _cargarOrdenesActivas();
  }

  void _onBottomNavChanged(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });
    
    switch (index) {
      case 0:
        // Home - navegar a HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
        break;
      case 1:
        // Botón central - ya estamos aquí
        break;
      case 2:
        // Account - navegar a pantalla de resumen del usuario
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const UsuarioResumenScreen(),
          ),
        );
        break;
    }
  }

  Future<void> _handleLogout() async {
    await _authService.logout();
    if (mounted) {
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
                _handleLogout();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingEstaciones) {
    return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null && _estaciones.isEmpty) {
      return Scaffold(
        body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header con nombre de usuario
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (_usuario != null) ...[
                          Text(
                            '${_usuario!.nombre} ${_usuario!.apellido}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.black,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _usuario!.usuarioUnico,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.gray500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.menu, color: AppColors.black, size: 32),
                    iconSize: 32,
                    onPressed: () => _showMenu(context),
                  ),
                ],
              ),
            ),
            // Tabs de navegación
            TabNavigationBar(
              selectedIndex: _selectedTab,
              onTabChanged: _onTabChanged,
            ),
            const SizedBox(height: 16),
            // Área de contenido
            Expanded(
              child: _isLoadingOrdenes
                  ? const Center(child: CircularProgressIndicator())
                  : _buildContenidoTab(),
            ),
            // Botón "Iniciar Orden" - solo se muestra si no hay órdenes activas y tiene estación asignada
            if (_ordenesActivas.isEmpty && _tieneEstacionAsignada)
              Padding(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 24,
                  bottom: 32,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _abrirModalCrearOrden,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'Iniciar Orden',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: BuildBottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        cambiarTab: _onBottomNavChanged,
      ),
    );
  }

  Widget _buildContenidoTab() {
    // Tab de En Proceso - mostrar contenido usando OrdenEnProcesoWidget
    if (_selectedTab == 2) {
      return _buildContenidoEnProceso();
    }

    final ordenes = _getOrdenesPorTab();

    if (_selectedTab == 1) {
      // Tab de Servicios - mostrar servicios y paquetes disponibles
      if (_usuario == null) {
        return const Center(child: CircularProgressIndicator());
      }
      
      final ordenActiva = _ordenesActivas.isNotEmpty ? _ordenesActivas.first : null;
      
      return ServiciosYPaquetesWidget(
        negocioId: _usuario!.negocioId,
        ordenActiva: ordenActiva,
        onServicioAgregado: () async {
          // Recargar órdenes activas después de agregar un servicio
          await _cargarOrdenesActivas();
          if (mounted) {
            setState(() {});
          }
        },
      );
    }

    if (_selectedTab == 0) {
      // Tab de Pasadas - mostrar con filtros
      return Column(
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
                  onPressed: _mostrarFiltrosOrdenesPasadas,
                  tooltip: 'Filtrar órdenes',
                ),
              ],
            ),
          ),
          // Lista de órdenes
          Expanded(
            child: ordenes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _tieneFiltrosActivos() ? Icons.filter_alt_off : Icons.history,
                          size: 64,
                          color: AppColors.gray500,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _tieneFiltrosActivos()
                              ? 'No hay órdenes que coincidan con los filtros'
                              : 'No hay órdenes pasadas',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppColors.gray500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _cargarOrdenesActivas,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: ordenes.length,
                      itemBuilder: (context, index) {
                        final orden = ordenes[index];
                        final isExpanded = _expandedOrdenes[orden.id] ?? false;
                        return _buildOrdenExpandible(orden, isExpanded);
                      },
                    ),
                  ),
          ),
        ],
      );
    }

    if (ordenes.isEmpty) {
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
      onRefresh: _cargarOrdenesActivas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: ordenes.length,
        itemBuilder: (context, index) {
          final orden = ordenes[index];
          final isExpanded = _expandedOrdenes[orden.id] ?? false;
          return _buildOrdenExpandible(orden, isExpanded);
        },
      ),
    );
  }

  Widget _buildContenidoEnProceso() {
    // Si el usuario no tiene estación asignada, mostrar mensaje
    if (!_tieneEstacionAsignada) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.person_off,
                size: 80,
                color: AppColors.gray500,
              ),
              const SizedBox(height: 16),
              Text(
                'No tiene estación asignada',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.titleText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Contacte a su supervisor para que le asigne una estación de trabajo.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Obtener la orden activa (debería haber solo una)
    final ordenActiva = _ordenesActivas.isNotEmpty ? _ordenesActivas.first : null;

    return OrdenEnProcesoWidget(
      key: ValueKey<int>(ordenActiva?.id ?? 0), // Forzar reconstrucción cuando cambia la orden
      ordenActiva: ordenActiva,
      onRefresh: () async {
        // Recargar órdenes activas para obtener la orden actualizada con el nuevo subtotal
        await _cargarOrdenesActivas();
        // Forzar reconstrucción del widget después de recargar
        if (mounted) {
          setState(() {});
        }
      },
      onCambiarTabServicios: () {
        // Cambiar al tab de Servicios cuando se presiona "Agregar Servicio"
                setState(() {
          _selectedTab = 1; // Tab de Servicios
                });
              },
    );
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
        // Recargar todas las órdenes (activas y pasadas)
        await _cargarOrdenesActivas();

        setState(() {});
        
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
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
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


  Future<void> _cargarDetallesOrden(int ordenId) async {
    if (_detallesOrdenes.containsKey(ordenId)) {
      // Ya están cargados
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
          ListTile(
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
                Icons.receipt_long,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
            title: Text(
              'Orden #${orden.id}',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.titleText,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  'Estado: ${_formatEstado(orden.estado)}',
                  style: TextStyle(
                    color: _getEstadoColor(orden.estado),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: Lps. ${orden.subtotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                  ),
                ),
                if (orden.tiempoTotal > 0)
                  Text(
                    'Tiempo: ${orden.tiempoTotal} min',
                    style: TextStyle(
                      fontSize: 13,
                    ),
                  ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Botón X para cancelar orden (solo si no está cancelada o completada)
                if (orden.estado.toLowerCase() != 'cancelada' && 
                    orden.estado.toLowerCase() != 'completada' &&
                    orden.estado.toLowerCase() != 'facturada')
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.red, size: 28),
                    onPressed: () => _cancelarOrden(orden),
                    tooltip: 'Cancelar orden',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                const SizedBox(width: 8),
                Icon(
              isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                ),
              ],
            ),
            onTap: () async {
              if (!isExpanded) {
                // Cargar detalles si no están cargados
                await _cargarDetallesOrden(orden.id);
              }
              setState(() {
                _expandedOrdenes[orden.id] = !isExpanded;
              });
            },
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
                                          fontSize: 13,
                                          color: AppColors.titleText,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 24),
                                    child: Text(
                                      _formatFechaHora(orden.fecha),
                                      style: TextStyle(
                                        fontSize: 13,
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
                                            fontSize: 13,
                                            color: AppColors.titleText,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Padding(
                                      padding: const EdgeInsets.only(left: 24),
                                      child: Text(
                                        _formatFechaHora(orden.fecha),
                                        style: TextStyle(
                                          fontSize: 13,
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
                                  color: AppColors.gray800,
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
                                                padding:
                                                    const EdgeInsets.only(
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
           (_filtroServicioSeleccionado != null && _filtroServicioSeleccionado!.isNotEmpty) ||
           (_tipoFiltroFecha != 'todos');
  }
  
  Future<void> _mostrarFiltrosOrdenesPasadas() async {
    // Actualizar servicios realizados antes de abrir el modal
    _obtenerServiciosRealizados();
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          return Container(
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Estado',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    DropdownButton<String>(
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
                          value: 'facturada',
                          child: Text('Facturada'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _filtroEstado = value;
                        });
                        setModalState(() {});
                        _aplicarFiltrosOrdenesPasadas();
                      },
                    ),
                  ],
                ),
              ),
              // Filtro por servicio - Dropdown
              if (_serviciosRealizados.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Servicio realizado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      DropdownButton<String>(
                        value: _filtroServicioSeleccionado,
                        hint: const Text('Todos'),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('Todos'),
                          ),
                          ..._serviciosRealizados.map((servicio) {
                            return DropdownMenuItem<String>(
                              value: servicio,
                              child: Text(
                                servicio,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _filtroServicioSeleccionado = value;
                            // Limpiar el campo de texto cuando se selecciona del dropdown
                            if (value != null) {
                              _filtroServicio = null;
                            }
                          });
                          setModalState(() {});
                          _aplicarFiltrosOrdenesPasadas();
                        },
                      ),
                    ],
                  ),
                ),
              // Filtro por fecha
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filtrar por fecha',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    OutlinedButton(
                      onPressed: _mostrarSelectorFechaOrdenesPasadas,
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: _tipoFiltroFecha != 'todos'
                              ? AppColors.primary
                              : AppColors.gray400,
                          width: 1,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatearRangoFechasOrdenesPasadas(),
                            style: TextStyle(
                              color: _tipoFiltroFecha != 'todos'
                                  ? AppColors.primary
                                  : AppColors.gray600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            color: _tipoFiltroFecha != 'todos'
                                ? AppColors.primary
                                : AppColors.gray600,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ],
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
                          _filtroServicioSeleccionado = null;
                          _fechaInicio = null;
                          _fechaFin = null;
                          _tipoFiltroFecha = 'todos';
                        });
                        _aplicarFiltrosOrdenesPasadas();
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
          );
        },
      ),
    );
  }
  
  String _formatearRangoFechasOrdenesPasadas() {
    switch (_tipoFiltroFecha) {
      case 'hoy':
        return 'Hoy';
      case 'mes':
        return 'Este mes';
      case 'dia':
        if (_fechaInicio != null) {
          return _formatearFechaOrdenesPasadas(_fechaInicio!);
        }
        return 'Día específico';
      case 'rango':
        if (_fechaInicio != null && _fechaFin != null) {
          return '${_formatearFechaOrdenesPasadas(_fechaInicio!)} - ${_formatearFechaOrdenesPasadas(_fechaFin!)}';
        }
        return 'Rango de fechas';
      default:
        return 'Todos';
    }
  }
  
  String _formatearFechaOrdenesPasadas(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year}';
  }
  
  Future<void> _mostrarSelectorFechaOrdenesPasadas() async {
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
            _buildOpcionFiltroFechaOrdenesPasadas('hoy', 'Hoy', Icons.today),
            _buildOpcionFiltroFechaOrdenesPasadas('mes', 'Este mes', Icons.calendar_month),
            _buildOpcionFiltroFechaOrdenesPasadas('dia', 'Día específico', Icons.event),
            _buildOpcionFiltroFechaOrdenesPasadas('rango', 'Rango de fechas', Icons.date_range),
            _buildOpcionFiltroFechaOrdenesPasadas('todos', 'Todos', Icons.clear_all),
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
          _aplicarFiltroDiaEspecificoOrdenesPasadas();
          return;
        case 'rango':
          _tipoFiltroFecha = 'rango';
          _aplicarFiltroRangoOrdenesPasadas();
          return;
      }
      _aplicarFiltrosOrdenesPasadas();
    });
  }
  
  Widget _buildOpcionFiltroFechaOrdenesPasadas(String valor, String texto, IconData icono) {
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
  
  Future<void> _aplicarFiltroDiaEspecificoOrdenesPasadas() async {
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
      _aplicarFiltrosOrdenesPasadas();
    } else {
      setState(() {
        _tipoFiltroFecha = 'todos';
        _fechaInicio = null;
        _fechaFin = null;
      });
      _aplicarFiltrosOrdenesPasadas();
    }
  }

  Future<void> _aplicarFiltroRangoOrdenesPasadas() async {
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
      _aplicarFiltrosOrdenesPasadas();
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
      _aplicarFiltrosOrdenesPasadas();
    } else {
      setState(() {
        _tipoFiltroFecha = 'todos';
        _fechaInicio = null;
        _fechaFin = null;
      });
      _aplicarFiltrosOrdenesPasadas();
    }
  }

}

// Modal para crear orden
class _CrearOrdenModal extends StatefulWidget {
  final Usuario usuario;
  final Estacion estacionSeleccionada;
  final List<Estacion> estaciones;
  final Function(Estacion) onEstacionChanged;
  final VoidCallback onCreateOrden;
  final bool isLoading;

  const _CrearOrdenModal({
    required this.usuario,
    required this.estacionSeleccionada,
    required this.estaciones,
    required this.onEstacionChanged,
    required this.onCreateOrden,
    required this.isLoading,
  });

  @override
  State<_CrearOrdenModal> createState() => _CrearOrdenModalState();
}

class _CrearOrdenModalState extends State<_CrearOrdenModal> {
  final _formKey = GlobalKey<FormState>();
  final _observacionesController = TextEditingController();
  Estacion? _estacionSeleccionada;

  @override
  void initState() {
    super.initState();
    _estacionSeleccionada = widget.estacionSeleccionada;
  }

  @override
  void dispose() {
    _observacionesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
              mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: AppColors.gray300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Crear Orden',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                // Información de Sucursal
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Información de Sucursal',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                        Text('Sucursal: ${widget.usuario.sucursal.nombre}'),
                        Text('Código: ${widget.usuario.sucursal.codigo}'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                // Estación
                widget.estaciones.length == 1
                            ? TextFormField(
                        initialValue: '${widget.estacionSeleccionada.codigo}${widget.estacionSeleccionada.descripcion != null ? ' - ${widget.estacionSeleccionada.descripcion}' : ''}',
                                decoration: const InputDecoration(
                                  labelText: 'Estación Asignada *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.place),
                                  filled: true,
                                  enabled: false,
                                ),
                                readOnly: true,
                              )
                            : DropdownButtonFormField<Estacion>(
                                value: _estacionSeleccionada,
                                decoration: const InputDecoration(
                                  labelText: 'Estación *',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.place),
                                ),
                        items: widget.estaciones.map((estacion) {
                                  return DropdownMenuItem<Estacion>(
                                    value: estacion,
                                    child: Text('${estacion.codigo}${estacion.descripcion != null ? ' - ${estacion.descripcion}' : ''}'),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _estacionSeleccionada = value;
                                  });
                          if (value != null) {
                            widget.onEstacionChanged(value);
                          }
                                },
                                validator: (value) {
                                  if (value == null) {
                                    return 'Por favor selecciona una estación';
                                  }
                                  return null;
                                },
                              ),
                        const SizedBox(height: 16),
                // Observaciones
                        TextFormField(
                          controller: _observacionesController,
                          decoration: const InputDecoration(
                            labelText: 'Observaciones (opcional)',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.note),
                          ),
                          maxLines: 3,
                        ),
                        const SizedBox(height: 24),
                // Botón crear
                        ElevatedButton(
                  onPressed: widget.isLoading
                      ? null
                      : () {
                          if (_formKey.currentState!.validate()) {
                            widget.onCreateOrden();
                          }
                        },
                          style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                          ),
                  ),
                  child: widget.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                          ),
                                )
                              : const Text(
                                  'Crear Orden',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ],
            ),
                    ),
                  ),
                ),
    );
  }
}

