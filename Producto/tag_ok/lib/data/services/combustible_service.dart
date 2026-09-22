import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/carga_combustible_model.dart';

class CombustibleService {
  final SupabaseClient _client = Supabase.instance.client;

  String get _userId => _client.auth.currentUser!.id;

  Stream<List<CargaCombustibleModel>> streamPorVehiculo(String vehiculoId) {
    return _client
        .from('combustible_cargas')
        .stream(primaryKey: ['id'])
        .eq('usuario_id', _userId)
        .eq('vehiculo_id', vehiculoId)
        .order('fecha', ascending: false)
        .map((rows) => rows.map((row) => CargaCombustibleModel.fromJson(row)).toList());
  }

  Future<void> agregarCarga(CargaCombustibleModel carga) async {
    await _client.from('combustible_cargas').insert({
      ...carga.toJson(),
      'usuario_id': _userId,
    });
  }

  Future<void> eliminarCarga(String id) async {
    await _client.from('combustible_cargas').delete().eq('id', id);
  }
}
