import 'package:flutter/material.dart';
import '../services/orden_detalle.service.dart';
import '../services/servicio.service.dart';
import '../services/paquete.service.dart';
import '../models/orden.model.dart';
import '../models/servicio.model.dart';
import '../models/paquete.model.dart';
import '../config/app_colors.dart';

class ServiciosYPaquetesWidget extends StatefulWidget {
  final int negocioId;
  final Orden? ordenActiva;
  final VoidCallback? onServicioAgregado;

  const ServiciosYPaquetesWidget({
    super.key,
    required this.negocioId,
    this.ordenActiva,
    this.onServicioAgregado,
  });

  @override
  State<ServiciosYPaquetesWidget> createState() => _ServiciosYPaquetesWidgetState();
}

class _ServiciosYPaquetesWidgetState extends State<ServiciosYPaquetesWidget> {
  final OrdenDetalleService _ordenDetalleService = OrdenDetalleService();
  final ServicioService _servicioService = ServicioService();
  final PaqueteService _paqueteService = PaqueteService();
  
  List<Servicio> _servicios = [];
  List<Paquete> _paquetes = [];
  bool _isLoading = false;
  bool _isLoadingDatos = true;
  String _searchQuery = '';
  int _selectedTab = 0; // 0 = Servicios, 1 = Paquetes

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() {
      _isLoadingDatos = true;
    });

    try {
      final servicios = await _servicioService.getServiciosByNegocio(widget.negocioId);
      final paquetes = await _paqueteService.getPaquetesByNegocio(widget.negocioId);

      if (mounted) {
        setState(() {
          _servicios = servicios;
          _paquetes = paquetes;
          _isLoadingDatos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingDatos = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar datos: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _agregarServicio(Servicio servicio) async {
    if (widget.ordenActiva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes tener una orden en proceso para agregar servicios'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _ordenDetalleService.createOrdenDetalle(
        ordenId: widget.ordenActiva!.id,
        servicioId: servicio.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Servicio "${servicio.nombre}" agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.onServicioAgregado != null) {
          widget.onServicioAgregado!();
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _agregarPaquete(Paquete paquete) async {
    if (widget.ordenActiva == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes tener una orden en proceso para agregar paquetes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await _ordenDetalleService.createOrdenDetalle(
        ordenId: widget.ordenActiva!.id,
        paqueteId: paquete.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Paquete "${paquete.nombre}" agregado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        if (widget.onServicioAgregado != null) {
          widget.onServicioAgregado!();
        }
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Servicio> _getServiciosFiltrados() {
    if (_searchQuery.isEmpty) {
      return _servicios;
    }
    return _servicios.where((servicio) {
      final nombre = servicio.nombre.toLowerCase();
      final codigo = servicio.codigo?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return nombre.contains(query) || codigo.contains(query);
    }).toList();
  }

  List<Paquete> _getPaquetesFiltrados() {
    if (_searchQuery.isEmpty) {
      return _paquetes;
    }
    return _paquetes.where((paquete) {
      final nombre = paquete.nombre.toLowerCase();
      final codigo = paquete.codigo?.toLowerCase() ?? '';
      final query = _searchQuery.toLowerCase();
      return nombre.contains(query) || codigo.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingDatos) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _cargarDatos,
      child: Column(
        children: [
          // Tabs de Servicios y Paquetes
          Card(
            margin: const EdgeInsets.all(8),
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Servicios (${_servicios.length})'),
                      selected: _selectedTab == 0,
                      selectedColor: AppColors.secondary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _selectedTab == 0
                            ? AppColors.secondary
                            : AppColors.gray600,
                        fontWeight: _selectedTab == 0
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTab = 0;
                            _searchQuery = '';
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: Text('Paquetes (${_paquetes.length})'),
                      selected: _selectedTab == 1,
                      selectedColor: AppColors.primary.withOpacity(0.2),
                      labelStyle: TextStyle(
                        color: _selectedTab == 1
                            ? AppColors.primary
                            : AppColors.gray600,
                        fontWeight: _selectedTab == 1
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedTab = 1;
                            _searchQuery = '';
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Barra de búsqueda
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: _selectedTab == 0 ? 'Buscar servicio' : 'Buscar paquete',
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
          // Lista de servicios o paquetes
          Expanded(
            child: _selectedTab == 0
                ? _buildListaServicios()
                : _buildListaPaquetes(),
          ),
          // Mensaje si no hay orden activa
          if (widget.ordenActiva == null)
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.warning),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.warning, size: 40,),
                  const SizedBox(width: 12),
                  Expanded(
                    child:                       Text(
                        'Crea una orden en proceso para poder agregar servicios o paquetes',
                        style: TextStyle(
                          color: AppColors.secondaryDark,
                          fontSize: 16,
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

  Widget _buildListaServicios() {
    final serviciosFiltrados = _getServiciosFiltrados();

    if (_servicios.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cut, size: 64, color: AppColors.gray500),
            const SizedBox(height: 16),
            Text(
              'No hay servicios disponibles',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    if (serviciosFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.gray500),
            const SizedBox(height: 16),
            Text(
              'No se encontraron servicios',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: serviciosFiltrados.length,
      itemBuilder: (context, index) {
        final servicio = serviciosFiltrados[index];
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
              servicio.nombre,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.titleText,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (servicio.codigo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Código: ${servicio.codigo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Precio: Lps. ${servicio.precioTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (servicio.duracionEstimada != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Duración Estimada: ${servicio.duracionEstimada} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
              ],
            ),
            trailing: widget.ordenActiva == null
                ? Icon(
                    Icons.info_outline,
                    color: AppColors.gray500,
                  )
                : _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.success,
                        ),
                        onPressed: () => _agregarServicio(servicio),
                        tooltip: 'Agregar a orden',
                      ),
            onTap: widget.ordenActiva == null || _isLoading
                ? null
                : () => _agregarServicio(servicio),
          ),
        );
      },
    );
  }

  Widget _buildListaPaquetes() {
    final paquetesFiltrados = _getPaquetesFiltrados();

    if (_paquetes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2, size: 64, color: AppColors.gray500),
            const SizedBox(height: 16),
            Text(
              'No hay paquetes disponibles',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    if (paquetesFiltrados.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: AppColors.gray500),
            const SizedBox(height: 16),
            Text(
              'No se encontraron paquetes',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: paquetesFiltrados.length,
      itemBuilder: (context, index) {
        final paquete = paquetesFiltrados[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary,
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
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.inventory_2,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            title: Text(
              paquete.nombre,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: AppColors.titleText,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (paquete.codigo != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Código: ${paquete.codigo}',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  'Precio: Lps. ${paquete.precioTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (paquete.duracionTotal != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Duración: ${paquete.duracionTotal} min',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.gray600,
                    ),
                  ),
                ],
                if (paquete.servicios != null && paquete.servicios!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Servicios incluidos:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.gray700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...paquete.servicios!.map((servicio) => Padding(
                        padding: const EdgeInsets.only(left: 8, top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              size: 14,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                servicio.nombre,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.gray600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
            trailing: widget.ordenActiva == null
                ? Icon(
                    Icons.info_outline,
                    color: AppColors.gray500,
                  )
                : _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : IconButton(
                        icon: const Icon(
                          Icons.add_circle,
                          color: AppColors.success,
                        ),
                        onPressed: () => _agregarPaquete(paquete),
                        tooltip: 'Agregar a orden',
                      ),
            onTap: widget.ordenActiva == null || _isLoading
                ? null
                : () => _agregarPaquete(paquete),
          ),
        );
      },
    );
  }
}

