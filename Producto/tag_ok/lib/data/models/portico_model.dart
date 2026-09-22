class PorticoModel {
  final String id;
  final String nombre;
  final double lat;
  final double lng;
  final String? nombreAutopista;

  PorticoModel({
    required this.id,
    required this.nombre,
    required this.lat,
    required this.lng,
    this.nombreAutopista,
  });

  factory PorticoModel.fromJson(Map<String, dynamic> row) {
    return PorticoModel(
      id: row['id'] ?? '',
      nombre: row['nombre'] ?? '',
      lat: (row['lat'] as num).toDouble(),
      lng: (row['lng'] as num).toDouble(),
      nombreAutopista: row['autopista'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'lat': lat,
      'lng': lng,
      'autopista': nombreAutopista,
    };
  }
}
