-- combustible_cargas_all solo validaba usuario_id = auth.uid(), a diferencia
-- de vehiculo_documentos_all (que ademas valida que el vehiculo referenciado
-- pertenezca al usuario). Esto permitia insertar una carga de combustible
-- con un vehiculo_id ajeno mientras usuario_id fuera el propio.

drop policy if exists combustible_cargas_all on public.combustible_cargas;

create policy combustible_cargas_all on public.combustible_cargas
  for all using (
    is_admin() or (
      usuario_id = auth.uid() and (
        vehiculo_id is null or exists (
          select 1 from public.vehiculos v
          where v.id = combustible_cargas.vehiculo_id and v.usuario_id = auth.uid()
        )
      )
    )
  ) with check (
    is_admin() or (
      usuario_id = auth.uid() and (
        vehiculo_id is null or exists (
          select 1 from public.vehiculos v
          where v.id = combustible_cargas.vehiculo_id and v.usuario_id = auth.uid()
        )
      )
    )
  );
