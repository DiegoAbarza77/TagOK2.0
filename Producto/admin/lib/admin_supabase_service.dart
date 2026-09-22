import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOverview {
  const AdminOverview({
    required this.users,
    required this.vehicles,
    required this.porticos,
    required this.tariffs,
  });

  final int users;
  final int vehicles;
  final int porticos;
  final int tariffs;
}

class ReportMetrics {
  const ReportMetrics({
    required this.totalUsers,
    required this.totalVehicles,
    required this.totalTrips,
    required this.totalTollCost,
    required this.averageCostPerTrip,
    required this.costByHighway,
  });

  final int totalUsers;
  final int totalVehicles;
  final int totalTrips;
  final double totalTollCost;
  final double averageCostPerTrip;
  final Map<String, double> costByHighway;
}

class AdminSupabaseService {
  AdminSupabaseService({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  String _classifyHighway(String tollName) {
    final name = tollName.toLowerCase();
    if (name.contains('autopista de conexión') || name.contains('conexión')) {
      return 'Conexión / Otras';
    }
    if (name.startsWith('pa') ||
        name.contains('autopista central') ||
        name.contains('ruta 5')) {
      return 'Autopista Central';
    }
    if (name.contains('costanera') ||
        name.contains('vivaceta') ||
        name.contains('lo saldes') ||
        name.contains('la dehesa') ||
        name.contains('estoril') ||
        name.contains('padre arteaga') ||
        name.contains('tranqueras') ||
        name.contains('carrascal') ||
        name.contains('padre hurtado') ||
        name.startsWith('ev ') ||
        name.startsWith('sv ')) {
      return 'Costanera Norte';
    }
    if (name.contains('avo') ||
        name.contains('kennedy') ||
        name.contains('p101') ||
        name.contains('p102') ||
        name.contains('vespucio oriente')) {
      return 'Vespucio Oriente (AVO)';
    }
    if (name.contains('vespucio norte') ||
        name.contains('guanaco') ||
        name.contains('el salto') ||
        name.contains('lo boza') ||
        name.contains('recabal') ||
        name.contains('enea') ||
        name.contains('p14') ||
        name.contains('p13') ||
        name.contains('p12') ||
        name.contains('p15')) {
      return 'Vespucio Norte';
    }
    if (name.contains('vespucio sur') ||
        name.contains('pvs') ||
        name.contains('velásquez') ||
        name.contains('velasquez') ||
        name.contains('gran avenida') ||
        name.contains('santa rosa') ||
        name.contains('vicuña mackenna') ||
        name.contains('alderete') ||
        name.contains('2a transversal') ||
        name.contains('los mares') ||
        name.contains('coronel') ||
        name.contains('camino a melipilla')) {
      return 'Vespucio Sur';
    }
    if (name.contains('ruta 68')) {
      return 'Conexión / Otras';
    }
    if (name.contains('ruta 78') || name.contains('autopista del sol')) {
      return 'Conexión / Otras';
    }
    return 'Conexión / Otras';
  }

  Future<ReportMetrics> fetchReportMetrics() async {
    final users = await _client.from('usuarios').select('id').count(CountOption.exact);
    final vehicles = await _client.from('vehiculos').select('id').count(CountOption.exact);
    // RLS (is_admin() OR usuario_id = auth.uid()) le da al admin visibilidad
    // de los viajes de todos los usuarios; reemplaza al collectionGroup('trips') de Firestore.
    final tripsRows = await _client.from('trips').select('total_cost, tolls');

    final int totalUsers = users.count;
    final int totalVehicles = vehicles.count;
    final int totalTrips = tripsRows.length;

    double totalTollCost = 0.0;
    final Map<String, double> costByHighway = {
      'Autopista Central': 0.0,
      'Costanera Norte': 0.0,
      'Vespucio Norte': 0.0,
      'Vespucio Sur': 0.0,
      'Vespucio Oriente (AVO)': 0.0,
      'Conexión / Otras': 0.0,
    };

    for (var row in tripsRows) {
      final double tripCost = (row['total_cost'] as num?)?.toDouble() ?? 0.0;
      totalTollCost += tripCost;

      final List<dynamic> tollsList = row['tolls'] as List<dynamic>? ?? [];
      for (var tollRaw in tollsList) {
        if (tollRaw is Map) {
          final String tollName = (tollRaw['name'] ?? '').toString();
          final double tollCost =
              double.tryParse(tollRaw['cost']?.toString() ?? '0') ?? 0.0;
          final String highway = _classifyHighway(tollName);

          if (costByHighway.containsKey(highway)) {
            costByHighway[highway] = costByHighway[highway]! + tollCost;
          } else {
            costByHighway['Conexión / Otras'] =
                costByHighway['Conexión / Otras']! + tollCost;
          }
        }
      }
    }

    final double averageCostPerTrip = totalTrips > 0
        ? (totalTollCost / totalTrips)
        : 0.0;

    return ReportMetrics(
      totalUsers: totalUsers,
      totalVehicles: totalVehicles,
      totalTrips: totalTrips,
      totalTollCost: totalTollCost,
      averageCostPerTrip: averageCostPerTrip,
      costByHighway: costByHighway,
    );
  }

  Future<AdminOverview> fetchOverview() async {
    final results = await Future.wait([
      _count('usuarios'),
      _count('vehiculos'),
      _count('porticos'),
      _count('tarifas'),
    ]);

    return AdminOverview(
      users: results[0],
      vehicles: results[1],
      porticos: results[2],
      tariffs: results[3],
    );
  }

  Stream<List<Map<String, dynamic>>> streamUsers() {
    return _client.from('usuarios').stream(primaryKey: ['id']);
  }

  Stream<List<Map<String, dynamic>>> streamPorticos() {
    return _client.from('porticos').stream(primaryKey: ['id']);
  }

  Stream<List<Map<String, dynamic>>> streamTariffs() {
    return _client
        .from('tarifas')
        .stream(primaryKey: ['id'])
        .order('fecha_actualizacion', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamUserTrips() {
    return _client.from('trips').stream(primaryKey: ['id']).order('date', ascending: false);
  }

  Future<void> logAction({
    required String action,
    required String target,
    required String details,
  }) async {
    final String adminEmail = _client.auth.currentUser?.email ?? 'admin_desconocido';
    await _client.from('auditoria').insert({
      'admin_email': adminEmail,
      'action': action,
      'target': target,
      'details': details,
    });
  }

  Stream<List<Map<String, dynamic>>> streamAuditLogs() {
    return _client
        .from('auditoria')
        .stream(primaryKey: ['id'])
        .order('fecha', ascending: false);
  }

  Stream<List<Map<String, dynamic>>> streamAdministradores() {
    return _client.from('administradores').stream(primaryKey: ['id']);
  }

  Future<void> updateAdminRole(String docId, String role) async {
    await _client.from('administradores').update({'rol': role}).eq('id', docId);
  }

  /// Borra al administrador y su cuenta de Auth completa a través de la
  /// Edge Function "delete-user" (requiere la service-role key en el
  /// servidor, no disponible en el cliente Flutter). Evita dejar cuentas de
  /// Auth huérfanas, a diferencia del borrado directo de Firestore de antes.
  Future<void> deleteAdmin(String docId) async {
    final response = await _client.functions.invoke(
      'delete-user',
      body: {'userId': docId},
    );
    if (response.status != 200) {
      throw Exception('No se pudo eliminar el administrador: ${response.data}');
    }
  }

  Future<int> _count(String table) async {
    final response = await _client.from(table).select('id').count(CountOption.exact);
    return response.count;
  }
}
