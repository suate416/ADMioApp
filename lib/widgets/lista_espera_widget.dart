import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../services/orden.service.dart';
import '../models/orden.model.dart';
import '../config/app_colors.dart';

class ListaEsperaWidget extends StatefulWidget {
  final int sucursalId;

  const ListaEsperaWidget({
    super.key,
    required this.sucursalId,
  });

  @override
  State<ListaEsperaWidget> createState() => _ListaEsperaWidgetState();
}

class _ListaEsperaWidgetState extends State<ListaEsperaWidget> {
  final OrdenService _ordenService = OrdenService();
  List<Orden> _listaEspera = [];
  bool _isLoadingListaEspera = false;

  @override
  void initState() {
    super.initState();
    _cargarListaEspera();
  }

  Future<void> _cargarListaEspera() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingListaEspera = true;
    });
    
    try {
      final ordenes = await _ordenService.getOrdenesBySucursal(widget.sucursalId);
      final ordenesPendientes = ordenes.where((orden) => 
        orden.estado.toLowerCase() == 'pendiente' && orden.activo
      ).toList();
      
      if (mounted) {
        setState(() {
          _listaEspera = ordenesPendientes;
          _isLoadingListaEspera = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _listaEspera = [];
          _isLoadingListaEspera = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.person_add_alt_1,
                    color: AppColors.secondary,
                    size: 25,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lista de Espera',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.titleText,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (_isLoadingListaEspera)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          '${_listaEspera.length} ${_listaEspera.length == 1 ? 'cliente' : 'clientes'} en espera',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.gray600,
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isLoadingListaEspera)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_listaEspera.length}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (_listaEspera.isNotEmpty)
            Container(
              height: 1,
              color: AppColors.gray300,
            ),
          const SizedBox(height: 16),
          if (_isLoadingListaEspera)
            const Padding(
              padding: EdgeInsets.all(24.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            )
          else if (_listaEspera.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline,
                      size: 56,
                      color: AppColors.gray500,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No hay clientes en espera',
                      style: TextStyle(
                        fontSize: 16,
                        color: AppColors.gray600,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.5,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: _listaEspera.length,
                itemBuilder: (context, index) {
                  final orden = _listaEspera[index];
                  final isLast = index == _listaEspera.length - 1;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.secondary.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.secondary,
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
                                    'Orden #${orden.id}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.titleText,
                                    ),
                                  ),
                                  if (orden.usuario != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      '${orden.usuario!.nombre} ${orden.usuario!.apellido}',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.gray600,
                                      ),
                                    ),
                                  ],
                                  if (orden.estacion != null) ...[
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.place,
                                          size: 14,
                                          color: AppColors.gray500,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Estación: ${orden.estacion!.codigo}',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.gray500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.warning.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.warning.withOpacity(0.3),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Pendiente',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.warning,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (!isLast)
                        Container(
                          height: 1,
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          color: AppColors.gray300,
                        ),
                    ],
                  )
                      .animate()
                      .fadeIn(duration: 700.ms)
                      .slideY(
                        begin: 0.1,
                        end: 0,
                        duration: 700.ms,
                        delay: (index * 100).ms,
                      );
                },
              ),
            ),
        ],
      ),
    );
  }
}

