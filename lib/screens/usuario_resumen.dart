import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/orden.service.dart';
import '../services/orden_detalle.service.dart';
import '../models/usuario.model.dart';
import '../models/orden.model.dart';
import '../models/orden_detalle.model.dart';
import '../widgets/bottom_nav_bar.dart';
import '../config/app_colors.dart';
import 'crear_orden_screen.dart';
import 'home_screen.dart';

class UsuarioResumenScreen extends StatefulWidget {
  const UsuarioResumenScreen({super.key});

  @override
  State<UsuarioResumenScreen> createState() => _UsuarioResumenScreenState();
}

class _UsuarioResumenScreenState extends State<UsuarioResumenScreen> {
  final AuthService _authService = AuthService();
  final OrdenService _ordenService = OrdenService();
  final OrdenDetalleService _ordenDetalleService = OrdenDetalleService();

  Usuario? _usuario;
  List<Orden> _ordenes = [];
  List<OrdenDetalle> _detalles = [];
  bool _isLoading = true;
  String? _error;
  int _currentBottomNavIndex = 2; // Account está activo
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String _tipoFiltro = 'hoy'; // 'todos', 'hoy', 'mes', 'rango', 'dia'

  @override
  void initState() {
    super.initState();
    // Inicializar filtro por defecto a "Hoy"
    final ahora = DateTime.now();
    _fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
    _fechaFin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

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

      // Cargar todas las órdenes del usuario
      final ordenes = await _ordenService.getOrdenesBySucursal(
        usuario.sucursalId,
      );
      final ordenesUsuario = ordenes
          .where((orden) => orden.usuarioId == usuario.id)
          .toList();

      // Cargar detalles de todas las órdenes
      List<OrdenDetalle> todosLosDetalles = [];
      for (var orden in ordenesUsuario) {
        try {
          final detalles = await _ordenDetalleService.getOrdenesDetallesByOrden(
            orden.id,
          );
          todosLosDetalles.addAll(detalles);
        } catch (e) {}
      }

      if (mounted) {
        setState(() {
          _ordenes = ordenesUsuario;
          _detalles = todosLosDetalles;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceAll('Exception: ', '');
          _isLoading = false;
        });
      }
    }
  }

  // Obtener órdenes facturadas
  List<Orden> _getOrdenesFacturadas() {
    var ordenesFiltradas = _ordenes.where((orden) {
      final estado = orden.estado.toLowerCase().trim();
      return estado == 'facturada';
    }).toList();

    // Filtrar por fecha si hay filtros aplicados
    if (_tipoFiltro != 'todos' && _fechaInicio != null && _fechaFin != null) {
      ordenesFiltradas = ordenesFiltradas.where((orden) {
        final fechaOrden = orden.fecha;
        final fechaInicio = _fechaInicio ?? DateTime(1900);
        final fechaFin =
            _fechaFin ?? DateTime.now().add(const Duration(days: 365));

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

    return ordenesFiltradas;
  }

  // Obtener detalles de órdenes facturadas
  List<OrdenDetalle> _getDetallesFacturadas() {
    final ordenesFacturadas = _getOrdenesFacturadas();
    final idsFacturadas = ordenesFacturadas.map((o) => o.id).toSet();
    return _detalles
        .where((detalle) => idsFacturadas.contains(detalle.ordenId))
        .toList();
  }

  Map<String, int> _getServiciosCount() {
    final Map<String, int> serviciosCount = {};
    final detallesFacturadas = _getDetallesFacturadas();

    for (var detalle in detallesFacturadas) {
      if (detalle.servicio != null) {
        final nombreServicio = detalle.servicio!.nombre;
        serviciosCount[nombreServicio] =
            (serviciosCount[nombreServicio] ?? 0) + 1;
      }
    }
    return serviciosCount;
  }

  double _getTotalIngresos() {
    final ordenesFacturadas = _getOrdenesFacturadas();
    return ordenesFacturadas.fold(0.0, (sum, orden) => sum + orden.subtotal);
  }

  int _getTotalOrdenes() {
    final ordenesFacturadas = _getOrdenesFacturadas();
    return ordenesFacturadas.length;
  }

  int _getTotalTiempo() {
    final ordenesFacturadas = _getOrdenesFacturadas();
    return ordenesFacturadas.fold(0, (sum, orden) => sum + orden.tiempoTotal);
  }

  void _onBottomNavChanged(int index) {
    setState(() {
      _currentBottomNavIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const CrearOrdenScreen()),
        );
        break;
      case 2:
        // Account - ya estamos aquí
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: const Center(child: CircularProgressIndicator()),
        bottomNavigationBar: BuildBottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          cambiarTab: _onBottomNavChanged,
        ),
      );
    }

    if (_error != null) {
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
        bottomNavigationBar: BuildBottomNavigationBar(
          currentIndex: _currentBottomNavIndex,
          cambiarTab: _onBottomNavChanged,
        ),
      );
    }

    final serviciosCount = _getServiciosCount();
    final totalIngresos = _getTotalIngresos();
    final totalOrdenes = _getTotalOrdenes();
    final totalTiempo = _getTotalTiempo();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header con información del usuario
                if (_usuario != null) ...[
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.secondary, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.gray300.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: AppColors.secondary,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  radius: 28,
                                  backgroundColor: AppColors.white,
                                  child: Text(
                                    '${_usuario!.nombre[0]}${_usuario!.apellido[0]}',
                                    style: TextStyle(
                                      color: AppColors.secondary,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${_usuario!.nombre} ${_usuario!.apellido}',
                                      style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.titleText,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      _usuario!.usuarioUnico,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.gray600,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.secondary.withOpacity(
                                          0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: AppColors.secondary
                                              .withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        _usuario!.rol.nombre,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.secondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Container(height: 1, color: AppColors.gray300),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: _buildInfoItem(
                                  'Sucursal',
                                  _usuario!.sucursal.nombre,
                                  Icons.store,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 40,
                                color: AppColors.gray300,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildInfoItem(
                                  'Negocio',
                                  _usuario!.negocio.nombre,
                                  Icons.business,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                // Resumen de estadísticas
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Resumen',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.titleText,
                      ),
                    ),
                    _buildFiltroFecha(),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Órdenes',
                        totalOrdenes.toString(),
                        Icons.receipt_long,
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatCard(
                        'Total Ingreso al Negocio',
                        'Lps. ${totalIngresos.toStringAsFixed(2)}',
                        Icons.attach_money,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildStatCard(
                  'Tiempo Total',
                  '${totalTiempo} min',
                  Icons.access_time,
                  AppColors.info,
                  fullWidth: true,
                ),
                const SizedBox(height: 24),

                // Servicios realizados
                Text(
                  'Servicios Realizados',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.titleText,
                  ),
                ),
                const SizedBox(height: 16),
                if (serviciosCount.isEmpty)
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.gray300, width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(
                              Icons.content_cut,
                              size: 56,
                              color: AppColors.gray500,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'No hay servicios realizados',
                              style: TextStyle(
                                color: AppColors.gray600,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  ...serviciosCount.entries.map((entry) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.secondary,
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
                          entry.key,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: AppColors.titleText,
                          ),
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${entry.value}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BuildBottomNavigationBar(
        currentIndex: _currentBottomNavIndex,
        cambiarTab: _onBottomNavChanged,
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, IconData icon) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.secondary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 16, color: AppColors.secondary),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.titleText,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool fullWidth = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 35),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppColors.gray600,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.titleText,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFiltroFecha() {
    final tieneFiltro = _tipoFiltro != 'todos';

    return Row(
      children: [
        if (tieneFiltro)
          IconButton(
            icon: const Icon(Icons.clear, size: 20),
            color: AppColors.gray600,
            onPressed: () {
              setState(() {
                _tipoFiltro = 'todos';
                _fechaInicio = null;
                _fechaFin = null;
              });
            },
            tooltip: 'Limpiar filtro',
          ),
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(0, 136, 222, 251).withOpacity(0.15),
                const Color.fromARGB(0, 248, 190, 163).withOpacity(0.08),
                AppColors.white,
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.gray400, width: 1.5),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _mostrarSelectorFecha,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: tieneFiltro
                          ? AppColors.primary
                          : AppColors.gray600,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      tieneFiltro
                          ? _formatearRangoFechas()
                          : 'Filtrar por fecha',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: tieneFiltro
                            ? AppColors.primary
                            : AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatearRangoFechas() {
    switch (_tipoFiltro) {
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
        return 'Filtrar por fecha';
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
            _buildOpcionFiltro('hoy', 'Hoy', Icons.today),
            _buildOpcionFiltro('mes', 'Este mes', Icons.calendar_month),
            _buildOpcionFiltro('dia', 'Día específico', Icons.event),
            _buildOpcionFiltro('rango', 'Rango de fechas', Icons.date_range),
            _buildOpcionFiltro('todos', 'Todos', Icons.clear_all),
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
          _tipoFiltro = 'todos';
          _fechaInicio = null;
          _fechaFin = null;
          break;
        case 'hoy':
          _tipoFiltro = 'hoy';
          _fechaInicio = DateTime(ahora.year, ahora.month, ahora.day);
          _fechaFin = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
          break;
        case 'mes':
          _tipoFiltro = 'mes';
          _fechaInicio = DateTime(ahora.year, ahora.month, 1);
          _fechaFin = DateTime(ahora.year, ahora.month + 1, 0, 23, 59, 59);
          break;
        case 'dia':
          _tipoFiltro = 'dia';
          _aplicarFiltroDiaEspecifico();
          break;
        case 'rango':
          _tipoFiltro = 'rango';
          _aplicarFiltroRango();
          break;
      }
    });
  }

  Widget _buildOpcionFiltro(String valor, String texto, IconData icono) {
    final estaSeleccionado = _tipoFiltro == valor;
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
    } else {
      setState(() {
        _tipoFiltro = 'todos';
        _fechaInicio = null;
        _fechaFin = null;
      });
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
        _tipoFiltro = 'todos';
        _fechaInicio = null;
        _fechaFin = null;
      });
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
    } else {
      setState(() {
        _tipoFiltro = 'todos';
        _fechaInicio = null;
        _fechaFin = null;
      });
    }
  }
}
