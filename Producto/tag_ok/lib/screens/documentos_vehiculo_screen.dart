import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/models/documento_vehiculo_model.dart';
import '../data/services/vehiculo_documentos_service.dart';

class DocumentosVehiculoScreen extends StatefulWidget {
  final String vehiculoId;
  final String patente;

  const DocumentosVehiculoScreen({
    super.key,
    required this.vehiculoId,
    required this.patente,
  });

  @override
  State<DocumentosVehiculoScreen> createState() => _DocumentosVehiculoScreenState();
}

class _DocumentosVehiculoScreenState extends State<DocumentosVehiculoScreen> {
  final Color bgColor = const Color(0xFF0F172A);
  final Color primaryColor = const Color(0xFF4F46E5);
  final Color navBgColor = const Color(0xFF1E293B);
  final Color textMuted = const Color(0xFF94A3B8);
  final Color textMain = const Color(0xFFF8FAFC);

  final VehiculoDocumentosService _service = VehiculoDocumentosService();

  Color _colorEstado(EstadoVencimiento estado) {
    switch (estado) {
      case EstadoVencimiento.alDia:
        return const Color(0xFF10B981);
      case EstadoVencimiento.atencion:
        return const Color(0xFFF59E0B);
      case EstadoVencimiento.vencido:
        return const Color(0xFFEF4444);
      case EstadoVencimiento.sinDatos:
        return textMuted;
    }
  }

  String _labelEstado(EstadoVencimiento estado) {
    switch (estado) {
      case EstadoVencimiento.alDia:
        return 'Al día';
      case EstadoVencimiento.atencion:
        return 'Por vencer';
      case EstadoVencimiento.vencido:
        return 'Vencido';
      case EstadoVencimiento.sinDatos:
        return 'Sin datos';
    }
  }

  IconData _iconoEstado(EstadoVencimiento estado) {
    switch (estado) {
      case EstadoVencimiento.alDia:
        return Icons.check_circle;
      case EstadoVencimiento.atencion:
        return Icons.warning_amber_rounded;
      case EstadoVencimiento.vencido:
        return Icons.error;
      case EstadoVencimiento.sinDatos:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text('Documentos · ${widget.patente}', style: const TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<List<DocumentoVehiculoModel>>(
        stream: _service.streamDocumentos(widget.vehiculoId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error al cargar documentos: ${snapshot.error}', style: TextStyle(color: textMain)),
            );
          }

          final documentos = snapshot.data ?? [];
          final estadoGeneral = peorEstado(documentos.map((d) => d.estado).toList());

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: navBgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _colorEstado(estadoGeneral).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Icon(_iconoEstado(estadoGeneral), color: _colorEstado(estadoGeneral), size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Estado general del vehículo', style: TextStyle(color: textMuted, fontSize: 12)),
                          Text(
                            _labelEstado(estadoGeneral),
                            style: TextStyle(color: _colorEstado(estadoGeneral), fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ...documentos.map((doc) => _buildDocumentoCard(doc)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDocumentoCard(DocumentoVehiculoModel doc) {
    final color = _colorEstado(doc.estado);
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Card(
      color: navBgColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _mostrarFormularioDocumento(doc),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                child: Icon(Icons.description_outlined, color: primaryColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(doc.label, style: TextStyle(color: textMain, fontWeight: FontWeight.bold, fontSize: 15)),
                    const SizedBox(height: 4),
                    if (doc.numero != null && doc.numero!.isNotEmpty)
                      Text('N° ${doc.numero}', style: TextStyle(color: textMuted, fontSize: 12)),
                    if (doc.compania != null && doc.compania!.isNotEmpty)
                      Text(doc.compania!, style: TextStyle(color: textMuted, fontSize: 12)),
                    if (doc.fechaVencimiento != null)
                      Text('Vence: ${dateFmt.format(doc.fechaVencimiento!)}', style: TextStyle(color: textMuted, fontSize: 12))
                    else
                      Text('Toca para agregar datos', style: TextStyle(color: textMuted.withValues(alpha: 0.7), fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _labelEstado(doc.estado),
                  style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarFormularioDocumento(DocumentoVehiculoModel doc) {
    final numeroCtrl = TextEditingController(text: doc.numero ?? '');
    final companiaCtrl = TextEditingController(text: doc.compania ?? '');
    DateTime? fechaEmision = doc.fechaEmision;
    DateTime? fechaVencimiento = doc.fechaVencimiento;
    final dateFmt = DateFormat('dd/MM/yyyy');

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Future<void> pickDate(bool esVencimiento) async {
              final picked = await showDatePicker(
                context: context,
                initialDate: (esVencimiento ? fechaVencimiento : fechaEmision) ?? DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setModalState(() {
                  if (esVencimiento) {
                    fechaVencimiento = picked;
                  } else {
                    fechaEmision = picked;
                  }
                });
              }
            }

            return AlertDialog(
              backgroundColor: navBgColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(doc.label, style: TextStyle(color: textMain, fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: numeroCtrl,
                      style: TextStyle(color: textMain),
                      decoration: InputDecoration(
                        labelText: 'Número de documento',
                        labelStyle: TextStyle(color: textMuted),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textMuted.withValues(alpha: 0.5))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: companiaCtrl,
                      style: TextStyle(color: textMain),
                      decoration: InputDecoration(
                        labelText: 'Compañía / Emisor',
                        labelStyle: TextStyle(color: textMuted),
                        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: textMuted.withValues(alpha: 0.5))),
                        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: primaryColor)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildDateRow(
                      label: 'Fecha de emisión',
                      valor: fechaEmision != null ? dateFmt.format(fechaEmision!) : 'Sin definir',
                      onTap: () => pickDate(false),
                    ),
                    const SizedBox(height: 12),
                    _buildDateRow(
                      label: 'Fecha de vencimiento',
                      valor: fechaVencimiento != null ? dateFmt.format(fechaVencimiento!) : 'Sin definir',
                      onTap: () => pickDate(true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancelar', style: TextStyle(color: textMuted)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    final nuevoDoc = DocumentoVehiculoModel(
                      tipo: doc.tipo,
                      numero: numeroCtrl.text.trim().isEmpty ? null : numeroCtrl.text.trim(),
                      compania: companiaCtrl.text.trim().isEmpty ? null : companiaCtrl.text.trim(),
                      fechaEmision: fechaEmision,
                      fechaVencimiento: fechaVencimiento,
                    );
                    await _service.guardarDocumento(widget.vehiculoId, nuevoDoc);
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text('Guardar', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDateRow({required String label, required String valor, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(Icons.calendar_today_outlined, color: textMuted, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(color: textMuted, fontSize: 11)),
                  Text(valor, style: TextStyle(color: textMain, fontSize: 14, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Icon(Icons.edit, color: primaryColor, size: 16),
          ],
        ),
      ),
    );
  }
}
