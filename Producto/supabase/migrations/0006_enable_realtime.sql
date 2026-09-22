-- Supabase NO habilita Realtime automáticamente al crear una tabla; hay que
-- agregarla explícitamente a la publicación "supabase_realtime". Todas las
-- pantallas que usan .stream() (StreamBuilder en Flutter) dependen de esto.
-- Descubierto en vivo: el dashboard de admin fallaba con
-- "RealtimeSubscribeException ... Please check Realtime is enabled" porque
-- la tabla "trips" nunca se agregó a la publicación.
--
-- El bloque DO evita que el script falle si una tabla ya estaba agregada
-- (por ejemplo, si el proyecto la activó a mano desde el dashboard).
do $$
declare
  t text;
begin
  foreach t in array array[
    'usuarios',
    'vehiculos',
    'vehiculo_documentos',
    'trips',
    'combustible_cargas',
    'audited_invoices',
    'porticos',
    'tarifas',
    'auditoria',
    'administradores',
    'beneficios',
    'mantenciones',
    'estacionamientos'
  ] loop
    begin
      execute format('alter publication supabase_realtime add table public.%I', t);
    exception when duplicate_object then
      -- ya estaba agregada a la publicación, no hacer nada
      null;
    end;
  end loop;
end $$;
