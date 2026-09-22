class UsuarioModel {
  final String uid;
  final String email;
  final String? nombreMostrar;
  final String? telefono;
  final DateTime fechaCreacion;
  final String? vehiculoPrincipalPatente;
  final double limitePresupuestoMensual;
  final bool notifCobros;
  final bool notifPresupuesto;
  final Map<String, dynamic> alertasVistas;

  UsuarioModel({
    required this.uid,
    required this.email,
    this.nombreMostrar,
    this.telefono,
    required this.fechaCreacion,
    this.vehiculoPrincipalPatente,
    this.limitePresupuestoMensual = 0.0,
    this.notifCobros = true,
    this.notifPresupuesto = true,
    this.alertasVistas = const {},
  });

  factory UsuarioModel.fromJson(Map<String, dynamic> row) {
    return UsuarioModel(
      uid: row['id'] ?? '',
      email: row['email'] ?? '',
      nombreMostrar: row['nombre_mostrar'],
      telefono: row['telefono'],
      fechaCreacion: DateTime.parse(row['fecha_creacion']),
      vehiculoPrincipalPatente: row['vehiculo_principal_patente'],
      limitePresupuestoMensual: (row['limite_presupuesto_mensual'] ?? 0.0).toDouble(),
      notifCobros: row['notif_cobros'] ?? true,
      notifPresupuesto: row['notif_presupuesto'] ?? true,
      alertasVistas: Map<String, dynamic>.from(row['alertas_vistas'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'nombre_mostrar': nombreMostrar,
      'telefono': telefono,
      'vehiculo_principal_patente': vehiculoPrincipalPatente,
      'limite_presupuesto_mensual': limitePresupuestoMensual,
      'notif_cobros': notifCobros,
      'notif_presupuesto': notifPresupuesto,
      'alertas_vistas': alertasVistas,
    };
  }
}
