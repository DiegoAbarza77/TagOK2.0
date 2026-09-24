import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../mock/tolls_database.dart';
import '../models/route_model.dart';

/// Fuente de los pórticos y tarifas que usa el cálculo de peajes.
///
/// Lee la tabla `porticos` de Supabase (la misma que edita el panel admin),
/// así un cambio de tarifa hecho por el admin se aplica en el próximo cálculo
/// de ruta. Si Supabase no responde o la tabla está vacía, usa la lista local
/// de `TollsDatabase` como respaldo para que la app siga calculando rutas.
class PorticosRepository {
  PorticosRepository._();
  static final PorticosRepository instance = PorticosRepository._();

  /// Tiempo que se reutiliza la lista antes de volver a consultar Supabase.
  static const Duration _cacheTtl = Duration(minutes: 5);

  List<TollData>? _cache;
  DateTime? _cachedAt;

  Future<List<TollData>> getPorticos({bool forceRefresh = false}) async {
    final cache = _cache;
    final cachedAt = _cachedAt;
    if (!forceRefresh &&
        cache != null &&
        cachedAt != null &&
        DateTime.now().difference(cachedAt) < _cacheTtl) {
      return cache;
    }

    try {
      final rows = await Supabase.instance.client.from('porticos').select();
      final porticos = rows.map(_fromRow).toList();
      if (porticos.isEmpty) {
        debugPrint('PorticosRepository: la tabla porticos está vacía; usando la lista local.');
        return cache ?? TollsDatabase.santiagoTolls;
      }
      _cache = porticos;
      _cachedAt = DateTime.now();
      return porticos;
    } catch (e) {
      debugPrint('PorticosRepository: no se pudo leer porticos ($e); usando respaldo.');
      return cache ?? TollsDatabase.santiagoTolls;
    }
  }

  static TollData _fromRow(Map<String, dynamic> row) {
    return TollData(
      name: row['nombre'] ?? '',
      location: LatLng((row['lat'] as num).toDouble(), (row['lng'] as num).toDouble()),
      cost: (row['costo'] as num?)?.toDouble() ?? 0,
      costPunta: (row['costo_punta'] as num?)?.toDouble(),
      costSaturacion: (row['costo_saturacion'] as num?)?.toDouble(),
      direction: row['sentido'],
      highway: row['autopista'],
      group: row['grupo'],
      sequence: int.tryParse('${row['secuencia'] ?? ''}'),
    );
  }
}
