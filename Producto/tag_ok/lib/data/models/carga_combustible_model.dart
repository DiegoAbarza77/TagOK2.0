class CargaCombustibleModel {
  final String id;
  final String vehiculoId;
  final String vehiculoPatente;
  final DateTime fecha;
  final double? kilometraje;
  final String estacion;
  final String? tipoCombustible;
  final double litros;
  final double precioLitro;
  final double total;

  CargaCombustibleModel({
    required this.id,
    required this.vehiculoId,
    required this.vehiculoPatente,
    required this.fecha,
    this.kilometraje,
    required this.estacion,
    this.tipoCombustible,
    required this.litros,
    required this.precioLitro,
    required this.total,
  });

  factory CargaCombustibleModel.fromJson(Map<String, dynamic> row) {
    return CargaCombustibleModel(
      id: row['id'] ?? '',
      vehiculoId: row['vehiculo_id'] ?? '',
      vehiculoPatente: row['vehiculo_patente'] ?? '',
      fecha: DateTime.parse(row['fecha']),
      kilometraje: (row['kilometraje'] as num?)?.toDouble(),
      estacion: row['estacion'] ?? '',
      tipoCombustible: row['tipo_combustible'],
      litros: (row['litros'] as num?)?.toDouble() ?? 0.0,
      precioLitro: (row['precio_litro'] as num?)?.toDouble() ?? 0.0,
      total: (row['total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'vehiculo_id': vehiculoId,
      'vehiculo_patente': vehiculoPatente,
      'fecha': fecha.toIso8601String(),
      'kilometraje': kilometraje,
      'estacion': estacion,
      'tipo_combustible': tipoCombustible,
      'litros': litros,
      'precio_litro': precioLitro,
      'total': total,
    };
  }
}
