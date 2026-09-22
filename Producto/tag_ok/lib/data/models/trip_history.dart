class TollRecord {
  final String name;
  final double cost;
  final DateTime timestamp;

  TollRecord({
    required this.name,
    required this.cost,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'cost': cost,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory TollRecord.fromMap(Map<String, dynamic> map) {
    return TollRecord(
      name: map['name'] ?? '',
      cost: (map['cost'] as num).toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}

class TripHistory {
  final String id;
  final DateTime date;
  final double totalCost;
  final List<TollRecord> tolls;
  final double distanceKm;
  final String duration;
  final String vehicleName;

  TripHistory({
    required this.id,
    required this.date,
    required this.totalCost,
    required this.tolls,
    required this.distanceKm,
    required this.duration,
    required this.vehicleName,
  });

  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'total_cost': totalCost,
      'tolls': tolls.map((t) => t.toMap()).toList(),
      'distance_km': distanceKm,
      'duration': duration,
      'vehicle_name': vehicleName,
    };
  }

  factory TripHistory.fromJson(Map<String, dynamic> row) {
    return TripHistory(
      id: row['id'],
      date: DateTime.parse(row['date']),
      totalCost: (row['total_cost'] as num).toDouble(),
      tolls: (row['tolls'] as List).map((t) => TollRecord.fromMap(t)).toList(),
      distanceKm: (row['distance_km'] as num).toDouble(),
      duration: row['duration'] ?? '',
      vehicleName: row['vehicle_name'] ?? 'Desconocido',
    );
  }
}
