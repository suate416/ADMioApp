import 'package:flutter/material.dart';
import '../models/usuario.model.dart';
import '../models/orden.model.dart';
import '../config/app_colors.dart';

class CrearOrdenModal extends StatefulWidget {
  final Usuario usuario;
  final Estacion estacionSeleccionada;
  final List<Estacion> estaciones;
  final Function(Estacion) onEstacionChanged;
  final Function(String? observaciones) onCreateOrden;
  final bool isLoading;

  const CrearOrdenModal({
    super.key,
    required this.usuario,
    required this.estacionSeleccionada,
    required this.estaciones,
    required this.onEstacionChanged,
    required this.onCreateOrden,
    required this.isLoading,
  });

  @override
  State<CrearOrdenModal> createState() => _CrearOrdenModalState();
}

class _CrearOrdenModalState extends State<CrearOrdenModal> {
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
                            final observaciones = _observacionesController.text.trim().isEmpty
                                ? null
                                : _observacionesController.text.trim();
                            widget.onCreateOrden(observaciones);
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

