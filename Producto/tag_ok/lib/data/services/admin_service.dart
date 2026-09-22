import 'package:supabase_flutter/supabase_flutter.dart';
import '../mock/tolls_database.dart';

class AdminService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> uploadTollsToSupabase() async {
    try {
      final tolls = TollsDatabase.santiagoTolls;

      // Verificamos si ya hay datos para no duplicar si el usuario re-ejecuta
      final existing = await _client.from('porticos').select('id').limit(1);
      if (existing.isNotEmpty) {
        print('TAG_OK_ADMIN: La colección "porticos" ya tiene datos. Abortando para evitar duplicados.');
        return;
      }

      print('TAG_OK_ADMIN: Iniciando subida de ${tolls.length} pórticos...');

      final rows = tolls.map((toll) => {
            'nombre': toll.name,
            'lat': toll.location.latitude,
            'lng': toll.location.longitude,
            'costo': toll.cost,
            'costo_punta': toll.costPunta,
            'costo_saturacion': toll.costSaturacion,
            'sentido': toll.direction,
          }).toList();

      await _client.from('porticos').insert(rows);
      print('TAG_OK_ADMIN: ¡Subida completada con éxito! (${rows.length} pórticos)');
    } catch (e) {
      print('TAG_OK_ADMIN: ERROR CRÍTICO: $e');
    }
  }
}
