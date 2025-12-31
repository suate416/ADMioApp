import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/orden.service.dart';
import '../services/estacion.service.dart';
import '../services/orden_detalle.service.dart';
import '../services/caja.service.dart';
import '../models/usuario.model.dart';
import '../models/orden.model.dart';
import '../models/orden_detalle.model.dart';
import '../widgets/tab_navigation_bar.dart';
import '../widgets/orden_en_proceso_widget.dart';
import '../widgets/logout_menu_bottom_sheet.dart';
import '../widgets/servicios_y_paquetes_widget.dart';
import '../widgets/crear_orden_modal.dart';
import '../config/app_colors.dart';
import 'login_screen.dart';
import 'ordenes_pasadas_screen.dart';

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
  final CajaService _cajaService = CajaService();

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
  Map<int, List<OrdenDetalle>> _detallesOrdenes =
      {}; // Cache de detalles por orden (usado para cargar detalles de órdenes pasadas)

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
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
        final estacionesUsuario = await _estacionService.getEstacionesByUsuario(
          usuario.id,
        );
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
        
      }

      final estaciones = await _estacionService.getEstacionesBySucursal(
        usuario.sucursalId,
      );
      if (mounted) {
        setState(() {
          _estaciones = estaciones;
          _tieneEstacionAsignada =
              false; // No tiene estación asignada 
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
      final ordenes = await _ordenService.getOrdenesBySucursal(
        _usuario!.sucursalId,
      );
      if (mounted) {
        final todasLasOrdenes = ordenes
            .where((orden) => orden.usuarioId == _usuario!.id)
            .toList();

        // Cargar detalles de órdenes pasadas
        final ordenesPasadas = todasLasOrdenes.where((orden) {
          final estado = orden.estado.toLowerCase().trim();
          return estado == 'completada' ||
              estado == 'cancelada' ||
              estado == 'facturada';
        }).toList();

        for (var orden in ordenesPasadas) {
          try {
            final detalles = await _ordenDetalleService
                .getOrdenesDetallesByOrden(orden.id);
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
      }
    } catch (e) {
      // Si hay error al cargar órdenes, no mostramos el botón
      if (mounted) {
        setState(() {
          _ordenesActivas = [];
          _todasLasOrdenes = [];
        });
      }
    }
  }

  Future<bool> _verificarCajaAbierta() async {
    if (_usuario == null) {
      return false;
    }

    try {
      // Verificar si hay una caja abierta para la sucursal del usuario
      final tieneCajaAbierta = await _cajaService
          .verificarCajaAbiertaPorSucursal(_usuario!.sucursalId);
      return tieneCajaAbierta;
    } catch (e) {
      // Si hay error al verificar, asumimos que no hay caja abierta
      return false;
    }
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

    // Verificar si hay una caja abierta
    final tieneCajaAbierta = await _verificarCajaAbierta();
    if (!tieneCajaAbierta) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No hay una caja abierta. Por favor, abra una caja antes de crear una orden.',
            ),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.all(16),
            action: SnackBarAction(
              label: 'Entendido',
              textColor: AppColors.white,
              onPressed: () {},
            ),
          ),
        );
      }
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CrearOrdenModal(
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

  Future<void> _crearOrden(String? observaciones) async {
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
        observaciones: observaciones,
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
    LogoutMenuBottomSheet.show(
      context: context,
      onLogout: _handleLogout,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingEstaciones) {
      return Scaffold(body: const Center(child: CircularProgressIndicator()));
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
                    icon: const Icon(
                      Icons.menu,
                      color: AppColors.black,
                      size: 32,
                    ),
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
    );
  }

  Widget _buildContenidoTab() {
    // Tab de En Proceso
    if (_selectedTab == 2) {
      return _buildContenidoEnProceso();
    }

    if (_selectedTab == 1) {
      // Tab de Servicios
      if (_usuario == null) {
        return const Center(child: CircularProgressIndicator());
      }

      final ordenActiva = _ordenesActivas.isNotEmpty
          ? _ordenesActivas.first
          : null;

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
      // Tab de Pasadas
      if (_usuario == null) {
        return const Center(child: CircularProgressIndicator());
      }

      return OrdenesPasadasScreen(
        usuario: _usuario!,
        onRefresh: () async {
          await _cargarOrdenesActivas();
        },
      );
    }

    return const Center(child: Text('Tab no implementado'));
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
              Icon(Icons.person_off, size: 80, color: AppColors.gray500),
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
                style: TextStyle(fontSize: 14, color: AppColors.gray600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    // Obtener la orden activa
    final ordenActiva = _ordenesActivas.isNotEmpty
        ? _ordenesActivas.first
        : null;

    return OrdenEnProcesoWidget(
      key: ValueKey<int>(
        ordenActiva?.id ?? 0,
      ), // Forzar reconstrucción cuando cambia la orden
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
}
