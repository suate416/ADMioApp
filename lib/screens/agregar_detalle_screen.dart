import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/orden.model.dart';
import '../widgets/servicios_y_paquetes_widget.dart';

class AgregarDetalleScreen extends StatefulWidget {
  final Orden orden;

  const AgregarDetalleScreen({super.key, required this.orden});

  @override
  State<AgregarDetalleScreen> createState() => _AgregarDetalleScreenState();
}

class _AgregarDetalleScreenState extends State<AgregarDetalleScreen> {
  final AuthService _authService = AuthService();
  int? _negocioId;

  @override
  void initState() {
    super.initState();
    _loadNegocioId();
  }

  Future<void> _loadNegocioId() async {
    try {
      final usuario = await _authService.getUsuario();
      if (usuario != null && mounted) {
      setState(() {
          _negocioId = usuario.negocioId;
      });
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_negocioId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Agregar a Orden #${widget.orden.id}'),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Agregar a Orden #${widget.orden.id}'),
      ),
      body: ServiciosYPaquetesWidget(
        negocioId: _negocioId!,
        ordenActiva: widget.orden,
        onServicioAgregado: () {
          Navigator.pop(context, true);
                                  },
                ),
    );
  }
}

