-- Crea automaticamente la fila de public.usuarios cuando se registra un
-- nuevo usuario en auth.users. Reemplaza el segundo insert que hacia
-- AuthRepository.signUpWithEmailAndPassword del lado del cliente.

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.usuarios (id, email, nombre_mostrar, telefono, limite_presupuesto_mensual)
  values (
    new.id,
    new.email,
    new.raw_user_meta_data ->> 'nombre_mostrar',
    new.raw_user_meta_data ->> 'telefono',
    50000.00
  );
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
